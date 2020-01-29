import "@openzeppelin/contracts/ownership/Ownable.sol";
pragma solidity ^0.5.0;

/* The Registry contract keeps track of the land registry of the city. Every house should be registered in this contract */

contract Registry is Ownable {

//address public owner;
/* Data model that allows me to have a stucts with delete and index */
  struct Property {
    address owner;
    uint listPointer;
  }

  //variables
  mapping(uint => Property) public properties;
  uint[] public propertyList;

  //events
  event LogNewProperty(uint _pin, address _owner);
  event LogDeleteProperty(uint _pin);
  event LogUpdateProperty(address _oldOwner,address _newOwner);


constructor() public{
  properties[1].owner = 0xDf7064894A0da6b741b86104af7875647b7767A3;
  properties[1].listPointer = propertyList.push(1)-1;
}
/// @dev function that allows to retrieve all the pin
/// @return an array of ints representing the properties
  function listProperties() public view returns(uint[] memory ){
    return propertyList;
  }

  /// @dev check if a PIN (property identification number) exists 
  /// @param pin which is the pin
  /// @return the owner of this pin if it exists
  function isProperty(uint pin) public view returns(address) {
    require(propertyList.length>0,"There is no property yet");
    if(propertyList[properties[pin].listPointer] == pin) {
         return properties[pin].owner;
     }else{
         return address(0);
     } 
  }

    /// @dev Check the number of property on the blockchain 
    /// @return the number of property on the blockchain
  function getPropertyCount() public view returns(uint propertyCount) {
    return propertyList.length;

  }
  
  /// @dev  create a new property on the blockchain 
  /// @param ownerAddress is the owner of the property
  /// @param pin is the corresponding pin
  /// @return true to notify everything went well
  function newProperty(address ownerAddress, uint pin) public returns(bool success) {
    require(properties[pin].owner==address(0),"This PIN already exist");
    properties[pin].owner = ownerAddress;
    properties[pin].listPointer = propertyList.push(pin)-1;
    emit LogNewProperty(pin,ownerAddress);
    return true;
  }
  /// @dev allows the owner of the contract to change the owner of a property 
  /// @param ownerAddress is the new owner of the property
  /// @param pin is the corresponding pin
  /// @return true to notify everything went well
  function updateProperty(address ownerAddress, uint pin) public onlyOwner() returns(bool success) {
    require(isProperty(pin)!=address(0),"This PIN doens't exist or no property on the blockchain");
    address oldOwner=properties[pin].owner;
    properties[pin].owner = ownerAddress;
    emit LogUpdateProperty(oldOwner,ownerAddress);
    return true;
  }

  /// @dev allows to change the owner of a property automatically from the Mortgage contract
  /// @param ownerAddress is the owner of the property
  /// @param pin is the corresponding pin
  /// @return true to notify everything went well
  function updatePropertyFromMortgage(address ownerAddress, uint pin) public returns(bool success) {
    require(isProperty(pin)!=address(0),"This PIN doens't exist or no property on the blockchain");
    address oldOwner=properties[pin].owner;
    properties[pin].owner = ownerAddress;
    emit LogUpdateProperty(oldOwner,ownerAddress);
    return true;
  }

  /// @dev allows the owner to delete a property on the blockchain 
  /// @param pin pin of the property the owner wants to delete
  /// @return true to notify everything went well
  function deleteProperty(uint pin) public onlyOwner() returns(bool success) {
    require(properties[pin].owner!=address(0),"This PIN doens't exist");
    uint rowToDelete = properties[pin].listPointer;
    uint keyToMove   = propertyList[propertyList.length-1];
    propertyList[rowToDelete] = keyToMove;
    properties[keyToMove].listPointer = rowToDelete;
    propertyList.length--;
    emit LogDeleteProperty(pin);
    return true;
  }

}
