// The public file for automated testing can be found here: https://gist.github.com/ConsenSys-Academy/e9ec0d8d6c53b56ca9673cfa139b5644

var Mortgage = artifacts.require('Mortgage')
let catchRevert = require("./utils/exceptionsHelpers.js").catchRevert
const helper = require('./utils/utils.js');

const BN = web3.utils.BN

contract('Mortgage', function (accounts) {

    const bank = accounts[0]
    const client = accounts[1]
    const prop_owner = accounts[2]
    const other = accounts[3]


    beforeEach(async () => {
        instance = await Mortgage.new(bank,client,prop_owner,3)
        
    })

    

    it("Unable to confirm a transaction if you are not a party", async () => {
        const tId = await instance.submitTransaction(bank,client,2,5, 2,98,{value:5*(10**18)})
        await catchRevert(instance.confirmTransaction(0,{from: accounts[4]}))
    })

    it("Client, Bank or Client able to revoke contract ", async () => {
        const tId = await instance.submitTransaction(bank,client,2,5, 2,98,{value:5*(10**18)})
        const propconfirm = await instance.confirmTransaction(0,{from: prop_owner})
        const proprevoc = await instance.revokeConfirmation(0,{from:prop_owner})
        const clientconfirm = await instance.confirmTransaction(0,{from: client})
        assert.equal(clientconfirm.logs[1].event,"ExecutionFailure","Transaction shouldn't be confirmed")
    })

    it("check that bank has to deposit same amount has in the contract", async () => {

        await catchRevert(instance.submitTransaction(bank,client,2,5, 2,98,{value : 4}))
    })

    it("check that we can get the money in a contract",async()=>{
        const deposit=5*(10**18)
        const tId = await instance.submitTransaction(bank,client,2,5,2,98,{value:deposit})
        let ball = await instance.getDeposit()

        assert.equal(ball,deposit,"we should be able to check how much money the contract holds")

    })

    it("Check that the transaction is executed when all parties have sign the transaction", async () => {
        let actualBank = await web3.eth.getBalance(accounts[0])
        let actualClient = await web3.eth.getBalance(accounts[1])
        let actualPropowner = await web3.eth.getBalance(accounts[2])
         //console.log(actualBalance0, actualBalance1,actualBalance2)
     
        const tId = await instance.submitTransaction(bank,client,2,5,2,98,{value:5*(10**18)})
         let ball = await instance.getDeposit()
         //console.log(ball.toNumber())
         
         const propconfirm = await instance.confirmTransaction(0,{from: prop_owner})
         const clientconfirm = await instance.confirmTransaction(0,{from: client})
         let newBalanceBank = await web3.eth.getBalance(accounts[0])
         let newBalanceClient = await web3.eth.getBalance(accounts[1])
         let newBalancePropOwner = await web3.eth.getBalance(accounts[2])
         
         //console.log(newBalance0,newBalance1,newBalance2)
         let bal = await instance.getDeposit()
         //console.log(bal.toNumber())
         let before = parseInt(actualPropowner,10)
         let after = parseInt(newBalancePropOwner,10);
         console.log(before,after);
         
 
         assert.isAbove(after,before, "Balance incorrect!");
         
         /*
         assert.equal(propconfirm.logs[1].event,"Execution","The transaction should be executed and return true ")
         */
 
     })



})