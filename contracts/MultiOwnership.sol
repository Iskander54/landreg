pragma solidity ^0.5.0;

contract MultiOwnership{
    // Variables
    address[] public owners;
    bytes32[] public allOperations;
    uint256 public pourcentToPass;

    //Reverse lookup to match owners and indices
    mapping(address => uint) public ownersIndices;
    mapping(bytes => uint) public allOperationsIndicies

    //Owners voting per operations
    mapping(bytes32 => uint256) public votesMaskByOperation;
    mapping(bytes32 => uint256) public votesCountByOperation;

    //Accessors
    function isOwner() public {

    }

    function ownersCount() public {

    }

    function allOperationsCount() public {

    }

    function pendingOperationsCount() public {

    }
    
    function getBalance() public {

    }
    //Events

    //Modifiers
    modifier onlyOwner{

    }

    modifier onlyAllOwner{

    }

    //Constructor

    constructor() public{

    }

    //Internal Methods
    function checkUpVote(){

    }

    function()
        external
        payable
    {
        if (msg.value > 0) {
            //emit Deposit(msg.sender, msg.value);
    }
    }

    
    //Public Methods
    function buyProperty(){

    }

    function transferOwnership(){

    }

    function upVote(){

    }

    function downVote(){

    }


}