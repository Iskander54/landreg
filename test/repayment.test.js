// The public file for automated testing can be found here: https://gist.github.com/ConsenSys-Academy/e9ec0d8d6c53b56ca9673cfa139b5644

var Repayment = artifacts.require('Repayment')
var Registry = artifacts.require('Registry')
let catchRevert = require("./utils/exceptionsHelpers.js").catchRevert
const helper = require('./utils/utils.js');
const time = require("./utils/timeHelper.js");

const BN = web3.utils.BN

contract('Repayment', function (accounts) {

    const owner = accounts[0]
    const creditor = accounts[1]
    const creditee = accounts[2]


    beforeEach(async () => {
        Reg = await Registry.new()
        contract_addr = Reg.address
        const prop = await Reg.newProperty(creditee,2)
        Repay = await Repayment.new(creditor,creditee,1,4,2,12,contract_addr,2)
        const admin = await Reg.addAdminRoles(Repay.address,{from:owner})
        
    })

    describe("Testing Helper Functions", () => {
        /*
        it("should advance the blockchain forward a block", async () =>{
            const originalBlockHash = await web3.eth.getBlock('latest').hash;
            console.log(await web3.eth.getBlock('latest'))
            let newBlockHash = await web3.eth.getBlock('latest');
            console.log(newBlockHash)
            console.log(await web3.eth.getBlock('latest'))
            newBlockHash = await time.advanceBlock();
            console.log(newBlockHash) 
            console.log(await web3.eth.getBlock('latest'))
            assert.notEqual(originalBlockHash, newBlockHash);
        });
    */
        it("should be able to advance time and block together", async () => {
            const advancement = 600;
            const originalBlock = await web3.eth.getBlock('latest');
            const newBlock = await time.advanceTimeAndBlock(advancement);
            //console.log("timestamp originalblock "+originalBlock.timestamp)
            //console.log("timestamp newblock "+newBlock.timestamp)
            const timeDiff = newBlock.timestamp - originalBlock.timestamp;
    
            assert.isTrue(timeDiff >= advancement);
        });
    });

    it("Receiving a payment on time", async () =>{
       // const advancement = 604800; //7days
        const advancement = 600000;//less than 7days
        const pay = 0.3*(10**18)
        const newBlock = await time.advanceTimeAndBlock(advancement);
        balancebefore = parseInt(await web3.eth.getBalance(Repay.address))
        const tId = await Repay.makePayment({from:creditee,value:pay});
        balanceafter = parseInt(await web3.eth.getBalance(Repay.address))
        assert.equal(balanceafter,balancebefore+pay,"Checking that the balance of the contract is what the creditee send") 
    })

    it("Withdraw money", async () =>{
         const advancement = 604800; //7days
         const pay = 0.3*(10**18)
         const tx1 = await Repay.makePayment({from:creditee,value:pay});
         const newBlock = await time.advanceTimeAndBlock(advancement);
         balancebefore = parseInt(await web3.eth.getBalance(creditor))
         const tx2 = await Repay.makePayment({from:creditee,value:pay});
         const balancontract = await web3.eth.getBalance(Repay.address);
         const withdraw = await Repay.withdraw({from:creditor});
         balanceafter = parseInt(await web3.eth.getBalance(creditor));
         const gp = await web3.eth.getTransaction(withdraw.tx);
         const txcost = withdraw.receipt.cumulativeGasUsed*gp.gasPrice;
         assert.equal(balanceafter,(balancebefore+(balancontract-txcost)),"Balance of the creditor should increase") 
     })

    it("Missed Payment so can't accept it", async()=>{
        const advancement = 604900; //7days+100sec
        const pay = 0.3*(10**18)
        const newBlock = await time.advanceTimeAndBlock(advancement);
        const balanceA = parseInt(await web3.eth.getBalance(creditee))
        const tId = await Repay.makePayment({from:creditee,value:pay});
        const tx = await web3.eth.getTransaction(tId.tx);
        const penalty=parseInt(await Repay.penalty())
        const balanceB = parseInt(await web3.eth.getBalance(creditee))
        const diffBalance = balanceA-balanceB
        const txcost=tId.receipt.cumulativeGasUsed*tx.gasPrice
        assert.equal(await Repay.missedPayment(),1,"count the missed payment")
        assert.equal(diffBalance.toString().substring(0,6),(penalty+txcost).toString().substring(0,6)," Balance after is not the right one, should be Balance - fees and transaction cost")  
    })

    it(" 3 Missed Payment so property should be transfered to creditor",async()=>{
        const advancement = 604900;
        const first_owner = await Reg.isProperty(2);
        await time.advanceTimeAndBlock(advancement);
        await Repay.processMissedPayment();
        await time.advanceTimeAndBlock(advancement);
        await Repay.processMissedPayment();
        await time.advanceTimeAndBlock(advancement);
        await Repay.processMissedPayment();
        await time.advanceTimeAndBlock(advancement);
        await Repay.processMissedPayment();
        await time.advanceTimeAndBlock(advancement);
        await Repay.processMissedPayment();
        const last_owner = await Reg.isProperty(2);
        assert.equal(last_owner,creditor,"Too much missed Payment, ownership transferred");
    })


})