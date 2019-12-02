// The public file for automated testing can be found here: https://gist.github.com/ConsenSys-Academy/e9ec0d8d6c53b56ca9673cfa139b5644

var Registry = artifacts.require('Registry')
let catchRevert = require("./exceptionsHelpers.js").catchRevert
const BN = web3.utils.BN

contract('Registry',function(accounts){
    
    const alex=accounts[0]
    const kevin=accounts[1]

    beforeEach(async () => {
        instance = await Registry.new()
    })

    it("Check new property is created",async()=>{
        const add=await instance.newProperty(alex,3)
        const check= await instance.isProperty(3)

        assert.equal(check,alex,"new property is not found")
    })

    it("Should add two property to the blockchain and count them",async()=>{
        const tx1=await instance.newProperty(alex,5)
        /*
        if (tx.logs[0].event == "PropertyAdd") {
            eventEmitted = true
            console.log[tx.logs[0].value]
        }*/
        const tx2=await instance.newProperty(kevin,2)
        /*
        if (txx.logs[0].event == "PropertyAdd") {
            eventEmitted = true
        }*/
        const nb = await instance.getPropertyCount()
        assert.equal(nb,2,'the number of accounts is the same as the number of added accounts')
    })

    it("Update a property that has been added ",async()=>{
        const add=await instance.newProperty(alex,3)
        const checkAdded= await instance.isProperty(3)
        if(checkAdded==alex){
            const update=await instance.updateProperty(kevin,3)
        }
        const checkUpdate = await instance.isProperty(3)
        assert.equal(checkUpdate,kevin,"The property hasnt changed owner")
    })

    it("Delete a property that has been added ",async()=>{
        const add=await instance.newProperty(alex,3)
        const checkAdded= await instance.isProperty(3)
        if(checkAdded==alex){
            const update=await instance.deleteProperty(3,{from: kevin})
        }
        const nb = await instance.getPropertyCount()
        assert.equal(nb,0,"The property hasnt changed owner")
    })
})