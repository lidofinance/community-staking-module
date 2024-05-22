<p align="center">
  <img src="logo.png" width="120" alt="CSM Logo"/>
</p>
<h1 align="center"> Lido Community Staking Module </h1>

> **This project is under heavy development. Do not consider any code as final.**

### Getting Started

- Install [Foundry tools](https://book.getfoundry.sh/getting-started/installation)

- Install [Just](https://github.com/casey/just)

- Install project dependencies

```bash
just deps
```

- Config environment variables

```bash
cp .env.sample .env
```

Fill vars in the `.env` file with your own values

- Build and test contracts

```bash
just
```

### Features

## Run tests

```bash
just test-all # run all tests that possible to run without additional configurations
# or run specific tests
just test-unit
# deploy CSM to local fork and run integration tests over it
just test-local

# run integration tests with specific deployment config
# make sure that corresponding RPC_URL is set
DEPLOYMENT_CONFIG=./config/holesky-devnet-0/deploy-holesky-devnet.json just test-integration
```

**Note:** the CSM requires to be added to the Staking Router 1.5,
so it's impossible to run integration tests over the network with the old contracts.
Technically it's possible to add the CSM to the previous Staking Router version,
but it's supposed to be added to the new one.

Please Make sure that `test-local` or `test-integration` are running against the correct protocol setup:

```bash
export CHAIN=devnet
```

## Make a gas report

It requires all unit tests to be green

```bash
just gas-report
```

## Add new dependencies

Dependencies are managed using yarn. To install new dependencies, run:

```bash
yarn add <package-name>
```

Whenever you install new libraries using yarn, make sure to update your
`remappings.txt`.

## Deploy and test using local fork

```bash
just deploy-local
```

The result of deployment is `./artifacts/local/deploy-devnet.json` deployment config, which is required for integration testing

Integration tests should pass either before a vote, or after

```bash
just deploy-local
export RPC_URL=http://127.0.0.1:8545
export DEPLOY_CONFIG=./artifacts/local/deploy-devnet.json

just test-integration
```

There also fork helper scripts to prepare a fork state for e.g. UI testing purposes

```bash
just deploy-local
export RPC_URL=http://127.0.0.1:8545
export DEPLOY_CONFIG=./artifacts/local/deploy-devnet.json

just simulate-vote
just test-integration
```

Kill fork after testing

```bash
just kill-fork
```

## Deploy on a chain

The following commands are related to the deployment process:

- Dry run of deploy script to be sure it works as expected

```bash
just deploy-prod-dry
```

- Broadcast transactions

> Note: pass `--legacy` arg in case of the following error: `Failed to get EIP-1559 fees`

```bash
just deploy-prod
```

After that there should be artifacts in the `./artifacts/latest` directory,
which is might be moved to the particular directory and commited

```bash
mv ./artifacts/latest ./artifacts/$CHAIN
```
