// The public file for automated testing can be found here: https://gist.github.com/ConsenSys-Academy/e9ec0d8d6c53b56ca9673cfa139b5644

var Mortgage = artifacts.require('Mortgage')
var Registry = artifacts.require('Registry')
let catchRevert = require("./utils/exceptionsHelpers.js").catchRevert
const helper = require('./utils/utils.js');

const BN = web3.utils.BN

contract('Mortgage', function (accounts) {

    const bank = accounts[0]
    const client = accounts[1]
    const prop_owner = accounts[2]
    const other = accounts[3]


    beforeEach(async () => {
        instance = await Mortgage.new()
        Reg = await Registry.new()
        contract_addr = Reg.address
        resp = await Reg.newProperty(prop_owner,2)
        
    })

    
/*
    it("Unable to confirm a transaction if you are not a party", async () => {
        const tId = await instance.submitTransaction(bank,client,prop_owner,2,5, 2,98,contract_addr,{value:5*(10**18)})
        await catchRevert(instance.confirmTransaction(0,contract_addr,{from: accounts[4]}))
    })
    */

    it("Circuit Breaker working", async () =>{
        const tId = await instance.submitTransaction(bank,client,prop_owner,2,5, 2,98,contract_addr,{value:5*(10**18)})
        await instance.circuitBreaker()
        await catchRevert(instance.confirmTransaction(0,contract_addr,{from: prop_owner}))

    })

    it("Client, Bank or Client able to revoke contract ", async () => {
        const tId = await instance.submitTransaction(bank,client,prop_owner,2,5, 2,98,contract_addr,{value:5*(10**18)})
        const propconfirm = await instance.confirmTransaction(0,contract_addr,{from: prop_owner})
        const proprevoc = await instance.revokeConfirmation(0,{from:prop_owner})
        const clientconfirm = await instance.confirmTransaction(0,contract_addr,{from: client})
        assert.equal(clientconfirm.logs[1].event,"ExecutionFailure","Transaction shouldn't be confirmed")
    })

    it("check that bank has to deposit same amount has in the contract", async () => {

        await catchRevert(instance.submitTransaction(bank,client,prop_owner,2,5, 2,98,contract_addr,{value : 4}))
    })

    it("check that we can get the money in a contract",async()=>{
        const initial=parseInt(await instance.getDeposit(),10)
        const deposit=5*(10**18)
        const tId = await instance.submitTransaction(bank,client,prop_owner,2,5,2,98,contract_addr,{value:deposit})
        let ball = parseInt(await instance.getDeposit(),10)

        assert.equal(initial+parseInt(deposit,10),ball,"we should be able to check how much money the contract holds")

    })

    it("Check that the transaction is executed when all parties have sign the transaction", async () => {
        let actualPropowner = await web3.eth.getBalance(accounts[2])
     
        const tId = await instance.submitTransaction(bank,client,prop_owner,2,5,2,98,contract_addr,{value:5*(10**18)})
         let ball = await instance.getDeposit()
         
         const propconfirm = await instance.confirmTransaction(0,contract_addr,{from: prop_owner})
         const clientconfirm = await instance.confirmTransaction(0,contract_addr,{from: client})
         let newBalancePropOwner = await web3.eth.getBalance(accounts[2])
         
         let bal = await instance.getDeposit()
         let before = parseInt(actualPropowner,10)
         let after = parseInt(newBalancePropOwner,10);
         
 
         assert.isAbove(after,before, "Balance incorrect!");
         

     })



})