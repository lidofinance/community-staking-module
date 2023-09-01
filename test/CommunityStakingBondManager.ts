import { ethers } from "hardhat";
import { expect } from "chai";

import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import {
  StETHMock,
  LidoLocatorMock,
  CommunityStakingModuleMock,
  CommunityStakingFeeDistributorMock,
} from "../typechain-types/src/test_helpers";
import { CommunityStakingBondManager } from "../typechain-types";

describe("CommunityStakingBondManager", async () => {
  async function deployBondManager() {
    const [stranger, alice] = await ethers.getSigners();

    const burner = ethers.Wallet.createRandom();
    const csm = (await ethers.deployContract(
      "CommunityStakingModuleMock",
      [],
    )) as CommunityStakingModuleMock;
    const stETH = (await ethers.deployContract("StETHMock", [
      8013386371917025835991984n,
    ])) as StETHMock;
    await stETH.mintShares(stETH.target, 7059313073779349112833523n);
    const lidoLocator = (await ethers.deployContract("LidoLocatorMock", [
      stETH,
      burner,
    ])) as LidoLocatorMock;
    const feeDistributor = (await ethers.deployContract(
      "CommunityStakingFeeDistributorMock",
      [lidoLocator.target],
    )) as CommunityStakingFeeDistributorMock;
    const bondManager = (await ethers.deployContract(
      "CommunityStakingBondManager",
      [
        BigInt(2 * 10 ** 18),
        alice,
        lidoLocator.target,
        csm.target,
        feeDistributor.target,
        [alice],
      ],
    )) as CommunityStakingBondManager;
    await feeDistributor.setBondManager(bondManager.target);

    return { stranger, alice, stETH, bondManager, csm, feeDistributor, burner };
  }

  it("should return totalBondShares", async () => {
    const { stETH, bondManager } = await loadFixture(deployBondManager);
    await stETH.mintShares(bondManager.target, BigInt(32 * 10 ** 18));

    expect(await bondManager.totalBondShares()).to.equal(BigInt(32 * 10 ** 18));
  });

  it("should return totalBondEth", async () => {
    const { stETH, bondManager } = await loadFixture(deployBondManager);
    await stETH.mintShares(bondManager.target, BigInt(32 * 10 ** 18));

    expect(await bondManager.totalBondEth()).to.equal(36324667688196920249n);
  });

  it("should make deposit", async () => {
    const { stranger, stETH, bondManager } =
      await loadFixture(deployBondManager);
    await stETH.mintShares(stranger, BigInt(32 * 10 ** 18));

    const tx = await bondManager
      .connect(stranger)
      .deposit(0, BigInt(32 * 10 ** 18));

    expect(tx)
      .to.emit(bondManager, "BondDeposited")
      .withArgs(0, stranger.address, BigInt(32 * 10 ** 18));
    expect(await bondManager.getBondShares(0)).to.equal(BigInt(32 * 10 ** 18));
  });

  it("should return bond eth", async () => {
    const { stranger, stETH, bondManager } =
      await loadFixture(deployBondManager);
    await stETH.mintShares(stranger, BigInt(32 * 10 ** 18));

    await bondManager.connect(stranger).deposit(0, BigInt(32 * 10 ** 18));

    expect(await bondManager.getBondEth(0)).to.equal(36324667688196920249n);
  });

  it("should return required bond eth when no withdrawn", async () => {
    const { alice, bondManager, csm } = await loadFixture(deployBondManager);
    await csm.setNodeOperator(0, true, "Alice", alice, 16, 0, 0, 16, 16);

    expect(await bondManager.getRequiredBondEth(0)).to.equal(
      BigInt(32 * 10 ** 18),
    );
  });

  it("should return required bond eth when one withdrawn", async () => {
    const { alice, bondManager, csm } = await loadFixture(deployBondManager);
    await csm.setNodeOperator(0, true, "Alice", alice, 16, 0, 1, 16, 16);

    expect(await bondManager.getRequiredBondEth(0)).to.equal(
      BigInt(30 * 10 ** 18),
    );
  });

  it("should claim rewards", async () => {
    const { stranger, stETH, bondManager, csm, feeDistributor } =
      await loadFixture(deployBondManager);
    await stETH._submit(stranger, BigInt(32 * 10 ** 18));

    const sharesAfterSubmit = await stETH.sharesOf(stranger);
    await bondManager.connect(stranger).deposit(0, sharesAfterSubmit);

    await csm.setNodeOperator(0, true, "Stranger", stranger, 16, 0, 0, 16, 16);

    const sharesAsFee = await stETH.getSharesByPooledEth(
      BigInt(0.1 * 10 ** 18),
    );
    await stETH._submit(feeDistributor.target, BigInt(0.1 * 10 ** 18));

    const bondSharesBefore = await bondManager.getBondShares(0);
    const sharesToClaim = BigInt(0.05 * 10 ** 18);
    await bondManager
      .connect(stranger)
      .claimRewards([], 0, sharesAsFee, sharesToClaim);

    expect(await stETH.sharesOf(stranger)).to.be.equal(sharesToClaim);
    expect(await bondManager.getBondShares(0)).to.be.equal(
      bondSharesBefore + sharesAsFee - sharesToClaim,
    );
  });

  it("should claim rewards when amout to claim is hither than rewards", async () => {
    const { stranger, stETH, bondManager, csm, feeDistributor } =
      await loadFixture(deployBondManager);
    await stETH._submit(stranger, BigInt(32 * 10 ** 18));

    const sharesAfterSubmit = await stETH.sharesOf(stranger);
    await bondManager.connect(stranger).deposit(0, sharesAfterSubmit);

    await csm.setNodeOperator(0, true, "Stranger", stranger, 16, 0, 0, 16, 16);

    const sharesAsFee = await stETH.getSharesByPooledEth(
      BigInt(0.1 * 10 ** 18),
    );
    await stETH._submit(feeDistributor.target, BigInt(0.1 * 10 ** 18));

    const requiredBondShares = await bondManager.getRequiredBondShares(0);
    const tx = await bondManager
      .connect(stranger)
      .claimRewards([], 0, sharesAsFee, BigInt(100 * 10 ** 18));
    const bondSharesAfter = await bondManager.getBondShares(0);

    expect(tx)
      .to.emit(bondManager, "RewardsClaimed")
      .withArgs(0, stranger.address, sharesAsFee);
    expect(await stETH.sharesOf(stranger)).to.be.equal(sharesAsFee);
    expect(bondSharesAfter).to.be.equal(requiredBondShares);
  });

  it("should revert claim rewards when caller is not reward address", async () => {
    const { stranger, alice, stETH, bondManager, csm, feeDistributor } =
      await loadFixture(deployBondManager);
    await stETH._submit(stranger, BigInt(32 * 10 ** 18));

    const sharesAfterSubmit = await stETH.sharesOf(stranger);
    await bondManager.connect(stranger).deposit(0, sharesAfterSubmit);

    await csm.setNodeOperator(0, true, "Stranger", stranger, 16, 0, 0, 16, 16);

    const sharesAsFee = await stETH.getSharesByPooledEth(
      BigInt(0.1 * 10 ** 18),
    );
    await stETH._submit(feeDistributor.target, BigInt(0.1 * 10 ** 18));
    await expect(
      bondManager
        .connect(alice)
        .claimRewards([], 0, sharesAsFee, BigInt(100 * 10 ** 18)),
    ).to.be.revertedWith("only reward address can claim rewards");
  });

  it("should penalize with value less than deposit", async () => {
    const { stranger, alice, stETH, bondManager, burner } =
      await loadFixture(deployBondManager);
    await stETH.mintShares(stranger, BigInt(32 * 10 ** 18));

    await bondManager.connect(stranger).deposit(0, BigInt(32 * 10 ** 18));

    const tx = await bondManager
      .connect(alice)
      .penalize(0, BigInt(1 * 10 ** 18));

    expect(tx)
      .to.emit(bondManager, "BondPenalized")
      .withArgs(0, BigInt(1 * 10 ** 18), BigInt(1 * 10 ** 18));
    expect(await bondManager.getBondShares(0)).to.equal(BigInt(31 * 10 ** 18));
    expect(await stETH.sharesOf(burner)).to.equal(BigInt(1 * 10 ** 18));
  });

  it("should penalize with value more than deposit", async () => {
    const { stranger, alice, stETH, bondManager, burner } =
      await loadFixture(deployBondManager);
    await stETH.mintShares(stranger, BigInt(32 * 10 ** 18));

    await bondManager.connect(stranger).deposit(0, BigInt(32 * 10 ** 18));

    const tx = await bondManager
      .connect(alice)
      .penalize(0, BigInt(33 * 10 ** 18));

    expect(tx)
      .to.emit(bondManager, "BondPenalized")
      .withArgs(0, BigInt(33 * 10 ** 18), BigInt(32 * 10 ** 18));
    expect(await bondManager.getBondShares(0)).to.equal(BigInt(0));
    expect(await stETH.sharesOf(burner)).to.equal(BigInt(32 * 10 ** 18));
  });

  it("should penalize with value eq to deposit", async () => {
    const { stranger, alice, stETH, bondManager, burner } =
      await loadFixture(deployBondManager);
    await stETH.mintShares(stranger, BigInt(32 * 10 ** 18));

    await bondManager.connect(stranger).deposit(0, BigInt(32 * 10 ** 18));

    const tx = await bondManager
      .connect(alice)
      .penalize(0, BigInt(32 * 10 ** 18));

    expect(tx)
      .to.emit(bondManager, "BondPenalized")
      .withArgs(0, BigInt(32 * 10 ** 18), BigInt(32 * 10 ** 18));
    expect(await bondManager.getBondShares(0)).to.equal(BigInt(0));
    expect(await stETH.sharesOf(burner)).to.equal(BigInt(32 * 10 ** 18));
  });

  it("should revert penalize when caller has no role", async () => {
    const { stranger, alice, stETH, bondManager } =
      await loadFixture(deployBondManager);
    await stETH.mintShares(alice, BigInt(32 * 10 ** 18));

    await bondManager.connect(alice).deposit(0, BigInt(32 * 10 ** 18));

    await expect(
      bondManager.connect(stranger).penalize(0, BigInt(1 * 10 ** 18)),
    ).to.be.revertedWith(
      `AccessControl: account ${stranger.address.toLowerCase()} is missing role 0xf3c54f9b8dbd8c6d8596d09d52b61d4bdce01620000dd9d49c5017dca6e62158`,
    );
  });
});
