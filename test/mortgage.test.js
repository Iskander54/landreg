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
        instance = await Mortgage.new([bank,client,prop_owner],3)
        const tId = await instance.submitTransaction(bank,client,2,50, 2,98)
    })

    it("Check that the transaction is executed when all parties have sign the transaction", async () => {
        //const tId2 = await instance.submitTransaction(bank,client,3,51, 3,99)
        //assert.equal(events.length,2,"wesh1")
       /* const clientconfirm = await instance.confirmTransaction(tId,{from: client}).then(function(events){
            assert.equal(events[3].args.sender.valueOf(),client,"wesh2")
        }).then(done).catch(done)
        */
        const clientconfirm = await instance.confirmTransaction(0,{from: client})
        const propconfirm = await instance.confirmTransaction(0,{from: prop_owner})

        assert.equal(propconfirm.logs[1].event,"Execution","The transaction should be executed and return true ")

    })

    it("Unable to confirm a transaction if you are not a party", async () => {
        for (let i=0; i<3 ;i++){
            console.log(await instance.mortgages[0][0])
        }
        await catchRevert(instance.confirmTransaction(0,{from: accounts[4]}))
    })

    it("Client, Bank or Client able to revoke contract within 14 days ", async () => {
        const propconfirm = await instance.confirmTransaction(0,{from: prop_owner})
        await helper.advanceTimeAndBlock(3600*20);
        const originalBlock = web3.eth.getBlock('latest');
        const clientconfirm = await instance.confirmTransaction(0,{from: client})
        await catchRevert(instance.revokeConfirmation(0,{from: prop_owner}))
    })

    it("not able to process transaction if not all requirement met", async () => {

    })


})