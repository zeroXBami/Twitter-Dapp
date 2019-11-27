pragma solidity ^0.4.24;
import "../Identity/IdentityRegistry.sol";
import "../Identity/ClaimHolder.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract TweetServices is Ownable, ERC20 {

    /**
    * @dev a struct of Comment in Twwet
    * @param text is content of comment
    * @param commenter is identity address of commenter
    */
    struct Comment {
        address commenter; 
        bytes text; 
    }

     /**
    * @dev a struct of Tweet
    * @param tweetId is id of tweet, type interger > 0
    * @param time is tweet's post time
    * @param commentID is number of comments of tweets, also an id of comment
    * @param tweeter is identity address of poster 
    * @param content is content of tweet
    * @param comment is mapping from uint256 (from 0 to commentID) to Comment
    */
    struct Tweet {
        uint256 tweetId;
        uint256 time;
        uint256 commentID;
        address tweeter;
        mapping(uint256 => Comment) comment;
        bytes content;
    }
    /**
    * @dev an address of IdentityRegistry contrac
     */
    IdentityRegistry internal identityRegistry;

     /**
    * @dev mapping type
    * @param tweets is mapping from address -> tweetID -> Tweet, use for lookup a Tweet from user
    * @param tweetPostedNo is number of tweets that used at address was posted, and also use as tweetID
     */
    mapping (address => mapping(uint256 => Tweet)) public tweets;
    mapping (address => uint256) internal tweetPostedNo;
    
    event NewTweet(address indexed tweetOwner, uint256 indexed tweetId, uint256 indexed tweetTime);
    event ReTweet(address indexed reTweeter, address indexed tweetOwner, uint256 indexed tweetId);
    event CommentTweet(address indexed commenter, address indexed tweetOwner, uint256 indexed tweetId);
    /**
    * @dev modifier to check valid User
    * @param _userIdentity is an identity address (ClaimHolder contract) of user
     */
    modifier validUser(ClaimHolder _userIdentity) {
        require(identityRegistry.isValidUser(_userIdentity));
        _;
    }
    /**
    * @dev modifier to check valid tweet, to prevent waste transaction reTweet or comment on invalid tweet
    * @param tweetOwner is an identity address (ClaimHolder contract) of user, owner of tweet
    * @param tweetId is tweet's id.
     */
    modifier validTweet(address tweetOwner, uint256 tweetId) {
        require(tweets[tweetOwner][tweetId].tweetId > 0, " Tweet with tweetId does not exist");
        _;
    }
    
    /**
     */

    constructor(address _identityRegistry) public {
        identityRegistry = IdentityRegistry(_identityRegistry);
    }
    /**
    * @dev Tweet feature, allow valid user post new tweet
    * @notice only valid user can use this feature
    * @param content is content of tweet
     */
    function tweetNewPost(bytes memory content) validUser(ClaimHolder(msg.sender)) public returns(bool) {
        Tweet memory newTweet;
        newTweet.tweetId = tweetPostedNo[msg.sender] + 1;
        newTweet.tweeter = msg.sender;
        newTweet.time = now;
        newTweet.content = content;
        tweets[msg.sender][newTweet.tweetId] = newTweet;
        tweetPostedNo[msg.sender]++;
        emit NewTweet(msg.sender, newTweet.tweetId, now);
        return true;
    }

    /**
    * @dev re tweet feature, allow user retweet from other user or themself
    * @notice If other user re-tweet from other user, its mean tweet is useful, 
    * @notice we wil mint 1 token (ERC20) and transfer to tweet owner as gift.
    * @notice Tweet owner can use other services (game, lotery,...)
    * @param tweetOwner is owner (identity contract address) of tweet will be re-tweet
    * @param tweetId is id of tweet will be re-tweet
     */
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
        if(msg.sender != tweetOwner) {
            _mint(tweetOwner, 1);
        }
        emit ReTweet(msg.sender, tweetOwner, tweetId);
        emit NewTweet(msg.sender, newTweet.tweetId, now);
        return true;
    }

    /**
    * @dev comment feature
    * @param tweetOwner is owner (identity contract address) of tweet
    * @param tweetId is id of tweet 
    * @param text is content of comment in bytes memory
     */
    function commentOnTweet(address tweetOwner, uint256 tweetId, bytes memory text) 
            validUser(ClaimHolder(msg.sender)) 
            validTweet(tweetOwner, tweetId)
            public returns(bool) 
    {
        Comment memory newComment;
        newComment.text = text;
        newComment.commenter = msg.sender;
        tweets[tweetOwner][tweetId].comment[tweets[tweetOwner][tweetId].commentID] = newComment;
        tweets[tweetOwner][tweetId].commentID++;
        emit CommentTweet(msg.sender, tweetOwner, tweetId);
        return true;
    }
}