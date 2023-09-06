import { expect } from "chai";
import { ethers } from "hardhat";
import { skipIfNoRpc } from "./common";

describe("Add staking module", function () {
  const LIDO_LOCATOR_ADDRESS = "0xC1d0b3DE6792Bf6b4b37EccdcC24e45978Cfd2Eb";

  before(async function () {
    skipIfNoRpc.call(this);
  });

  it("should handle add module", async () => {
    const [alice] = await ethers.getSigners();

    const csm = await ethers.deployContract("CommunityStakingModule", [
      ethers.encodeBytes32String("community-staking-module"),
    ]);
    const lidoLocator = await ethers.getContractAt(
      "ILidoLocator",
      LIDO_LOCATOR_ADDRESS,
    );
    const stakingRouterAddress = await lidoLocator.stakingRouter();
    const stakingRouter = await ethers.getContractAt(
      "IStakingRouter",
      stakingRouterAddress,
    );

    const adminAddress = await stakingRouter.getRoleMember(
      await stakingRouter.DEFAULT_ADMIN_ROLE(),
      0,
    );

    await alice.sendTransaction({
      to: adminAddress,
      value: ethers.parseEther("1"),
    });
    const srAdmin = await ethers.getImpersonatedSigner(adminAddress);

    await stakingRouter
      .connect(srAdmin)
      .grantRole(await stakingRouter.STAKING_MODULE_MANAGE_ROLE(), alice);

    const tx = await stakingRouter
      .connect(alice)
      .addStakingModule("community-onchain-v1", csm.target, 10_000, 500, 500);

    const blockTimestamp = (await ethers.provider.getBlock(tx.blockNumber))
      ?.timestamp as number;

    const modules = (await stakingRouter.getStakingModules()).map((m: any) =>
      Array.from(m),
    );

    expect(modules).to.deep.include([
      2n,
      csm.target,
      500n,
      500n,
      10000n,
      0n,
      "community-onchain-v1",
      BigInt(blockTimestamp),
      BigInt(tx.blockNumber),
      0n,
    ]);
  });
});
