import React, { Component } from "react";
import Registry from "./contracts/Registry.json";
import getWeb3 from "./getWeb3";
import {
  BrowserRouter as Router,
  Switch,
  Route,
  Link
} from "react-router-dom";
import Mortgage from "./Mortgage"
import App from "./App"
import "./App.css";


class Admin extends Component {
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
      /*
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
      */
      //this.setState({ web3, accounts, contract: instance }, this.runExample);
      //this.setState({ web3:this.props.web3, accounts:this.props.accounts, contract: this.props.contract}, this.runExample);

      // Set web3, accounts, and contract to the state, and then proceed with an
      // example of interacting with the contract's methods.
    

  };

  runExample = async () => {
    this.checkProperties();
  };

  checkProperties = async(event)=>{
    const { accounts, contract } = this.props;

    const response = await contract.methods.getPropertyCount().call();
    this.setState({ form: response });
    const wesh = await contract.methods.properties(1).call();
    var test=[];
    var pins=[];
    for(var i=0;i<response;i++){
      const index = await contract.methods.propertyList(i).call();
      const mapping = await contract.methods.properties(index).call();
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
    const { accounts, contract } = this.props;
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
    const { accounts, contract } = this.props;
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
    if (!this.props.web3) {
      return <div>Loading Web3, accounts, and contract...</div>;
    }
    return (
    
      <div className="Admin">
        <h1>Admin</h1>
        <h2>{this.props.accounts[0]}</h2>
        <p>
          <div><strong>Owner's address</strong> -- <strong>Property Identification Number ({this.state.storageValue})</strong></div>
          <div>
   {this.state.properties.map(txt => <p>{txt.owner} -- {this.state.PIN[txt.listPointer]}</p>)}
</div>
  
        </p>
        <input 
        type="text" 
        value={this.state.value}
        onChange={this.handleChange} />
        

      <form onSubmit={this.addProperty}>
        <p>Add a property on sale</p>
        <label>
          Owner :
          <input type="text" value={this.state.add_address} onChange={this.handleChangeAddressAdd} />
        </label>
        <label>
          PIN :
          <input type="text" value={this.state.add_pin} onChange={this.handleChangePinAdd}/>
        </label>
        <input type="submit" value="Add" />
      </form>

      <form onSubmit={this.updProperty}>
        <p>Updatea Property sale</p>
        <label>
          Owner :
          <input type="text" value={this.state.upd_address} onChange={this.handleChangeAddressUpd} />
        </label>
        <label>
          PIN :
          <input type="text" value={this.state.upd_pin} onChange={this.handleChangePinUpd}/>
        </label>
        <input type="submit" value="Update" />
      </form>

      <form onSubmit={this.delProperty}>
        <p>Delete a Property sale</p>
        <label>
          PIN :
          <input type="text" value={this.state.del_pin} onChange={this.handleChangePinDel}/>
        </label>
        <input type="submit" value="Delete" />
      </form>

      </div>
    );
  }
}
export default Admin;
