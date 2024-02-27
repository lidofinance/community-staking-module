import {
  BooleanType,
  ContainerType,
  UintBigintType,
  ByteVectorType,
} from "@chainsafe/ssz";

import JSON from "json-bigint";
const { parse } = JSON({
  useNativeBigInt: true,
});

const json = process.argv[2];
if (!json) {
  throw Error("no json provided");
}

const BLSPubkey = new ByteVectorType(48);
const UintNum64 = new UintBigintType(8);
const Bytes32 = new ByteVectorType(32);
const Boolean = new BooleanType();
const Epoch = UintNum64;

const Validator = new ContainerType(
  {
    pubkey: BLSPubkey,
    withdrawalCredentials: Bytes32,
    effectiveBalance: UintNum64,
    slashed: Boolean,
    activationEligibilityEpoch: Epoch,
    activationEpoch: Epoch,
    exitEpoch: Epoch,
    withdrawableEpoch: Epoch,
  },
  { typeName: "Validator", jsonCase: "eth2" },
);

const root = Validator.toView(Validator.fromJson(parse(json))).hashTreeRoot();

console.log("0x" + Buffer.from(root).toString("hex"));
