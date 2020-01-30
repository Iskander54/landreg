import React, { Component } from "react";
import "./App.css";


class Validate extends Component {
  constructor(props) {
    super(props);
    this.state = { storageValue: null, web3: null, accounts: null,
      contract: null,

      mortgageValue:null,
      mlist:[],

      isparty:[],
      confirmed:[],

      confirmtid:null,
      revoketid:null

      };
  }

  componentDidMount = async () => {
    const {accounts} = this.props;
    await this.checkMortgages();
    const _confirmed=[]
    const _isparty=[]
    console.log("who's logged :" ,accounts[0])
    for(var i=0;i<this.state.mlist.length;i++){
      if(await this.hasConfirmed(this.state.mlist[i].tid,accounts[0])){
        _confirmed.push(this.state.mlist[i])
      } else if(await this.isParty(this.state.mlist[i].tid,accounts[0])){
        _isparty.push(this.state.mlist[i])
      }
      this.setState({isparty:_isparty,confirmed:_confirmed})
      console.log("length of confirmed ",this.state.confirmed.length," length of isparty ",this.state.isparty.length)
    } 
    
  };

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
    }
    this.setState({mlist:morts});
    console.log("mortgages ",this.state.mlist);
  }


  isParty = async(tid,account)=>{
    const {mortgage} = this.props;
    const resp = await mortgage.methods.isParty(tid,account).call();
    return resp
  }

  hasConfirmed = async(tid,account)=>{
    const {mortgage} = this.props;
    const resp = await mortgage.methods.confirmations(tid,account).call();
    return resp
  }

  confirmTx = async(event) =>{
    event.preventDefault();
    const {accounts,mortgage} =this.props;
    console.log(this.state.confirmtid);
    console.log(accounts[0])
    await mortgage.methods.confirmTransaction(this.state.confirmtid,this.props.contract_addr).send({from:accounts[0]})
    window.location.reload();
  }

  revokeTransaction = async(event) =>{
    event.preventDefault();
    const {accounts,mortgage} =this.props;
    await mortgage.methods.revokeConfirmation(this.state.revoketid).send({from:accounts[0]})
    window.location.reload();
  }

  handleChangeconfirmtid = async(event) =>{
    this.setState({confirmtid:event.target.value})
  }

  handleChangerevoketid = async(event) =>{
    this.setState({revoketid:event.target.value})
  }



  render(){
      return(
        <div className="Validate">
      <h1>Validate</h1>
      <div>
      <p>List of Mortgages your are involved
          <div> Transaction Id-- <strong>Client's address</strong> -- <strong>Property Identification Number -- <strong>Amount</strong> -- <strong>Executed ?</strong>({this.state.isparty.length})</strong></div>
          <div>{this.state.tidlist}
   {this.state.isparty.map(txt =>  <p>{txt.tid} -- {txt.mortgage.beneficiary} -- {txt.mortgage.pin} -- {txt.mortgage.amount} -- {txt.mortgage.executed.toString()}</p>)}</div></p>
      
            <form onSubmit={this.confirmTx}>
            <p>Validate</p>
            <label>
              Transaction Id:
              <input type="text" value={this.state.confirmtid} onChange={this.handleChangeconfirmtid}/>
            </label>
            <input type="submit" value="confirm" />
          </form>
          </div>
          <div>
          <p>List of Mortgages your confirmed
          <div> Transaction Id-- <strong>Client's address</strong> -- <strong>Property Identification Number -- <strong>Amount</strong> -- <strong>Executed ?</strong>({this.state.confirmed.length})</strong></div>
          <div>{this.state.tidlist}
   {this.state.confirmed.map(txt =>  <p style={{color: txt.mortgage.executed === true ?  "green" : "red"  }}>{txt.tid} -- {txt.mortgage.beneficiary} -- {txt.mortgage.pin} -- {txt.mortgage.amount} -- <strong>{txt.mortgage.executed.toString()}</strong></p>)}</div></p>
      
            <form onSubmit={this.revokeTransaction}>
            <p>Validate</p>
            <label>
              Transaction Id:
              <input type="text" value={this.state.revoketid} onChange={this.handleChangerevoketid}/>
            </label>
            <input type="submit" value="revoke" />
          </form>
          </div>
          </div>
      )

  }
}
export default Validate;