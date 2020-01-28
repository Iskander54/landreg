var Registry = artifacts.require("Registry")
var Mortgage = artifacts.require("Mortgage")

module.exports = function(deployer){
    deployer.deploy(Registry)
    deployer.deploy(Mortgage)
}