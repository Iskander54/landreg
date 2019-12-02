pragma solidity ^0.5.0;

/* The Registry contract keeps track of the land registry of the city. Every house should be registered in this contract */

contract Registry {

address payable public owner;
/* Data model that allows me to have a stucts with delete and index */
  struct Property {
    address owner;
    uint listPointer;
  }

  mapping(uint => Property) public properties;
  uint[] public propertyList;

  modifier isContractOwner(){ require(msg.sender == owner,"Only owner of the contract can call this function");_;}
  modifier isPropertyOwner(uint pin){ require(msg.sender == properties[pin].owner,"Only owner of the property can call this function");_;}

constructor() public{
  owner=msg.sender;
}

/* Function that check if a PIN (property identification number) exists */
  function isProperty(uint pin) public view returns(address) {
    //require(propertyList.length>0,"There is no property yet");
    if(propertyList[properties[pin].listPointer] == pin) {
         return properties[pin].owner;
     }else{
         return address(0);
     } 
  }

    /* Check the number of property on the blockchain */
  function getPropertyCount() public view returns(uint propertyCount) {
    return propertyList.length;
  }
  
/*function that create a new property on the blockchain */
  function newProperty(address ownerAddress, uint pin) public returns(bool success) {
    //require(isProperty(pin)==address(0),"This PIN already exist");
    properties[pin].owner = ownerAddress;
    properties[pin].listPointer = propertyList.push(pin) - 1;
    return true;
  }
/* Function that allows to change the owner of a property */
  function updateProperty(address ownerAddress, uint pin) public isContractOwner() returns(bool success) {
    //require(isProperty(pin)!=address(0),"This PIN doens't exist");
    properties[pin].owner = ownerAddress;
    return true;
  }
/*function that allow to delete a property on the blockchain */
  function deleteProperty(uint pin) public isContractOwner() isPropertyOwner(pin) returns(bool success) {
    //require(isProperty(pin)!=address(0),"This PIN doens't exist");
    uint rowToDelete = properties[pin].listPointer;
    uint keyToMove   = propertyList[propertyList.length-1];
    propertyList[rowToDelete] = keyToMove;
    properties[keyToMove].listPointer = rowToDelete;
    propertyList.length--;
    return true;
  }

}
