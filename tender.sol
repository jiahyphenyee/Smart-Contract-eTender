pragma solidity ^0.5.0;

contract Tender {
    
    struct Bid {
        bytes32 companyName;    // cheaper than string
        bytes32 hiddenBid;
        uint deposit;
    }
    
    address public owner = msg.sender;
    uint public tenderCloseDate;
    uint public highestBid;
    address payable[] private bidderList;     // all bidders
    address[] public highestBidders;
    
    mapping(address => Bid) public allBids;   // bidder:Bid
    mapping(address => uint) toRefund;  // bidder:amount
    
    //events
    event TenderClosed(address winner, uint lowestBid);
    
    //modifiers
    modifier checkBefore(uint _time) {
        require(now < _time);
        _;
    }
    
    modifier checkAfter(uint _time) {
        require(now > _time);
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    constructor (uint _tenderDuration) public {
        tenderCloseDate = now + _tenderDuration;
    }
    
    /// Submit bids before tender closing date
    function submitBid(bytes32 _companyName, bytes32 _hiddenBid) public payable checkBefore(tenderCloseDate) {
        require(msg.sender != address(0), "Invalid submission address");
        require(msg.value >= 0, "Negative deposit");
        
        address payable bidAddr = msg.sender;
        
        allBids[bidAddr] = Bid({
            companyName: _companyName, 
            hiddenBid: _hiddenBid,
            deposit: msg.value
        });
        
        bidderList.push(bidAddr);
    }
    
    /// Reveal bid. Hidden bids which were valid will have deposits returned except for the selected bidder.
    function revealBid(uint _value, bool _fake, bytes32 _secret) public checkAfter(tenderCloseDate)  {
        
        uint refund;
        Bid storage currentBid = allBids[msg.sender];
        (uint value, bool fake, bytes32 secret) = (_value, _fake, _secret);
        
        if (currentBid.hiddenBid != keccak256(abi.encodePacked(value, fake, secret))){
            // do not refund deposit
        } else {
            refund += currentBid.deposit;
            if (!fake && currentBid.hiddenBid.deposit >= value) {
                
                if (checkHighest(msg.sender, value)){
                    // if bid is highest, no refund
                    refund -= value;
                }
            }
        }
        
        // reset bid amount
        currentBid.hiddenBid = bytes32(0);
        
        msg.sender.transfer(refund);
    }
    
    /// Check Highest Bidder
    function checkHighest(address bidder, uint amount) internal returns (bool){
        if (amount < highestBid) {
            return false;
        } else if (amount == highestBid) {
            highestBidders.push(bidder);
            return true;
        } 
        
        // if new highest bidder, refund all previous highest
        if (highestBidders.length != 0){
            for (uint i = 0; i < toRefund.length; i++) {
                toRefund[highestBidders[i]]  += highestBid;
            }
            delete highestBidders;
        }
        
        highestBid = amount;
        highestBidders.push(bidder);
        
        return true;
    }
    
    
    /// Withdraw bid
    function withdraw() public checkBefore(tenderCloseDate) {
        uint refund = toRefund[msg.sender];
        if (refund > 0) {
            // reset amount. so that can't withdraw twice before transfer() returns
            toRefund[msg.sender] = 0;
            msg.sender.transfer(refund);
        }
    }
    
    
    /// Cancel tender
    function cancelTender() public onlyOwner checkBefore(tenderCloseDate) {
        tenderCloseDate = now;
        
        // refund everyone
        uint refund;
        for (uint i = 0; i < bidderList.length; i++) {
            refund = allBids[bidderList[i]].deposit;
            allBids[bidderList[i]].deposit = 0;
            bidderList[i].transfer(refund);
        }
    }
    
    
    //--------------- read-only ---------------//
    
    function getTenderStatus() public view returns (bool) {
        if (now < tenderCloseDate) {
            return true;    //still open
        } 
        
        return false;
    }
    
    /// Get company name of highest bidder
    function getHighestCompany() public view checkBefore(tenderCloseDate) returns (bytes32[] memory) {
        require(highestBidders.length > 0, "No winner!");
        
        bytes32[] memory companies;
        for (uint i=0; i < highestBidders.length; i++){
            companies.push(allBids[highestBidders[i]]);
        }
        return companies;
    }

}
