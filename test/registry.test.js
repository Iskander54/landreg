// The public file for automated testing can be found here: https://gist.github.com/ConsenSys-Academy/e9ec0d8d6c53b56ca9673cfa139b5644

var Registry = artifacts.require('Registry')
//let catchRevert = require("./exceptionsHelpers.js").catchRevert
const BN = web3.utils.BN

contract('Registry',function(accounts){
    
    const alex=accounts[0]
    const kevin=accounts[0]

    beforeEach(async () => {
        instance = await Registry.new()
    })
    it("should add two property to the blockchain",async()=>{
        const tx =await instance.newProperty(alex,5)
        /*
        if (tx.logs[0].event == "PropertyAdd") {
            eventEmitted = true
            console.log[tx.logs[0].value]
        }*/
        const txx=await instance.newProperty(kevin,2)
        /*
        if (txx.logs[0].event == "PropertyAdd") {
            eventEmitted = true
        }*/
        assert.equal(instance.getPropertyCount(),3,'the number of accounts is the same as the number of added accounts')
    })
})