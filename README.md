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

The result of deployment is `./out/latest.json` deployment config, which is required for integration testing

Integration tests should pass either before a vote, or after

```bash
just deploy-local
export RPC_URL=http://127.0.0.1:8545
export DEPLOY_CONFIG=./out/latest.json

just test-integration
```

There also fork helper scripts to prepare a fork state for e.g. UI testing purposes

```bash
just deploy-local
export RPC_URL=http://127.0.0.1:8545
export DEPLOY_CONFIG=./out/latest.json

just simulate-vote
just test-integration
```

Kill fork after testing

```bash
just kill-fork
```
