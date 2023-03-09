pragma solidity ^0.8.0;

contract Owner{
    enum State {
        Started, 
        Running,
        Ended,
        Canceled
    }

    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    string public ipfaHash;                 //luu tru thong tin mat hang tren IFS
    State public auctionState;
    uint public highestBindingBid;          //ban gia cao nhat
    address payable public highestBidder;
    mapping(address => uint) public bids;
    uint bidIncrement;  //the hien muc tang dau gia

    //this owner can call variable
    bool public ownerFinalized = false;

    constructor() {
        owner = payable(msg.sender);
        auctionState = State.Running;
        startBlock = block.number;
        endBlock = startBlock + 3;
        ipfaHash = "";
        bidIncrement = 1000000000000000000;
    }

    modifier notOwner(){
        require(msg.sender != owner);
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }

    modifier afterStart(){
        require(block.number >= startBlock);
        _;
    }

    modifier beforeEnd(){
        require(block.number <= endBlock);
        _;
    }

    function min(uint a, uint b) pure internal returns(uint) {
        if(a <= b) {
            return a ;
        }else {
            return b;
        }
    }

    function cancelAuction() public beforeEnd onlyOwner {
        auctionState = State.Canceled;
    }

    function placeBid() public payable notOwner afterStart beforeEnd returns(bool){
        //to place a bid auction should be running
        require(auctionState == State.Running);
        uint currentBid = bids[msg.sender] + msg.value;
        require(currentBid > highestBindingBid);
        bids[msg.sender] = currentBid;

        if(currentBid <= bids[highestBidder]){  //highestBidder remains unchanged
            highestBindingBid = min(currentBid + bidIncrement, bids[highestBidder]);
        } else {    //highestBidder is another bidder
            highestBindingBid = min(currentBid, bids[highestBidder] + bidIncrement);
            highestBidder = payable(msg.sender);
        }
        return true;
    }

    function finalizeAuction() public {
        require(auctionState == State.Canceled || block.number > endBlock);
        require(msg.sender == owner || bids[msg.sender] > 0);

        address payable recipient;
        uint value;
        
        if(auctionState == State.Canceled){ //auction cancel, not end
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        } else {    //auction end, not canceled
            if(msg.sender == owner && ownerFinalized == false) {
                recipient = owner;
                value = highestBindingBid;
                ownerFinalized = true;
            } else {
                if(msg.sender == highestBidder){
                    recipient = highestBidder;
                    value = bids[highestBidder] - highestBindingBid;
                } else {
                    recipient = payable(msg.sender);
                    value = bids[msg.sender];
                }
            }
        }
        bids[recipient] = 0;
        recipient.transfer(value);
    }
}