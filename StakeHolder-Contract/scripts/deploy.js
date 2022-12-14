const { ethers } = require("hardhat");

async function deploy() {
  const [deployer] = await ethers.getSigners();

  console.log("Deploying contracts with the account:", deployer.address);

  console.log("Account Balance:", (await deployer.getBalance()).toString());

  const StakeHolder = await ethers.getContractFactory("StakeHolder");

  const deployedStakeHolderContract = await StakeHolder.deploy();

  const transactionReceipt =
    deployedStakeHolderContract.deployTransaction.wait();

  console.log(
    "Successfully deployed StakeHolder at:",
    deployedStakeHolderContract.address
  );
  console.log(await transactionReceipt);
}
module.exports.default = deploy;
deploy()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
