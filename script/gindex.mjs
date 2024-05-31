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

  console.log(
    "BeaconState.latest_execution_payload_header.withdrawals[0]:",
    `0x${gI.toString(16)}`,
  );
}

{
  const Validators = BeaconState.getPathInfo(["validators"]).type;

  // prettier-ignore
  const gI = pack(
    BeaconState.getPathInfo(["validators", 0]).gindex,
    Validators.limit
  );

  console.log("BeaconState.validators[0]`: ", `0x${gI.toString(16)}`);
}

{
  const gI = pack(BeaconState.getPathInfo(["historicalSummaries"]).gindex, 0); // 0 because `historicalSummaries` is a bytes32 value.
  console.log("BeaconState.historical_summaries`: ", `0x${gI.toString(16)}`);
}

// Analog of the GIndex.pack.
// @param {bigint} gI
// @param {number} limit
// @return {bigint}
function pack(gI, limit) {
  const width = limit ? BigInt(Math.log2(limit)) : 0n;
  return (gI << 8n) | width;
}
