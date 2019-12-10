pragma solidity ^0.5.0;

contract Mortgage {
    address payable owner;

    struct BankContract{
        address bank;
        address beneficiary;
        uint pin;
        uint amount;
        uint rates;
        uint length;
        bool executed;
    }

    address[] public parties;
    uint public required=3;
    mapping (address => bool) public isParty;
    uint public MortgageCount=0;
    mapping (uint => BankContract) public mortgages;
    mapping (uint => mapping (address => bool)) public confirmations;

    event Submission(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event Confirmation(address indexed sender, uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event Revocation(uint transactionId,address indexed sender);
    event ExecutionFailure(uint indexed transactionId);

    modifier validRequirement(uint ownerCount, uint _required) {
        if (   _required > ownerCount || _required == 0 || ownerCount == 0)
            revert();
        _;
    }
    
    //modifier isParty(uint pin){ require(isParty[msg.sender],"Only parties of this bankContract can call this function");_;}
 
 

    /// @dev Fallback function allows to deposit ether.
    function()
        external
        payable
    {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
    }
    }


    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners and required number of confirmations.
    /// @param _parties List of initial owners.
    /// @param _required Number of required confirmations.
    constructor(address[] memory _parties, uint _required) public validRequirement(_parties.length, _required) {
        for (uint i=0; i<_parties.length; i++) {
            require(!isParty[_parties[i]] && _parties[i] != address(0));
            isParty[_parties[i]] = true;
        }
        parties = _parties;
        required = _required;
    }



    /// @dev Allows an owner to submit and confirm a transaction.
    /// @return Returns transaction ID.
    function submitTransaction(address _bank,address _beneficiary, uint _pin, uint _amount,uint _rates, uint _length) public returns (uint transactionId) {
        BankContract memory tx = BankContract({
            bank: _bank,
            beneficiary: _beneficiary,
            pin:_pin,
            amount: _amount,
            rates: _rates,
            length: _length,
            executed: false,
        });
        transactionId = addTransaction(tx);
        confirmTransaction(transactionId);
        return transactionId;
    }

        /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @return Returns transaction ID.
    function addTransaction(BankContract memory tx) internal returns (uint transactionId) {
        transactionId = MortgageCount;
        mortgages[transactionId] = tx;
        MortgageCount += 1;
        emit Submission(transactionId);
    }

    function isExecuted(uint transactionId)public view returns (bool){
        return mortgages[transactionId].executed;
    }

    /// @dev Allows an owner to confirm a transaction.
    /// @param transactionId Transaction ID.
    function confirmTransaction(uint transactionId) public returns (bool) {
        require(confirmations[transactionId][msg.sender] == false);
        require(isParty[msg.sender]==true);
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    /// @dev Allows an owner to revoke a confirmation for a transaction.
    /// @param transactionId Transaction ID.
    function revokeConfirmation(uint transactionId) public {
        require(confirmations[transactionId][msg.sender] == true);
        require(isParty[msg.sender]==true);
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(transactionId,msg.sender);
    }

    /// @dev Allows anyone to execute a confirmed transaction.
    /// @param transactionId Transaction ID.
    function executeTransaction(uint transactionId) public returns (bool) {
        if (isConfirmed(transactionId)) {
            mortgages[transactionId].executed=true;
            emit Execution(transactionId);
            
        }else{
            emit ExecutionFailure(transactionId);
        }
            //Transaction storage t = transactions[transactionId];  // using the "storage" keyword makes "t" a pointer to storage 
            t.executed = true;
            //(bool success, bytes memory returnedData) = t.destination.call.value(t.value)(t.data);
            //if (success)
        
            //else {
              //  emit ExecutionFailure(transactionId);
               // t.executed = false;
            //}
//        }
        //return true;
    //}
    }

        /*
         * (Possible) Helper Functions
         */
    /// @dev Returns the confirmation status of a transaction.
    /// @param transactionId Transaction ID.
    /// @return Confirmation status.
    function isConfirmed(uint transactionId) internal view returns (bool) {
        uint count = 0;
        for (uint i=0; i<parties.length; i++) {
            if (confirmations[transactionId][parties[i]])
                count += 1;
            if (count == required)
                return true;
        }
    }





}