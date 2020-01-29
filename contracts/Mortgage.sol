import "@openzeppelin/contracts/ownership/Ownable.sol";
pragma solidity ^0.5.0;

contract Registry {
    function updatePropertyFromMortgage(address ownerAddress, uint pin) public returns(bool success);
}

contract Mortgage is Ownable {
    //Variables
    uint ETHER=(10**18);
    uint public MortgageCount=0;
    bool public contractPaused = false;

    mapping (uint => address[]) public parties;
    mapping (uint => mapping(address => bool)) public isParty;
    mapping (uint => BankContract) public mortgages;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => uint) pendingWithdrawals;

    //Structs
    struct BankContract{
        address bank;
        address beneficiary;
        //mapping (address => bool) isParty;
        uint required;
        //address[] parties;
        address payable pin_owner;
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

    //modifiers
    // If the contract is paused, stop the modified function attached
    modifier checkIfPaused() {
        require(contractPaused == false);
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
    function circuitBreaker() public onlyOwner() {
    if (contractPaused == false) { contractPaused = true; }
    else { contractPaused = false; }
}

    /// @dev allows anyone to check the balance of the contract
    /// @return returns the contract balance
    function getDeposit() public view returns (uint256){
        return address(this).balance;
    }

    /// @dev Allows the contract to give the money to the owner of the property after everybody signed
    /// @param  transactionId Transaction ID
    function withdraw(uint transactionId) public{
        require(isParty[transactionId][msg.sender],"Only party");
        // against re-entrancy attack 
        require(pendingWithdrawals[mortgages[transactionId].pin_owner]!=0);
        pendingWithdrawals[mortgages[transactionId].pin_owner]=0;
        mortgages[transactionId].pin_owner.transfer(address(this).balance);
    }


    /// @dev Allows anyone to submit and confirm a transaction.
    /// @param _bank represent the one that lend money
    /// @param _beneficiary represent the one whom the money has been lent to
    /// @param _pin_owner represent the owner of the property that the beneficiary wants to buy
    /// @param _pin represent the property identification number
    /// @param _amount represent the nb of ether lent
    /// @param _rates represent the interest
    /// @param _length the amount of time the beneficiary has to pay back the _bank
    /// @param addr the address of the contract that holds the registry
    /// @return Returns transaction ID.
    function submitTransaction(address _bank,address _beneficiary,address payable _pin_owner, uint _pin, uint _amount,uint _rates, uint _length,address addr) payable public checkIfPaused() returns (uint transactionId) {

        BankContract memory trx = BankContract(_bank,_beneficiary,3,
        _pin_owner,_pin,_amount,_rates,_length,false);
        transactionId = addTransaction(trx);
        parties[transactionId].push(_bank);
        parties[transactionId].push(_beneficiary);
        parties[transactionId].push(_pin_owner);
        for (uint i=0; i<parties[transactionId].length; i++) {
            require(!isParty[transactionId][parties[transactionId][i]] && parties[transactionId][i] != address(0));
            isParty[transactionId][parties[transactionId][i]] = true;
        }
        pendingWithdrawals[_pin_owner]=_amount*ETHER;
        require(msg.value == _amount*ETHER,"The sender has to deposit the exact price of the loan in the contract");
        address(this).transfer(_amount*ETHER);
        confirmTransaction(transactionId,addr);
        return transactionId;
    }

        /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
        /// @param txx is the bankcontract just initialized 
        /// @return Returns transaction ID.
    function addTransaction(BankContract memory txx) internal returns (uint transactionId) {
        transactionId = MortgageCount;
        mortgages[transactionId] = txx;
        MortgageCount += 1;
        emit Submission(transactionId);
    }

    /// @dev Check if the transaction has been executed
    /// @param transactionId Transaction ID.
    function isExecuted(uint transactionId)public view returns (bool){
        return mortgages[transactionId].executed;
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    /// @param addr is the address of the contract representing the land registry
    function confirmTransaction(uint transactionId,address addr) public checkIfPaused() {
        require(confirmations[transactionId][msg.sender] == false);
        require(isParty[transactionId][msg.sender]==true);
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId,addr);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId) public {
        require(confirmations[transactionId][msg.sender] == true);
        require(isParty[transactionId][msg.sender]==true);
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(transactionId,msg.sender);
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    /// @param addr is the address of the contract representing the land registry
    function executeTransaction(uint transactionId,address addr) public payable {
        if (isConfirmed(transactionId)) {
            //pin_owner.transfer(mortgages[transactionId].amount);
            mortgages[transactionId].executed=true;
            emit Execution(transactionId);
            withdraw(transactionId);
            Registry r = Registry(addr);
            r.updatePropertyFromMortgage(mortgages[transactionId].beneficiary,mortgages[transactionId].pin);
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