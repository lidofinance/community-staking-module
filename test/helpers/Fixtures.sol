// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import { StdCheats } from "forge-std/StdCheats.sol";
import { LidoMock } from "./mocks/LidoMock.sol";
import { WstETHMock } from "./mocks/WstETHMock.sol";
import { LidoLocatorMock } from "./mocks/LidoLocatorMock.sol";
import { BurnerMock } from "./mocks/BurnerMock.sol";
import { WithdrawalQueueMock } from "./mocks/WithdrawalQueueMock.sol";
import { Stub } from "./mocks/Stub.sol";
import "forge-std/Test.sol";
import { IStakingRouter } from "../../src/interfaces/IStakingRouter.sol";
import { ILido } from "../../src/interfaces/ILido.sol";
import { IBurner } from "../../src/interfaces/IBurner.sol";
import { ILidoLocator } from "../../src/interfaces/ILidoLocator.sol";
import { IWstETH } from "../../src/interfaces/IWstETH.sol";
import { IGateSeal } from "../../src/interfaces/IGateSeal.sol";
import { NodeOperatorManagementProperties } from "../../src/interfaces/ICSModule.sol";
import { HashConsensus } from "../../src/lib/base-oracle/HashConsensus.sol";
import { IWithdrawalQueue } from "../../src/interfaces/IWithdrawalQueue.sol";
import { CSModule } from "../../src/CSModule.sol";
import { CSParametersRegistry } from "../../src/CSParametersRegistry.sol";
import { PermissionlessGate } from "../../src/PermissionlessGate.sol";
import { VettedGate } from "../../src/VettedGate.sol";
import { CSAccounting } from "../../src/CSAccounting.sol";
import { CSFeeOracle } from "../../src/CSFeeOracle.sol";
import { CSFeeDistributor } from "../../src/CSFeeDistributor.sol";
import { CSEjector } from "../../src/CSEjector.sol";
import { CSStrikes } from "../../src/CSStrikes.sol";
import { CSVerifier } from "../../src/CSVerifier.sol";
import { DeployParams, DeployParamsV1 } from "../../script/DeployBase.s.sol";
import { IACL } from "../../src/interfaces/IACL.sol";
import { IKernel } from "../../src/interfaces/IKernel.sol";
import { Utilities } from "./Utilities.sol";
import { Batch } from "../../src/lib/QueueLib.sol";
import { VEBMock } from "./mocks/VEBMock.sol";

contract Fixtures is StdCheats, Test {
    bytes32 public constant INITIALIZABLE_STORAGE =
        0xf0c57e16840df040f15088dc2f81fe391c3923bec73e23a9662efc9c229c6a00;

    function initLido()
        public
        returns (
            LidoLocatorMock locator,
            WstETHMock wstETH,
            LidoMock stETH,
            BurnerMock burner,
            WithdrawalQueueMock wq
        )
    {
        stETH = new LidoMock({ _totalPooledEther: 8013386371917025835991984 });
        stETH.mintShares({
            _account: address(stETH),
            _sharesAmount: 7059313073779349112833523
        });
        burner = new BurnerMock(address(stETH));
        Stub elVault = new Stub();
        wstETH = new WstETHMock(address(stETH));
        wq = new WithdrawalQueueMock(address(wstETH), address(stETH));
        Stub treasury = new Stub();
        Stub stakingRouter = new Stub();
        VEBMock veb = new VEBMock();
        locator = new LidoLocatorMock(
            address(stETH),
            address(burner),
            address(wq),
            address(elVault),
            address(treasury),
            address(stakingRouter),
            address(veb)
        );
        vm.label(address(stETH), "lido");
        vm.label(address(wstETH), "wstETH");
        vm.label(address(locator), "locator");
        vm.label(address(burner), "burner");
        vm.label(address(wq), "wq");
        vm.label(address(elVault), "elVault");
        vm.label(address(treasury), "treasury");
        vm.label(address(stakingRouter), "stakingRouter");
        vm.label(address(veb), "validatorExitBus");
    }

    function _enableInitializers(address implementation) internal {
        // cheat to allow implementation initialisation
        vm.store(implementation, INITIALIZABLE_STORAGE, bytes32(0));
    }
}

