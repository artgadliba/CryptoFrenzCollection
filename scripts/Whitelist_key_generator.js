// @dev Generator used once to provide random private key and signer

const { privateToAddress } = require("ethereumjs-utils");
const { ethers } = require("ethers");
const crypto = require("crypto");

const pvtKey = crypto.randomBytes(32);
const pvtKeyString = pvtKey.toString("hex");
const signerAddress = ethers.utils.getAddress(

privateToAddress(pvtKey).toString("hex"));
