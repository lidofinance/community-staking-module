# SSZ
[Git Source](https://github.com/lidofinance/community-staking-module/blob/a195b01bbb6171373c6b27ef341ec075aa98a44e/src/lib/SSZ.sol)


## Functions
### hashTreeRoot


```solidity
function hashTreeRoot(BeaconBlockHeader memory header) internal view returns (bytes32 root);
```

### hashTreeRoot


```solidity
function hashTreeRoot(Validator memory validator) internal view returns (bytes32 root);
```

### verifyProof

Modified version of `verify` from Solady `MerkleProofLib` to support generalized indices and sha256 precompile.

*Reverts if `leaf` doesn't exist in the Merkle tree with `root`, given `proof`.*


```solidity
function verifyProof(bytes32[] calldata proof, bytes32 root, bytes32 leaf, GIndex gI) internal view;
```

### hashTreeRoot


```solidity
function hashTreeRoot(Withdrawal memory withdrawal) internal pure returns (bytes32);
```

### toLittleEndian


```solidity
function toLittleEndian(uint256 v) internal pure returns (bytes32);
```

### toLittleEndian


```solidity
function toLittleEndian(bool v) internal pure returns (bytes32);
```

## Errors
### BranchHasMissingItem

```solidity
error BranchHasMissingItem();
```

### BranchHasExtraItem

```solidity
error BranchHasExtraItem();
```

### InvalidProof

```solidity
error InvalidProof();
```

