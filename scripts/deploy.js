const hre = require("hardhat");
const ethers = hre.ethers;

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log(
    "Deploying contracts with the account:",
    deployer.address
  );
  
  console.log("Account balance:", (await deployer.getBalance()).toString());

  const Contract = await ethers.getContractFactory("Splitter");

  // Generate new random accounts
  let randomWallet1 = ethers.Wallet.createRandom();
  let randomWallet2 = ethers.Wallet.createRandom();
  
  // Use the address of the random accounts as payees
  let payees = [randomWallet1.address, randomWallet2.address];
  let guardians = [randomWallet1.address, randomWallet2.address,'0x0000000000000000000000000000000000000000'];
  let shares = [50, 50];
  
  const contract = await Contract.deploy(payees, shares,guardians);

  await contract.deployed();

  console.log("Contract deployed to:", contract.address);
  console.log(`Payee 1 address (Randomly generated): ${randomWallet1.address}`);
  console.log(`Payee 2 address (Randomly generated): ${randomWallet2.address}`);
 
 
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
