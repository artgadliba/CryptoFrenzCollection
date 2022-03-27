const ethers = require('ethers');
const allowlistedAddresses = require('./whitelisted_addresses.js').whitelistedAddresses;

require('dotenv').config();

const signerAddress = process.env.SIGNER_ADDRESS;
const signerPvtKeyString = process.env.PRIVATE_KEY;

const signer = new ethers.Wallet(signerPvtKeyString);

// Get first allowlisted address
for ( let i = 0; i < allowlistedAddresses.length; i++) {
  let message = allowlistedAddresses[i];
  // Compute hash of the address
  let messageHash = ethers.utils.solidityKeccak256(["address"],[message]);
  // Sign the hashed address
  let messageBytes = ethers.utils.arrayify(messageHash);
  let signature = signer.signMessage(messageBytes);

  const whitelist_dict = {};

  whitelist_dict[allowlistedAddresses[i]] = signature;
  console.log(whitelist_dict);

}
