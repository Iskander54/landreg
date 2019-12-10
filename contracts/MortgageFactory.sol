pragma solidity ^0.5.0;
import "./Factory.sol";
import "./Mortgage.sol";


///@title Mortgage contract factory - Allows creation of mortgage contracts
///@author Alex-Kevin Loembe - <loembe.ak@gmail.com>
contract MortgageFactory is Factory{
    Mortgage[] public deployedMortgage;

    /*
     * Public functions
     */
     ///@dev Allows verified creation of mortgage contracts.
     ///@param _parties list of the parties of this contract.
     ///@param _required number of required confirmations.
     ///@return returns the contracts address
     function create(address[] memory _parties, uint _required) public{
        Mortgage mortgage = new Mortgage(_parties,_required);
        deployedMortgage.push(mortgage);
        register(mortgage);         
     }  

}