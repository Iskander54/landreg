import "@openzeppelin/contracts/math/SafeMath.sol";
pragma solidity ^0.5.0;

contract Repayment{

    
    address creditor;
    address creditee;
    uint originalamount;
    uint rates;
    uint length;
    uint balance; 

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
        require(amount>=interest);
        principal = amount - interest;
        return (interest,principal)
    }

    function minimumPayment() public{

    }

    function processPeriod(uint principal) internal {
        balance-=principal;
        dueDate=+= paymentperiod;
    }


    function makePayment() public {

    }

    function checkMissedPayment() public{
        requires(now>dueDate);
        if(missedPayment<4){
            interest = mul(balance,rates)
            fees = div(missedPayment,10)
            penalty = mul(fees,interest )
        }else{
            cancelLoan();
        }
        
        

    }

    function cancelLoan() public {

    }




}