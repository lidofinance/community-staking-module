<p align="center">
  <img src="logo.png" width="120" alt="CSM Logo"/>
</p>
<h1 align="center"> Lido Community Staking Module </h1>

### Getting Started

- Install [Foundry tools](https://book.getfoundry.sh/getting-started/installation)

- Install project dependencies

```bash
forge install
```

- Config environment variables

```bash
cp .env.sample .env
```

Fill vars in the `.env` file with your own values

### Features

- Run tests

```bash
make test # run all tests
make test-unit
make test-inegration
```

- Install libraries

```bash
forge install rari-capital/solmate
```

- Deploy to local fork

```bash
make deploy-local
```

- Deploy to local fork of non-mainnet chain

```bash
CHAIN=holesky make deploy-local
```

### Notes

Whenever you install new libraries using Foundry, make sure to update your
`remappings.txt` file by running `forge remappings > remappings.txt`
