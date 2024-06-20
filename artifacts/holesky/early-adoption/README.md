# Early adoption list on Holesky

Consists of the following parts:

## Rated's Solo Staker list

Source: https://github.com/rated-network/solo-stakers/blob/096876e7a9a298e969e76376cc5fe3e60cab305e/solo_stakers_v1.csv

## Stake Cat's Solo Staker list

Source: https://github.com/Stake-Cat/Solo-Stakers/blob/6f03dad1bbe5bf8ea60bf8bc73ea63563e1f29cf/Solo-Stakers/Solo-Stakers-B.csv

## Obol Techne credentials

Source: https://arbiscan.io/token/0x3cbbcc4381e0812f89175798ae7be2f47bc22021#balances  
At: 20th of June 2024

## Participants of Galxe's Lido Space campaigns with >5 points

Source: https://app.galxe.com/quest/lido/leaderboard  
At: 20th of June 2024

## How to build

```bash
node compose.js
```

## Output files

- `addresses.json` - plain list of unique addresses
- `merkle-tree.json` - Merkle tree of the list
- `merkle-proofs.json` - Merkle proofs for each address
