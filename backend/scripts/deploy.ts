import { ethers } from "hardhat";

async function main() {
  console.log("Deploying ConnectFour contract to Lisk Sepolia...");

  // Get the deployer
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);

  // Check balance
  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("Account balance:", ethers.formatEther(balance), "ETH");

  if (balance < ethers.parseEther("0.01")) {
    throw new Error(
      "Insufficient balance. Need at least 0.01 ETH for deployment"
    );
  }

  // Get the contract factory
  const ConnectFour = await ethers.getContractFactory("ConnectFour");

  // Deploy the contract
  console.log("Deploying contract...");
  const connectFour = await ConnectFour.deploy();

  // Wait for deployment
  await connectFour.waitForDeployment();

  const contractAddress = await connectFour.getAddress();
  console.log("✅ ConnectFour deployed to:", contractAddress);

  // Wait for a few confirmations
  console.log("Waiting for confirmations...");
  await connectFour.deploymentTransaction()?.wait(3);

  console.log("Contract deployment confirmed!");
  console.log(
    "View on explorer:",
    `https://sepolia-blockscout.lisk.com/address/${contractAddress}`
  );

  // Save deployment info
  const deploymentInfo = {
    contractAddress: contractAddress,
    network: "liskSepolia",
    deployer: deployer.address,
    deploymentTime: new Date().toISOString(),
    txHash: connectFour.deploymentTransaction()?.hash,
  };

  console.log("\nDeployment Info:", JSON.stringify(deploymentInfo, null, 2));
}

// Handle errors
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Deployment failed:", error);
    process.exit(1);
  });
