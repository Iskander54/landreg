import React, { Component } from "react";
import "./App.css";


class Validate extends Component {
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

  render(){
      return(
      <h1>Validate</h1>
      )
  }
}
export default Validate;