import { SafeMath } from "@openzeppelin/contracts/math/SafeMath.sol";
pragma solidity ^0.5.0;

contract Registry {
    function updatePropertyFromMortgage(address ownerAddress, uint256 pin) public returns(bool success);
}

contract Repayment{
    using SafeMath for uint256;
    uint256 ETHER=(10**18);
    address creditor;
    address creditee;
    uint256 originalamount;
    uint256 rates;
    uint256 length;
    uint256 public balance;
    uint256 pin; 

    uint256 public missedPayment=0;
    uint256 public paymentPeriod = 7 days;
    uint256 public dueDate = now + paymentPeriod;
    address Reg;
    uint256 public penalty=0;

    event penal(uint256 p);



    constructor(
        address _creditor,
        address _creditee,
        uint256 _originalamount,
        uint256 _rates,
        uint256 _length,
        address _reg
    ) public {
        creditor = _creditor;
        creditee = _creditee;
        originalamount = _originalamount*ETHER;
        rates = _rates; //to be divided by 100 bc solidity dont deal with float
        length = _length;
        balance = originalamount;
        Reg=_reg;
    }

    function calculateComponents(uint256 amount)internal view returns(uint256,uint256){
        uint256 tmp = SafeMath.mul(balance,rates);
        uint256 interest = SafeMath.div(tmp,100);
        require(amount>=interest,"The minimun payment is the interest per period");
        uint256 principal = amount - interest;
        return (interest,principal);
    }

    function minimumPayment() public view returns (uint256){
        return balance.mul(rates);

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
            MissedPayment();
            uint256 change = msg.value-penalty;
            msg.sender.transfer(change);
        }else{
        (uint256 interest,uint256 principal) = calculateComponents(msg.value);
        require(principal<=balance,"You can't pay more than what you owe");
        require(msg.value >=interest || principal == balance, "payment is at least interest amount or maximum balance amount+interest ");
        processPeriod(principal);
        }

    }

    function MissedPayment() public {
        require(now>dueDate);
        if(missedPayment<4){
            missedPayment+=1;
            uint256 tmp = SafeMath.mul(balance,rates);
            uint256 interest = SafeMath.div(tmp,100);
            uint256 fees = SafeMath.mul(missedPayment,interest);
            fees = SafeMath.div(fees,100);
            penalty = interest+fees;
            emit penal(fees);
            emit penal(interest);
        }else{
            cancelLoan();
        }
        
        

    }

    function cancelLoan() internal {
        Registry r = Registry(Reg);
        r.updatePropertyFromMortgage(creditor,pin);
    }




}