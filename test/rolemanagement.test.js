// The public file for automated testing can be found here: https://gist.github.com/ConsenSys-Academy/e9ec0d8d6c53b56ca9673cfa139b5644

var RoleManagement = artifacts.require('RoleManagement')
let catchRevert = require("./utils/exceptionsHelpers.js").catchRevert
const helper = require('./utils/utils.js');

const BN = web3.utils.BN

contract('RoleManagement',function(accounts){
    Yann= accounts[0];
    Alex= accounts[1];
    Kevin= accounts[2];

    beforeEach(async() =>{
        instance = await RoleManagement.new()
    })

    it("Check if role is not granted when not part of predefine roles.",async()=>{
        await catchRevert(instance.grantPermission(Alex,'landlord'))
    })
    it("Check if role can be granted.",async()=>{
        const add=await instance.grantPermission(Alex,'Client')
        assert.equal(await instance.hasRole(Alex,'Client'),true,"Role granted")
    })
    it("Grant admin role to an address and grant role with the later",async()=>{
        const add=await instance.grantPermission(Alex,'Admin')
        const ad=await instance.grantPermission(Kevin,'Client',{from: Alex})
        assert.equal(await instance.hasRole(Kevin,'Client'),true,"Role")
    })
    it("Granting role when you are not admin doesn't work",async()=>{
        await catchRevert(instance.grantPermission(Kevin,'Client',{from: Alex}))
    })
    it("Check if role can be removed after being granted.",async()=>{
        const add=await instance.grantPermission(Alex,'Client')
        assert.equal(await instance.hasRole(Alex,'Client'),true,"Role granted")
        const rem=await instance.revokePermission(Alex,'Client')
        assert.equal(await instance.hasRole(Alex,'Client'),false,"Role removed")
    })
    it("Cannot remove role when you are not admin.", async()=>{
        const add=await instance.grantPermission(Alex,'Client')
        assert.equal(await instance.hasRole(Alex,'Client'),true,"Role granted")
        await catchRevert(instance.revokePermission(Alex,'Client',{from:Kevin}))
        
    })
    it("Add roles to UserRoles", async()=>{
        const roles_before = await instance.getRolesCount();
        const addRoles = await instance.addRolesList('Tenant');
        const roles_after = await instance.getRolesCount();
        assert.equal(parseInt(roles_before)+1,roles_after,"New Role has been added.")
        assert.equal(await instance.userRoles.call(roles_after-1),'Tenant',"Everything is correct.")
    })
})