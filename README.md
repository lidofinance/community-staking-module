# Lido Community Staking Module

### Getting Started

- Use Foundry:

```bash
forge install
forge test
```

- Use Hardhat:

```bash
yarn install
yarn test
```

### Features

- Write / run tests with either Hardhat or Foundry:

```bash
forge test
# or
yarn test
```

- Install libraries with Foundry which work with Hardhat.

```bash
forge install rari-capital/solmate
```

- Deploy to local fork via Hardhat.

```bash
anvil
npx hardhat run --network localhost scripts/deploy.ts
```

### Notes

Whenever you install new libraries using Foundry, make sure to update your
`remappings.txt` file by running `forge remappings > remappings.txt`. This is
required because we use `hardhat-preprocessor` and the `remappings.txt` file to
allow Hardhat to resolve libraries you install with Foundry.
