// The public file for automated testing can be found here: https://gist.github.com/ConsenSys-Academy/e9ec0d8d6c53b56ca9673cfa139b5644

var Admin = artifacts.require('Admin')
let catchRevert = require("./utils/exceptionsHelpers.js").catchRevert
const helper = require('./utils/utils.js');

const BN = web3.utils.BN

contract('Admin',function(accounts){

    beforeEach(async() =>{
        instance = await Admin.new()
    })

    it("test test",async()=>{
        const add=await instance.getRegistry()
        console.log(add.toNumber())
        assert.equal(true,true,"wesh wesh")
    })

})