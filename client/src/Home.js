import React, { Component } from "react";
import "./App.css";



class Home extends Component {
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

    this.addProperty = this.addProperty.bind(this);
    this.updProperty = this.updProperty.bind(this);
    this.delProperty = this.delProperty.bind(this);
  }

  componentDidMount = async () => {
    this.checkProperties();


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
    if (!this.props.web3) {
      return <div>Loading Web3, accounts, and contract...</div>;
    }
    return (
      <div className="Home">
        <h1>Welcome to Land Registry Blockchain</h1>
        <h2>This dApp allows you to deal with you land registry based on smart contracts</h2>
        <p>List of registered properties
          <div><strong>Owner's address</strong> -- <strong>Property Identification Number ({this.state.storageValue})</strong></div>
          <div>
   {this.state.properties.map(txt => <p>{txt.owner} -- {this.state.PIN[txt.listPointer]}</p>)}</div></p>
   </div>
    );
  }
}

export default Home;
