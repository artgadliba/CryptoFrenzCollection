async function main() {
  // We get the contract to deploy
  const CryptoFrenzCollection = await ethers.getContractFactory("CryptoFrenzCollection");
  const cfz = await CryptoFrenzCollection.deploy("CryptoFrenzCollection", "CFZ", "https://gateway.pinata.cloud/ipfs/QmfMyFZndk3ZjKXXv7zBDrogYjowKpPr7262aG1RG8zwpU/Token_ID_");

  await cfz.deployed();

  console.log("CryptoFrenzCollection deployed to:", cfz.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
