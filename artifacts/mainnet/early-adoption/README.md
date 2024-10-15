
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

## IPFS

- `addresses.json` - https://ipfs.io/ipfs/QmfYtR3JocHVaeYoyXCikSPN9gTT24o1DXKkRLECHbusCL
- `merkle-tree.json` - https://ipfs.io/ipfs/QmUZ94QLqFEGv2AqemDqWPna7T2UFibmcR7VhdzuXFkmbd
- `merkle-proofs.json` - https://ipfs.io/ipfs/QmUdh1pPDxkPjzBnvVprYnbFPhqqwb3dkeVwjVxc5bcG2v
