import React, { Component } from "react";
import Registry from "./contracts/Registry.json";
import getWeb3 from "./getWeb3";

import "./App.css";

class App extends Component {
  constructor(props) {
    super(props);
    this.state = { storageValue: 5, web3: null, accounts: null,
      contract: null,value:null, form:null,
      address:null,
      pin:null
      };

    this.handleChange = this.handleChange.bind(this);
    this.handleSubmit = this.handleSubmit.bind(this);
  }

  componentDidMount = async () => {
  
      // Get network provider and web3 instance.
      const web3 = await getWeb3();

      // Use web3 to get the user's accounts.
      const accounts = await web3.eth.getAccounts();

      // Get the contract instance.
      const networkId = await web3.eth.net.getId();
      const deployedNetwork = Registry.networks[networkId];
      const instance = new web3.eth.Contract(
        Registry.abi,
        deployedNetwork && deployedNetwork.address,
      );
      this.setState({ web3, accounts, contract: instance }, this.runExample);

      // Set web3, accounts, and contract to the state, and then proceed with an
      // example of interacting with the contract's methods.
    

  };

  runExample = async () => {
    const { accounts, contract } = this.state;

    // Stores a given value, 5 by default.
    //await contract.methods.set(5).send({ from: accounts[0] });
    const response = await contract.methods.getPropertyCount().call();


    // Get the value from the contract to prove it worked.
    //const response = await contract.methods.get().call();

    // Update state with the result.
     this.setState({ storageValue: response });
  };

  handleChange = async(event) =>{
    
    const response = await this.state.contract.methods.getPropertyCount().call();
    debugger
    this.setState({ storageValue: response });
  }

  handleChangeSubmit = async(event)=> {
    this.setState({address: event.target.value});
  }

  handleChangePin= async(event)=> {
    this.setState({pin: event.target.value});
  }

  handleSubmit = async(event) => {
    event.preventDefault();
    const { accounts, contract } = this.state;
    const response = await contract.methods.newProperty(this.state.address,this.state.pin).call();
    alert('Le nom a été soumis : ' + response);
    
  }

  render() {
    if (!this.state.web3) {
      return <div>Loading Web3, accounts, and contract...</div>;
    }
    return (
      <div className="App">
        <h1>Good to Go!</h1>
        <p>Your Truffle Box is installed and ready.</p>
        <h2>Smart Contract Example</h2>
        <p>
          If your contracts compiled and migrated successfully, below will show
          a stored value of 5 (by default).
        </p>
        <p>
          Try changing the value stored on <strong>line 40</strong> of App.js.
        </p>
        <div>The stored value is: {this.state.storageValue}</div>
        <input 
        type="text" 
        value={this.state.value}
        onChange={this.handleChange} />

      <form onSubmit={this.handleSubmit}>
        <label>
          Nom :
          <input type="text" value={this.state.address} onChange={this.handleChangeSubmit} />
        </label>
        <label>
          PIN :
          <input type="text" value={this.state.pin} onChange={this.handleChangePin}/>
        </label>
        <input type="submit" value="Envoyer" />
      </form>

      <div>{this.state.form}</div>
      </div>
    );
  }
}

export default App;
