include .env

.PHONY: artifacts clean test deploy-prod deploy-local anvil-fork kill-anvil

DEPLOY_SCRIPT_PATH := script/Deploy.s.sol:Deploy

artifacts:
	forge compile --force
clean:
	forge clean
	rm -rf cache_foundry broadcast
check:
	prettier --config ./.prettierrc **.{sol,ts} --check
fix:
	prettier --config ./.prettierrc **.{sol,ts} -w
test:
	forge test -vvvvv

deploy-prod:
	forge script $(DEPLOY_SCRIPT_PATH) --force --rpc-url ${RPC_URL} --broadcast --slow
deploy-local:
	anvil -f ${RPC_URL} &
	@while ! echo exit | nc localhost 8545; do sleep 1; done
	forge script $(DEPLOY_SCRIPT_PATH) --force --fork-url http://127.0.0.1:8545 --broadcast --slow
ifeq (${KEEP_ANVIL_AFTER_LOCAL_DEPLOY},false)
	@pkill anvil
else
	@echo "\033[0;33m[WARNING] Anvil is kept running in the background: http://127.0.0.1:8545"
endif