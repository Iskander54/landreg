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
import Buy from "./Mortgage";
import Admin from "./Admin";
import Home from "./Home";
import "./App.css";



class App extends Component {
  constructor(props) {
    super(props);
    this.state = { storageValue: null, web3: null, accounts: null,
      contract: null,value:null,PIN:null,
      add_address:null,
      add_pin:null,
      upd_address:null,
      upd_pin:null,
      del_pin:null,
      index:null,
      properties:[]
      };

    this.handleChange = this.handleChange.bind(this);
    this.addProperty = this.addProperty.bind(this);
    this.updProperty = this.updProperty.bind(this);
    this.delProperty = this.delProperty.bind(this);
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
    this.checkProperties();
  };

  checkProperties = async(event)=>{
    const { accounts, contract } = this.state;

    const response = await this.state.contract.methods.getPropertyCount().call();
    this.setState({ form: response });
    const wesh = await this.state.contract.methods.properties(1).call();
    var test=[];
    var pins=[];
    for(var i=0;i<response;i++){
      const index = await this.state.contract.methods.propertyList(i).call();
      const mapping = await this.state.contract.methods.properties(index).call();
      test.push(mapping);
      pins.push(index)
    }
    this.setState({properties:test,storageValue: response, PIN:pins});

  }

  handleChange = async(event) =>{
  
  }

  handleChangeAddressAdd = async(event)=> {
    this.setState({add_address: event.target.value});
  }

  handleChangePinAdd= async(event)=> {
    this.setState({add_pin: event.target.value});
  }

  addProperty = async(event) => {
    event.preventDefault();
    const { accounts, contract } = this.state;
    console.log(this.state.add_address)
    console.log(this.state.add_pin)
    const resp = await contract.methods.newProperty(this.state.add_address,this.state.add_pin).send({from:accounts[0]});
    alert('Property added : ' + resp);
    this.checkProperties();
    
  }

  handleChangeAddressUpd = async(event)=> {
    this.setState({upd_address: event.target.value});
  }

  handleChangePinUpd= async(event)=> {
    this.setState({upd_pin: event.target.value});
  }

  updProperty = async(event) => {
    event.preventDefault();
    const { accounts, contract } = this.state;
    const resp = await contract.methods.updateProperty(this.state.upd_address,this.state.upd_pin).send({from:accounts[0]});
    alert('Property updated: ' + resp);
    this.checkProperties();
    
  }

  handleChangePinDel= async(event)=> {
    this.setState({del_pin: event.target.value});
  }

  delProperty = async(event) => {
    event.preventDefault();
    const { accounts, contract } = this.state;
    const resp = await contract.methods.deleteProperty(this.state.del_pin).send({from:accounts[0]});
    alert('Property deleted: ' + resp);
    this.checkProperties();
    
  }

  render() {
    if (!this.state.web3) {
      return <div>Loading Web3, accounts, and contract...</div>;
    }
    return (
      <div className="App">
        <Router>
        <div>
          <nav>
            <ul>
              <li>
                <Link to="/Home">Home</Link>
              </li>
              <li>
                <Link to="/Mortgage">Mortgage</Link>
              </li>
              <li>
                <Link to="/Admin">Admin</Link>
              </li>
            </ul>
          </nav>
      <Switch>
        <Route path="/Mortgage">
        <Buy web3={this.state.web3} accounts={this.state.accounts} contract={this.state.contract} />
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
