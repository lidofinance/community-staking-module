# Module testing

First of all, your module should implement `IStakingModule` interface to proper work with Lido protocol and Staking Router in particular.

## Lido protocol <-> Staking module

In this chapter, we describe what and how to test **integration external to the module** (when communication is initiated by the protocol, not the module) with the protocol to check internal module's logic.

### What should be tested (minimal forced set)

#### `Lido` contract

- [ ] `deposit()` - method called by depositor bot and deposit protocol's ETH to the validators keys from particular staking module through official Deposit contract. It calls `StakingModule.obtainDepositData()`

- [ ] `handleOracleReport()` - distributes protocol fee (treasury & modules), performs token rebase. It calls `StakingModule.onRewardsMinted()`

#### `StakingRouter` contract

- [ ] `updateExitedValidatorsCountByStakingModule()` - updates exited validators count for particular Node Operators staking module when accounting oracle report. It calls: `StakingModule.getStakingModuleSummary()`

- [ ] `reportStakingModuleStuckValidatorsCountByNodeOperator()` - updates stuck validators (that was selected by `ValidatorsExitBusOracle` to exit, but weren't exited before particular deadline) count for particular Node Operators in staking module when accounting oracle report. It calls `StakingModule.updateStuckValidatorsCount()`

- [ ] `reportStakingModuleExitedValidatorsCountByNodeOperator()` - updates exited validators count for particular Node Operators in staking module when accounting oracle report. It calls `StakingModule.updateExitedValidatorsCount()`

- [ ] `onValidatorsCountsByNodeOperatorReportingFinished()` - calls when oracle report processing is complete. It calls: `StakingModule.onExitedAndStuckValidatorsCountsUpdated()`, `StakingModule.getStakingModuleSummary()`

- [ ] `updateRefundedValidatorsCount()` - method called by staking router manager and update refunded validators count for particular Node operator in staking module. It calls `StakingModule.updateRefundedValidatorsCount()`

- [ ] `updateTargetValidatorsLimits()` - method called by staking router manager and update target validators limits (limit of the validators that can be used for deposit) for particular Node operator in staking module. It calls `StakingModule.updateTargetValidatorsLimits()`

- [ ] `unsafeSetExitedValidatorsCount()` - method called by staking router manager and update exited validators count for particular Node operator in staking module. It calls `StakingModule.unsafeUpdateValidatorsCount()`, `StakingModule.onExitedAndStuckValidatorsCountsUpdated()`, `StakingModule.getNodeOperatorSummary()`

- [ ] `setWithdrawalCredentials()` - method called by staking router manager and update withdrawal credentials for the Consensus Layer rewards in protocol. It calls `StakingModule.onWithdrawalCredentialsChanged()`

- [ ] `getStakingModuleDigests()` - returns digests of all staking modules. It calls `StakingModule.getStakingModuleSummary()`, `StakingModule.getNodeOperatorsCount()`, `StakingModule.getActiveNodeOperatorsCount()`

- [ ] `getNodeOperatorDigests()` - returns digests for node operator in particular staking module. It calls `StakingModule.getNodeOperatorSummary()`, `StakingModule.getNodeOperatorIsActive()`, `StakingModule.getNodeOperatorIds()`

- [ ] `getAllNodeOperatorDigests()` - returns digests of all node operators in all staking modules. It calls `StakingModule.getNodeOperatorsCount()`

- [ ] `getStakingModuleActiveValidatorsCount()` - returns active validators count for particular staking module. It calls `StakingModule.getStakingModuleSummary()`

- [ ] `getStakingModuleMaxDepositsCount()` - returns max deposits count for particular staking module. It calls `StakingModule.getStakingModuleSummary()`

- [ ] `getDepositsAllocation()` - returns deposit allocation for particular staking module. It calls `StakingModule.getStakingModuleSummary()`

    > Please, pay attention, that all oracle reports obey `OracleReportSanityChecker` rules. So, when you test your module with some values, you should take into account that they values should pass sanity checks. Also you should care that your module will functional properly in missed, delayed or reverted due to sanity checks. Don't forget that not only the frequency of reports can change, but any other constant as well.

#### `DepositSecurityModule` contract

- [ ] `DepositSecurityModule` - TBD. The module can be changed in the future. Will be described later.


  
### How it should be tested

- We strongly recommend **using the mainnet fork** on particular blocks for testing because of the high complexity of the protocol and possible problems when using custom **mocks** that can doesn't account important parts of protocol processing.
  
- A good starting point is to take a fork from the next block after [voting for the Lido v2 update](https://vote.lido.fi/vote/156) - `17266005`. You can change protocol state here to reach your conditions or you can use any other block after v2 where protocol suits your needs. 
  
- Take care that **all storage variables** in the protocol that change their value as a result of tests **should be checked** with the your expected value.
  
- If you need to test interaction with stETH/wstETH only in some tests, it's okay to do in **mocks** way, just because the Lido protocol uses `ERC` standarts for tokens and nothing special for here. We recommend using the mainnet values for state variables in mocks (like `totalShares` and `totalSupply`) in general cases.
  >Some examples of mocks can be found in `test/helpers/mocks` folder.

### Connect the module to `StakingRouter` contract

There are a few steps to connect to Staking Router on the mainnet fork:
1. Create a fork with the mainnet state
2. Deploy your module
3. Add your module to Staking Router:
   - Pretend to be the address of the steaking module admin. You can get it  
by calling `StakingRouter.getRoleMember(stakingRouter.DEFAULT_ADMIN_ROLE(), 0)`
   - Grant `STAKING_MODULE_MANAGE_ROLE` to your address using `grantRole`
function
   - Call `addStakingModule` method with deployed module address and needed parameters
4. Interact with other Staking Router methods using your address

### Interact with `Lido` contract

Before it, you should connect your module to Staking Router. See the previous chapter.

After that you should do the next steps:
1. Pretend to be the address of `DepositSecurityModule` contract. You can get it by calling `LidoLocator.depositSecurityModule`. It will allow you to call `Lido.deposit` method.
2. Pretent to be the address of `AccountingOracle` contract. You can get it by calling `LidoLocator.accountingOracle`. It will allow you to call `Lido.handleOracleReport` method.

#### Using `Lido.deposit` method 

Args for `Lido.deposit` are the next:

`uint256 _maxDepositsCount, uint256 _stakingModuleId, bytes _depositCalldata`

-  `_maxDepositsCount` - the maximum number of deposits for the module. In the end it depends on `targetShare` of the module
- `_stakingModuleId` - your module id after adding to Staking Router (the last one in the `StakingRouter.getStakingModuleIds`)
- `_depositCalldata` - module calldata for `StakingModule.obtainDepositData` method if your module use it. If not, you can pass any bytes here.

`StakingModule.obtainDepositData` should return the next values:

`bytes memory publicKeys, bytes memory signatures`

- `publicKeys` - concatenated public keys of the validators that should be used for deposit. The length of the public key is 48 bytes
- `signatures` - concatenated signatures of the `publicKeys`. The length of the signature is 96 bytes


#### Using `Lido.handleOracleReport` method

Args for `Lido.handleOracleReport` are the next:
```
// Oracle timings
uint256 _reportTimestamp,
uint256 _timeElapsed,
// CL values
uint256 _clValidators,
uint256 _clBalance,
// EL values
uint256 _withdrawalVaultBalance,
uint256 _elRewardsVaultBalance,
uint256 _sharesRequestedToBurn,
// Decision about withdrawals processing
uint256[] _withdrawalFinalizationBatches,
uint256 _simulatedShareRate
```

You can get all these values from the `AccountingOracle` contract real transactions as basis. For example, [the very first accounting report](https://etherscan.io/tx/0x7cdd45433bdb2953dd6cd4d4a2d37449d4f93907afdfedaf65a892f91a4ea263) after v2 upgrade contained the next values:
```
refSlot = 6451199
numValidators = 196087
clBalanceGwei = 6276095756977027
withdrawalVaultBalance	= 277712792775539582008297
elRewardsVaultBalance = 579806686319271377574
sharesRequestedToBurn = 0
```

That can be modified to the next args for `Lido.handleOracleReport`:
```
// Oracle timings
_reportTimestamp = GENESIS_TIME + refSlot * SECONDS_PER_SLOT,
_timeElapsed = refSlot - prevRefSlot, // prevRefSlot - previous accounting report slot
// CL values
_clValidators = numValidators,
_clBalance = clBalanceGwei * 1e9,
// EL values
_withdrawalVaultBalance = withdrawalVaultBalance,
_elRewardsVaultBalance = elRewardsVaultBalance,
_sharesRequestedToBurn = sharesRequestedToBurn,
// Decision about withdrawals processing
_withdrawalFinalizationBatches = [],
_simulatedShareRate = 0
```

## Examples

### Connect to Staking Router on the mainnet fork using `forge-std`

```javascript
// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { ILidoLocator } from "../../src/interfaces/ILidoLocator.sol";
import { IStakingRouter } from "../../src/interfaces/IStakingRouter.sol";

contract StakingRouterIntegrationTest is Test {
    uint256 networkFork;

    ILidoLocator public locator;
    IStakingRouter public stakingRouter;

    address internal agent;

    string RPC_URL;
    string LIDO_LOCATOR_ADDRESS;

    function setUp() public {
        RPC_URL = vm.envOr("RPC_URL", string(""));
        LIDO_LOCATOR_ADDRESS = vm.envOr("LIDO_LOCATOR_ADDRESS", string(""));
        vm.skip(
            keccak256(abi.encodePacked(RPC_URL)) ==
                keccak256(abi.encodePacked("")) ||
                keccak256(abi.encodePacked(LIDO_LOCATOR_ADDRESS)) ==
                keccak256(abi.encodePacked(""))
        );

        networkFork = vm.createFork(RPC_URL, 17266005);
        vm.selectFork(networkFork);

        locator = ILidoLocator(vm.parseAddress(LIDO_LOCATOR_ADDRESS));
        stakingRouter = IStakingRouter(payable(locator.stakingRouter()));

        address stakingModule = address(new YourModule());
        /*
        Your module init code
        */

        agent = stakingRouter.getRoleMember(
            stakingRouter.DEFAULT_ADMIN_ROLE(),
            0
        );
        vm.startPrank(agent);
        stakingRouter.grantRole(
            stakingRouter.STAKING_MODULE_MANAGE_ROLE(),
            agent
        );
        stakingRouter.addStakingModule({
            _name: "some-staking-module-v1",
            _stakingModuleAddress: stakingModule,
            _targetShare: 10000,
            _stakingModuleFee: 500,
            _treasuryFee: 500
        });
        vm.stopPrank();
    }
}
```