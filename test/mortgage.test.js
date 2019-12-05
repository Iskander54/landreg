// The public file for automated testing can be found here: https://gist.github.com/ConsenSys-Academy/e9ec0d8d6c53b56ca9673cfa139b5644

var Mortgage = artifacts.require('Mortgage')
let catchRevert = require("./exceptionsHelpers.js").catchRevert
const BN = web3.utils.BN

contract('Mortgage',function(accounts){

    const bank=accounts[0]
    const client=accounts[1]
    const prop_owner=accounts[2]
    const other=accounts[3]

    beforeEach(async()=>{
        instance = await Mortgage.new();
    })

    it("Check that the transaction is executed when all parties have sign the transaction",async()=>{

    })

    it("Unable to confirm a transaction if you are not a party",async()=>{

    })

    it("Client or Bank able to revoke contract within 14 days ",async()=>{

    })

    it("not able to process transaction if not all requirement met",async()=>{
        
    })


})