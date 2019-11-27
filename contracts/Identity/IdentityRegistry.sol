pragma solidity ^0.4.24;

import "./ClaimHolder.sol";
import "./ClaimTypesRegistry.sol";
import "./ClaimVerifier.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";


contract IdentityRegistry is Ownable, ClaimVerifier {

    /**
    @dev identity is a mapping between an user identity contract to bool
    */
    mapping(address => bool) public identity;
    
    /**
    @dev claimTypes is an array of trusted ClaimTypes
    */
    uint256[] public claimTypes;

    ClaimTypesRegistry public typesRegistry;

    event IdentityRegistered(ClaimHolder indexed identity, uint256 indexed time);
    event IdentityRemoved(ClaimHolder indexed identity, uint256 indexed time);
    event ClaimTypesRegistrySet(address indexed _claimTypesRegistry);
    event TrustedIssuersRegistrySet(address indexed _trustedIssuersRegistry);
    /**
    * @dev check valid identity (KYC)
    * @param _identityContract an address of user identity contract (ClaimHolder)
     */
    modifier isValidIdentity(ClaimHolder _identityContract) {
        require(_identityContract != address(0), "contract address can't be a zero address");
        require(checkValidIdentity(_identityContract),  "Your Claim is not valid for KYC");
        _;
    }

     /**
    * @dev constructor of the contract
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
    * @dev Register an identity contract for user account
    * @param _identity The address of the user's identity contract (ClaimHolder)
    * @return true or false
    */
    function registerIdentity(ClaimHolder _identity) isValidIdentity(_identity) public returns (bool) {
        require(identity[_identity] == false);
        identity[_identity] = true;
        emit IdentityRegistered(_identity, now);
        return true;
    }

    /**
    * @dev Remove an identity contract
    * @param _identity is an identity contract of user
    * @return true or false
     */
    function removeIdentity(ClaimHolder _identity) onlyOwner public returns (bool) {
        require(identity[_identity] == true);
        emit IdentityRemoved(_identity, now);
        delete identity[_identity];
        return true;
    }

    /**
    * @dev Set ClaimTypeRegistry
    * @param _claimTypesRegistry an address of ClaimTypeRegistry
     */
    function setClaimTypesRegistry(address _claimTypesRegistry) public onlyOwner {
        typesRegistry = ClaimTypesRegistry(_claimTypesRegistry);
        emit ClaimTypesRegistrySet(_claimTypesRegistry);
    }

    /**
    * @dev Set TrustedIssuerRegistry
    * @param _trustedIssuersRegistry an address of TrustedIssuerRegistry
     */
    function setTrustedIssuerRegistry(address _trustedIssuersRegistry) public onlyOwner {
        issuersRegistry = TrustedIssuersRegistry(_trustedIssuersRegistry);
        emit TrustedIssuersRegistrySet(_trustedIssuersRegistry);
    }

    /**
    * @dev Check valid identity contract
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

    function isValidUser(ClaimHolder _identity) public returns (bool){
        return identity[_identity];
    }
} 