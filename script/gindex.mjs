// The script can be used to find the gindicies required for CSVerifier deployment.

import { concatGindices } from "@chainsafe/persistent-merkle-tree";
import { ssz } from "@lodestar/types";

for (const fork of ["capella", "deneb"]) {
  /** @type (ssz.capella|ssz.deneb) */
  const Fork = ssz[fork];

  {
    const gI = pack(Fork.BeaconState.getPathInfo(["historicalSummaries"]).gindex, 0); // 0 because `historicalSummaries` is a bytes32 value.
    console.log(`${fork}::gIHistoricalSummaries: `, toBytes32String(gI));
  }

  {
    const Withdrawals = Fork.BeaconBlock.getPathInfo([
      "body",
      "executionPayload",
      "withdrawals",
    ]).type;

    const gI = pack(
      concatGindices([
        Fork.BeaconState.getPathInfo(["latestExecutionPayloadHeader", "withdrawalsRoot"]).gindex,
        Withdrawals.getPropertyGindex(0),
      ]),
      Withdrawals.limit,
    );

    console.log(`${fork}::gIFirstWithdrawal:`, toBytes32String(gI));
  }

  {
    const Validators = Fork.BeaconState.getPathInfo(["validators"]).type;

    // prettier-ignore
    const gI = pack(
    Fork.BeaconState.getPathInfo(["validators", 0]).gindex,
    Validators.limit
  );

    console.log(`${fork}::gIFirstValidator: `, toBytes32String(gI));
  }

  console.log();
}

// Analog of the GIndex.pack.
// @param {bigint} gI
// @param {number} limit
// @return {bigint}
function pack(gI, limit) {
  const width = limit ? BigInt(Math.log2(limit)) : 0n;
  return (gI << 8n) | width;
}

// Return hex-encoded representation of GIndex
// @param {number} limit
// @return {bigint}
function toBytes32String(gI) {
  return `0x${gI.toString(16).padStart(64, "0")}`;
}
