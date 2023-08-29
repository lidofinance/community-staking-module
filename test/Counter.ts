import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("Lock", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployCounter() {
    // Contracts are deployed using the first signer/account by default
    const [owner] = await ethers.getSigners();

    const Counter = await ethers.getContractFactory("Counter");
    const counter = await Counter.deploy();

    return { counter, owner };
  }

  describe("Deployment", function () {
    it("Should get the right number", async function () {
      const { counter, owner } = await loadFixture(deployCounter);

      await counter.increment();
      expect(await counter.number()).to.equal(1);
    });
  });
});
