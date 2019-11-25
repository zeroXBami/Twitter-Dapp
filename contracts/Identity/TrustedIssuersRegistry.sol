pragma solidity ^0.4.24;

import "./ClaimHolder.sol";

import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract TrustedIssuersRegistry is Ownable {
    //Mapping between a trusted issuer index and its corresponding identity contract address.
    mapping(uint => ClaimHolder) trustedIssuers;
    //Mapping between a trusted issuer address and true/false if address is/is not trusted issuer
    mapping(address => bool) public isTrustedIssuers;

    //Array stores the trusted issuer indexes
    uint[] indexes;

    event TrustedIssuerAdded(uint indexed index, ClaimHolder indexed trustedIssuer);
    event TrustedIssuerRemoved(uint indexed ndex, ClaimHolder indexed trustedIssuer);
    event TrustedIssuerUpdated(uint indexed index, ClaimHolder indexed oldTrustedIssuer, ClaimHolder indexed newTrustedIssuer);

    /**
    * @notice Add the identity contract of a trusted claim issuer corresiponding
    * to the index provided.
    * Requires the index to be greater than zero.
    * Requires that an identity contract doesnt already exist corresponding to the index.
    * Only owner can call
    *
    * @param _trustedIssuer The identity contract address of the trusted claim issuer.
    * @param index The desired index of the claim issuer
    */
    function addTrustedIssuer(ClaimHolder _trustedIssuer, uint index) public onlyOwner {
        require(index > 0);
        require(trustedIssuers[index] == address(0), "A trustedIssuer already exists by this name");
        require(_trustedIssuer != address(0));
        uint length = indexes.length;
        for (uint i = 0; i < length; i++) {
            require(_trustedIssuer != trustedIssuers[indexes[i]], "Issuer address already exists in another index");
        }
        trustedIssuers[index] = _trustedIssuer;
        isTrustedIssuers[_trustedIssuer] = true;
        indexes.push(index);
        emit TrustedIssuerAdded(index, _trustedIssuer);
    }

    /**
    * @notice Removes the identity contract of a trusted claim issuer corresponding
    * to the index provided.
    * Requires the index to be greater than zero.
    * Requires that an identity contract exists corresponding to the index.
    * Only owner can call.
    *
    * @param index The desired index of the claim issuer to be removed.
    */
    function removeTrustedIssuer(uint index) public onlyOwner {
        require(index > 0);
        require(trustedIssuers[index] != address(0), "No such issuer exists");
        isTrustedIssuers[trustedIssuers[index]] = false;
        delete trustedIssuers[index];
        emit TrustedIssuerRemoved(index, trustedIssuers[index]);
        uint length = indexes.length;
        for (uint i = 0; i < length; i++) {
            if (indexes[i] == index) {
                delete indexes[i];
                indexes[i] = indexes[length - 1];
                delete indexes[length - 1];
                indexes.length--;
                return;
            }
        }
    }

    /**
    * @notice Function for getting all the trusted claim issuer indexes stored.
    * @return array of indexes of all the trusted claim issuer indexes stored.
    */
    function getTrustedIssuers() public view returns (uint[] memory) {
        return indexes;
    }

    /**
    * @notice Function for getting the trusted claim issuer's
    * identity contract address corresponding to the index provided.
    * Requires the provided index to have an identity contract stored.
    * Only owner can call.
    *
    * @param index The index corresponding to which identity contract address is required.
    *
    * @return Address of the identity contract address of the trusted claim issuer.
    */
    function getTrustedIssuer(uint index) public view returns (ClaimHolder) {
        require(index > 0);
        require(trustedIssuers[index] != address(0), "No such issuer exists");
        return trustedIssuers[index];
    }

    /**
    * @notice Updates the identity contract of a trusted claim issuer corresponding
    * to the index provided.
    * Requires the index to be greater than zero.
    * Requires that an identity contract already exists corresponding to the provided index.
    * Only owner can call.
    *
    * @param index The desired index of the claim issuer to be updated.
    * @param _newTrustedIssuer The new identity contract address of the trusted claim issuer.
    */
    function updateIssuerContract(uint index, ClaimHolder _newTrustedIssuer) public onlyOwner {
        require(index > 0);
        require(trustedIssuers[index] != address(0), "No such issuer exists");
        uint length = indexes.length;
        for (uint i = 0; i < length; i++) {
            require(trustedIssuers[indexes[i]] != _newTrustedIssuer, "Address already exists");
        }
        emit TrustedIssuerUpdated(index, trustedIssuers[index], _newTrustedIssuer);
        trustedIssuers[index] = _newTrustedIssuer;
    }


    /**
    * @notice Check the given address is identity contract of a trusted claim issuer or not
    * @param _trustedIssuerIdentity The given address will be check
    * @return true or false
    */
    
    function checkIsTrustedIssuer(address _trustedIssuerIdentity) public returns (bool) {
        return isTrustedIssuers[_trustedIssuerIdentity];
    }

}