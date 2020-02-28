import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
pragma solidity ^0.5.0;

contract Registry {
    function updatePropertyFromAdmin(address ownerAddress, uint256 pin) public returns(bool success);
}

contract Repayment{
    using SafeMath for uint256;
    uint256 ETHER=(10**18);
    address payable public creditor;
    address public creditee;
    uint256 public originalamount;
    uint256 public rates;
    uint256 public length;
    uint256 public balance;
    uint256 public pin; 

    uint256 public missedPayment=0;
    uint256 public paymentPeriod = 7 days;
    uint256 public dueDate = now + paymentPeriod;
    uint256 public penalty;
    address Reg;

    event PaymentMissed(uint256 newBalance, uint256 newDueDate);
    event LatePayment(uint256 fees,uint256 interest,uint256 NewDueDate);
    event PaymentAccepted(uint256 balance,uint256 NewDueDate);
    event LoanCancelled(uint256 pin);
    event ChangeFromPenalty(uint256 change);



    constructor(
        address payable _creditor,
        address _creditee,
        uint256 tid,
        uint256 _originalamount,
        uint256 _rates,
        uint256 _length,
        address _reg,
        uint256 _pin
    ) public {
        creditor = _creditor;
        creditee = _creditee;
        originalamount = _originalamount*ETHER;
        rates = _rates; //to be divided by 100 bc solidity dont deal with float
        length = _length;
        balance = originalamount;
        Reg=_reg;
        pin=_pin;
    }

    function calculateComponents(uint256 amount)public view returns(uint256,uint256){
        uint256 tmp = SafeMath.mul(balance,rates);
        uint256 interest = SafeMath.div(tmp,100);
        require(amount>=interest,"The minimun payment is the interest per period");
        uint256 principal = amount - interest;
        return (interest,principal);
    }

    function minimumPayment() public view returns (uint256){
        return balance.mul(rates);

    }

    function withdraw() public{
        require(msg.sender==creditor,"Only creditor can withdraw money");
        creditor.transfer(address(this).balance);
    }

    function processPeriod(uint256 principal) internal {
        balance-=principal;
        dueDate+= paymentPeriod;
    }

    /// @dev allows anyone to check the balance of the contract
    /// @return returns the contract balance
    function getNow() public view returns (uint256){
        return now;
    }


    function makePayment() public payable {
        if(now>dueDate){
            penalty=MissedPayment();
            require(msg.value>=penalty,"You have to pay at least the penalty before going through");
            uint256 change = msg.value-penalty;
            if(change>=0){
                msg.sender.transfer(change);
                emit ChangeFromPenalty(change);
            }
            processPeriod(0);
        }else{
        (uint256 interest,uint256 principal) = calculateComponents(msg.value);
        require(principal<=balance,"You can't pay more than what you owe");
        require(msg.value >=interest || principal == balance, "payment is at least interest amount or maximum balance amount+interest ");
        processPeriod(principal);
        emit PaymentAccepted(balance,dueDate);
        }

    }


    function processMissedPayment() public {
        require(now>dueDate);
        if(missedPayment<4){
            missedPayment+=1;
            uint256 tmp = SafeMath.mul(balance,rates);
            uint256 interest = SafeMath.div(tmp,100);
            uint256 fees = SafeMath.mul(missedPayment,interest);
            fees = SafeMath.div(fees,100);
            balance+= fees + interest;
            processPeriod(0);
            emit PaymentMissed(balance,dueDate);
        }else{
            cancelLoan();
        }

    } 

    function MissedPayment() internal returns (uint256) {
        require(now>dueDate);
        if(missedPayment<4){
            missedPayment+=1;
            uint256 tmp = SafeMath.mul(balance,rates);
            uint256 interest = SafeMath.div(tmp,100);
            uint256 fees = SafeMath.mul(missedPayment,interest);
            fees = SafeMath.div(fees,100);
            emit LatePayment(fees,interest,dueDate);
            return interest+fees;
        }else{
            cancelLoan();
        }
    }

    function cancelLoan() internal {
        Registry r = Registry(Reg);
        r.updatePropertyFromAdmin(creditor,pin);
        emit LoanCancelled(pin);
    }




}