contract DeploymentHelpers is Test {
    struct Env {
        string RPC_URL;
        string DEPLOY_CONFIG;
        string UPGRADE_CONFIG;
        uint256 VOTE_PREV_BLOCK;
    }

    struct DeploymentConfig {
        uint256 chainId;
        address csm;
        address permissionlessGate;
        address vettedGate;
        address parametersRegistry;
        /// legacy from v1
        address earlyAdoption;
        address accounting;
        address oracle;
        address feeDistributor;
        address ejector;
        address strikes;
        address verifier;
        address hashConsensus;
        address lidoLocator;
        address gateSeal;
    }

    struct UpgradeConfig {
        address permissionlessGate;
        address vettedGate;
        address parametersRegistry;
        address ejector;
        address strikes;
        address csmImpl;
        address accountingImpl;
        address oracleImpl;
        address feeDistributorImpl;
        address verifier;
        address earlyAdoption;
        address hashConsensus;
        address gateSeal;
    }

    function envVars() public returns (Env memory) {
        Env memory env = Env(
            vm.envOr("RPC_URL", string("")),
            vm.envOr("DEPLOY_CONFIG", string("")),
            vm.envOr("UPGRADE_CONFIG", string("")),
            vm.envOr("VOTE_PREV_BLOCK", uint256(0))
        );
        vm.skip(_isEmpty(env.RPC_URL));
        vm.skip(_isEmpty(env.DEPLOY_CONFIG));
        return env;
    }

    function parseDeploymentConfig(
        string memory config
    ) public returns (DeploymentConfig memory deploymentConfig) {
        deploymentConfig.chainId = vm.parseJsonUint(config, ".ChainId");

        deploymentConfig.csm = vm.parseJsonAddress(config, ".CSModule");
        vm.label(deploymentConfig.csm, "csm");

        /// Optional for v1 compatibility (upgrade tests). Removed in v2
        if (vm.keyExistsJson(config, ".CSEarlyAdoption")) {
            deploymentConfig.earlyAdoption = vm.parseJsonAddress(
                config,
                ".CSEarlyAdoption"
            );
            vm.label(deploymentConfig.earlyAdoption, "earlyAdoption");
        }

        /// Optional, new in v2. Gates and other stuff not present in v1 deployment configs
        if (vm.keyExistsJson(config, ".PermissionlessGate")) {
            deploymentConfig.permissionlessGate = vm.parseJsonAddress(
                config,
                ".PermissionlessGate"
            );
            vm.label(deploymentConfig.permissionlessGate, "permissionlessGate");
            deploymentConfig.vettedGate = vm.parseJsonAddress(
                config,
                ".VettedGate"
            );
            vm.label(deploymentConfig.vettedGate, "vettedGate");
            deploymentConfig.parametersRegistry = vm.parseJsonAddress(
                config,
                ".CSParametersRegistry"
            );
            vm.label(deploymentConfig.parametersRegistry, "parametersRegistry");
            deploymentConfig.strikes = vm.parseJsonAddress(
                config,
                ".CSStrikes"
            );
            vm.label(deploymentConfig.strikes, "strikes");
            deploymentConfig.ejector = vm.parseJsonAddress(
                config,
                ".CSEjector"
            );
            vm.label(deploymentConfig.strikes, "ejector");
        }

        deploymentConfig.accounting = vm.parseJsonAddress(
            config,
            ".CSAccounting"
        );
        vm.label(deploymentConfig.accounting, "accounting");

        deploymentConfig.oracle = vm.parseJsonAddress(config, ".CSFeeOracle");
        vm.label(deploymentConfig.oracle, "oracle");

        deploymentConfig.feeDistributor = vm.parseJsonAddress(
            config,
            ".CSFeeDistributor"
        );
        vm.label(deploymentConfig.feeDistributor, "feeDistributor");

        deploymentConfig.verifier = vm.parseJsonAddress(config, ".CSVerifier");
        vm.label(deploymentConfig.verifier, "verifier");

        deploymentConfig.hashConsensus = vm.parseJsonAddress(
            config,
            ".HashConsensus"
        );
        vm.label(deploymentConfig.hashConsensus, "hashConsensus");

        deploymentConfig.lidoLocator = vm.parseJsonAddress(
            config,
            ".LidoLocator"
        );
        vm.label(deploymentConfig.lidoLocator, "LidoLocator");

        deploymentConfig.gateSeal = vm.parseJsonAddress(config, ".GateSeal");
        vm.label(deploymentConfig.gateSeal, "GateSeal");
    }

    function parseUpgradeConfig(
        string memory config
    ) internal pure returns (UpgradeConfig memory upgradeConfig) {
        upgradeConfig.permissionlessGate = vm.parseJsonAddress(
            config,
            ".PermissionlessGate"
        );
        upgradeConfig.vettedGate = vm.parseJsonAddress(config, ".VettedGate");
        upgradeConfig.parametersRegistry = vm.parseJsonAddress(
            config,
            ".CSParametersRegistry"
        );
        upgradeConfig.strikes = vm.parseJsonAddress(config, ".CSStrikes");
        upgradeConfig.ejector = vm.parseJsonAddress(config, ".CSEjector");
        upgradeConfig.csmImpl = vm.parseJsonAddress(config, ".CSModuleImpl");
        upgradeConfig.accountingImpl = vm.parseJsonAddress(
            config,
            ".CSAccountingImpl"
        );
        upgradeConfig.oracleImpl = vm.parseJsonAddress(
            config,
            ".CSFeeOracleImpl"
        );
        upgradeConfig.feeDistributorImpl = vm.parseJsonAddress(
            config,
            ".CSFeeDistributorImpl"
        );
        upgradeConfig.verifier = vm.parseJsonAddress(config, ".CSVerifier");
        upgradeConfig.hashConsensus = vm.parseJsonAddress(
            config,
            ".HashConsensus"
        );
        upgradeConfig.gateSeal = vm.parseJsonAddress(config, ".GateSeal");
    }

    function parseDeployParamsV1(
        string memory deployConfigPath
    ) internal view returns (DeployParamsV1 memory) {
        string memory config = vm.readFile(deployConfigPath);
        return
            abi.decode(
                vm.parseJsonBytes(config, ".DeployParams"),
                (DeployParamsV1)
            );
    }

    function parseDeployParams(
        string memory deployConfigPath
    ) internal view returns (DeployParams memory) {
        string memory config = vm.readFile(deployConfigPath);
        return
            abi.decode(
                vm.parseJsonBytes(config, ".DeployParams"),
                (DeployParams)
            );
    }

    function _isEmpty(string memory s) internal pure returns (bool) {
        return
            keccak256(abi.encodePacked(s)) == keccak256(abi.encodePacked(""));
    }
}

