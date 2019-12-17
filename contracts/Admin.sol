pragma solidity ^0.5.0;

import "./Mortgage.sol";
import "./Registry.sol";

contract RegistryInterface{
    function isProperty(uint pin)public view returns(address);
}

contract RegistryProxyInterface{
    function owner() public view returns (address);
    function Registry() public view returns (RegistryInterface);
}
contract Admin {
    address owner;
    RegistryProxyInterface public registryProxy;
    


    constructor(address _registry) public{
        owner=msg.sender;
        registryProxy = RegistryProxyInterface(_registry);
    }

    modifier exist(){
        RegistryInterface registry = RegistryInterface(registryProxy.Registry());
    }


    function getRegistry() public view returns(uint){
        return address(land);
    }
}