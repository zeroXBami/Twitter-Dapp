pragma solidity ^0.4.24;
import "../Identity/IdentityRegistry.sol";
import "openzeppelin-solidity/contracts/token/ERC20/ERC20Mintable.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";

contract TweetServices is Ownable, ERC20Mintable {

    /**
    * @dev a struct of Comment in Twwet
    * @param text is content of each comment
    * @param commenter is identity address of commenter
    */

    struct Comment {
        string text; 
        address commenter; 
    }

     /**
    * @dev a struct of Tweet
    * @param tweetId is id of each tweet
    * @param tweeter is identity address of poster 
    * @param time is tweet's post time
    * @param commentList is list comment's keys of this tweet 
    * @param comment is mapping from key (value in commentList) to Comment, key=keccak256(commenter, time)
    */
    struct Tweet {
        uint256 tweetId;
        address tweeter;
        uint256 time;
        bytes32[] commentList; 
        mapping (bytes32 => Comment) comment;
    }

    IdentityRegistry internal identityRegistry;
    modifier validUser(address _user) {
        require(identityRegistry.);
        _;
    }

    mapping (address => Tweet[]) public tweets ;
    
    function tweetNewPost(Tweet memory tweet)  {
        
    }



    
    
}