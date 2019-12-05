pragma solidity ^0.5.0;
import "./Factory.sol";
import "./Mortgage.sol";


///@title Mortgage contract factory - Allows creation of mortgage contracts
///@author Alex-Kevin Loembe - <loembe.ak@gmail.com>
contract MortgageFactory is Factory{

    /*
     * Public functions
     */
     ///@dev Allows verified creation of mortgage contracts.
     ///@param _parties list of the parties of this contract.
     ///@param _required number of required confirmations.
     ///@return returns the contracts address
     function create(address[] _owners, uint_required) public returns (address mortgage){
        mortgage = new Mortgage(_owners,_required);
        register(mortgage);         
     }  

}