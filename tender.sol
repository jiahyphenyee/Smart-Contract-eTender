pragma solidity ^0.4.24;

contract Tender {
    
    struct Bid {
        bytes32 hiddenBid;
        uint deposit;
    }
    
    uint public tenderCloseDate;
    uint public revealEnd;
    bool public ended;
    
    mapping(address => Bid[]) public bids;
    mapping(address => uint) withdrawnBids;
    
    //events
    event TenderClosed(address winner, uint lowestBid);
    
    //modifiers
    
    constructor (
        uint _tenderDuration
        
    ) public {
        tenderCloseDate = now + _tenderDuration;
    }
    

}
