import { concatGindices } from "@chainsafe/persistent-merkle-tree";
import { ssz } from "@lodestar/types";

const BeaconState = ssz.deneb.BeaconState;
const BeaconBlock = ssz.deneb.BeaconBlock;

{
  const Withdrawals = BeaconBlock.getPathInfo(["body", "executionPayload", "withdrawals"]).type;
  const nav = BeaconState.getPathInfo(["latestExecutionPayloadHeader", "withdrawalsRoot"]);

  const gI =
    (concatGindices([nav.gindex, Withdrawals.getPropertyGindex(0)]) << 8n) |
    BigInt(Math.log2(Withdrawals.limit));

  console.log(
    "BeaconState.latest_execution_payload_header.withdrawals[0]:",
    `0x${gI.toString(16)}`,
  );
}

{
  const gI =
    (BeaconState.getPathInfo(["validators", 0]).gindex << 8n) |
    BigInt(Math.log2(BeaconState.getPathInfo(["validators"]).type.limit));

  console.log("BeaconState.validators[0]`: ", `0x${gI.toString(16)}`);
}

{
  const nav = BeaconState.getPathInfo(["historicalSummaries"]);
  const gI = (nav.gindex << 8n) | 0n; // 0 because `historicalSummaries` is a bytes32 value.
  console.log("BeaconState.historical_summaries`: ", `0x${gI.toString(16)}`);
}
