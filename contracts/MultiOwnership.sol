pragma solidity ^0.5.0;

contract MultiOwnership{
    // Variables
    address[] public owners;
    bytes32[] public allOperations;
    uint256 public pourcentToPass;
    uint256 public amountToReach;
    uint256 public pin;
    uint256 public pinOwner;

    //Reverse lookup to match owners and indices
    mapping(address => uint) public ownersPct;
    mapping(address => uint) public ownersIndices;
    mapping(bytes => uint) public allOperationsIndicies;

    //Owners voting per operations
    mapping(bytes32 => uint256) public votesMaskByOperation;
    mapping(bytes32 => uint256) public votesCountByOperation;

    //Accessors
    function isOwner(address _owners) public view returns (bool){
        return ownersIndices[_owners]>0;
    }

    function ownersCount() public view returns(uint) {
        return owners.length;
    }

    function allOperationsCount() public {

    }

    function pendingOperationsCount() public {

    }
    
    function getBalance() public view returns(uint) {
        return address(this).balance;

    }
    //Events

    //Modifiers
    modifier onlyOwner{
        _;
    }

    modifier onlyAllOwner{
        _;
    }

    modifier notAchieved{
        require(address(this).balance<amountToReach);
        _;
    }

    //Constructor

    constructor(uint256 _pourcent, uint256 _amount, uint256 _pin, uint256 _pinOwner) public payable{
        require(msg.value>0);
        require(msg.value<_amount);
        amountToReach=_amount;
        pourcentToPass=_pourcent;
        pin=_pin;
        pinOwner=_pinOwner;
        owners.push(msg.sender);
        ownersIndices[msg.sender]=owners.length;
        ownersPct[msg.sender]=(msg.value/amountToReach)*100;
    }

    //Internal Methods
    function checkUpVote() internal {

    }

    function()
        external
        payable
    {
        if (msg.value > 0) {
            //emit Deposit(msg.sender, msg.value);
    }
    }

    function buyProperty() internal {

    }

    
    //Public Methods
    function joinSharedProperty() public payable notAchieved() {
        require(ownersIndices[msg.sender]==0);
        require(msg.value>0);
        require(msg.value<=(amountToReach-address(this).balance));
        owners.push(msg.sender);
        ownersIndices[msg.sender]=owners.length;
        ownersPct[msg.sender]=(msg.value/amountToReach)*100;
        buyProperty();
    }

    function addMoney() public payable onlyOwner() notAchieved(){
        require(msg.value>0);
        require(msg.value<=(amountToReach-address(this).balance));
        uint256 tmp=ownersPct[msg.sender];
        ownersPct[msg.sender]=((msg.value/amountToReach)*100)+tmp;
        buyProperty();
    }


    function sellShare() public {

    }

    function upVote() public {

    }

    function downVote() public {

    }


}