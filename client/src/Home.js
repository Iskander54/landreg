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
  }

  componentDidMount = async () => {
    this.checkProperties();


  };

  runExample = async () => {
    this.checkProperties();
  };

  checkProperties = async(event)=>{
    const {contract } = this.props;

    const response = await contract.methods.getPropertyCount().call();
    this.setState({ form: response });
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

  render() {
    if (!this.props.web3) {
      return <div>Loading Web3, accounts, and contract...</div>;
    }
    return (
      <div className="Home">
        <h1>Welcome to Land Registry Blockchain</h1>
        <h2>This dApp allows you to deal with your land registry based on smart contracts</h2>
        <p>List of registered properties
          <div><strong>Owner's address</strong> -- <strong>Property Identification Number ({this.state.storageValue})</strong></div>
          <div>
   {this.state.properties.map(txt => <p>{txt.owner} -- {this.state.PIN[txt.listPointer]}</p>)}</div></p>
   </div>
    );
  }
}

export default Home;
