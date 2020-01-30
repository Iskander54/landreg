// The public file for automated testing can be found here: https://gist.github.com/ConsenSys-Academy/e9ec0d8d6c53b56ca9673cfa139b5644

var Registry = artifacts.require('Registry')
let catchRevert = require("./utils/exceptionsHelpers.js").catchRevert
const helper = require('./utils/utils.js');

const BN = web3.utils.BN

contract('Registry',function(accounts){
    
    const alex=accounts[0]
    const kevin=accounts[1]
    const yann=accounts[2]

    beforeEach(async () => {
        instance = await Registry.new()
    })

    it("Checking property should be able only when there is more than one",async()=>{
        await instance.deleteProperty(1)
        await catchRevert(instance.isProperty(2))
    })

    it("Check new property is created",async()=>{
        const add=await instance.newProperty(alex,3)
        const check= await instance.isProperty(3)

        assert.equal(check,alex,"new property is not found")
    })

    it("Should add two property to the blockchain and count them",async()=>{
        const before = await instance.getPropertyCount()
        const tx1=await instance.newProperty(alex,5)
        const tx2=await instance.newProperty(kevin,2)
        const nb = await instance.getPropertyCount()
        assert.equal(nb.toNumber(),before.toNumber()+2,'the number of accounts is the same as the number of added accounts')
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

    it("Trying to delete a property when you not the owner of the contract",async()=>{
        const add=await instance.newProperty(kevin,3)
        const checkAdded= await instance.isProperty(3)
        await catchRevert(instance.deleteProperty(3,{from: yann}))
        
    })

    it("Delete a property by the owner of the contract ",async()=>{
        const add=await instance.newProperty(kevin,3)
        const before= await instance.getPropertyCount()
        const checkAdded= await instance.isProperty(3)
        if(checkAdded==kevin){
            const update=await instance.deleteProperty(3,{from:alex})
        }
        const nb = await instance.getPropertyCount()
        assert.equal(nb.toNumber(),before.toNumber()-1,"The deleteProperty is called by the owner and should be deleted")
    })


})