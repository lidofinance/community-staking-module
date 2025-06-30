import fs from "fs";
import { ssz } from "@lodestar/types";
import { concatGindices, createProof, ProofType } from "@chainsafe/persistent-merkle-tree";

// main({
//   validatorIndex: 673610,
//   withdrawalOffset: 1,
//   amount: 31997502795n,
//   address: "b3e29c46ee1745724417c0c51eb2351a1c01cf36",
//   slashed: false,
//   activationEligibilityEpoch: 21860,
//   activationEpoch: 21866,
//   exitEpoch: 41672,
//   withdrawableEpoch: 41928,
// }).catch();

main(
  {
    validatorIndex: 673610,
    withdrawalOffset: 1,
    amount: 31997502795n,
    address: "b3e29c46ee1745724417c0c51eb2351a1c01cf36",
    slashed: false,
    activationEligibilityEpoch: 21860,
    activationEpoch: 21866,
    exitEpoch: 28736,
    withdrawableEpoch: 28961,
  },
  ssz.deneb,
  ssz.electra,
).catch();

/**
 * @param {Object} opts
 * @param {number} opts.validatorIndex
 * @param {number} opts.withdrawalOffset
 * @param {bigint} opts.amount
 * @param {string} opts.address
 * @param {boolean} opts.slashed
 * @param {number} opts.activationEligibilityEpoch,
 * @param {number} opts.activationEpoch,
 * @param {number} opts.exitEpoch,
 * @param {number} opts.withdrawableEpoch,
 */
async function main(opts, PrevFork = ssz.electra, NextFork = ssz.electra) {
  const Withdrawal = PrevFork.BeaconBlock.getPathInfo([
    "body",
    "executionPayload",
    "withdrawals",
    0,
  ]).type;
  const Validator = PrevFork.BeaconState.getPathInfo(["validators", 0]).type;

  // http -d $CL_URL/eth/v2/debug/beacon/states/finalized Accept:application/octet-stream
  // Phase 0. Think of it as of a seed value for our fixture.

  const r = await readBinaryState("finalized.bin");
  const state = PrevFork.BeaconState.deserializeToView(r);

  // Phase 1. Pathching a validator.

  const validator = state.validators.get(opts.validatorIndex);
  validator.slashed = opts.slashed;
  validator.withdrawalCredentials = new Uint8Array([
    ...new Uint8Array([0x01]),
    ...new Uint8Array(11), // gap
    ...fromHex(opts.address),
  ]);
  validator.activationEligibilityEpoch = opts.activationEligibilityEpoch;
  validator.activationEpoch = opts.activationEpoch;
  validator.exitEpoch = opts.exitEpoch;
  validator.withdrawableEpoch = opts.withdrawableEpoch;
  state.validators.set(opts.validatorIndex, validator);

  // Phase 2. Patching a withdrawal.

  const wd = Withdrawal.defaultView();
  wd.index = state.nextWithdrawalIndex;
  wd.validatorIndex = opts.validatorIndex;
  wd.address = fromHex(opts.address);
  wd.amount = opts.amount;

  // Phase 3. Constructing a beacon block.

  const block = PrevFork.BeaconBlock.defaultView();
  [...Array(16).keys()].forEach(() =>
    block.body.executionPayload.withdrawals.push(Withdrawal.defaultView()),
  );
  block.body.executionPayload.withdrawals.set(opts.withdrawalOffset, wd);
  state.latestExecutionPayloadHeader.withdrawalsRoot =
    block.body.executionPayload.withdrawals.hashTreeRoot();
  block.slot = state.slot;
  block.proposerIndex = 1337;
  block.parentRoot = state.latestBlockHeader.hashTreeRoot();
  block.stateRoot = state.hashTreeRoot();

  // Phase 4. Creating a block in future to be used in historical proofs.

  const blockInFuture = block.clone();
  blockInFuture.slot += 0x421337;
  blockInFuture.proposerIndex = 31415;

  // Phase 5. Creating a state for the future block.

  const stateInFuture = NextFork.BeaconState.defaultView();
  stateInFuture.historicalSummaries.push(stateInFuture.historicalSummaries.type.defaultView());

  const BlockRoots = NextFork.BeaconState.getPathInfo(["blockRoots"]).type;
  const blockRoots = BlockRoots.defaultView();
  blockRoots.set(block.slot % 8192, block.hashTreeRoot());

  stateInFuture.historicalSummaries.get(0).blockSummaryRoot = blockRoots.hashTreeRoot();
  blockInFuture.stateRoot = stateInFuture.hashTreeRoot();
  blockInFuture.parentRoot = blockInFuture.hashTreeRoot(); // This action changes the `blockInFuture`'s root.

  // Final step. Creating all the required input for a verifier.

  /** @type {Record<string, import('@chainsafe/persistent-merkle-tree').SingleProof>} */
  const proofs = {};

  {
    const { gindex } = PrevFork.BeaconState.getPathInfo(["validators", opts.validatorIndex]);
    proofs.validator = createProof(state.node, {
      type: ProofType.single,
      gindex: gindex,
    });
  }

  {
    const nav = state.type.getPathInfo(["latestExecutionPayloadHeader", "withdrawalsRoot"]);
    const withdrawals = block.body.executionPayload.withdrawals;

    const clone = state.clone();
    clone.tree.setNode(nav.gindex, withdrawals.node);
    proofs.withdrawal = createProof(clone.node, {
      type: ProofType.single,
      gindex: concatGindices([
        nav.gindex,
        withdrawals.type.getPropertyGindex(opts.withdrawalOffset),
      ]),
    });
  }

  {
    const nav = stateInFuture.type.getPathInfo(["historicalSummaries", 0, "blockSummaryRoot"]);
    const clone = stateInFuture.clone();
    clone.tree.setNode(nav.gindex, blockRoots.node);

    proofs.historicalRoot = createProof(clone.node, {
      type: ProofType.single,
      gindex: concatGindices([nav.gindex, BlockRoots.getPropertyGindex(block.slot % 8192)]),
    });
  }

  console.log({
    oldBlock: toHeaderJson(block),
    newBlock: toHeaderJson(blockInFuture),
    validator: { ...Validator.toJson(validator), index: opts.validatorIndex },
    validatorProof: proofs.validator?.witnesses.map(toHex),
    withdrawal: { ...Withdrawal.toJson(wd), offset: opts.withdrawalOffset },
    withdrawalProof: proofs.withdrawal?.witnesses.map(toHex),
    historicalSummariesGI: `0x${(proofs.historicalRoot?.gindex << 8n)
      .toString(16)
      .padStart(64, "0")}`,
    historicalRootProof: proofs.historicalRoot?.witnesses.map(toHex),
  });
}

async function readBinaryState(filepath) {
  const stream = fs.createReadStream(filepath);

  const buffer = [];
  for await (const chunk of stream) {
    buffer.push(chunk);
  }

  return Buffer.concat(buffer);
}

function toHeaderJson(blockView) {
  const header = blockView.type.toJson(blockView.toValue());
  header.root = toHex(blockView.hashTreeRoot());
  header.body_root = toHex(blockView.body.hashTreeRoot());
  delete header.body;
  return header;
}

export function fromHex(s) {
  return Uint8Array.from(s.match(/.{1,2}/g).map((byte) => parseInt(byte, 16)));
}

export function toHex(t) {
  return "0x" + Buffer.from(t).toString("hex");
}
