import { RoleManagement } from "./RoleManagement.sol";
import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";


pragma solidity ^0.5.0;

contract Registry {
    function updateProperty(address ownerAddress, uint256 pin) public returns(bool success);
    function grantPermission(address _operator,string memory _permission) public;
    function getPropertyOwner(uint pin) public returns(address payable);
}

contract MultiOwnership{
    using SafeMath for uint256;

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
    uint256 public pendingBuying;
    uint256 FINNEY=(10**15);

    //Reverse lookup to match owners and indices
    mapping(address => uint) public ownersPct;
    mapping(address => uint) public ownersIndices;
    mapping(bytes32 => uint) public allOperationsIndicies;

    //Owners voting per operations
    mapping(bytes32 => uint256) public votesMaskByOperation;
    mapping(bytes32 => uint256) public votesCountByOperation;
    mapping(bytes32 => mapping(address => bool)) public voters;

    //EVENTS 
    event SharedPropertyJoined(address newOwner,uint pourcentage,uint shareleft);
    event SharedPropertyBought(uint pin,address contract_address, uint OwnersCount);
    event OwnerSharedIncreased(address owner, uint newPct);
    event SharedPutMarket(address owner,uint PctofProp, uint price);
    event SharedSold(address oldOwner, address newOwner, uint newPct);
    event OwnershipTransferred(address previousOwner, address newOwner, uint pct);
    event OperationCreated(bytes32 operation, address proposer);
    event OperationUpvoted(bytes32 operation, uint votes, uint pourcentToPass, address upvoter);
    event OperationPerformed(bytes32 operation, uint howMany);
    event OperationDownvoted(bytes32 operation, uint votes, uint pourcentToFail,  address downvoter);
    event OperationCancelled(bytes32 operation, address lastCanceller,uint necessaryPct, uint againstPct);
    event OperationRemoved(bytes32 operation, bool performed);
    event SendingBackMoney(uint256 valuesent,uint256 pendingbalance, uint256 refund);

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


    function getPendingbuying() public view returns(uint){
        return amountToReach;
    }
    //Events

    //Modifiers
    modifier onlyOwner{
        require(isOwner(msg.sender)==true,"You are not part of the owners.");
        _;
    }

    modifier notAchieved{
        require(address(this).balance<=amountToReach,"The amount to reach for the contract is already achieved");
        _;
    }

    //Constructor

    constructor(uint256 _pourcent, uint256 _amount, uint256 _pin, uint256 _pinOwner, address _regaddr) public payable{
        require(msg.value>0,"You need to send money when youcreate this kind of contract");
        require(msg.value<_amount*FINNEY,"Sending more money that the amount to collect with this contract");
        amountToReach=_amount*FINNEY;
        pourcentToPass=_pourcent;
        pin=_pin;
        pinOwner=_pinOwner;
        owners.push(msg.sender);
        ownersIndices[msg.sender]=owners.length;
        ownersPct[msg.sender]=SafeMath.div(SafeMath.mul(msg.value,100),amountToReach);
        pendingBuying=address(this).balance;
        emit SharedPropertyJoined(msg.sender,ownersPct[msg.sender],SafeMath.sub(amountToReach,pendingBuying));
        regaddr=_regaddr;
    }

    //Internal Methods
    /**
    * @dev check if we reach the vote for any operations
     */
    function checkUpVote(bytes32 operation) internal returns (bool) {
        uint256 tmp_against = votesMaskByOperation[operation];
        uint256 tmp_for = votesCountByOperation[operation];
        bool performed =false;
        if(tmp_for>=pourcentToPass){
            performed=true;
            emit OperationPerformed(operation,tmp_for);
            deleteOperation(operation,performed);
        }else{
            uint256 pctMissing = SafeMath.sub(pourcentToPass,votesCountByOperation[operation]);
            uint256 pctToVote =  SafeMath.sub(100,SafeMath.add(votesCountByOperation[operation],votesMaskByOperation[operation]));
            if(pctMissing>pctToVote){
                performed=false;
                emit OperationCancelled(operation,msg.sender,pourcentToPass,tmp_against);
                deleteOperation(operation,performed);
            }
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
        require(pendingBuying!=0,"Check that pendingBuying is different form 0 to forbid reentrancy attack.");
        pendingBuying=0;
        Registry reg = Registry(regaddr);
        reg.getPropertyOwner(pin).transfer(address(this).balance);
        reg.updateProperty(address(this),pin);
        emit SharedPropertyBought(pin, address(this),owners.length);
    }

    
    //Public Methods
    /**
    * @dev if you want to join the multi-shared ownership contract
     */
    function joinSharedProperty() public payable {
        require(ownersIndices[msg.sender]==0,"You are already part of the shared property");
        require(msg.value>0,"You need to seend at least as much ether as amount.");
        uint256 amount = msg.value;
        if(msg.value>SafeMath.sub(amountToReach,pendingBuying)){
            msg.sender.transfer(SafeMath.sub(msg.value,SafeMath.sub(amountToReach,pendingBuying)));
            amount = SafeMath.sub(amountToReach,pendingBuying);
            emit SendingBackMoney(msg.value,SafeMath.sub(amountToReach,pendingBuying),SafeMath.sub(msg.value,SafeMath.sub(amountToReach,pendingBuying)));
        }
        owners.push(msg.sender);
        ownersIndices[msg.sender]=owners.length;
        ownersPct[msg.sender]=SafeMath.div(SafeMath.mul(amount,100),amountToReach);
        pendingBuying=address(this).balance;
        emit SharedPropertyJoined(msg.sender,ownersPct[msg.sender],SafeMath.sub(amountToReach,pendingBuying));
        if(pendingBuying==amountToReach){
            buyProperty();
        }
        
    }

    /**
    * @dev if someone already in the multi shared ownership contract wants to buy some more shares.
     */
    function addMoney() public payable onlyOwner(){
        require(msg.value>0,"You need to send ether with this function");
        uint256 amount = msg.value;
        if(msg.value>SafeMath.sub(amountToReach,pendingBuying)){
            msg.sender.transfer(SafeMath.sub(msg.value,SafeMath.sub(amountToReach,pendingBuying)));
            amount = SafeMath.sub(amountToReach,pendingBuying);
            emit SendingBackMoney(msg.value,SafeMath.sub(amountToReach,pendingBuying),SafeMath.sub(msg.value,SafeMath.sub(amountToReach,pendingBuying)));
        }
        uint256 tmp=ownersPct[msg.sender];
        ownersPct[msg.sender]=SafeMath.add(SafeMath.mul(SafeMath.div(msg.value,amountToReach),100),tmp);
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
        onSale memory share = onSale(msg.sender,_pct,SafeMath.mul(_amount,FINNEY));
        sales.push(share);
        emit SharedPutMarket(msg.sender,SafeMath.div(SafeMath.mul(ownersPct[msg.sender],_pct),100),SafeMath.mul(_amount,FINNEY));
    }
    
    /**
    * @dev If a new person wants to buy someone's share
    * @param index index of the on sale Share he wants to buy 
     */
    function buyShare(uint256 index) public payable {
        require(msg.value==sales[index].amount,"Value doesn't match price.");
        require(index<=SafeMath.sub(sales.length,1),"Sale doesn't exist");
        transferOwnership(msg.sender,sales[index].owner,sales[index].pct);
        sales[index]=sales[SafeMath.sub(sales.length,1)];
        delete sales[SafeMath.sub(sales.length,1)];
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
            ownersPct[_newOwner]=SafeMath.div(SafeMath.mul(ownersPct[_oldOwner],_pct),100);
            emit SharedPropertyJoined(_newOwner,ownersPct[_newOwner],0);
        }
        if(_pct==100){
            uint256 index=ownersIndices[_oldOwner];
            owners[index]=_newOwner;
            ownersIndices[_newOwner]=index;
            delete ownersIndices[_oldOwner];
            uint256 tmp = ownersPct[_oldOwner];
            ownersPct[_oldOwner]=0;
            ownersPct[_newOwner]=tmp;
            emit OwnershipTransferred(_oldOwner,_newOwner,_pct);
        }
        
    }

    /**
    * @dev allows any shareholder to suggest an operation about the property
     */
    function createOperation() public onlyOwner(){
        bytes32 operation = keccak256(msg.data);
        allOperationsIndicies[operation] = allOperations.length;
        allOperations.push(operation);
        emit OperationCreated(operation,msg.sender);
    }

    /**
    * @dev allows any shareholder to upvote an operation
    * send msg.data for refering to the operation
     */
    function upVote() public onlyOwner(){
        bytes32 operation=keccak256(msg.data);
        require(allOperations[allOperationsIndicies[operation]]>=0,"Operation doesn't exist");
        require(voters[operation][msg.sender]==false,"Sender already voted.");
        uint operationVotesCount=SafeMath.add(votesCountByOperation[operation],ownersPct[msg.sender]);
        votesCountByOperation[operation] = operationVotesCount;
        voters[operation][msg.sender]=true;
        emit OperationUpvoted(operation,operationVotesCount,pourcentToPass,msg.sender);
        checkUpVote(operation);

    }

    /**
    * @dev allows any shareholder to downVote an operation
    * send msg.data for refering to the operation
     */
    function downVote() public onlyOwner() {
        bytes32 operation=keccak256(msg.data);
        require(allOperations[allOperationsIndicies[operation]]!=0,"Operation doesn't exist");
        require(voters[operation][msg.sender]==false,"Sender already voted.");
        uint operationMaskCount=SafeMath.add(votesMaskByOperation[operation],ownersPct[msg.sender]);
        votesMaskByOperation[operation] = operationMaskCount;
        voters[operation][msg.sender]=true;
        emit OperationDownvoted(operation,operationMaskCount,SafeMath.sub(100,pourcentToPass),msg.sender);
        checkUpVote(operation);
    }

    /**
    * @dev Used to delete cancelled or performed operation
    * @param operation defines which operation to delete
    */
    function deleteOperation(bytes32 operation,bool perfomed) internal {
        uint index = allOperationsIndicies[operation];
        allOperations[index] = allOperations[SafeMath.sub(allOperations.length,1)];
        allOperationsIndicies[allOperations[index]] = index;
        delete allOperationsIndicies[allOperations[index]];
        delete allOperations[SafeMath.sub(allOperations.length,1)];
        delete votesMaskByOperation[operation];
        delete votesCountByOperation[operation];
        delete allOperationsIndicies[operation];
        emit OperationRemoved(operation,perfomed);
    }


}