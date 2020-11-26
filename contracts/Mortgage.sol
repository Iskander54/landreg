import "@openzeppelin/contracts/ownership/Ownable.sol";
import "./Repayment.sol";
import { RoleManagement } from "./RoleManagement.sol";
pragma solidity 0.5.11;




contract Mortgage is Ownable {
    //Variables
    uint constant ETHER_=(10**18);
    uint public mortgageCount=0;
    bool public contractPaused = false;
    address[] public repayments;

    mapping (uint => address[]) public parties;
    mapping (uint => mapping(address => bool)) public isParty;
    mapping (uint => BankContract) public mortgages;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => uint) pendingWithdrawals;

    //Structs
    struct BankContract{
        address payable bank;
        address payable beneficiary;
        //mapping (address => bool) isParty;
        uint required;
        //address[] parties;
        address payable pinOwner;
        uint pin;
        uint amount;
        uint rates;
        uint length;
        bool executed;
    }

    //events
    event Submission(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event Confirmation(address indexed sender, uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event Revocation(uint transactionId,address indexed sender);
    event ExecutionFailure(uint indexed transactionId);
    event CreateRepaymentContract(address addr);

    //modifiers
    // If the contract is paused, stop the modified function attached
    modifier checkIfPaused() {
        require(!contractPaused);
        _;
    } 
 

    /// @dev Fallback function allows to deposit ether.
    function()
        external
        payable
    {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
    }
    }



    /// @dev Contract constructor sets initial owners and required number of confirmations.
    constructor() public {
    }

    /// @dev circuitbreaker function that allows to stop the contract for time for any reason
    function circuitBreaker() external onlyOwner() {
    if (!contractPaused) { contractPaused = true; }
    else { contractPaused = false; }
}

    /// @dev allows anyone to check the balance of the contract
    /// @return returns the contract balance
    function getDeposit() external view returns (uint256){
        address self = address(this);
        uint256 balance = self.balance;
        return balance;
    }

    /// @dev Allows the contract to give the money to the owner of the property after everybody signed
    /// @param  transactionId Transaction ID
    function withdraw(uint transactionId) internal{
        require(isParty[transactionId][msg.sender],"Only party");
        // against re-entrancy attack 
        require(pendingWithdrawals[mortgages[transactionId].pinOwner]!=0);
        pendingWithdrawals[mortgages[transactionId].pinOwner]=0;
        address self = address(this);
        uint256 balance = self.balance;
        mortgages[transactionId].pinOwner.transfer(balance);
    }


    /// @dev Allows anyone to submit and confirm a transaction.
    /// @param bank represent the one that lend money
    /// @param beneficiary represent the one whom the money has been lent to
    /// @param pinOwner represent the owner of the property that the beneficiary wants to buy
    /// @param pin represent the property identification number
    /// @param amount represent the nb of ether lent
    /// @param rates represent the interest
    /// @param length the amount of time the beneficiary has to pay back the _bank
    /// @param addr the address of the contract that holds the registry
    /// @return Returns transaction ID.
    function submitTransaction(address payable bank,address payable beneficiary,address payable pinOwner, uint pin, uint amount,uint rates, uint length,address addr) payable external checkIfPaused() returns (uint transactionId) {

        BankContract memory trx = BankContract(bank,beneficiary,3,
        pinOwner,pin,amount,rates,length,false);
        transactionId = addTransaction(trx);
        parties[transactionId].push(bank);
        parties[transactionId].push(beneficiary);
        parties[transactionId].push(pinOwner);
        for (uint i=0; i<parties[transactionId].length; i++) {
            require(!isParty[transactionId][parties[transactionId][i]] && parties[transactionId][i] != address(0));
            isParty[transactionId][parties[transactionId][i]] = true;
        }
        pendingWithdrawals[pinOwner]=amount*ETHER_;
        require(msg.value == amount*ETHER_,"The sender has to deposit the exact price of the loan in the contract");
        confirmTransaction(transactionId,addr);
        address(this).transfer(amount*ETHER_);
        return transactionId;
    }

        /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
        /// @param txx is the bankcontract just initialized 
        /// @return Returns transaction ID.
    function addTransaction(BankContract memory txx) internal returns (uint transactionId) {
        transactionId = mortgageCount;
        mortgages[transactionId] = txx;
        mortgageCount += 1;
        emit Submission(transactionId);
    }

    /// @dev Check if the transaction has been executed
    /// @param transactionId Transaction ID.
    function isExecuted(uint transactionId) external view returns (bool){
        return mortgages[transactionId].executed;
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    /// @param addr is the address of the contract representing the land registry
    function confirmTransaction(uint transactionId,address addr) public checkIfPaused() {
        require(!confirmations[transactionId][msg.sender]);
        require(isParty[transactionId][msg.sender]);
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId,addr);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId) external {
        require(confirmations[transactionId][msg.sender]);
        require(isParty[transactionId][msg.sender]);
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(transactionId,msg.sender);
    }

    function createRepayment(uint tId,address addr)internal returns(address){
        Repayment repay = new Repayment(mortgages[tId].bank,mortgages[tId].beneficiary,
        tId,
        mortgages[tId].amount,mortgages[tId].rates,
        mortgages[tId].length,addr,mortgages[tId].pin);
        repayments.push(address(repay));
        emit CreateRepaymentContract(address(repay));
        return address(repay);

    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @param addr is the address of the contract representing the land registry
    function executeTransaction(uint transactionId,address addr) public payable {
        if (isConfirmed(transactionId)) {
            //pinOwner.transfer(mortgages[transactionId].amount);
            mortgages[transactionId].executed=true;
            emit Execution(transactionId);
            RegistryforRepayment r = RegistryforRepayment(addr);
            withdraw(transactionId);
            address repay =createRepayment(transactionId,addr);
            bool success = r.updateProperty(mortgages[transactionId].beneficiary,mortgages[transactionId].pin);
            r.grantPermission(repay,'Admin');  
        }else{
            emit ExecutionFailure(transactionId);
        }
    }

    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId) internal view returns (bool) {
        uint count = 0;
        for (uint i=0; i<parties[transactionId].length; i++) {
            if (confirmations[transactionId][parties[transactionId][i]])
                count += 1;
            if (count == mortgages[transactionId].required)
                return true;
        }
    }

}