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

    it("test test",async()=>{
        const add=await instance.grantPermission(Alex,'landlord')
        assert.equal(await instance.hasRole(Alex,'Client'),true,"wesh wesh")
    })
    it("test2 test2",async()=>{
        const add=await instance.grantPermission(Alex,'Client')
        assert.equal(await instance.hasRole(Alex,'Client'),true,"wesh wesh")
    })
    it("test3 test3",async()=>{
        const add=await instance.grantPermission(Alex,'Admin')
        const ad=await instance.grantPermission(Kevin,'Client',{from: Alex})
        assert.equal(await instance.hasRole(Kevin,'Client'),true,"wesh wesh")
    })
    it("test3 test3",async()=>{
        const add=await instance.grantPermission(Kevin,'Client',{from: Alex})
        assert.equal(await instance.hasRole(Kevin,'Client'),true,"wesh wesh")
    })

})