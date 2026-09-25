// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/// @title Registry (remediated)
/// @notice Authoritative record of property PINs to owners.
/// @dev Fixes vs the original `contracts/Registry.sol`:
///      - H-01: every mutator is gated by REGISTRAR_ROLE (newProperty was unguarded).
///      - L-01: no hardcoded property/owner in the constructor.
///      - L-02: existence tracked by a flag; deleteProperty resets the moved pointer via pop().
///      - L-05/L-06 & M-02: OpenZeppelin AccessControl (bytes32 roles) replaces the custom,
///        string-keyed, uint8-looped role system.
contract Registry is AccessControl {
    bytes32 public constant REGISTRAR_ROLE = keccak256("REGISTRAR_ROLE");

    struct Property {
        address owner;
        uint256 listPointer;
        bool exists;
    }

    mapping(uint256 => Property) private _properties;
    uint256[] private _pins;

    event PropertyCreated(uint256 indexed pin, address indexed owner);
    event PropertyUpdated(uint256 indexed pin, address indexed previousOwner, address indexed newOwner);
    event PropertyDeleted(uint256 indexed pin);

    /// @param admin account granted DEFAULT_ADMIN_ROLE (can manage roles) and REGISTRAR_ROLE.
    constructor(address admin) {
        require(admin != address(0), "Registry: zero admin");
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(REGISTRAR_ROLE, admin);
    }

    /// @notice Register a new property. H-01: now restricted to REGISTRAR_ROLE.
    function newProperty(address owner, uint256 pin) external onlyRole(REGISTRAR_ROLE) {
        require(owner != address(0), "Registry: zero owner");
        require(!_properties[pin].exists, "Registry: PIN exists");
        _properties[pin] = Property({owner: owner, listPointer: _pins.length, exists: true});
        _pins.push(pin);
        emit PropertyCreated(pin, owner);
    }

    /// @notice Reassign a property's owner.
    function updateProperty(address newOwner, uint256 pin) external onlyRole(REGISTRAR_ROLE) {
        require(newOwner != address(0), "Registry: zero owner");
        Property storage p = _properties[pin];
        require(p.exists, "Registry: PIN missing");
        address previous = p.owner;
        p.owner = newOwner;
        emit PropertyUpdated(pin, previous, newOwner);
    }

    /// @notice Remove a property (swap-and-pop, pointers kept consistent).
    function deleteProperty(uint256 pin) external onlyRole(REGISTRAR_ROLE) {
        Property storage p = _properties[pin];
        require(p.exists, "Registry: PIN missing");

        uint256 rowToDelete = p.listPointer;
        uint256 lastPin = _pins[_pins.length - 1];
        _pins[rowToDelete] = lastPin;
        _properties[lastPin].listPointer = rowToDelete;
        _pins.pop();
        delete _properties[pin];
        emit PropertyDeleted(pin);
    }

    function getPropertyOwner(uint256 pin) external view returns (address) {
        return _properties[pin].owner;
    }

    function isProperty(uint256 pin) external view returns (bool) {
        return _properties[pin].exists;
    }

    function getPropertyCount() external view returns (uint256) {
        return _pins.length;
    }

    function propertyAt(uint256 index) external view returns (uint256) {
        return _pins[index];
    }
}
