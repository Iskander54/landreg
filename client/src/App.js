import React, { Component } from "react";
import Registry from "./contracts/Registry.json";
import Mortgage from "./contracts/Mortgage.json";
import getWeb3 from "./getWeb3";
import {
  BrowserRouter as Router,
  Switch,
  Route,
  Link
} from "react-router-dom";
import Create from "./Create";
import Validate from "./Validate";
import Admin from "./Admin";
import Home from "./Home";
import "./App.css";




class App extends Component {
  constructor(props) {
    super(props);
    this.state = { storageValue: null, web3: null, accounts: null,
      contract: null,contract_addr:null,mortgage:null,value:null,PIN:null,
      add_address:null,
      add_pin:null,
      upd_address:null,
      upd_pin:null,
      del_pin:null,
      index:null,
      stopper:null,
      properties:[],
      user:null
      };
/*
    module.exports = function(deployer){
      deployer.deploy(Mortgage)

  }
  */
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
      const deployedNetwork2= Mortgage.networks[networkId];
      const instance2 = new web3.eth.Contract(
        Mortgage.abi,deployedNetwork2 && deployedNetwork2.address,
        );
      this.setState({ web3, accounts, contract: instance, mortgage:instance2, contract_addr:deployedNetwork.address,user:accounts[0] }, this.runExample);
      // Set web3, accounts, and contract to the state, and then proceed with an
      // example of interacting with the contract's methods.
      console.log(Registry)
  };

  runExample = async () => {
    const {mortgage} = this.state;
    const resp = await mortgage.methods.contractPaused().call();
    this.setState({stopper : resp})
  };

  stopper = async () =>{
    const {accounts,mortgage } = this.state;
    await mortgage.methods.circuitBreaker().send({from:accounts[0]})
    const cb = await mortgage.methods.contractPaused().call();
    this.setState({stopper : cb})
  }


  render() {
    if (!this.state.web3) {
      return <div>Loading Web3, accounts, and contract...</div>;
    }
    return (
      <div className="App">
        <button onClick={this.stopper}><strong><p style={{color: this.state.stopper === false ?  "green" : "red"  }}>Circuit Breaker</p></strong></button>
        <h2>{this.state.user} : {this.state.user === "0x42CAD0CA3716b4664c2658A0a48664369D511C54"? "Contracts owner" : "User"}</h2>
        <Router>
        <div>
          <nav>
            <ul>
              <li>
                <Link to="/Home">Home</Link>
              </li>
              <li>
                <Link to="/create">Create Transactions</Link>
              </li>
              <li>
                <Link to="/validate">Validate/Revoke</Link>
              </li>
              <li>
                <Link to="/Admin">Admin</Link>
              </li>
            </ul>
          </nav>
      <Switch>
        <Route path="/create">
        <Create web3={this.state.web3} accounts={this.state.accounts} contract={this.state.contract} mortgage={this.state.mortgage} contract_addr={this.state.contract_addr} />
        </Route>
        <Route path="/validate">
        <Validate web3={this.state.web3} accounts={this.state.accounts} contract={this.state.contract} mortgage={this.state.mortgage} contract_addr={this.state.contract_addr} />
        </Route>
        <Route path="/Admin">
        <Admin web3={this.state.web3} accounts={this.state.accounts} contract={this.state.contract} />
        </Route>
        <Route path="/Home">
        <Home web3={this.state.web3} accounts={this.state.accounts} contract={this.state.contract} />
        </Route>
      </Switch>
      </div>
      </Router>
   </div>
    );
  }
}

export default App;
