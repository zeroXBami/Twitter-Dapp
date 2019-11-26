pragma solidity ^0.4.24;
import "../Identity/IdentityRegistry.sol";
import "../Identity/ClaimHolder.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract TweetServices is Ownable, ERC20Mintable {

    /**
    * @dev a struct of Comment in Twwet
    * @param text is content of each comment
    * @param commenter is identity address of commenter
    */

    struct Comment {
        bytes32 text; 
        address commenter; 
    }

     /**
    * @dev a struct of Tweet
    * @param tweetId is id of each tweet, is interger > 0
    * @param tweeter is identity address of poster 
    * @param time is tweet's post time
    * @param content is content of post
    * @param commentList is list comment's keys of this tweet 
    * @param comment is mapping from key (value in commentList) to Comment, key=keccak256(commenter, time)
    */
    struct Tweet {
        uint256 tweetId;
        address tweeter;
        uint256 time;
        bytes32 content;
        bytes32[] commentList; 
        mapping (bytes32 => Comment) comment;
    }

    IdentityRegistry internal identityRegistry;
    mapping (address => mapping(uint256 => Tweet)) public tweets;
    mapping (address => uint256) internal tweetPostedNo;
    modifier validUser(ClaimHolder _userIdentity) {
        require(identityRegistry.isValidUser(_userIdentity));
        _;
    }

    modifier validTweet(address tweetOwner, uint256 tweetId) {
        require(tweets[msg.sender][tweetId].tweetId > 0, " Twwet with tweetId does not exist");
        _;
    }

    
    
    function tweetNewPost(bytes32 content) validUser(ClaimHolder(msg.sender)) public returns(bool) {
        Tweet memory newTweet;
        newTweet.tweetId = tweetPostedNo[msg.sender] + 1;
        newTweet.tweeter = msg.sender;
        newTweet.time = now;
        newTweet.content = content;
        tweets[msg.sender][newTweet.tweetId] = newTweet;
        tweetPostedNo[msg.sender]++;
        return true;
    }


    function reTweet(address tweetOwner, uint256 tweetId) 
            validUser(ClaimHolder(msg.sender)) 
            validTweet(tweetOwner, tweetId)
            public returns(bool) 
    {
        Tweet memory newTweet;
        newTweet = tweets[tweetOwner][tweetId];
        newTweet.tweetId = tweetPostedNo[msg.sender] + 1;
        tweets[msg.sender][newTweet.tweetId] = newTweet;
        tweetPostedNo[msg.sender]++;
        return true;
    }

    function commentOnTweet(address tweetOwner, uint256 tweetId, bytes32 text) 
            validUser(ClaimHolder(msg.sender)) 
            validTweet(tweetOwner, tweetId)
            public returns(bool) 
    {
        tweet.
    }



    
    
}