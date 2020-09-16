var Registry = artifacts.require("Registry")
var Mortgage = artifacts.require("Mortgage")
var MultiOwnership = artifacts.require("MultiOwnership")
var Repayment = artifacts.require("Repayment")

module.exports = function(deployer){
    deployer.then(async() => {
    await deployer.deploy(Registry)
    await deployer.deploy(Mortgage)
})
}