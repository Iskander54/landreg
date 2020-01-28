import React, { Component } from "react";
import Registry from "./contracts/Registry.json";
import getWeb3 from "./getWeb3";
import {
  BrowserRouter as Router,
  Switch,
  Route,
  Link
} from "react-router-dom";
import Admin from "./Admin"
import App from "./App"
import "./App.css";


class Mortgage extends Component {
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
      <h1>Mortgage stuff</h1>
      )
  }
}
export default Mortgage;