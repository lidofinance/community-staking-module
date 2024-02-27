import { ContainerType, UintBigintType, ByteVectorType } from "@chainsafe/ssz";

import JSON from "json-bigint";
const { parse } = JSON({
  useNativeBigInt: true,
});

const json = process.argv[2];
if (!json) {
  throw Error("no json provided");
}

const UintNum64 = new UintBigintType(8);
const Bytes20 = new ByteVectorType(20);

const Withdrawal = new ContainerType(
  {
    index: UintNum64,
    validatorIndex: UintNum64,
    address: Bytes20,
    amount: UintNum64,
  },
  { typeName: "Withdrawal", jsonCase: "eth2" },
);

const root = Withdrawal.toView(Withdrawal.fromJson(parse(json))).hashTreeRoot();

console.log("0x" + Buffer.from(root).toString("hex"));
