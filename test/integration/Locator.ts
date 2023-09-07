import { expect } from "chai";
import { ethers } from "hardhat";
import { skipIfNoRpc } from "./common";

describe("Read Lido Locator", function () {
  before(function () {
    skipIfNoRpc.call(this);
  });

  const LIDO_LOCATOR_ADDRESS = "0xC1d0b3DE6792Bf6b4b37EccdcC24e45978Cfd2Eb";

  it("Should read lido locator on mainnet", async function () {
    const lidoLocator = await ethers.getContractAt(
      "ILidoLocator",
      LIDO_LOCATOR_ADDRESS,
    );
    const lidoAddress = await lidoLocator.lido();
    expect(lidoAddress).to.equal("0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84");
  });
});
