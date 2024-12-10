// The script can be used to find the gindicies required for CSVerifier deployment.

import { concatGindices } from "@chainsafe/persistent-merkle-tree";
import { ssz } from "@lodestar/types";

for (const fork of ["deneb", "electra"]) {
  /** @type ssz.deneb|ssz.electra */
  const Fork = ssz[fork];

  {
    const gI = pack(Fork.BeaconState.getPathInfo(["historicalSummaries"]).gindex, 0); // limit = 0 because `historicalSummaries` is a singular bytes32 value and not a list.
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

    const gI = pack(Fork.BeaconState.getPathInfo(["validators", 0]).gindex, Validators.limit);

    console.log(`${fork}::gIFirstValidator: `, toBytes32String(gI));
  }

  console.log();
}

// Analog of the GIndex.pack (lib used in CSVerifier)
// @param {bigint} gI
// @param {number} limit
// @return {bigint}
function pack(gI, limit) {
  const width = limit ? BigInt(Math.log2(limit)) : 0n;
  return (gI << 8n) | width;
}

// Return hex-encoded representation of GIndex
// @param {bigint} gI
// @return {string}
function toBytes32String(gI) {
  return `0x${gI.toString(16).padStart(64, "0")}`;
}
