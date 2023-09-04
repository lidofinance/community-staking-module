import { expect } from "chai";
import { ethers } from "hardhat";
import { skipIfNoRpc } from "./common";

describe("Read Lido Locator", function () {
  before(function () {
    skipIfNoRpc.call(this);
  });

  const LIDO_LOCATOR_ADDRESS = "0xC1d0b3DE6792Bf6b4b37EccdcC24e45978Cfd2Eb";

  it("Should read lido locator on mainnet", async function () {
    const abi = [
      {
        inputs: [],
        name: "lido",
        outputs: [{ internalType: "address", name: "", type: "address" }],
        stateMutability: "view",
        type: "function",
      },
    ];
    const lidoLocator = new ethers.Contract(
      LIDO_LOCATOR_ADDRESS,
      abi,
      ethers.provider,
    );
    const lidoAddress = await lidoLocator.lido();
    expect(lidoAddress).to.equal("0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84");
  });
});
