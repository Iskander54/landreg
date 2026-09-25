// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {IAccessControl} from "@openzeppelin/contracts/access/IAccessControl.sol";
import {Registry} from "../contracts-v2/Registry.sol";

/// @dev Proves the Registry remediations, above all H-01 (access control on newProperty).
contract RegistryTest is Test {
    Registry reg;
    address admin = address(this);
    address attacker = makeAddr("attacker");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    function setUp() public {
        reg = new Registry(admin);
    }

    /// H-01 FIXED: an account without REGISTRAR_ROLE can no longer register a property.
    function test_H01_newProperty_reverts_for_nonAdmin() public {
        // Read the role BEFORE the prank so the only pranked call is newProperty.
        bytes32 registrar = reg.REGISTRAR_ROLE();
        vm.prank(attacker);
        vm.expectRevert(
            abi.encodeWithSelector(
                IAccessControl.AccessControlUnauthorizedAccount.selector,
                attacker,
                registrar
            )
        );
        reg.newProperty(alice, 42);
    }

    /// The registrar (admin) can still register, and it persists.
    function test_admin_can_register_property() public {
        reg.newProperty(alice, 42);
        assertEq(reg.getPropertyOwner(42), alice);
        assertTrue(reg.isProperty(42));
        assertEq(reg.getPropertyCount(), 1);
    }

    /// A granted registrar can register; a revoked one cannot.
    function test_role_grant_and_revoke() public {
        reg.grantRole(reg.REGISTRAR_ROLE(), bob);
        vm.prank(bob);
        reg.newProperty(alice, 7);
        assertEq(reg.getPropertyOwner(7), alice);

        reg.revokeRole(reg.REGISTRAR_ROLE(), bob);
        vm.prank(bob);
        vm.expectRevert();
        reg.newProperty(alice, 8);
    }

    /// L-02 FIXED: delete keeps the list consistent and clears existence.
    function test_delete_keeps_list_consistent() public {
        reg.newProperty(alice, 1);
        reg.newProperty(bob, 2);
        reg.newProperty(alice, 3);
        assertEq(reg.getPropertyCount(), 3);

        reg.deleteProperty(2); // delete a middle element
        assertFalse(reg.isProperty(2));
        assertEq(reg.getPropertyCount(), 2);
        // remaining PINs still resolve to their owners
        assertEq(reg.getPropertyOwner(1), alice);
        assertEq(reg.getPropertyOwner(3), alice);
    }

    function test_cannot_double_register() public {
        reg.newProperty(alice, 42);
        vm.expectRevert(bytes("Registry: PIN exists"));
        reg.newProperty(bob, 42);
    }
}