contract DeploymentFixtures is StdCheats, DeploymentHelpers {
    CSModule public csm;
    CSParametersRegistry public parametersRegistry;
    PermissionlessGate public permissionlessGate;
    VettedGate public vettedGate;
    address public earlyAdoption;
    CSAccounting public accounting;
    CSFeeOracle public oracle;
    CSFeeDistributor public feeDistributor;
    CSStrikes public strikes;
    CSEjector public ejector;
    CSVerifier public verifier;
    HashConsensus public hashConsensus;
    ILidoLocator public locator;
    IWstETH public wstETH;
    IStakingRouter public stakingRouter;
    ILido public lido;
    IGateSeal public gateSeal;
    IBurner public burner;

    // v2 implementations
    CSModule public csmImpl;
    CSAccounting public accountingImpl;
    CSFeeOracle public oracleImpl;
    CSFeeDistributor public feeDistributorImpl;

    error CSModuleNotFound();

    function initializeFromDeployment() public {
        Env memory env = envVars();
        string memory config = vm.readFile(env.DEPLOY_CONFIG);
        DeploymentConfig memory deploymentConfig = parseDeploymentConfig(
            config
        );
        assertEq(deploymentConfig.chainId, block.chainid, "ChainId mismatch");

        csm = CSModule(deploymentConfig.csm);
        parametersRegistry = CSParametersRegistry(
            deploymentConfig.parametersRegistry
        );
        permissionlessGate = PermissionlessGate(
            deploymentConfig.permissionlessGate
        );
        vettedGate = VettedGate(deploymentConfig.vettedGate);
        earlyAdoption = deploymentConfig.earlyAdoption;
        accounting = CSAccounting(deploymentConfig.accounting);
        oracle = CSFeeOracle(deploymentConfig.oracle);
        feeDistributor = CSFeeDistributor(deploymentConfig.feeDistributor);
        ejector = CSEjector(payable(deploymentConfig.ejector));
        strikes = CSStrikes(deploymentConfig.strikes);
        verifier = CSVerifier(deploymentConfig.verifier);
        hashConsensus = HashConsensus(deploymentConfig.hashConsensus);
        locator = ILidoLocator(deploymentConfig.lidoLocator);
        lido = ILido(locator.lido());
        stakingRouter = IStakingRouter(locator.stakingRouter());
        wstETH = IWstETH(IWithdrawalQueue(locator.withdrawalQueue()).WSTETH());
        gateSeal = IGateSeal(deploymentConfig.gateSeal);
        burner = IBurner(locator.burner());

        if (!_isEmpty(env.UPGRADE_CONFIG)) {
            UpgradeConfig memory upgradeConfig = parseUpgradeConfig(
                vm.readFile(env.UPGRADE_CONFIG)
            );
            csmImpl = CSModule(upgradeConfig.csmImpl);
            accountingImpl = CSAccounting(upgradeConfig.accountingImpl);
            oracleImpl = CSFeeOracle(upgradeConfig.oracleImpl);
            feeDistributorImpl = CSFeeDistributor(
                upgradeConfig.feeDistributorImpl
            );

            parametersRegistry = CSParametersRegistry(
                upgradeConfig.parametersRegistry
            );
            ejector = CSEjector(payable(upgradeConfig.ejector));
            strikes = CSStrikes(upgradeConfig.strikes);
            permissionlessGate = PermissionlessGate(
                upgradeConfig.permissionlessGate
            );
            vettedGate = VettedGate(upgradeConfig.vettedGate);
            verifier = CSVerifier(upgradeConfig.verifier);
            hashConsensus = HashConsensus(upgradeConfig.hashConsensus);
            gateSeal = IGateSeal(upgradeConfig.gateSeal);
        }
    }

    function handleStakingLimit() public {
        address agent = stakingRouter.getRoleMember(
            stakingRouter.DEFAULT_ADMIN_ROLE(),
            0
        );
        IACL acl = IACL(IKernel(lido.kernel()).acl());
        bytes32 role = lido.STAKING_CONTROL_ROLE();
        vm.prank(acl.getPermissionManager(address(lido), role));
        acl.grantPermission(agent, address(lido), role);

        vm.prank(agent);
        lido.removeStakingLimit();
    }

    function handleBunkerMode() public {
        IWithdrawalQueue wq = IWithdrawalQueue(locator.withdrawalQueue());
        if (wq.isBunkerModeActive()) {
            vm.prank(wq.getRoleMember(wq.ORACLE_ROLE(), 0));
            wq.onOracleReport(false, 0, 0);
        }
    }

    function hugeDeposit() internal {
        // It's impossible to process deposits if withdrawal requests amount is more than the buffered ether,
        // so we need to make sure that the buffered ether is enough by submitting this tremendous amount.
        handleStakingLimit();
        handleBunkerMode();

        address whale = address(100499);
        vm.prank(whale);
        vm.deal(whale, 1e7 ether);
        lido.submit{ value: 1e7 ether }(address(0));
    }

    function findCSModule() internal view returns (uint256) {
        uint256[] memory ids = stakingRouter.getStakingModuleIds();
        for (uint256 i = ids.length - 1; i > 0; i--) {
            IStakingRouter.StakingModule memory module = stakingRouter
                .getStakingModule(ids[i]);
            if (module.stakingModuleAddress == address(csm)) {
                return ids[i];
            }
        }
        revert CSModuleNotFound();
    }

    function addNodeOperator(
        address from,
        uint256 keysCount
    ) internal returns (uint256 nodeOperatorId) {
        (bytes memory keys, bytes memory signatures) = new Utilities()
            .keysSignatures(keysCount);
        uint256 amount = accounting.getBondAmountByKeysCount(keysCount, 0);
        vm.deal(from, amount);

        vm.prank(from);
        nodeOperatorId = permissionlessGate.addNodeOperatorETH{
            value: amount
        }({
            keysCount: keysCount,
            publicKeys: keys,
            signatures: signatures,
            managementProperties: NodeOperatorManagementProperties({
                managerAddress: address(0),
                rewardAddress: address(0),
                extendedManagerPermissions: false
            }),
            referrer: address(0)
        });
    }

    function getDepositableNodeOperator(
        address nodeOperatorAddress
    ) internal returns (uint256 noId, uint256 keysCount) {
        for (uint256 i = 0; i < csm.QUEUE_LOWEST_PRIORITY(); ++i) {
            (uint128 head, ) = csm.depositQueuePointers(i);
            Batch batch = csm.depositQueueItem(i, head);
            if (!batch.isNil()) {
                return (batch.noId(), batch.keys());
            }
        }
        keysCount = 5;
        noId = addNodeOperator(nodeOperatorAddress, keysCount);
    }
}
