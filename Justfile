set dotenv-load

chain := env_var_or_default("CHAIN", "mainnet")
deploy_script_path := if chain == "mainnet" {
    "script" / "DeployMainnetish.s.sol" + ":DeployMainnetish"
} else if chain == "holesky" {
    "script" / "DeployHolesky.s.sol" + ":DeployHolesky"
} else if chain == "devnet" {
    "script" / "DeployHoleskyDevnet.s.sol" + ":DeployHoleskyDevnet"
} else {
    error("Unsupported chain " + chain)
}

anvil_host := env_var_or_default("ANVIL_IP_ADDR", "127.0.0.1")
anvil_port := "8545"

default: clean deps build test-all

build *args:
    forge build --force {{args}}

clean:
    forge clean
    rm -rf cache broadcast out node_modules

deps:
    yarn install --immutable

lint-solhint:
    yarn lint:solhint

lint-fix:
    yarn lint:fix

lint:
    yarn lint:check

test-all:
    just test-unit &
    just test-local

test-unit *args:
    forge test --no-match-path '*test/integration*' -vvv {{args}}

test-integration *args:
    forge test --match-path '*test/integration*' -vvv {{args}}

gas-report:
    #!/usr/bin/env python

    import subprocess
    import re

    command = "just test-unit --nmt 'testFuzz.+' --gas-report"
    output = subprocess.check_output(command, shell=True, text=True)

    lines = output.split('\n')

    filename = 'GAS.md'
    to_print = False
    skip_next = False

    with open(filename, 'w') as fh:
        for line in lines:
            if skip_next:
                skip_next = False
                continue

            if line.startswith('|'):
                to_print = True

            if line.startswith('| Deployment Cost'):
                to_print = False
                skip_next = True

            if re.match(r"Ran \d+ test suites", line):
                break

            if to_print:
                fh.write(line + '\n')

coverage:
    forge coverage

# Run coverage and save the report in LCOV file.
coverage-lcov:
    forge coverage --report lcov

abis:
    just build --ast
    yarn generate:abis

make-fork *args:
    @if pgrep -x "anvil" > /dev/null; \
        then just _warn "anvil process is already running in the background. Make sure it's connected to the right network and in the right state."; \
        else anvil -f ${RPC_URL} --host {{anvil_host}} --port {{anvil_port}} --config-out localhost.json {{args}}; \
    fi

kill-fork:
    @-pkill anvil && just _warn "anvil process is killed"

deploy *args:
    forge script {{deploy_script_path}} --rpc-url http://{{anvil_host}}:{{anvil_port}} --broadcast --slow {{args}}

deploy-prod:
    forge script {{deploy_script_path}} --force --rpc-url ${RPC_URL} --broadcast --slow

deploy-local:
    just make-fork &
    @while ! echo exit | nc {{anvil_host}} {{anvil_port}} > /dev/null; do sleep 1; done
    just deploy
    just _warn "anvil is kept running in the background: http://{{anvil_host}}:{{anvil_port}}"

test-local *args:
    just make-fork --silent &
    @while ! echo exit | nc {{anvil_host}} {{anvil_port}} > /dev/null; do sleep 1; done
    DEPLOYER_PRIVATE_KEY=`cat localhost.json | jq -r ".private_keys[0]"` \
        just deploy --silent
    DEPLOY_CONFIG=./out/latest.json \
    RPC_URL=http://{{anvil_host}}:{{anvil_port}} \
        just test-integration {{args}}
    just kill-fork

simulate-vote:
    cast rpc anvil_autoImpersonateAccount true
    forge script script/fork-helpers/SimulateVote.sol --rpc-url=http://{{anvil_host}}:{{anvil_port}} -vvv \
        --broadcast --slow --unlocked --sender=`cat localhost.json | jq -r ".available_accounts[0]"`
    cast rpc anvil_autoImpersonateAccount false

_warn message:
    @tput setaf 3 && printf "[WARNING]" && tput sgr0 && echo " {{message}}"
