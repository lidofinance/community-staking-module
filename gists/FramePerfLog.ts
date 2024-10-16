type FramePerfLog = {
  frame: [number, number];
  distributable: bigint;
  operators: {
    [operatorId: string]: {
      distributed: bigint;
      stuck: boolean;
      validators: {
        [validatorId: string]: {
          perf: {
            assigned: number;
            included: number;
          };
          slashed: boolean;
        };
      };
    };
  };
  threshold: number;
  blockstamp: {
    ref_slot: number;
    block_hash: `0x${string}`;
  };
};
