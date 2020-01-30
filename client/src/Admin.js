import React, { Component } from "react";
import "./App.css";


class Admin extends Component {
  constructor(props) {
    super(props);
    this.state = { storageValue: null, web3: null, accounts: null,
      contract: null,PIN:null,
      add_address:null,
      add_pin:null,
      upd_address:null,
      upd_pin:null,
      del_pin:null,
      properties:[]
      };

    this.handleChange = this.handleChange.bind(this);
    this.addProperty = this.addProperty.bind(this);
    this.updProperty = this.updProperty.bind(this);
    this.delProperty = this.delProperty.bind(this);
  }

  componentDidMount = async () => {
    const {contract} = this.props;
    this.checkProperties();
    contract.events.LogNewProperty({fromBlock:0},function(error,event)
    {console.log(event.returnValues._owner);})
    
    

  };

  checkProperties = async(event)=>{
    const {contract } = this.props;

    const response = await contract.methods.getPropertyCount().call();
    var propertylist=[];
    for(var i=0;i<response;i++){
      const index = await contract.methods.propertyList(i).call();
      const mapping = await contract.methods.properties(index).call();
      var properties = {
        property:mapping,
        pin:index
      }
      propertylist.push(properties);
    }
    console.log(propertylist)
    this.setState({properties:propertylist,storageValue: response});

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
    try{
    const resp = await contract.methods.updateProperty(this.state.upd_address,this.state.upd_pin).send({from:accounts[0]});
    alert('Property updated: ' + resp);
    this.checkProperties();
    } catch(e){
      console.log(e)
    }
    
  }

  handleChangePinDel= async(event)=> {
    this.setState({del_pin: event.target.value});
  }

  delProperty = async(event) => {
    event.preventDefault();
    const { accounts, contract } = this.props;
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
        <p>
          <div><strong>Owner's address</strong> -- <strong>Property Identification Number ({this.state.storageValue})</strong></div>
          <div>
   {this.state.properties.map(txt => <p>{txt.property.owner} -- {txt.pin}</p>)}
</div>
  
        </p>
        

      <form onSubmit={this.addProperty}>
        <p>Add Property </p>
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
      <br></br>
      <br></br>
      <form onSubmit={this.updProperty}>
        <p>Updated Property (only Owner) </p>
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
      <br></br>
      <br></br>

      <form onSubmit={this.delProperty}>
        <p>Delete Property (only Owner) </p>
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
