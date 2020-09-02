import { RoleManagement } from "./RoleManagement.sol";
pragma solidity ^0.5.0;

contract MultiOwnership{

    struct onSale{
        address owner;
        uint256 pct;
        uint256 amount;
    }
    // Variables
    address[] public owners;
    onSale[] public sales;
    bytes32[] public allOperations;
    uint256 public pourcentToPass;
    uint256 public amountToReach;
    uint256 public pin;
    uint256 public pinOwner;
    address public regaddr;
    uint public pendingBuying;

    //Reverse lookup to match owners and indices
    mapping(address => uint) public ownersPct;
    mapping(address => uint) public ownersIndices;
    mapping(bytes32 => uint) public allOperationsIndicies;

    //Owners voting per operations
    mapping(bytes32 => uint256) public votesMaskByOperation;
    mapping(bytes32 => uint256) public votesCountByOperation;
    mapping(bytes32 => mapping(address => bool)) public voters;

    //EVENTS 
    event SharedPropertyJoined(address newOwner,uint pourcentage);
    event SharedPropertyBought(uint pin,address contract_address, uint OwnersCount);
    event OwnerSharedIncreased(address owner, uint newPct);
    event SharedSold(address oldOwner, address newOwner, uint newPct);
    event OwnershipTransferred(address previousOwner, address newOwner, uint pct);
    event OperationCreated(bytes32 operation, address proposer);
    event OperationUpvoted(bytes32 operation, uint votes, uint ownersCount, address upvoter);
    event OperationPerformed(bytes32 operation, uint howMany);
    event OperationDownvoted(bytes32 operation, uint votes, uint ownersCount,  address downvoter);
    event OperationCancelled(bytes32 operation, address lastCanceller,uint necessaryPct, uint againstPct);

    //Accessors
    function isOwner(address _owners) public view returns (bool){
        return ownersIndices[_owners]>0;
    }

    function ownersCount() public view returns(uint) {
        return owners.length;
    }

    function allOperationsCount() public view returns(uint) {
        return allOperations.length;
    }
    
    function getBalance() public view returns(uint) {
        return address(this).balance;

    }
    //Events

    //Modifiers
    modifier onlyOwner{
        require(isOwner(msg.sender)==true,"You are not part of the owners.");
        _;
    }
    /*
    modifier onlyAllOwner{
        _;
    }
    */
    modifier notAchieved{
        require(address(this).balance<amountToReach);
        _;
    }

    //Constructor

    constructor(uint256 _pourcent, uint256 _amount, uint256 _pin, uint256 _pinOwner, address _regaddr) public payable{
        require(msg.value>0);
        require(msg.value<_amount);
        amountToReach=_amount;
        pourcentToPass=_pourcent;
        pin=_pin;
        pinOwner=_pinOwner;
        owners.push(msg.sender);
        ownersIndices[msg.sender]=owners.length;
        ownersPct[msg.sender]=(msg.value/amountToReach)*100;
       
       /* regaddr=_regaddr;
        Registry reg = Registry(regaddr);
        reg.grantPermission(address(this),'Admin');*/
    }

    //Internal Methods

    /**
    * @dev check if we reach the vote for any operations
     */
    function checkUpVote(bytes32 operation) internal returns (bool) {
        uint256 tmp_against = votesMaskByOperation[operation]/owners.length;
        uint256 tmp_for = votesCountByOperation[operation]/owners.length;
        if(tmp_for>tmp_against && (tmp_for*100)>pourcentToPass){
            emit OperationPerformed(operation,tmp_for);
            return true;
        }else{
            uint256 votesNecessary = pourcentToPass*owners.length;
            uint256 votesMissing = votesNecessary-votesCountByOperation[operation];
            uint256 leftVotee = owners.length - votesCountByOperation[operation] - votesMaskByOperation[operation];
            if(votesMissing>leftVotee){
                emit OperationCancelled(operation,msg.sender,pourcentToPass,tmp_against);
            }
            return false;
        }
    }

    function()
        external
        payable
    {
        if (msg.value > 0) {
            //emit Deposit(msg.sender, msg.value);
    }
    }

    /**
    * @dev function that link this contract with the registry, allows to own a property on the registry contract
     */

    function buyProperty() internal {
        require(pendingBuying!=0);
        pendingBuying=0;
        /*
        Registry reg = Registry(regaddr);
        reg.properties[uint].owner.transfer(address(this).balance);
        reg.updateProperty(address(this),pin);
        */
        emit SharedPropertyBought(pin, address(this),owners.length);
    }

    
    //Public Methods
    /**
    * @dev if you want to join the multi-shared ownership contract
     */
    function joinSharedProperty() public payable notAchieved() {
        require(ownersIndices[msg.sender]==0);
        require(msg.value>0);
        require(msg.value<=(amountToReach-address(this).balance));
        owners.push(msg.sender);
        ownersIndices[msg.sender]=owners.length;
        ownersPct[msg.sender]=(msg.value/amountToReach)*100;
        pendingBuying=address(this).balance;
        emit SharedPropertyJoined(msg.sender,ownersPct[msg.sender]);
        buyProperty();
    }

    /**
    * @dev if someone already in the multi shared ownership contract wants to buy some more shares.
     */
    function addMoney() public payable onlyOwner() notAchieved(){
        require(msg.value>0);
        require(msg.value<=(amountToReach-address(this).balance));
        uint256 tmp=ownersPct[msg.sender];
        ownersPct[msg.sender]=((msg.value/amountToReach)*100)+tmp;
        pendingBuying=address(this).balance;
        emit OwnerSharedIncreased(msg.sender,ownersPct[msg.sender]);
        buyProperty();
    }

    /**
    * @dev If one of the owner wants to sell part of all his share
    * @param _pct pourcentage of his share that the owner is willing to sell
    * @param _amount how much money the onwer is asking for his share 
     */
    function sellShare(uint256 _pct, uint256 _amount) public onlyOwner() {
        onSale memory share = onSale(msg.sender,_pct,_amount);
        sales.push(share);
        
    }
    
    /**
    * @dev If a new person wants to buy someone's share
    * @param index index of the on sale Share he wants to buy 
     */
    function buyShare(uint256 index) public payable {
        require(msg.value==sales[index].amount,"Value doesn't match price.");
        require(index<sales.length-1,"Sale doesn't exist");
        transferOwnership(msg.sender,sales[index].owner,sales[index].pct);
        for (uint i = index; i<sales.length-1; i++){
            sales[i] = sales[i+1];
        }
        sales.length--;
        emit SharedSold(sales[index].owner, msg.sender, sales[index].pct);
    }


    /**
    * @dev transfer the ownership of the share 
    * @param _newOwner new owner address
    * @param _oldOwner old owner address
    * @param _pct pourcentage of the transfer
     */
    function transferOwnership(address _newOwner, address _oldOwner, uint256 _pct) internal {
        require(_pct<=100,"Can't buy more than 100% of a someone's property");
        if(_pct!=100){
            require(owners.length<256,"Can't have more than 256 owners.");
            owners.push(_newOwner);
            ownersIndices[_newOwner]=owners.length;
            ownersPct[_newOwner]=(ownersPct[_oldOwner]*_pct)/100;
        }
        if(_pct==100){
            owners[ownersIndices[_oldOwner]]=_newOwner;
            uint256 tmp = ownersPct[_oldOwner];
            ownersPct[_oldOwner]=0;
            ownersPct[_newOwner]=tmp;
        }
        emit OwnershipTransferred(_oldOwner,_newOwner,_pct);
    }

    function createOperation() public onlyOwner(){
        bytes32 operation = keccak256(msg.data);
        allOperationsIndicies[operation] = allOperations.length;
        allOperations.push(operation);
        emit OperationCreated(operation,msg.sender);
    }

    function upVote(bytes32 operation) public onlyOwner() {
        require(voters[operation][msg.sender]==false,"Sender already voted.");
        uint operationVotesCount=votesCountByOperation[operation]+1;
        votesCountByOperation[operation] = operationVotesCount;
        voters[operation][msg.sender]=true;
        emit OperationUpvoted(operation,operationVotesCount,owners.length,msg.sender);
        checkUpVote(operation);

    }

    function downVote(bytes32 operation) public onlyOwner() {
        require(voters[operation][msg.sender]==false,"Sender already voted.");
        uint operationMaskCount=votesMaskByOperation[operation]+1;
        votesMaskByOperation[operation] = operationMaskCount;
        voters[operation][msg.sender]=true;
        emit OperationDownvoted(operation,operationMaskCount,owners.length,msg.sender);
        checkUpVote(operation);
    }


}