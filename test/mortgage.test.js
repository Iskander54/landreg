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

    it("Check that the transaction is executed when all parties have sign the transaction", async () => {
       let actualBalance0 = await web3.eth.getBalance(accounts[0])
       let actualBalance1 = await web3.eth.getBalance(accounts[1])
       let actualBalance2 = await web3.eth.getBalance(accounts[2])
        console.log(actualBalance0, actualBalance1,actualBalance2)
    
       const tId = await instance.submitTransaction(bank,client,2,200000000000000,2,98,{value:200000000000000 })
        let ball = await instance.getDeposit()
        console.log(ball.toNumber())
        
        const propconfirm = await instance.confirmTransaction(0,{from: prop_owner})
        const clientconfirm = await instance.confirmTransaction(0,{from: client})
        let newBalance0 = await web3.eth.getBalance(accounts[0])
        let newBalance1 = await web3.eth.getBalance(accounts[1])
        let newBalance2 = await web3.eth.getBalance(accounts[2])
        
        console.log(newBalance0,newBalance1,newBalance2)
        let bal = await instance.getDeposit()
        console.log(bal.toNumber())
        let before = parseInt(actualBalance2,10)
        let after = parseInt(newBalance2,10);
        console.log(before,after);
        

        assert.isAbove(before,after, "Balance incorrect!");
        
        /*
        assert.equal(propconfirm.logs[1].event,"Execution","The transaction should be executed and return true ")
        */

    })

    it("Unable to confirm a transaction if you are not a party", async () => {
        const tId = await instance.submitTransaction(bank,client,2,50, 2,98,{value:50})
        await catchRevert(instance.confirmTransaction(0,{from: accounts[4]}))
    })

    it("Client, Bank or Client able to revoke contract ", async () => {
        const tId = await instance.submitTransaction(bank,client,2,50, 2,98,{value:50})
        const propconfirm = await instance.confirmTransaction(0,{from: prop_owner})
        const proprevoc = await instance.revokeConfirmation(0,{from:prop_owner})
        const clientconfirm = await instance.confirmTransaction(0,{from: client})
        assert.equal(clientconfirm.logs[1].event,"ExecutionFailure","Transaction shouldn't be confirmed")
    })

    it("check that bank has to deposit same amount has in the contract", async () => {

        await catchRevert(instance.submitTransaction(bank,client,2,5000, 2,98,{value : 4999}))
    })



})