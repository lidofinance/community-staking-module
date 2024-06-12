// The script can be used to find the gindicies required for CSVerifier deployment.

import { concatGindices } from "@chainsafe/persistent-merkle-tree";
import { ssz } from "@lodestar/types";

const BeaconState = ssz.deneb.BeaconState;
const BeaconBlock = ssz.deneb.BeaconBlock;

{
  const Withdrawals = BeaconBlock.getPathInfo(["body", "executionPayload", "withdrawals"]).type;

  const gI = pack(
    concatGindices([
      BeaconState.getPathInfo(["latestExecutionPayloadHeader", "withdrawalsRoot"]).gindex,
      Withdrawals.getPropertyGindex(0),
    ]),
    Withdrawals.limit,
  );

  console.log("gIFirstWithdrawal:", toBytes32String(gI));
}

{
  const Validators = BeaconState.getPathInfo(["validators"]).type;

  // prettier-ignore
  const gI = pack(
    BeaconState.getPathInfo(["validators", 0]).gindex,
    Validators.limit
  );

  console.log("gIFirstValidator: ", toBytes32String(gI));
}

{
  const gI = pack(BeaconState.getPathInfo(["historicalSummaries"]).gindex, 0); // 0 because `historicalSummaries` is a bytes32 value.
  console.log("gIHistoricalSummaries: ", toBytes32String(gI));
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
