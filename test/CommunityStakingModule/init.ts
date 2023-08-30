import { loadFixture } from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("CommunityStakingModule init", function () {
  const moduleType = "community-staking-module";
  async function deployCsm() {
    const [owner] = await ethers.getSigners();

    const Csm = await ethers.getContractFactory("CommunityStakingModule");
    const csm = await Csm.deploy(ethers.encodeBytes32String(moduleType));

    return { csm, owner };
  }

  it("Should init values", async function () {
    const { csm, owner } = await loadFixture(deployCsm);
    expect(await csm.getType()).to.equal(
      ethers.encodeBytes32String(moduleType),
    );
    expect(await csm.getNodeOperatorsCount()).to.equal(0);
  });
});
