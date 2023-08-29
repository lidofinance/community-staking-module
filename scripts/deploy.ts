import { ethers } from "hardhat";

async function main() {
  const counter = await ethers.deployContract("Counter");

  await counter.waitForDeployment();

  console.log(
    `Counter deployed to ${counter.target}`
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
