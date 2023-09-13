include .env

.PHONY: artifacts clean test deploy-prod deploy-local anvil-fork anvil-kill

DEPLOY_SCRIPT_PATH := script/Deploy.s.sol:Deploy

artifacts:
	forge compile --force
clean:
	forge clean
	rm -rf cache_foundry broadcast
lint-check:
	prettier --config ./.prettierrc **.{sol,ts} --check
lint-fix:
	prettier --config ./.prettierrc **.{sol,ts} -w
test: # in parallel
	$(MAKE) test-unit & 
	$(MAKE) test-integration
test-unit:
	forge test --match-path '*test/unit*'
test-integration:
	forge test --match-path '*test/integration*'

anvil-fork:
	exec anvil -f ${RPC_URL}
anvil-kill:
	pkill anvil

deploy-prod:
	forge script $(DEPLOY_SCRIPT_PATH) --force --rpc-url ${RPC_URL} --broadcast --slow
deploy-local:
ifeq ($(shell pgrep anvil),)
	$(MAKE) anvil-fork &
	@while ! echo exit | nc localhost 8545; do sleep 1; done
else
	@tput setaf 3 && printf "[WARNING]" && tput sgr0 && echo " Anvil is already running in the background. Make sure it's connected to the right network and state"
endif
	forge script $(DEPLOY_SCRIPT_PATH) --force --fork-url http://127.0.0.1:8545 --broadcast --slow
ifeq (${KEEP_ANVIL_AFTER_LOCAL_DEPLOY},false)
	$(MAKE) anvil-kill
else
	@tput setaf 3 && printf "[WARNING]" && tput sgr0 && echo " Anvil is kept running in the background: http://127.0.0.1:8545"
endif
