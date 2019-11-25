pragma solidity ^0.4.24;

import "./ClaimHolder.sol";
import "./ClaimTypesRegistry.sol";
import "./ClaimVerifier.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";


contract IdentityRegistry is Ownable, ClaimVerifier {

    //mapping between a user id and the corresponding identity contract
    mapping(uint256 => ClaimHolder) public identity;

    //Array storing trusted claim types of the services
    uint256[] public claimTypes;

    ClaimTypesRegistry public typesRegistry;

    event IdentityRegistered(ClaimHolder indexed identity, uint256 indexed index);
    event IdentityRemoved(ClaimHolder indexed identity, uint256 indexed index);
    event ClaimTypesRegistrySet(address indexed _claimTypesRegistry);
    event TrustedIssuersRegistrySet(address indexed _trustedIssuersRegistry);
    /**
    * @notice check valid identity (KYC)
    * @param _identityContract an address of user identity contract (ClaimHolder)
     */
    modifier isValidIdentity(ClaimHolder _identityContract) {
        require(_identityContract != address(0), "contract address can't be a zero address");
        require(checkValidIdentity(_identityContract),  "Your Claim is not valid for KYC");
        _;
    }

     /**
    * @notice constructor of the contract
    * @param _trustedIssuersRegistry the address of TrustedIssuerRegistry
    * @param _claimTypesRegistry the address of ClaimTypeRegistry
    */
    constructor(address _trustedIssuersRegistry, address _claimTypesRegistry) public {
        issuersRegistry = TrustedIssuersRegistry(_trustedIssuersRegistry);
        emit TrustedIssuersRegistrySet(_trustedIssuersRegistry);
        typesRegistry = ClaimTypesRegistry(_claimTypesRegistry);
        emit ClaimTypesRegistrySet(_claimTypesRegistry);
    }

    /**
    * @notice Register an identity contract for user account
    * @param index an user id
    * @param _identity The address of the user's identity contract (ClaimHolder)
    * @return true or false
    */
    function registerIdentity(uint256 index, ClaimHolder _identity) isValidIdentity(_identity) public returns (bool) {
        require(identity[index] == address(0));
        identity[index] = _identity;
        emit IdentityRegistered(_identity, index);
        return true;
    }

    /**
    * @notice Remove an identity contract
    * @param index index an user id that will be remove
    * @return true or false
     */
    function removeIdentity(uint256 index) onlyOwner public returns (bool) {
        require(identity[index] != address(0));
        emit IdentityRemoved(identity[index], index);
        delete identity[index];
        return true;
    }

    /**
    * @notice Set ClaimTypeRegistry
    * @param _claimTypesRegistry an address of ClaimTypeRegistry
     */
    function setClaimTypesRegistry(address _claimTypesRegistry) public onlyOwner {
        typesRegistry = ClaimTypesRegistry(_claimTypesRegistry);
        emit ClaimTypesRegistrySet(_claimTypesRegistry);
    }

    /**
    * @notice Set TrustedIssuerRegistry
    * @param _trustedIssuersRegistry an address of TrustedIssuerRegistry
     */
    function setTrustedIssuerRegistry(address _trustedIssuersRegistry) public onlyOwner {
        issuersRegistry = TrustedIssuersRegistry(_trustedIssuersRegistry);
        emit TrustedIssuersRegistrySet(_trustedIssuersRegistry);
    }

    /**
    * @notice Check valid identity contract
    * @param _identity an address of user
    * @return true or false
     */
    function checkValidIdentity(ClaimHolder _identity) public returns (bool) {
        claimTypes = typesRegistry.getClaimTypes();
        for(uint i = 0; i < claimTypes.length; i++) {
            if(claimIsValid(_identity, claimTypes[i])) {
                return true;
            }
        }
        return false;
    }
}