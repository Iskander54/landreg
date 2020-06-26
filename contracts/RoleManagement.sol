pragma solidity ^0.5.0;

import "@openzeppelin/contracts/access/Roles.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

contract RoleManagement is Ownable {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;
  string[] public UserRoles;
  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

  constructor() public {
    UserRoles.push('Admin');
    UserRoles.push('Client');
    UserRoles.push('Owner');
    UserRoles.push('Bank');
  }

  /**
   * @dev check if the role exists
   * @param _role the name of the role
   * @return bool
   */
  function checkExistingRole(string memory _role) public view returns(bool){
    uint8 i=0;
    while(i<UserRoles.length){
      if(keccak256(abi.encode(_role))==keccak256(abi.encode(UserRoles[i])))
        return true;
      i++;
    }
    return false;
  }

  /**
   * @dev modifier to ensure the role you want to grant is existing
   * @param _role the name of the role
   * // reverts
   */
  modifier onlyExistingRole(string memory _role){
    require(checkExistingRole(_role)==true,"The role you want to assign doesn't exist.");
    _;
  }
  /**
   * @dev check if the addr has the role admin or is owner of this contract
   * @param _operator addr 
   * @param _role the name of the role
   * @return bool
   */
  function checkAdmin(address _operator, string memory _role) public view returns (bool){
    if(_operator == owner()){
      return true;
    } else if(roles[_role].has(_operator)) {
      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev modifier to scope access to admin or contract owner
   * // reverts
   */
  modifier onlyAdmin(){
    require(checkAdmin(msg.sender,"Admin") == true , "You need to be an admin or an owner to proceed this action.");
    _;
  }

  /**
   * @dev keep track of the length of the UserRoles array
   * @return uint256
   */
  function getRolesCount() public view returns (uint256) {
    return UserRoles.length;
  }

  /**
   * @dev add a Role to the UserRoles array
   * @param _role the name of the role
   */
  function addRolesList(string memory _role) public onlyAdmin{
    if(checkExistingRole(_role)==false){
      UserRoles.push(_role);
    }
  }


  /**
   * @dev determine if addr has role
   * @param _operator address
   * @param _role the name of the role
   * @return bool
   */
  function hasRole(address _operator, string memory _role)
    public
    view
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

  /**
   * @dev add a role to an address
   * @param _operator address
   * @param _role the name of the role
   */
  function addRole(address _operator, string memory _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

  /**
   * @dev remove a role from an address
   * @param _operator address
   * @param _role the name of the role
   */
  function removeRole(address _operator, string memory _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

  
    function grantPermission(address _operator, string memory _permission) public onlyAdmin onlyExistingRole(_permission) {
    addRole(_operator, _permission);
  }

  function revokePermission(address _operator, string memory _permission) public onlyAdmin {
    removeRole(_operator, _permission);
  }
}