import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
pragma solidity 0.5.11;

contract RegistryforRepayment {
    function updateProperty(address ownerAddress, uint256 pin) external returns(bool success);
    function addAdminRoles(address _admin) external;
    function grantPermission(address _operator,string calldata _permission) external;
}

contract Repayment{
    using SafeMath for uint256;
    uint256 constant ETHER_=(10**18);
    address payable public creditor;
    address public creditee;
    uint256 public tid;
    uint256 public originalamount;
    uint256 public rates;
    uint256 public length;
    uint256 public balance;
    uint256 public pin; 

    uint256 public missedPaymentCount=0;
    uint256 constant public PAYMENT_PERIOD = 7 days;
    uint256 public dueDate = now + PAYMENT_PERIOD;
    uint256 public penalty;
    address reg;

    event PaymentMissed(uint256 newBalance, uint256 newDueDate);
    event LatePayment(uint256 fees,uint256 interest,uint256 NewDueDate);
    event PaymentAccepted(uint256 balance,uint256 NewDueDate);
    event LoanCancelled(uint256 pin);
    event ChangeFromPenalty(uint256 change);



    constructor(
        address payable _creditor,
        address _creditee,
        uint256 _tid,
        uint256 _originalamount,
        uint256 _rates,
        uint256 _length,
        address _reg,
        uint256 _pin
    ) public {
        creditor = _creditor;
        creditee = _creditee;
        tid = _tid;
        originalamount = _originalamount*ETHER_;
        rates = _rates; //to be divided by 100 bc solidity dont deal with float
        length = _length;
        balance = originalamount;
        reg=_reg;
        pin=_pin;
    }

    function calculateComponents(uint256 amount)public view returns(uint256,uint256){
        uint256 tmp = SafeMath.mul(balance,rates);
        uint256 interest = SafeMath.div(tmp,100);
        require(amount>=interest,"The minimun payment is the interest per period");
        uint256 principal = amount - interest;
        return (interest,principal);
    }

    function minimumPayment() external view returns (uint256){
        uint256 tmp = SafeMath.mul(balance,rates);
        return SafeMath.div(tmp,100);

    }

    function withdraw() external{
        require(msg.sender==creditor,"Only creditor can withdraw money");
        // because of invalid opcode
        address self = address(this);
        uint256 contractBalance = self.balance;
        creditor.transfer(contractBalance);
    }

    function processPeriod(uint256 principal) internal {
        balance-=principal;
        dueDate+= PAYMENT_PERIOD;
    }

    /// @dev allows anyone to check the balance of the contract
    /// @return returns the contract balance
    function getNow() external view returns (uint256){
        return now;
    }


    function makePayment() external payable {
        if(now>dueDate){
            penalty=missedPayment();
            require(msg.value>=penalty,"You have to pay at least the penalty before going through");
            uint256 change = msg.value-penalty;
            emit ChangeFromPenalty(change);
            processPeriod(0);
            msg.sender.transfer(change);
        }else{
        (uint256 interest,uint256 principal) = calculateComponents(msg.value);
        require(principal<=balance,"You can't pay more than what you owe");
        require(msg.value >=interest || principal == balance, "payment is at least interest amount or maximum balance amount+interest ");
        processPeriod(principal);
        emit PaymentAccepted(balance,dueDate);
        }

    }


    function processMissedPayment() external {
        require(now>dueDate);
        if(missedPaymentCount<4){
            missedPaymentCount+=1;
            uint256 tmp = SafeMath.mul(balance,rates);
            uint256 fees = SafeMath.div(SafeMath.mul(missedPaymentCount,tmp),10000);
            uint256 interest = SafeMath.div(tmp,100);
            balance+= fees + interest;
            processPeriod(0);
            emit PaymentMissed(balance,dueDate);
        }else{
            cancelLoan();
        }

    } 

    function missedPayment() internal returns (uint256) {
        require(now>dueDate);
        if(missedPaymentCount<4){
            missedPaymentCount+=1;
            uint256 tmp = SafeMath.mul(balance,rates);
            uint256 fees = SafeMath.div(SafeMath.mul(missedPaymentCount,tmp),10000);
            uint256 interest = SafeMath.div(tmp,100);
            emit LatePayment(fees,interest,dueDate);
            return interest+fees;
        }else{
            cancelLoan();
        }
    }

    function cancelLoan() internal {
        RegistryforRepayment r = RegistryforRepayment(reg);
        emit LoanCancelled(pin);
        bool success = r.updateProperty(creditor,pin);
        
    }




}