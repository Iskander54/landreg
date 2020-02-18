import "@openzeppelin/contracts/math/SafeMath.sol";
pragma solidity ^0.5.0;

contract Repayment{

    
    address creditor;
    address creditee;
    uint originalamount;
    uint rates;
    uint length;
    uint balance;
    uint pin; 

    uint missedPayment=0;
    uint256 paymentPeriod = 7 days;
    uint256 dueDate = now + paymentPeriod;


    constructor(
        address _creditor,
        address _creditee,
        uint _originalamount,
        uint _rates,
        uint _length,
        uint _balance
    ) public {
        creditor = _creditor;
        creditee = _creditee;
        originalamount = _originalamount;
        rates = div(_rates,100);
        length = _length;
        balance = _balance;

    }

    function calculateComponents(uint256 amount)internal view{
        interest = mul(balance,rates)
        require(amount>=interest,"The minimun payment is the interest per period");
        principal = amount - interest;
        return (interest,principal)
    }

    function minimumPayment() public view {
        return mul(balance,rates)

    }

    function processPeriod(uint principal) internal {
        balance-=principal;
        dueDate=+= paymentperiod;
    }


    function makePayment() public {
        if(now>dueDate){
            MissedPayment()
        }else{
        uint256 interest;
        uint256 principal;
        (interest,principal) = calculatePrincipal(msg.value);
        require(principal<=remainingBalance,"You can't pay more than what you owe");
        processPeriod(principal)
        }

    }

    function MissedPayment() public{
        requires(now>dueDate);
        if(missedPayment<4){
            interest = mul(balance,rates)
            fees = div(missedPayment,100)
            penalty = mul(fees,interest )
            missedPayment+=1
            return(interest,penalty)
        }else{
            cancelLoan();
            return 0
        }
        
        

    }

    function cancelLoan() public {
        Registry r = Registry(addr);
        r.updatePropertyFromMortgage(creditor,pin);

    }




}