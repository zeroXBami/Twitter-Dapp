const Web3 = require('web3');

const web3 = new Web3(new Web3.providers.HttpProvider("http://localhost:7545"));
const { BN, constants, balance, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { expect } = require('chai');

const ClaimHolder =  artifacts.require('../contracts/ClaimHolder.sol');
const TrustedIssuersRegistry = artifacts.require('../contracts/TrustedIssuersRegistry.sol');
const ClaimTypesRegistry = artifacts.require('../contracts/ClaimTypesRegistry.sol');
const IdentityRegistry = artifacts.require('../contracts/IdentityRegistry.sol');
const TweetServices = artifacts.require('../contracts/TweetServices.sol');

function getEncodedCall(instance, method, params = []) {
  const contract = new web3.eth.Contract(instance.abi)
  return contract.methods[method](...params).encodeABI()
}

contract('IdentityRegistry', function (accounts) {
    let identityRegistry, claimTypeRegistry, trustedIssuerRegistry, tweetServices;
    let addrZero = constants.ZERO_ADDRESS;
    let issuer_EOA = accounts[0];
    let signer_key = web3.utils.keccak256(accounts[4]);
    const privateKey_signer = '0xd84ba674356480b86ffb78e21bc57ee59e3e108dca5c97e0c77041506be45696' // this is private key of accounts[4]
    let user1_EOA = accounts[1];
    let user2_EOA = accounts[2];
    let services_EOA = accounts[3];
    let issuer_identity, user1_Identity, user2_Identity;
    
    beforeEach(async function () {

    });

    describe("Identity Registry Services", function () {
        /**
         * S
         */
        it("Deploy Issuer Identity", async function () {
            issuer_identity = await ClaimHolder.new({ from: issuer_EOA});
        });

        it("Issuer Add Signer Key - The key to sign Claim for user", async function () {
            await issuer_identity.addKey(signer_key, 3, 1, { from: issuer_EOA});
        });

        it("Deploy Trusted Issuer Registry - A contract contains list of trusted issuer", async function () {
            trustedIssuerRegistry = await TrustedIssuersRegistry.new({ from: services_EOA });
        });

         it("Deploy Trusted ClaimType Registry - A contract contains list of trusted claim type", async function () {
            claimTypeRegistry = await ClaimTypesRegistry.new({ from: services_EOA });
        });

         it("Deploy Identity Services - Twitter KYC", async function () {
            identityRegistry = await IdentityRegistry.new(trustedIssuerRegistry.address, claimTypeRegistry.address, { from: services_EOA });
        });


        it("Deploy User1 Identity - This is like an account present user on social Network", async function () {
            user1_Identity = await ClaimHolder.new({ from: user1_EOA});
        });

        it("Deploy User2 Identity - This is like an account present user on social Network", async function () {
            user2_Identity = await ClaimHolder.new({ from: user2_EOA});
        });
       
        it("Issuer sign claims by signer account and user1, user_2 add Claim to them identity", async function() {
            const rawClaimData_user1 = "This is Claim for User 1, signed by Twitter";
            const hexData_user1 = web3.utils.utf8ToHex(rawClaimData_user1);
            const hashedDataToSign_user1 = web3.utils.soliditySha3(user1_Identity.address, 1, hexData_user1) // 1 is KYC Claim Type
            const signature_user1 = await web3.eth.accounts.sign(hashedDataToSign_user1, privateKey_signer);
            await user1_Identity.addClaim(
                                1,      // Claim Type 
                                1,         // Claim Schema
                                issuer_identity.address,    //Address of issuer
                                signature_user1.signature,     // sigature of claim
                                hexData_user1,       // hex data of claim
                                'https://decentralized-twitter.com', { from: user1_EOA}) // uri for link, ipfs

            const rawClaimData_user2 = "This is Claim for User 2, signed by Twitter";
            const hexData_user2 = web3.utils.utf8ToHex(rawClaimData_user2);
            const hashedDataToSign_user2 = web3.utils.soliditySha3(user2_Identity.address, 1, hexData_user2) // 1 is KYC Claim Type
            const signature_user2 = await web3.eth.accounts.sign(hashedDataToSign_user2, privateKey_signer);
            await user2_Identity.addClaim(
                                1,      // Claim Type 
                                1,         // Claim Schema
                                issuer_identity.address,    //Address of issuer
                                signature_user2.signature,     // sigature of claim
                                hexData_user2,       // hex data of claim
                                'https://decentralized-twitter.com', { from: user2_EOA}) // uri for link, ipfs
        });

        it("Identity Services Provider add trusted ClaimType & Trusted Issuer", async function () {
            await trustedIssuerRegistry.addTrustedIssuer(issuer_identity.address, 1,  {from: services_EOA});
            await claimTypeRegistry.addClaimType(1, {from: services_EOA});
        });

        it("User1 now had ClaimSigned by Twitter Issuer, can use register services on IdentityRegistry contract", async function() {

           const registerData_user1 = getEncodedCall(identityRegistry, 'registerIdentity', [user1_Identity.address]);
           await  user1_Identity.execute(identityRegistry.address, 0, registerData_user1, { from: user1_EOA});
           const res = await identityRegistry.identity.call(user1_Identity.address); // 0 is id of user1_Identity on identityRegistry
            assert.equal(res, true)
        });

        it("User1 and User2 now had ClaimSigned by Twitter Issuer, can use register services on IdentityRegistry contract", async function() {
           const registerData_user2 = getEncodedCall(identityRegistry, 'registerIdentity', [user2_Identity.address]);
           await user2_Identity.execute(identityRegistry.address, 0, registerData_user2, { from: user2_EOA});
           const res = await identityRegistry.identity.call(user2_Identity.address); // 1 is id of user2_Identity on identityRegistry
           assert.equal(res, true)
        });
    })  

    describe("Tweet Services", function () {
        it("Deploy TweetServices", async function() {
            tweetServices = await TweetServices.new(identityRegistry.address, { from: services_EOA});
            
        });

        it("User 1 post new tweet", async function() {
            const content = web3.utils.asciiToHex("This is my first tweet on Decentralized Twitter app");
            const tweetData = getEncodedCall(tweetServices, 'tweetNewPost', [content]);
            await user1_Identity.execute(tweetServices.address, 0, tweetData, {from: user1_EOA});
        });

        it("User 2 retweet from User 1", async function() {
            const reTweetData = getEncodedCall(tweetServices, 'reTweet', [user1_Identity.address, 1]);
            await user2_Identity.execute(tweetServices.address, 0, reTweetData, {from: user2_EOA});
        });

        it("User 1 now have 1 token from re-tweet action of User 2", async function () {
            const user1_tokenBalance = await tweetServices.balanceOf.call(user1_Identity.address);
            assert.isTrue(user1_tokenBalance.toNumber() == 1);
        })

    });
});