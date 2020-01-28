pragma solidity ^0.5.0;

contract Mortgage {
    address payable owner;
    uint ETHER=(10**18);

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

    uint public MortgageCount=0;
    mapping (uint => address[]) public parties;
    mapping (uint => mapping(address => bool)) public isParty;
    mapping (uint => BankContract) public mortgages;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => uint) pendingWithdrawals;

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
    constructor() public {
    }

    function getDeposit() public view returns (uint256){
        return address(this).balance;
    }

    function withdraw(uint transactionId) public{
        require(isParty[transactionId][msg.sender],"Only party");
        // against re-entrancy attack 
        require(pendingWithdrawals[mortgages[transactionId].pin_owner]!=0);
        pendingWithdrawals[mortgages[transactionId].pin_owner]=0;
        mortgages[transactionId].pin_owner.transfer(address(this).balance);
    }


    /// @dev Allows an owner to submit and confirm a transaction.
    /// @return Returns transaction ID.
    function submitTransaction(address _bank,address _beneficiary,address payable _pin_owner, uint _pin, uint _amount,uint _rates, uint _length) payable public returns (uint transactionId) {
        //address[3] memory _parties = [_bank,_beneficiary,_pin_owner];
        /*
        BankContract storage trx = BankContract({
            bank: _bank,
            beneficiary: _beneficiary,
            parties: [_bank,_beneficiary,_pin_owner],
            pin_owner: _pin_owner,
            required:3,
            pin:_pin,
            amount: _amount,
            rates: _rates,
            length: _length,
            executed: false
        });
        BankContract storage trx;
    
        trx.bank=_bank;
        trx.beneficiary= _beneficiary;
        trx.parties=new address[](0);
        trx.parties.push(_bank);
        trx.parties.push(_beneficiary);
        trx.parties.push(_pin_owner);
        trx.pin_owner= _pin_owner;
        trx.required=3;
        trx.pin=_pin;
        trx.amount= _amount;
        trx.rates= _rates;
        trx.length= _length;
        trx.executed= false;
        */

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
        confirmTransaction(transactionId);
        return transactionId;
    }

        /// @dev Adds a new transaction to the transaction mapping, if transaction does not exist yet.
    /// @return Returns transaction ID.
    function addTransaction(BankContract memory txx) internal returns (uint transactionId) {
        transactionId = MortgageCount;
        mortgages[transactionId] = txx;
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
        require(isParty[transactionId][msg.sender]==true);
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
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
    function executeTransaction(uint transactionId) public payable returns (bool) {
        if (isConfirmed(transactionId)) {
            //pin_owner.transfer(mortgages[transactionId].amount);
            mortgages[transactionId].executed=true;
            emit Execution(transactionId);
            withdraw(transactionId);
        }else{
            emit ExecutionFailure(transactionId);
        }
    }

        /*
         * (Possible) Helper Functions
         */
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
/*
    function InitializeContract(address _bank, address _client, address payable _pin_owner, uint _required)public{
        address[] _parties=[];
        mapping (address => bool) public _isParty;
        parties.push(_bank);
        parties.push(_client);
        parties.push(_pin_owner);
        for (uint i=0; i<parties.length; i++) {
            require(!isParty[parties[i]] && parties[i] != address(0));
            isParty[parties[i]] = true;
        }
        pin_owner =_pin_owner;
        required = _required;
        DataContract memory dc = DataContract({
            isParty: _isParty,
            parties: _parties,
            pin_owner: _pin_owner,
            transactionid:_tid,
        })
    }
*/




}