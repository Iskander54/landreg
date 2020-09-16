// The public file for automated testing can be found here: https://gist.github.com/ConsenSys-Academy/e9ec0d8d6c53b56ca9673cfa139b5644
var Registry = artifacts.require('Registry')
var Multi = artifacts.require('MultiOwnership')
let catchRevert = require("./utils/exceptionsHelpers.js").catchRevert
const helper = require('./utils/utils.js');
const time = require("./utils/timeHelper.js");

const BN = web3.utils.BN

contract('MultiOwnership', function (accounts){

    const shared1 = accounts[1]
    const shared2 = accounts[2]
    const shared3 = accounts[3]
    const shared4 = accounts[4]
    const buyer1 = accounts[5]
    const buyer2 = accounts[6]

    beforeEach(async()=>{
        Reg = await Registry.new()
        contract_addr = Reg.address
        const newprop = await Reg.newProperty(accounts[0],2)
        // value in finney
        MultiO = await Multi.new(60,1000,2,accounts[0],contract_addr,{value:0.3*(10**18)})
        let admin = await Reg.grantPermission(MultiO.address,'Admin')
    })

    it("MultiOwnership contract buying a new property", async() =>{
        const join1 = await MultiO.joinSharedProperty({from: shared1,value:0.3*(10**18)})
        const join2 = await MultiO.joinSharedProperty({from: shared2,value:0.4*(10**18)})
        const owner_addr = await Reg.getPropertyOwner(2)
        assert.equal(MultiO.address,owner_addr," The owner of the property is the MultiOwnership contract")
    }),
    it("Sending too much money when joining shareproperty, you should receive the change",async() =>{
        const join1 = await MultiO.joinSharedProperty({from: shared1,value:0.3*(10**18)})
        const join2 = await MultiO.joinSharedProperty({from: shared2,value:0.6*(10**18)})
        assert.equal(join2.logs[0].event,'SendingBackMoney'," Shareholder sent too much money so he should receive some change")
    }),

    it("Revert when you don't send money when trying to join shared property", async() =>{
        const join1 = await MultiO.joinSharedProperty({from: shared1,value:0.3*(10**18)})
        await catchRevert(MultiO.joinSharedProperty())
    }),

    it("Shareholder adding money to the multiown to buy a property", async() =>{
        const join1 = await MultiO.joinSharedProperty({from: shared1,value:0.28*(10**18)})
        const join2 = await MultiO.addMoney({from: accounts[0],value:0.42*(10**18)})
        const owner_addr = await Reg.getPropertyOwner(2)
        assert.equal(MultiO.address,owner_addr," The owner of the property is the MultiOwnership contract")
    }),
    it("Sending too much money when adding money to the shared property, you should receive the change",async() =>{
        const join1 = await MultiO.joinSharedProperty({from: shared1,value:0.28*(10**18)})
        const join2 = await MultiO.addMoney({from: accounts[0],value:0.62*(10**18)})
        assert.equal(join2.logs[0].event,'SendingBackMoney'," Shareholder sent too much money so he should receive some change")
    }),

    it("Revert when sharedholder try to add money without sending money",async() =>{
        const join1 = await MultiO.joinSharedProperty({from: shared1,value:0.3*(10**18)})
        await catchRevert(MultiO.addMoney())
    }),

    it("Shareholder trying to sell his entire share",async() =>{
        const join1 = await MultiO.joinSharedProperty({from: shared1,value:0.3*(10**18)})
        const join2 = await MultiO.joinSharedProperty({from: shared2,value:0.4*(10**18)})
        const onSale = await MultiO.sellShare(100,400,{from: shared1})
        const tryBuying = await MultiO.buyShare(0,{from:shared3, value:0.4*(10**18)})
        assert.isTrue(await MultiO.isOwner(shared3));
        assert.isFalse(await MultiO.isOwner(shared1));
    }),

    it("Shareholder trying to sell part of his share",async() =>{
        const join1 = await MultiO.joinSharedProperty({from: shared1,value:0.3*(10**18)})
        const join2 = await MultiO.joinSharedProperty({from: shared2,value:0.4*(10**18)})
        const onSale = await MultiO.sellShare(50,400,{from: shared1})
        const tryBuying = await MultiO.buyShare(0,{from:shared3, value:0.4*(10**18)})
        assert.isTrue(await MultiO.isOwner(shared3));
        assert.isTrue(await MultiO.isOwner(shared1));
    }),

    it("Creating an operation and upvoting it until it's processed and trying to vote after processing",async()=>{
        const join1 = await MultiO.joinSharedProperty({from: shared1,value:0.3*(10**18)})
        const join2 = await MultiO.joinSharedProperty({from: shared2,value:0.4*(10**18)})
        const op = await MultiO.createOperation({from: shared1,data:"Renovate roof"})
        const upvote = await MultiO.upVote({from:shared1,data:"Renovate roof"})
        const upvote2 = await MultiO.upVote({from:shared2,data:"Renovate roof"})
        await catchRevert(MultiO.downVote({from:accounts[0],data:"Renovate roof"}))


    }),
    it("Creating an operation and upvoting until it is processed",async()=>{
        const join1 = await MultiO.joinSharedProperty({from: shared1,value:0.3*(10**18)})
        const join2 = await MultiO.joinSharedProperty({from: shared2,value:0.4*(10**18)})
        const op = await MultiO.createOperation({from: shared1,data:"Renovate roof"})
        const upvote = await MultiO.upVote({from:shared1,data:"Renovate roof"})
        const downvote = await MultiO.downVote({from:shared2,data:"Renovate roof"})
        const upvote2 = await MultiO.upVote({from:accounts[0],data:"Renovate roof"})
        index = upvote2.logs.length
        assert.isTrue(upvote2.logs[index-1].args.performed)
    }),
    it("Creating an operation and downvoting it until it's processed and trying to vote after processing",async()=>{
        const join1 = await MultiO.joinSharedProperty({from: shared1,value:0.28*(10**18)})
        const join2 = await MultiO.joinSharedProperty({from: shared2,value:0.42*(10**18)})
        const op = await MultiO.createOperation({from: shared1,data:"Renovate roof"})
        const downvote = await MultiO.downVote({from:shared2,data:"Renovate roof"})
        index = downvote.logs.length
        assert.isFalse(downvote.logs[index-1].args.performed)
    })



    
})