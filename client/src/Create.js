import React, { Component } from "react";
import "./App.css";


class Create extends Component {
  constructor(props) {
    super(props);
    this.state = { storageValue: null, web3: null, accounts: null,
      contract: null,PIN:null,
      add_address:null,
      add_pin:null,
      upd_address:null,
      upd_pin:null,
      del_pin:null,
      properties:[],

      c_client:null,
      c_owner:null,
      c_pin:null,
      c_amount:null,
      c_rates:null,
      c_length:null,

      mortgageValue:null,
      mlist:[],


      };
  }

 
  componentDidMount = async () => {
    this.checkProperties();
    this.checkMortgages();
    console.log(this.props.contract.ad)


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

  handleChangecclient = async(event)=> {
    this.setState({c_client: event.target.value});
  }

  handleChangecowner = async(event)=> {
    this.setState({c_owner: event.target.value});
  }

  handleChangecpin = async(event)=> {
    this.setState({c_pin: event.target.value});
  }
  
  handleChangecamount = async(event)=> {
    this.setState({c_amount: event.target.value});
  }

  handleChangecrates = async(event)=> {
    this.setState({c_rates: event.target.value});
  }

  handleChangeclength = async(event)=> {
    this.setState({c_length: event.target.value});
  }

  createTransaction = async(event)=>{
    event.preventDefault();
    const {accounts,mortgage} = this.props;
    await mortgage.methods.submitTransaction(accounts[0],this.state.c_client,this.state.c_owner,this.state.c_pin,this.state.c_amount,this.state.c_rates,this.state.c_length,this.props.contract_addr).send({from:accounts[0],value:this.state.c_amount*(10**18)})
    this.checkMortgages();
  }

  checkMortgages = async(event)=>{
    const {mortgage} = this.props;
    const count = await mortgage.methods.MortgageCount().call();
    this.setState({mortgageValue:count});
    const morts=[]
    for(var i=0;i<count;i++){
      const mapping = await mortgage.methods.mortgages(i).call();
      var mort ={
        mortgage: mapping,
        tid: i
      }
      morts.push(mort);
      console.log(morts[0]);
      console.log(morts[0].mortgage.bank);
    }
    this.setState({mlist:morts});
  }

  render() {
    if (!this.props.web3) {
      return <div>Loading Web3, accounts, and contract...</div>;
    }
    return (
      <div className="Home">
        <h1>Here the bank can create a mortgage transaction</h1>
        <p>List of registered properties
          <div><strong>Owner's address</strong> -- <strong>Property Identification Number ({this.state.storageValue})</strong></div>
          <div>
   {this.state.properties.map(txt => <p>{txt.property.owner} 
   -- {txt.pin}</p>)}</div></p>

   <p>List of Mortgages
          <div> Transaction Id-- <strong>Client's address</strong> -- <strong>Property Identification Number -- <strong>Amount</strong> -- <strong>Executed ?</strong>({this.state.mortgageValue})</strong></div>
          <div>
   {this.state.mlist.map(txt => <p>{txt.tid} -- {txt.mortgage.beneficiary} -- {txt.mortgage.pin} -- 
   {txt.mortgage.amount} -- {txt.mortgage.executed.toString()}</p>)}</div></p>

   <form onSubmit={this.createTransaction}>
        <p>Add a property on sale</p>
        <label>
          Client of the mortgage:
          <input type="text" value={this.state.c_client} onChange={this.handleChangecclient} />
        </label>
        <br></br>
        <label>
          Owner of the property :
          <input type="text" value={this.state.c_owner} onChange={this.handleChangecowner}/>
        </label>
        <br></br>
        <label>
          PIN :
          <input type="text" value={this.state.c_pin} onChange={this.handleChangecpin}/>
        </label>
        <br></br>
        <label>
          amount (in ether):
          <input type="text" value={this.state.c_amount} onChange={this.handleChangecamount}/>
        </label>
        <br></br>
        <label>
          rates :
          <input type="text" value={this.state.c_rates} onChange={this.handleChangecrates}/>
        </label>
        <br></br>
        <label>
          length :
          <input type="text" value={this.state.c_length} onChange={this.handleChangeclength}/>
        </label>
        <br></br>
        <input type="submit" value="submit" />
      </form>
   </div>
    );
  }
}
export default Create;