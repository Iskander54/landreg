pragma solidity 0.5.11;

import "@openzeppelin/contracts/access/Roles.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

contract RoleManagement is Ownable {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;
  string[] public userRoles;
  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);
  event SenderOnAdmin(address indexed operator);

  constructor() public {
    userRoles.push('Admin');
    userRoles.push('Client');
    userRoles.push('Owner');
    userRoles.push('Bank');
  }

  /**
   * @dev check if the role exists
   * @param role the name of the role
   * @return bool
   */
  function checkExistingRole(string memory role) public view returns(bool){
    uint8 i=0;
    while(i<userRoles.length){
      if(keccak256(abi.encode(role))==keccak256(abi.encode(userRoles[i])))
        return true;
      i++;
    }
    return false;
  }

  /**
   * @dev modifier to ensure the role you want to grant is existing
   * @param role the name of the role
   * // reverts
   */
  modifier onlyExistingRole(string memory role){
    require(checkExistingRole(role),"The role you want to assign doesn't exist.");
    _;
  }
  /**
   * @dev check if the addr has the role admin or is owner of this contract
   * @param operator addr 
   * @param role the name of the role
   * @return bool
   */
  function checkAdmin(address operator, string memory role) public view returns (bool){
    if(operator == owner()){
      return true;
    } else if(roles[role].has(operator)) {
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
    emit SenderOnAdmin(msg.sender);
    require(checkAdmin(msg.sender,"Admin"), "You need to be an admin or an owner to proceed this action.");
    _;
  }

  /**
   * @dev keep track of the length of the userRoles array
   * @return uint256
   */
  function getRolesCount() external view returns (uint256) {
    return userRoles.length;
  }

  /**
   * @dev add a Role to the userRoles array
   * @param role the name of the role
   */
  function addRolesList(string calldata role) external onlyAdmin{
    if(!checkExistingRole(role)){
      userRoles.push(role);
    }
  }


  /**
   * @dev determine if addr has role
   * @param operator address
   * @param role the name of the role
   * @return bool
   */
  function hasRole(address operator, string calldata role)
    external
    view
    returns (bool)
  {
    return roles[role].has(operator);
  }

  /**
   * @dev add a role to an address
   * @param operator address
   * @param role the name of the role
   */
  function addRole(address operator, string memory role)
    internal
  {
    roles[role].add(operator);
    emit RoleAdded(operator, role);
  }

  /**
   * @dev remove a role from an address
   * @param operator address
   * @param role the name of the role
   */
  function removeRole(address operator, string memory role)
    internal
  {
    roles[role].remove(operator);
    emit RoleRemoved(operator, role);
  }

  
    function grantPermission(address operator, string memory permission) public onlyAdmin onlyExistingRole(permission) {
    addRole(operator, permission);
  }

  function revokePermission(address operator, string calldata permission) external onlyAdmin {
    removeRole(operator, permission);
  }
}