
## How to build

Install dependencies from the root of the repository:
```bash
yarn install
```

Run the script:
```bash
cd artifacts/mainnet/early-adoption
node compose.js
```

## Output files

- `addresses.json` - plain list of unique addresses
- `merkle-tree.json` - Merkle tree of the list
- `merkle-proofs.json` - Merkle proofs for each address
- `exclusions.csv` - List of excluded addresses
- `sources.csv` - Detailed info about sources of inclusion
