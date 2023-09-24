const { expect } = require("chai");
const hre = require("hardhat");
const ethers = hre.ethers;
// Account 1 0x11E212FF10C7982c7Bb30ceaf60a18ADb392Fc7c
// Account 2 0xaFcA0a696A8490022fD4F973EBD88014D16Ea420
//   
async function main() {
    const [deployer] = await ethers.getSigners();
  
    console.log(
      "Deploying contracts with the account:",
      deployer.address
    );
    
    console.log("Account balance:", (await deployer.getBalance()).toString());
  
    const Contract = await ethers.getContractFactory("Splitter");
  
    const addressUser1 = '0x11E212FF10C7982c7Bb30ceaf60a18ADb392Fc7c';
    const addressUser2 = '0xaFcA0a696A8490022fD4F973EBD88014D16Ea420';
    let payees = [addressUser1, addressUser2];
    let guardians = [addressUser1, addressUser2,'0x0000000000000000000000000000000000000000'];
    let shares = [5, 5];
    const valueToSend = ethers.utils.parseEther("0.001")
    const contract = await Contract.deploy(payees, shares,guardians, { value: valueToSend });
    //
    await contract.deployed();
  
    console.log("Contract deployed to:", contract.address);
    console.log(`Payee 1 address (Randomly generated): ${addressUser1}`);
    console.log(`Payee 2 address (Randomly generated): ${addressUser2}`);

    const privateKeyUser1 = '0xb7f42db11a0c4b8c9d112ae849f9f996c61fe80df3891e2536b9e2fc62d9272c';
    const walletUser1 = new ethers.Wallet(privateKeyUser1, ethers.provider);
    
    const contractWithUser1 = contract.connect(walletUser1);
    
    try{
        await contractWithUser1.release(addressUser2);
    
        console.log("Good news as the guardians didn't gave his word the transaction doesnt work");
    }
    catch{
        console.log('Good news only the owner of the funds can release his funds')
    }
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });