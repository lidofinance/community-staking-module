set dotenv-load

chain := env_var_or_default("CHAIN", "mainnet")
deploy_script_path := if chain == "mainnet" {
	"script" / "DeployMainnetish.s.sol" + ":DeployMainnetish"
} else if chain == "holesky" {
	"script" / "DeployHolesky.s.sol" + ":DeployHolesky"
} else if chain == "goerli" {
	"script" / "DeployGoerli.s.sol" + ":DeployGoerli"
} else {
	error("Unsupported chain " + chain)
}

anvil_host := env_var_or_default("ANVIL_IP_ADDR", "127.0.0.1")
anvil_port := "8545"

default: clean build test-all

build:
	forge build --force

clean:
	forge clean
	rm -rf cache broadcast out

lint-solhint:
	yarn lint:solhint

lint-check:
	yarn lint:check

lint-fix:
	yarn lint:fix

test-all:
	just test-unit &
	just test-integration

test *args:
	forge test {{args}}

test-unit:
	forge test --no-match-path '*test/integration*' -vvv

test-integration:
	forge test --match-path '*test/integration*' -vvv

coverage:
	forge coverage

# Run coverage and save the report in LCOV file.
coverage-lcov:
	forge coverage --report lcov

make-fork:
	@if pgrep -x "anvil" > /dev/null; then just _warn "anvil process is already running in the background. Make sure it's connected to the right network and in the right state."; else anvil -f ${RPC_URL} --host {{anvil_host}} --port {{anvil_port}}; fi

kill-fork:
	@-pkill anvil && just _warn "anvil process is killed"

deploy-prod:
	forge script {{deploy_script_path}} --force --rpc-url ${RPC_URL} --broadcast --slow

deploy-local:
	just make-fork &
	@while ! echo exit | nc {{anvil_host}} {{anvil_port}} > /dev/null; do sleep 1; done
	forge script {{deploy_script_path}} --force --fork-url http://{{anvil_host}}:{{anvil_port}} --broadcast --slow
	@if ${KEEP_ANVIL_AFTER_LOCAL_DEPLOY}; then just _warn "anvil is kept running in the background: http://{{anvil_host}}:{{anvil_port}}"; else just kill-fork; fi

_warn message:
	@tput setaf 3 && printf "[WARNING]" && tput sgr0 && echo " {{message}}"
