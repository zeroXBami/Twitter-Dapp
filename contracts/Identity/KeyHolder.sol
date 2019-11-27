pragma solidity ^0.4.24;

import "./ERC725.sol";

contract KeyHolder is ERC725 {
    uint256 executionNonce;

    struct Execution {
        address to;
        uint256 value;
        bytes data;
        bool approved;
        bool executed;
    }

    mapping(bytes32 => Key) keys;
    mapping(uint256 => bytes32[]) keysByPurpose;
    mapping(uint256 => Execution) executions;

    event ExecutionFailed(uint256 indexed executionId, address indexed to, uint256 indexed value, bytes data);

    constructor() public {
        bytes32 _key = keccak256(msg.sender);
        keys[_key].key = _key;
        keys[_key].purpose = 1;
        keys[_key].keyType = 1;
        keysByPurpose[1].push(_key);
        emit KeyAdded(_key, keys[_key].purpose, 1);
    }

    /**
    * @dev Implementation of the getKey function from the ERC-725 standard
    * @param _key The public key.  for non-hex and long keys, its the Keccak256 hash of the key
    * @return Returns the full key data, if present in the identity.
    */

    function getKey(bytes32 _key) public view returns (uint256 purpose, uint256 keyType, bytes32 key) {
        return (keys[_key].purpose, keys[_key].keyType, keys[_key].key);
    }

    /**
    * @dev gets the purpose of a key
    * @param _key The public key.  for non-hex and long keys, its the Keccak256 hash of the key
    * @return Returns the purpose of the specified key
    */

    function getKeyPurpose(bytes32 _key) public view returns (uint256 purpose) {
        return (keys[_key].purpose);
    }

    /**
    * @dev gets all the keys with a specific purpose from an identity
    * @param _purpose a uint256[] Array of the key types, like 1 = MANAGEMENT, 2 = ACTION, 3 = CLAIM, 4 = ENCRYPTION
    * @return Returns an array of public key bytes32 hold by this identity and having the specified purpose
    */

    function getKeysByPurpose(uint256 _purpose) public view returns (bytes32[] memory _keys) {
        return keysByPurpose[_purpose];
    }

    /**
    * @dev implementation of the addKey function of the ERC-725 standard
    * Adds a _key to the identity. The _purpose specifies the purpose of key. Initially we propose four purposes:
    * 1: MANAGEMENT keys, which can manage the identity
    * 2: ACTION keys, which perform actions in this identities name (signing, logins, transactions, etc.)
    * 3: CLAIM signer keys, used to sign claims on other identities which need to be revokable.
    * 4: ENCRYPTION keys, used to encrypt data e.g. hold in claims.
    * MUST only be done by keys of purpose 1, or the identity itself.
    * If its the identity itself, the approval process will determine its approval.
    *
    * @param _key keccak256 representation of an ethereum address
    * @param _type type of key used, which would be a uint256 for different key types. e.g. 1 = ECDSA, 2 = RSA, etc.
    * @param _purpose a uint256[] Array of the key types, like 1 = MANAGEMENT, 2 = ACTION, 3 = CLAIM, 4 = ENCRYPTION
    *
    * @return Returns TRUE if the addition was successful and FALSE if not
    */

    function addKey(bytes32 _key, uint256 _purpose, uint256 _type) public returns (bool success) {
        require(keys[_key].key != _key, "Key already exdists"); // Key should not already exist
        if (msg.sender != address(this)) {
            require(keyHasPurpose(keccak256(msg.sender), 1), "Sender does not have management key"); // Sender has MANAGEMENT_KEY
        }

        keys[_key].key = _key;
        keys[_key].purpose = _purpose;
        keys[_key].keyType = _type;

        keysByPurpose[_purpose].push(_key);

        emit KeyAdded(_key, _purpose, _type);

        return true;
    }

    /**
    * @dev implement approve function to excecute contract call with data
    * @param _id is an id of execute request
    * @param _approve boolen of approve to execute this request or not
     */
    function approve(uint256 _id, bool _approve) public returns (bool success) {
        require(keyHasPurpose(keccak256(msg.sender), 2), "Sender does not have action key");

        emit Approved(_id, _approve);

        if (_approve == true) {
            executions[_id].approved = true;
            success = executeCall(executions[_id].to, executions[_id].value, executions[_id].data);
            if (success) {
                executions[_id].executed = true;
                emit Executed(_id, executions[_id].to, executions[_id].value, executions[_id].data);
                return;
            } else {
                emit ExecutionFailed(_id, executions[_id].to, executions[_id].value, executions[_id].data);
                return;
            }
        } else {
            executions[_id].approved = false;
        }
        return true;
    }

    /**
    * @dev implement execute function to create execute request
    * @param _to is a contract address will be call 
    * @param _value is value will be forward to contract _to
    * @param _data is data will be execute on contract _to
     */
    function execute(address _to, uint256 _value, bytes memory _data) public payable returns (uint256 executionId) {
        require(!executions[executionNonce].executed, "Already executed");
        executions[executionNonce].to = _to;
        executions[executionNonce].value = _value;
        executions[executionNonce].data = _data;

        emit ExecutionRequested(executionNonce, _to, _value, _data);

        if (keyHasPurpose(keccak256(msg.sender), 1) || keyHasPurpose(keccak256(msg.sender), 2)) {
            approve(executionNonce, true);
        }

        executionNonce++;
        return executionNonce - 1;
    }

    /**
    * @dev implement contract call by assemly code
    * @param to is a contract address will be call 
    * @param value is value will be forward to contract _to
    * @param data is data will be execute on contract _to
     */
    function executeCall(address to, uint256 value, bytes memory data)
        internal
        returns (bool success)
    {
        // solium-disable-next-line security/no-inline-assembly
        assembly {
            success := call(gas, to, value, add(data, 0x20), mload(data), 0, 0)
        }
    }

     /**
    * @dev implement function to remove key
    * @param _key is a key will be removed from key list
     */
    function removeKey(bytes32 _key) public returns (bool success) {
        require(keys[_key].key == _key, "No such key");
        if (msg.sender != address(this)) {
            require(keyHasPurpose(keccak256(msg.sender), 1), "Sender does not have management key"); // Sender has MANAGEMENT_KEY
        }
        emit KeyRemoved(keys[_key].key, keys[_key].purpose, keys[_key].keyType);

        bytes32[] keyList = keysByPurpose[keys[_key].purpose];

        for (uint i = 0; i < keyList.length; i++) {
            if (keyList[i] == _key) {
                delete keyList[i];
                keyList[i] = keyList[keyList.length - 1];
                keyList.length--;
            }
        }

        delete keys[_key];

        return true;
    }

     /**
    * @dev implement function return key has purpose or not
    * @param _key is a given key 
    * @param _purpose is purpose to check
     */
    function keyHasPurpose(bytes32 _key, uint256 _purpose) public view returns (bool result) {
        bool isThere;
        if (keys[_key].key == 0) return false;
        isThere = keys[_key].purpose <= _purpose;
        return isThere;
    }
}