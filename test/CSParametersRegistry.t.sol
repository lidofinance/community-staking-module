// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { CSParametersRegistry } from "../src/CSParametersRegistry.sol";
import { ICSParametersRegistry } from "../src/interfaces/ICSParametersRegistry.sol";

import { Utilities } from "./helpers/Utilities.sol";
import { Fixtures } from "./helpers/Fixtures.sol";

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract CSParametersRegistryBaseTest is Test, Utilities, Fixtures {
    address internal admin;
    address internal stranger;
    ICSParametersRegistry.InitializationData internal defaultInitData;

    CSParametersRegistry internal parametersRegistry;

    function setUp() public virtual {
        admin = nextAddress("ADMIN");
        stranger = nextAddress("STRANGER");

        parametersRegistry = new CSParametersRegistry({
            queueLowestPriority: 5
        });

        defaultInitData = ICSParametersRegistry.InitializationData({
            keyRemovalCharge: 0.05 ether,
            elRewardsStealingAdditionalFine: 0.1 ether,
            keysLimit: 100_000,
            rewardShare: 8000,
            performanceLeeway: 500,
            strikesLifetime: 6,
            strikesThreshold: 3,
            defaultQueuePriority: 0,
            defaultQueueMaxDeposits: 10,
            badPerformancePenalty: 0.1 ether,
            attestationsWeight: 54,
            blocksWeight: 8,
            syncWeight: 2,
            defaultAllowedExitDelay: 1 days
        });
    }
}

contract CSParametersRegistryInitTest is CSParametersRegistryBaseTest {
    function test_constructor_RevertWhen_InitOnImpl() public {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        parametersRegistry.initialize(admin, defaultInitData);
    }

    function test_initialize() public {
        _enableInitializers(address(parametersRegistry));

        vm.expectEmit(address(parametersRegistry));
        emit ICSParametersRegistry.DefaultKeyRemovalChargeSet(
            defaultInitData.keyRemovalCharge
        );
        vm.expectEmit(address(parametersRegistry));
        emit ICSParametersRegistry.DefaultElRewardsStealingAdditionalFineSet(
            defaultInitData.elRewardsStealingAdditionalFine
        );
        vm.expectEmit(address(parametersRegistry));
        emit ICSParametersRegistry.DefaultKeysLimitSet(
            defaultInitData.keysLimit
        );
        vm.expectEmit(address(parametersRegistry));
        emit ICSParametersRegistry.DefaultRewardShareSet(
            defaultInitData.rewardShare
        );
        vm.expectEmit(address(parametersRegistry));
        emit ICSParametersRegistry.DefaultPerformanceLeewaySet(
            defaultInitData.performanceLeeway
        );
        vm.expectEmit(address(parametersRegistry));
        emit ICSParametersRegistry.DefaultStrikesParamsSet(
            defaultInitData.strikesLifetime,
            defaultInitData.strikesThreshold
        );
        vm.expectEmit(address(parametersRegistry));
        emit ICSParametersRegistry.DefaultBadPerformancePenaltySet(
            defaultInitData.badPerformancePenalty
        );
        vm.expectEmit(address(parametersRegistry));
        emit ICSParametersRegistry.DefaultPerformanceCoefficientsSet(
            defaultInitData.attestationsWeight,
            defaultInitData.blocksWeight,
            defaultInitData.syncWeight
        );
        vm.expectEmit(address(parametersRegistry));
        emit ICSParametersRegistry.DefaultQueueConfigSet(
            defaultInitData.defaultQueuePriority,
            defaultInitData.defaultQueueMaxDeposits
        );
        vm.expectEmit(address(parametersRegistry));
        emit ICSParametersRegistry.DefaultAllowedExitDelaySet(
            defaultInitData.defaultAllowedExitDelay
        );
        parametersRegistry.initialize(admin, defaultInitData);

        assertTrue(
            parametersRegistry.hasRole(
                parametersRegistry.DEFAULT_ADMIN_ROLE(),
                admin
            )
        );
        assertEq(
            parametersRegistry.defaultKeyRemovalCharge(),
            defaultInitData.keyRemovalCharge
        );
        assertEq(
            parametersRegistry.defaultElRewardsStealingAdditionalFine(),
            defaultInitData.elRewardsStealingAdditionalFine
        );
        assertEq(
            parametersRegistry.defaultKeysLimit(),
            defaultInitData.keysLimit
        );
        assertEq(
            parametersRegistry.defaultRewardShare(),
            defaultInitData.rewardShare
        );
        assertEq(
            parametersRegistry.defaultPerformanceLeeway(),
            defaultInitData.performanceLeeway
        );

        (uint256 lifetime, uint256 threshold) = parametersRegistry
            .defaultStrikesParams();

        assertEq(lifetime, defaultInitData.strikesLifetime);
        assertEq(threshold, defaultInitData.strikesThreshold);

        (uint256 priority, uint256 maxDeposits) = parametersRegistry
            .defaultQueueConfig();

        assertEq(priority, defaultInitData.defaultQueuePriority);
        assertEq(maxDeposits, defaultInitData.defaultQueueMaxDeposits);

        assertEq(
            parametersRegistry.defaultBadPerformancePenalty(),
            defaultInitData.badPerformancePenalty
        );

        (
            uint256 attestationsOut,
            uint256 blocksOut,
            uint256 syncOut
        ) = parametersRegistry.defaultPerformanceCoefficients();

        assertEq(attestationsOut, defaultInitData.attestationsWeight);
        assertEq(blocksOut, defaultInitData.blocksWeight);
        assertEq(syncOut, defaultInitData.syncWeight);

        assertEq(
            parametersRegistry.defaultAllowedExitDelay(),
            defaultInitData.defaultAllowedExitDelay
        );
    }

    function test_initialize_RevertWhen_ZeroAdminAddress() public {
        _enableInitializers(address(parametersRegistry));
        vm.expectRevert(ICSParametersRegistry.ZeroAdminAddress.selector);
        parametersRegistry.initialize(address(0), defaultInitData);
    }

    function test_initialize_RevertWhen_InvalidDefaultRewardShare() public {
        _enableInitializers(address(parametersRegistry));

        ICSParametersRegistry.InitializationData
            memory customInitData = defaultInitData;

        customInitData.rewardShare = 10001;

        vm.expectRevert(ICSParametersRegistry.InvalidRewardShareData.selector);
        parametersRegistry.initialize(admin, customInitData);
    }

    function test_initialize_RevertWhen_InvalidDefaultPerformanceLeeway()
        public
    {
        _enableInitializers(address(parametersRegistry));

        ICSParametersRegistry.InitializationData
            memory customInitData = defaultInitData;

        customInitData.performanceLeeway = 10001;

        vm.expectRevert(
            ICSParametersRegistry.InvalidPerformanceLeewayData.selector
        );
        parametersRegistry.initialize(admin, customInitData);
    }

    function test_initialize_RevertWhen_InvalidStrikesParams_zeroLifetime()
        public
    {
        _enableInitializers(address(parametersRegistry));

        ICSParametersRegistry.InitializationData
            memory customInitData = defaultInitData;

        customInitData.strikesLifetime = 0;
        customInitData.strikesThreshold = 1;

        vm.expectRevert(ICSParametersRegistry.InvalidStrikesParams.selector);
        parametersRegistry.initialize(admin, customInitData);
    }

    function test_initialize_RevertWhen_InvalidStrikesParams_zeroThreshold()
        public
    {
        _enableInitializers(address(parametersRegistry));

        ICSParametersRegistry.InitializationData
            memory customInitData = defaultInitData;

        customInitData.strikesLifetime = 1;
        customInitData.strikesThreshold = 0;

        vm.expectRevert(ICSParametersRegistry.InvalidStrikesParams.selector);
        parametersRegistry.initialize(admin, customInitData);
    }

    function test_initialize_RevertWhen_InvalidPriorityQueueId_QueueIdGreaterThanAllowed()
        public
    {
        _enableInitializers(address(parametersRegistry));

        ICSParametersRegistry.InitializationData
            memory customInitData = defaultInitData;

        customInitData.defaultQueuePriority =
            parametersRegistry.QUEUE_LOWEST_PRIORITY() +
            1;

        vm.expectRevert(ICSParametersRegistry.QueueCannotBeUsed.selector);
        parametersRegistry.initialize(admin, customInitData);
    }

    function test_initialize_RevertWhen_InvalidPriorityQueueId_QueueIdIsLegacyQueue()
        public
    {
        _enableInitializers(address(parametersRegistry));

        ICSParametersRegistry.InitializationData
            memory customInitData = defaultInitData;

        customInitData.defaultQueuePriority = parametersRegistry
            .QUEUE_LEGACY_PRIORITY();

        vm.expectRevert(ICSParametersRegistry.QueueCannotBeUsed.selector);
        parametersRegistry.initialize(admin, customInitData);
    }

    function test_initialize_RevertWhen_ZeroPriorityQueueMaxDeposits() public {
        _enableInitializers(address(parametersRegistry));

        ICSParametersRegistry.InitializationData
            memory customInitData = defaultInitData;

        customInitData.defaultQueueMaxDeposits = 0;

        vm.expectRevert(ICSParametersRegistry.ZeroMaxDeposits.selector);
        parametersRegistry.initialize(admin, customInitData);
    }

    function test_initialize_RevertWhen_InvalidPerformanceCoefficients()
        public
    {
        _enableInitializers(address(parametersRegistry));

        ICSParametersRegistry.InitializationData
            memory customInitData = defaultInitData;

        customInitData.attestationsWeight = 0;
        customInitData.blocksWeight = 0;
        customInitData.syncWeight = 0;

        vm.expectRevert(
            ICSParametersRegistry.InvalidPerformanceCoefficients.selector
        );
        parametersRegistry.initialize(admin, customInitData);
    }
}

abstract contract ParametersTest {
    function test_setDefault() public virtual;

    function test_setDefault_RevertWhen_notAdmin() public virtual;

    function test_set() public virtual;

    function test_set_RevertWhen_notAdmin() public virtual;

    function test_unset() public virtual;

    function test_unset_RevertWhen_notAdmin() public virtual;

    function test_get_usualData() public virtual;

    function test_get_defaultData() public virtual;
}

contract CSParametersRegistryBaseTestInitialized is
    CSParametersRegistryBaseTest
{
    function setUp() public virtual override {
        super.setUp();
        _enableInitializers(address(parametersRegistry));
        parametersRegistry.initialize(admin, defaultInitData);
    }
}

contract CSParametersRegistryRewardShareDataTest is
    CSParametersRegistryBaseTestInitialized,
    ParametersTest
{
    function test_setDefault() public override {
        uint256 rewardShare = 700;

        vm.expectEmit(address(parametersRegistry));
        emit ICSParametersRegistry.DefaultRewardShareSet(rewardShare);
        vm.prank(admin);
        parametersRegistry.setDefaultRewardShare(rewardShare);

        assertEq(parametersRegistry.defaultRewardShare(), rewardShare);
    }

    function test_setDefault_RevertWhen_InvalidRewardShareData() public {
        uint256 rewardShare = 70001;

        vm.expectRevert(ICSParametersRegistry.InvalidRewardShareData.selector);
        vm.prank(admin);
        parametersRegistry.setDefaultRewardShare(rewardShare);
    }

    function test_setDefault_RevertWhen_notAdmin() public override {
        uint256 rewardShare = 70001;

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.setDefaultRewardShare(rewardShare);
    }

    function test_set() public override {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](1);
        keyPivots[0] = 10;

        uint256[] memory rewardShares = new uint256[](2);
        rewardShares[0] = 10000;
        rewardShares[1] = 8000;

        ICSParametersRegistry.PivotsAndValues
            memory data = ICSParametersRegistry.PivotsAndValues({
                pivots: keyPivots,
                values: rewardShares
            });

        vm.expectEmit(address(parametersRegistry));
        emit ICSParametersRegistry.RewardShareDataSet(curveId, data);
        vm.prank(admin);
        parametersRegistry.setRewardShareData(curveId, data);
    }

    function test_set_RevertWhen_notAdmin() public override {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](1);
        keyPivots[0] = 10;

        uint256[] memory rewardShares = new uint256[](2);
        rewardShares[0] = 10000;
        rewardShares[1] = 8000;

        ICSParametersRegistry.PivotsAndValues
            memory data = ICSParametersRegistry.PivotsAndValues({
                pivots: keyPivots,
                values: rewardShares
            });

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.setRewardShareData(curveId, data);
    }

    function test_set_RevertWhen_invalidDataLength() public {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](2);
        keyPivots[0] = 10;
        keyPivots[1] = 100;

        uint256[] memory rewardShares = new uint256[](2);
        rewardShares[0] = 10000;
        rewardShares[1] = 8000;

        ICSParametersRegistry.PivotsAndValues
            memory data = ICSParametersRegistry.PivotsAndValues({
                pivots: keyPivots,
                values: rewardShares
            });

        vm.expectRevert(ICSParametersRegistry.InvalidPivotsAndValues.selector);
        vm.prank(admin);
        parametersRegistry.setRewardShareData(curveId, data);
    }

    function test_set_RevertWhen_invalidPivotsSort() public {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](2);
        keyPivots[0] = 100;
        keyPivots[1] = 10;

        uint256[] memory rewardShares = new uint256[](3);
        rewardShares[0] = 10000;
        rewardShares[1] = 8000;
        rewardShares[2] = 5000;

        ICSParametersRegistry.PivotsAndValues
            memory data = ICSParametersRegistry.PivotsAndValues({
                pivots: keyPivots,
                values: rewardShares
            });

        vm.expectRevert(ICSParametersRegistry.InvalidPivotsAndValues.selector);
        vm.prank(admin);
        parametersRegistry.setRewardShareData(curveId, data);
    }

    function test_set_RevertWhen_firstPivotIsZero() public {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](2);
        keyPivots[0] = 0;
        keyPivots[1] = 10;

        uint256[] memory rewardShares = new uint256[](3);
        rewardShares[0] = 10000;
        rewardShares[1] = 8000;
        rewardShares[2] = 5000;

        ICSParametersRegistry.PivotsAndValues
            memory data = ICSParametersRegistry.PivotsAndValues({
                pivots: keyPivots,
                values: rewardShares
            });

        vm.expectRevert(ICSParametersRegistry.InvalidPivotsAndValues.selector);
        vm.prank(admin);
        parametersRegistry.setRewardShareData(curveId, data);
    }

    function test_set_RevertWhen_invalidBpValues() public {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](1);
        keyPivots[0] = 10;

        uint256[] memory rewardShares = new uint256[](2);
        rewardShares[0] = 100000;
        rewardShares[1] = 8000;

        ICSParametersRegistry.PivotsAndValues
            memory data = ICSParametersRegistry.PivotsAndValues({
                pivots: keyPivots,
                values: rewardShares
            });

        vm.expectRevert(ICSParametersRegistry.InvalidPivotsAndValues.selector);
        vm.prank(admin);
        parametersRegistry.setRewardShareData(curveId, data);
    }

    function test_unset() public override {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](1);
        keyPivots[0] = 10;

        uint256[] memory rewardShares = new uint256[](2);
        rewardShares[0] = 10000;
        rewardShares[1] = 8000;

        ICSParametersRegistry.PivotsAndValues
            memory data = ICSParametersRegistry.PivotsAndValues({
                pivots: keyPivots,
                values: rewardShares
            });

        vm.prank(admin);
        parametersRegistry.setRewardShareData(curveId, data);

        ICSParametersRegistry.PivotsAndValues
            memory dataOut = parametersRegistry.getRewardShareData(curveId);

        assertEq(dataOut.pivots.length, keyPivots.length);
        for (uint256 i = 0; i < dataOut.pivots.length; ++i) {
            assertEq(dataOut.pivots[i], keyPivots[i]);
        }

        assertEq(dataOut.values.length, rewardShares.length);
        for (uint256 i = 0; i < dataOut.values.length; ++i) {
            assertEq(dataOut.values[i], rewardShares[i]);
        }

        vm.prank(admin);
        parametersRegistry.unsetRewardShareData(curveId);

        dataOut = parametersRegistry.getRewardShareData(curveId);

        assertEq(dataOut.pivots.length, 0);

        assertEq(dataOut.values.length, 1);
        assertEq(dataOut.values[0], defaultInitData.rewardShare);
    }

    function test_unset_RevertWhen_notAdmin() public override {
        uint256 curveId = 1;

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.unsetRewardShareData(curveId);
    }

    function test_get_usualData() public override {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](1);
        keyPivots[0] = 10;

        uint256[] memory rewardShares = new uint256[](2);
        rewardShares[0] = 10000;
        rewardShares[1] = 8000;

        ICSParametersRegistry.PivotsAndValues
            memory data = ICSParametersRegistry.PivotsAndValues({
                pivots: keyPivots,
                values: rewardShares
            });

        vm.prank(admin);
        parametersRegistry.setRewardShareData(curveId, data);

        ICSParametersRegistry.PivotsAndValues
            memory dataOut = parametersRegistry.getRewardShareData(curveId);

        assertEq(dataOut.pivots.length, keyPivots.length);
        for (uint256 i = 0; i < dataOut.pivots.length; ++i) {
            assertEq(dataOut.pivots[i], keyPivots[i]);
        }

        assertEq(dataOut.values.length, rewardShares.length);
        for (uint256 i = 0; i < dataOut.values.length; ++i) {
            assertEq(dataOut.values[i], rewardShares[i]);
        }
    }

    function test_get_noPivotsData() public {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](0);

        uint256[] memory rewardShares = new uint256[](1);
        rewardShares[0] = 8500;

        ICSParametersRegistry.PivotsAndValues
            memory data = ICSParametersRegistry.PivotsAndValues({
                pivots: keyPivots,
                values: rewardShares
            });

        vm.prank(admin);
        parametersRegistry.setRewardShareData(curveId, data);

        ICSParametersRegistry.PivotsAndValues
            memory dataOut = parametersRegistry.getRewardShareData(curveId);

        assertEq(dataOut.pivots.length, keyPivots.length);

        assertEq(dataOut.values.length, rewardShares.length);
        for (uint256 i = 0; i < dataOut.values.length; ++i) {
            assertEq(dataOut.values[i], rewardShares[i]);
        }
    }

    function test_get_defaultData() public view override {
        uint256 curveId = 10;

        ICSParametersRegistry.PivotsAndValues
            memory dataOut = parametersRegistry.getRewardShareData(curveId);

        assertEq(dataOut.pivots.length, 0);

        assertEq(dataOut.values.length, 1);
        assertEq(dataOut.values[0], defaultInitData.rewardShare);
    }
}

contract CSParametersRegistryPerformanceLeewayDataTest is
    CSParametersRegistryBaseTestInitialized,
    ParametersTest
{
    function test_setDefault() public override {
        uint256 leeway = 700;

        vm.expectEmit(address(parametersRegistry));
        emit ICSParametersRegistry.DefaultPerformanceLeewaySet(leeway);
        vm.prank(admin);
        parametersRegistry.setDefaultPerformanceLeeway(leeway);

        assertEq(parametersRegistry.defaultPerformanceLeeway(), leeway);
    }

    function test_setDefault_RevertWhen_notAdmin() public override {
        uint256 leeway = 700;

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.setDefaultPerformanceLeeway(leeway);
    }

    function test_setDefault_RevertWhen_InvalidRewardShareData() public {
        uint256 leeway = 20001;
        vm.expectRevert(
            ICSParametersRegistry.InvalidPerformanceLeewayData.selector
        );
        vm.prank(admin);
        parametersRegistry.setDefaultPerformanceLeeway(leeway);
    }

    function test_set() public override {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](1);
        keyPivots[0] = 100;

        uint256[] memory performanceLeeways = new uint256[](2);
        performanceLeeways[0] = 500;
        performanceLeeways[1] = 400;

        ICSParametersRegistry.PivotsAndValues
            memory data = ICSParametersRegistry.PivotsAndValues({
                pivots: keyPivots,
                values: performanceLeeways
            });

        vm.expectEmit(address(parametersRegistry));
        emit ICSParametersRegistry.PerformanceLeewayDataSet(curveId, data);
        vm.prank(admin);
        parametersRegistry.setPerformanceLeewayData(curveId, data);
    }

    function test_set_RevertWhen_notAdmin() public override {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](1);
        keyPivots[0] = 100;

        uint256[] memory performanceLeeways = new uint256[](2);
        performanceLeeways[0] = 500;
        performanceLeeways[1] = 400;

        ICSParametersRegistry.PivotsAndValues
            memory data = ICSParametersRegistry.PivotsAndValues({
                pivots: keyPivots,
                values: performanceLeeways
            });

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.setPerformanceLeewayData(curveId, data);
    }

    function test_set_RevertWhen_invalidDataLength() public {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](2);
        keyPivots[0] = 10;
        keyPivots[1] = 100;

        uint256[] memory performanceLeeways = new uint256[](2);
        performanceLeeways[0] = 500;
        performanceLeeways[1] = 400;

        ICSParametersRegistry.PivotsAndValues
            memory data = ICSParametersRegistry.PivotsAndValues({
                pivots: keyPivots,
                values: performanceLeeways
            });

        vm.expectRevert(ICSParametersRegistry.InvalidPivotsAndValues.selector);
        vm.prank(admin);
        parametersRegistry.setPerformanceLeewayData(curveId, data);
    }

    function test_set_RevertWhen_invalidPivotsSort() public {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](2);
        keyPivots[0] = 100;
        keyPivots[1] = 10;

        uint256[] memory performanceLeeways = new uint256[](3);
        performanceLeeways[0] = 500;
        performanceLeeways[1] = 400;
        performanceLeeways[2] = 300;

        ICSParametersRegistry.PivotsAndValues
            memory data = ICSParametersRegistry.PivotsAndValues({
                pivots: keyPivots,
                values: performanceLeeways
            });

        vm.expectRevert(ICSParametersRegistry.InvalidPivotsAndValues.selector);
        vm.prank(admin);
        parametersRegistry.setPerformanceLeewayData(curveId, data);
    }

    function test_set_RevertWhen_firstPivotIsZero() public {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](2);
        keyPivots[0] = 0;
        keyPivots[1] = 10;

        uint256[] memory performanceLeeways = new uint256[](3);
        performanceLeeways[0] = 500;
        performanceLeeways[1] = 400;
        performanceLeeways[2] = 300;

        ICSParametersRegistry.PivotsAndValues
            memory data = ICSParametersRegistry.PivotsAndValues({
                pivots: keyPivots,
                values: performanceLeeways
            });

        vm.expectRevert(ICSParametersRegistry.InvalidPivotsAndValues.selector);
        vm.prank(admin);
        parametersRegistry.setPerformanceLeewayData(curveId, data);
    }

    function test_set_RevertWhen_invalidBpValues() public {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](1);
        keyPivots[0] = 100;

        uint256[] memory performanceLeeways = new uint256[](2);
        performanceLeeways[0] = 50000;
        performanceLeeways[1] = 400;

        ICSParametersRegistry.PivotsAndValues
            memory data = ICSParametersRegistry.PivotsAndValues({
                pivots: keyPivots,
                values: performanceLeeways
            });

        vm.expectRevert(ICSParametersRegistry.InvalidPivotsAndValues.selector);
        vm.prank(admin);
        parametersRegistry.setPerformanceLeewayData(curveId, data);
    }

    function test_unset() public override {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](1);
        keyPivots[0] = 100;

        uint256[] memory performanceLeeways = new uint256[](2);
        performanceLeeways[0] = 450;
        performanceLeeways[1] = 400;

        ICSParametersRegistry.PivotsAndValues
            memory data = ICSParametersRegistry.PivotsAndValues({
                pivots: keyPivots,
                values: performanceLeeways
            });

        vm.prank(admin);
        parametersRegistry.setPerformanceLeewayData(curveId, data);

        ICSParametersRegistry.PivotsAndValues
            memory dataOut = parametersRegistry.getPerformanceLeewayData(
                curveId
            );

        assertEq(dataOut.pivots.length, keyPivots.length);
        for (uint256 i = 0; i < dataOut.pivots.length; ++i) {
            assertEq(dataOut.pivots[i], keyPivots[i]);
        }

        assertEq(dataOut.values.length, performanceLeeways.length);
        for (uint256 i = 0; i < dataOut.values.length; ++i) {
            assertEq(dataOut.values[i], performanceLeeways[i]);
        }

        vm.prank(admin);
        parametersRegistry.unsetPerformanceLeewayData(curveId);

        dataOut = parametersRegistry.getPerformanceLeewayData(curveId);

        assertEq(dataOut.pivots.length, 0);

        assertEq(dataOut.values.length, 1);
        assertEq(dataOut.values[0], defaultInitData.performanceLeeway);
    }

    function test_unset_RevertWhen_notAdmin() public override {
        uint256 curveId = 1;

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.unsetPerformanceLeewayData(curveId);
    }

    function test_get_usualData() public override {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](1);
        keyPivots[0] = 100;

        uint256[] memory performanceLeeways = new uint256[](2);
        performanceLeeways[0] = 500;
        performanceLeeways[1] = 400;

        ICSParametersRegistry.PivotsAndValues
            memory data = ICSParametersRegistry.PivotsAndValues({
                pivots: keyPivots,
                values: performanceLeeways
            });

        vm.prank(admin);
        parametersRegistry.setPerformanceLeewayData(curveId, data);

        ICSParametersRegistry.PivotsAndValues
            memory dataOut = parametersRegistry.getPerformanceLeewayData(
                curveId
            );

        assertEq(dataOut.pivots.length, keyPivots.length);
        for (uint256 i = 0; i < dataOut.pivots.length; ++i) {
            assertEq(dataOut.pivots[i], keyPivots[i]);
        }

        assertEq(dataOut.values.length, performanceLeeways.length);
        for (uint256 i = 0; i < dataOut.values.length; ++i) {
            assertEq(dataOut.values[i], performanceLeeways[i]);
        }
    }

    function test_get_noPivotsData() public {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](0);

        uint256[] memory performanceLeeways = new uint256[](1);
        performanceLeeways[0] = 450;

        ICSParametersRegistry.PivotsAndValues
            memory data = ICSParametersRegistry.PivotsAndValues({
                pivots: keyPivots,
                values: performanceLeeways
            });

        vm.prank(admin);
        parametersRegistry.setPerformanceLeewayData(curveId, data);

        ICSParametersRegistry.PivotsAndValues
            memory dataOut = parametersRegistry.getPerformanceLeewayData(
                curveId
            );

        assertEq(dataOut.pivots.length, keyPivots.length);

        assertEq(dataOut.values.length, performanceLeeways.length);
        for (uint256 i = 0; i < dataOut.values.length; ++i) {
            assertEq(dataOut.values[i], performanceLeeways[i]);
        }
    }

    function test_get_defaultData() public view override {
        uint256 curveId = 10;

        ICSParametersRegistry.PivotsAndValues
            memory dataOut = parametersRegistry.getPerformanceLeewayData(
                curveId
            );

        assertEq(dataOut.pivots.length, 0);

        assertEq(dataOut.values.length, 1);
        assertEq(dataOut.values[0], defaultInitData.performanceLeeway);
    }
}

contract CSParametersRegistryKeyRemovalChargeTest is
    CSParametersRegistryBaseTestInitialized,
    ParametersTest
{
    function test_setDefault() public override {
        uint256 charge = 1 ether;

        vm.expectEmit(address(parametersRegistry));
        emit ICSParametersRegistry.DefaultKeyRemovalChargeSet(charge);
        vm.prank(admin);
        parametersRegistry.setDefaultKeyRemovalCharge(charge);

        assertEq(parametersRegistry.defaultKeyRemovalCharge(), charge);
    }

    function test_setDefault_RevertWhen_notAdmin() public override {
        uint256 charge = 1 ether;

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.setDefaultKeyRemovalCharge(charge);
    }

    function test_set() public override {
        uint256 curveId = 1;
        uint256 charge = 1 ether;

        vm.expectEmit(address(parametersRegistry));
        emit ICSParametersRegistry.KeyRemovalChargeSet(curveId, charge);
        vm.prank(admin);
        parametersRegistry.setKeyRemovalCharge(curveId, charge);
    }

    function test_set_RevertWhen_notAdmin() public override {
        uint256 curveId = 1;
        uint256 charge = 1 ether;

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.setKeyRemovalCharge(curveId, charge);
    }

    function test_unset() public override {
        uint256 curveId = 1;
        uint256 charge = 1 ether;

        vm.prank(admin);
        parametersRegistry.setKeyRemovalCharge(curveId, charge);

        uint256 chargeOut = parametersRegistry.getKeyRemovalCharge(curveId);

        assertEq(chargeOut, charge);

        vm.prank(admin);
        parametersRegistry.unsetKeyRemovalCharge(curveId);

        chargeOut = parametersRegistry.getKeyRemovalCharge(curveId);

        assertEq(chargeOut, defaultInitData.keyRemovalCharge);
    }

    function test_unset_RevertWhen_notAdmin() public override {
        uint256 curveId = 1;

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.unsetKeyRemovalCharge(curveId);
    }

    function test_get_usualData() public override {
        uint256 curveId = 1;
        uint256 charge = 1 ether;

        vm.prank(admin);
        parametersRegistry.setKeyRemovalCharge(curveId, charge);

        uint256 chargeOut = parametersRegistry.getKeyRemovalCharge(curveId);

        assertEq(chargeOut, charge);
    }

    function test_get_defaultData() public view override {
        uint256 curveId = 10;
        uint256 chargeOut = parametersRegistry.getKeyRemovalCharge(curveId);

        assertEq(chargeOut, defaultInitData.keyRemovalCharge);
    }
}

contract CSParametersRegistryElRewardsStealingAdditionalFineTest is
    CSParametersRegistryBaseTestInitialized,
    ParametersTest
{
    function test_setDefault() public override {
        uint256 fine = 1 ether;

        vm.expectEmit(address(parametersRegistry));
        emit ICSParametersRegistry.DefaultElRewardsStealingAdditionalFineSet(
            fine
        );
        vm.prank(admin);
        parametersRegistry.setDefaultElRewardsStealingAdditionalFine(fine);

        assertEq(
            parametersRegistry.defaultElRewardsStealingAdditionalFine(),
            fine
        );
    }

    function test_setDefault_RevertWhen_notAdmin() public override {
        uint256 fine = 1 ether;

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.setDefaultElRewardsStealingAdditionalFine(fine);
    }

    function test_set() public override {
        uint256 curveId = 1;
        uint256 fine = 1 ether;

        vm.expectEmit(address(parametersRegistry));
        emit ICSParametersRegistry.ElRewardsStealingAdditionalFineSet(
            curveId,
            fine
        );
        vm.prank(admin);
        parametersRegistry.setElRewardsStealingAdditionalFine(curveId, fine);
    }

    function test_set_RevertWhen_notAdmin() public override {
        uint256 curveId = 1;
        uint256 fine = 1 ether;

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.setElRewardsStealingAdditionalFine(curveId, fine);
    }

    function test_unset() public override {
        uint256 curveId = 1;
        uint256 fine = 1 ether;

        vm.prank(admin);
        parametersRegistry.setElRewardsStealingAdditionalFine(curveId, fine);

        uint256 fineOut = parametersRegistry.getElRewardsStealingAdditionalFine(
            curveId
        );

        assertEq(fineOut, fine);

        vm.prank(admin);
        parametersRegistry.unsetElRewardsStealingAdditionalFine(curveId);

        fineOut = parametersRegistry.getElRewardsStealingAdditionalFine(
            curveId
        );

        assertEq(fineOut, defaultInitData.elRewardsStealingAdditionalFine);
    }

    function test_unset_RevertWhen_notAdmin() public override {
        uint256 curveId = 1;

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.unsetElRewardsStealingAdditionalFine(curveId);
    }

    function test_get_usualData() public override {
        uint256 curveId = 1;
        uint256 fine = 1 ether;

        vm.prank(admin);
        parametersRegistry.setElRewardsStealingAdditionalFine(curveId, fine);

        uint256 fineOut = parametersRegistry.getElRewardsStealingAdditionalFine(
            curveId
        );

        assertEq(fineOut, fine);
    }

    function test_get_defaultData() public view override {
        uint256 curveId = 10;
        uint256 fineOut = parametersRegistry.getElRewardsStealingAdditionalFine(
            curveId
        );

        assertEq(fineOut, defaultInitData.elRewardsStealingAdditionalFine);
    }
}

contract CSParametersRegistryKeysLimitTest is
    CSParametersRegistryBaseTestInitialized,
    ParametersTest
{
    function test_setDefault() public override {
        uint256 limit = 1000;

        vm.expectEmit(address(parametersRegistry));
        emit ICSParametersRegistry.DefaultKeysLimitSet(limit);
        vm.prank(admin);
        parametersRegistry.setDefaultKeysLimit(limit);

        assertEq(parametersRegistry.defaultKeysLimit(), limit);
    }

    function test_setDefault_RevertWhen_notAdmin() public override {
        uint256 limit = 1000;

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.setDefaultKeysLimit(limit);
    }

    function test_set() public override {
        uint256 curveId = 1;
        uint256 limit = 1000;

        vm.expectEmit(address(parametersRegistry));
        emit ICSParametersRegistry.KeysLimitSet(curveId, limit);
        vm.prank(admin);
        parametersRegistry.setKeysLimit(curveId, limit);
    }

    function test_set_RevertWhen_notAdmin() public override {
        uint256 curveId = 1;
        uint256 limit = 1000;

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.setKeysLimit(curveId, limit);
    }

    function test_unset() public override {
        uint256 curveId = 1;
        uint256 limit = 1000;

        vm.prank(admin);
        parametersRegistry.setKeysLimit(curveId, limit);

        uint256 limitOut = parametersRegistry.getKeysLimit(curveId);

        assertEq(limitOut, limit);

        vm.prank(admin);
        parametersRegistry.unsetKeysLimit(curveId);

        limitOut = parametersRegistry.getKeysLimit(curveId);

        assertEq(limitOut, defaultInitData.keysLimit);
    }

    function test_unset_RevertWhen_notAdmin() public override {
        uint256 curveId = 1;

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.unsetKeysLimit(curveId);
    }

    function test_get_usualData() public override {
        uint256 curveId = 1;
        uint256 limit = 1000;

        vm.prank(admin);
        parametersRegistry.setKeysLimit(curveId, limit);

        uint256 limitOut = parametersRegistry.getKeysLimit(curveId);

        assertEq(limitOut, limit);
    }

    function test_get_defaultData() public view override {
        uint256 curveId = 10;
        uint256 limitOut = parametersRegistry.getKeysLimit(curveId);

        assertEq(limitOut, defaultInitData.keysLimit);
    }
}

contract CSParametersRegistryStrikesParamsTest is
    CSParametersRegistryBaseTestInitialized,
    ParametersTest
{
    function test_setDefault() public override {
        uint256 lifetime = 12;
        uint256 threshold = 6;

        vm.expectEmit(address(parametersRegistry));
        emit ICSParametersRegistry.DefaultStrikesParamsSet(lifetime, threshold);
        vm.prank(admin);
        parametersRegistry.setDefaultStrikesParams(lifetime, threshold);

        (uint256 lifetimeOut, uint256 thresholdOut) = parametersRegistry
            .defaultStrikesParams();

        assertEq(lifetimeOut, lifetime);
        assertEq(thresholdOut, threshold);
    }

    function test_setDefault_RevertWhen_zeroLifetime() public {
        uint256 lifetime = 0;
        uint256 threshold = 1;

        vm.expectRevert(ICSParametersRegistry.InvalidStrikesParams.selector);
        vm.prank(admin);
        parametersRegistry.setDefaultStrikesParams(lifetime, threshold);
    }

    function test_setDefault_RevertWhen_zeroThreshold() public {
        uint256 lifetime = 1;
        uint256 threshold = 0;

        vm.expectRevert(ICSParametersRegistry.InvalidStrikesParams.selector);
        vm.prank(admin);
        parametersRegistry.setDefaultStrikesParams(lifetime, threshold);
    }

    function test_setDefault_RevertWhen_notAdmin() public override {
        uint256 lifetime = 12;
        uint256 threshold = 6;

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.setDefaultStrikesParams(lifetime, threshold);
    }

    function test_set() public override {
        uint256 curveId = 1;
        uint256 lifetime = 8;
        uint256 threshold = 2;

        vm.expectEmit(address(parametersRegistry));
        emit ICSParametersRegistry.StrikesParamsSet(
            curveId,
            lifetime,
            threshold
        );
        vm.prank(admin);
        parametersRegistry.setStrikesParams(curveId, lifetime, threshold);
    }

    function test_set_RevertWhen_zeroLifetime() public {
        uint256 curveId = 1;
        uint256 lifetime = 0;
        uint256 threshold = 0;

        vm.expectRevert(ICSParametersRegistry.InvalidStrikesParams.selector);
        vm.prank(admin);
        parametersRegistry.setStrikesParams(curveId, lifetime, threshold);
    }

    function test_set_RevertWhen_zeroThreshold() public {
        uint256 curveId = 1;
        uint256 lifetime = 1;
        uint256 threshold = 0;

        vm.expectRevert(ICSParametersRegistry.InvalidStrikesParams.selector);
        vm.prank(admin);
        parametersRegistry.setStrikesParams(curveId, lifetime, threshold);
    }

    function test_set_RevertWhen_notAdmin() public override {
        uint256 curveId = 1;
        uint256 lifetime = 3;
        uint256 threshold = 2;

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.setStrikesParams(curveId, lifetime, threshold);
    }

    function test_unset() public override {
        uint256 curveId = 1;
        uint256 lifetime = 3;
        uint256 threshold = 2;

        vm.prank(admin);
        parametersRegistry.setStrikesParams(curveId, lifetime, threshold);

        (uint256 lifetimeOut, uint256 thresholdOut) = parametersRegistry
            .getStrikesParams(curveId);

        assertEq(lifetimeOut, lifetime);
        assertEq(thresholdOut, threshold);

        vm.prank(admin);
        parametersRegistry.unsetStrikesParams(curveId);

        (lifetimeOut, thresholdOut) = parametersRegistry.getStrikesParams(
            curveId
        );

        assertEq(lifetimeOut, defaultInitData.strikesLifetime);
        assertEq(thresholdOut, defaultInitData.strikesThreshold);
    }

    function test_unset_RevertWhen_notAdmin() public override {
        uint256 curveId = 1;

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.unsetStrikesParams(curveId);
    }

    function test_get_usualData() public override {
        uint256 curveId = 1;
        uint256 lifetime = 3;
        uint256 threshold = 2;

        vm.prank(admin);
        parametersRegistry.setStrikesParams(curveId, lifetime, threshold);

        (uint256 lifetimeOut, uint256 thresholdOut) = parametersRegistry
            .getStrikesParams(curveId);

        assertEq(lifetimeOut, lifetime);
        assertEq(thresholdOut, threshold);
    }

    function test_get_defaultData() public view override {
        uint256 curveId = 10;
        (uint256 lifetimeOut, uint256 thresholdOut) = parametersRegistry
            .getStrikesParams(curveId);

        assertEq(lifetimeOut, defaultInitData.strikesLifetime);
        assertEq(thresholdOut, defaultInitData.strikesThreshold);
    }
}

contract CSParametersRegistryBadPerformancePenaltyTest is
    CSParametersRegistryBaseTestInitialized,
    ParametersTest
{
    function test_setDefault() public override {
        uint256 penalty = 1 ether;

        vm.expectEmit(address(parametersRegistry));
        emit ICSParametersRegistry.DefaultBadPerformancePenaltySet(penalty);
        vm.prank(admin);
        parametersRegistry.setDefaultBadPerformancePenalty(penalty);

        assertEq(parametersRegistry.defaultBadPerformancePenalty(), penalty);
    }

    function test_setDefault_RevertWhen_notAdmin() public override {
        uint256 penalty = 1 ether;

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.setDefaultBadPerformancePenalty(penalty);
    }

    function test_set() public override {
        uint256 curveId = 1;
        uint256 penalty = 1 ether;

        vm.expectEmit(address(parametersRegistry));
        emit ICSParametersRegistry.BadPerformancePenaltySet(curveId, penalty);
        vm.prank(admin);
        parametersRegistry.setBadPerformancePenalty(curveId, penalty);

        assertEq(parametersRegistry.getBadPerformancePenalty(curveId), penalty);
    }

    function test_set_RevertWhen_notAdmin() public override {
        uint256 curveId = 1;
        uint256 penalty = 1 ether;

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.setBadPerformancePenalty(curveId, penalty);
    }

    function test_unset() public override {
        uint256 curveId = 1;
        uint256 expectedPenalty = 1 ether;

        vm.prank(admin);
        parametersRegistry.setBadPerformancePenalty(curveId, expectedPenalty);

        uint256 penalty = parametersRegistry.getBadPerformancePenalty(curveId);

        assertEq(penalty, expectedPenalty);

        vm.prank(admin);
        parametersRegistry.unsetBadPerformancePenalty(curveId);

        penalty = parametersRegistry.getBadPerformancePenalty(curveId);

        assertEq(penalty, defaultInitData.badPerformancePenalty);
    }

    function test_unset_RevertWhen_notAdmin() public override {
        uint256 curveId = 1;

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.unsetBadPerformancePenalty(curveId);
    }

    function test_get_usualData() public override {
        uint256 curveId = 1;
        uint256 expectedPenalty = 1 ether;

        vm.prank(admin);
        parametersRegistry.setBadPerformancePenalty(curveId, expectedPenalty);

        uint256 penalty = parametersRegistry.getBadPerformancePenalty(curveId);

        assertEq(penalty, expectedPenalty);
    }

    function test_get_defaultData() public view override {
        uint256 curveId = 10;
        uint256 penalty = parametersRegistry.getBadPerformancePenalty(curveId);

        assertEq(penalty, defaultInitData.badPerformancePenalty);
    }
}

contract CSParametersRegistryPerformanceCoefficientsTest is
    CSParametersRegistryBaseTestInitialized,
    ParametersTest
{
    function test_setDefault() public override {
        uint256 attestations = 110;
        uint256 blocks = 25;
        uint256 sync = 10;

        vm.expectEmit(address(parametersRegistry));
        emit ICSParametersRegistry.DefaultPerformanceCoefficientsSet(
            attestations,
            blocks,
            sync
        );
        vm.prank(admin);
        parametersRegistry.setDefaultPerformanceCoefficients(
            attestations,
            blocks,
            sync
        );

        (
            uint256 attestationsOut,
            uint256 blocksOut,
            uint256 syncOut
        ) = parametersRegistry.defaultPerformanceCoefficients();

        assertEq(attestationsOut, attestations);
        assertEq(blocksOut, blocks);
        assertEq(syncOut, sync);
    }

    function test_setDefault_RevertWhen_notAdmin() public override {
        uint256 attestations = 110;
        uint256 blocks = 25;
        uint256 sync = 10;

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.setDefaultPerformanceCoefficients(
            attestations,
            blocks,
            sync
        );
    }

    function test_setDefault_RevertWhen_InvalidPerformanceCoefficients()
        public
    {
        uint256 attestations = 0;
        uint256 blocks = 0;
        uint256 sync = 0;

        vm.expectRevert(
            ICSParametersRegistry.InvalidPerformanceCoefficients.selector
        );
        vm.prank(admin);
        parametersRegistry.setDefaultPerformanceCoefficients(
            attestations,
            blocks,
            sync
        );
    }

    function test_set() public override {
        uint256 curveId = 1;
        uint256 attestations = 100;
        uint256 blocks = 20;
        uint256 sync = 5;

        vm.expectEmit(address(parametersRegistry));
        emit ICSParametersRegistry.PerformanceCoefficientsSet(
            curveId,
            attestations,
            blocks,
            sync
        );
        vm.prank(admin);
        parametersRegistry.setPerformanceCoefficients(
            curveId,
            attestations,
            blocks,
            sync
        );
    }

    function test_set_RevertWhen_notAdmin() public override {
        uint256 curveId = 1;
        uint256 attestations = 100;
        uint256 blocks = 20;
        uint256 sync = 5;

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.setPerformanceCoefficients(
            curveId,
            attestations,
            blocks,
            sync
        );
    }

    function test_set_RevertWhen_InvalidPerformanceCoefficients() public {
        uint256 curveId = 1;
        uint256 attestations = 0;
        uint256 blocks = 0;
        uint256 sync = 0;

        vm.expectRevert(
            ICSParametersRegistry.InvalidPerformanceCoefficients.selector
        );
        vm.prank(admin);
        parametersRegistry.setPerformanceCoefficients(
            curveId,
            attestations,
            blocks,
            sync
        );
    }

    function test_unset() public override {
        uint256 curveId = 1;
        uint256 attestations = 100;
        uint256 blocks = 20;
        uint256 sync = 5;

        vm.prank(admin);
        parametersRegistry.setPerformanceCoefficients(
            curveId,
            attestations,
            blocks,
            sync
        );

        (
            uint256 attestationsOut,
            uint256 blocksOut,
            uint256 syncOut
        ) = parametersRegistry.getPerformanceCoefficients(curveId);

        assertEq(attestationsOut, attestations);
        assertEq(blocksOut, blocks);
        assertEq(syncOut, sync);

        vm.prank(admin);
        parametersRegistry.unsetPerformanceCoefficients(curveId);

        (attestationsOut, blocksOut, syncOut) = parametersRegistry
            .getPerformanceCoefficients(curveId);

        assertEq(attestationsOut, defaultInitData.attestationsWeight);
        assertEq(blocksOut, defaultInitData.blocksWeight);
        assertEq(syncOut, defaultInitData.syncWeight);
    }

    function test_unset_RevertWhen_notAdmin() public override {
        uint256 curveId = 1;

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.unsetPerformanceCoefficients(curveId);
    }

    function test_get_usualData() public override {
        uint256 curveId = 1;
        uint256 attestations = 100;
        uint256 blocks = 20;
        uint256 sync = 5;

        vm.prank(admin);
        parametersRegistry.setPerformanceCoefficients(
            curveId,
            attestations,
            blocks,
            sync
        );

        (
            uint256 attestationsOut,
            uint256 blocksOut,
            uint256 syncOut
        ) = parametersRegistry.getPerformanceCoefficients(curveId);

        assertEq(attestationsOut, attestations);
        assertEq(blocksOut, blocks);
        assertEq(syncOut, sync);
    }

    function test_get_defaultData() public view override {
        uint256 curveId = 10;

        (
            uint256 attestationsOut,
            uint256 blocksOut,
            uint256 syncOut
        ) = parametersRegistry.getPerformanceCoefficients(curveId);

        assertEq(attestationsOut, defaultInitData.attestationsWeight);
        assertEq(blocksOut, defaultInitData.blocksWeight);
        assertEq(syncOut, defaultInitData.syncWeight);
    }
}

contract CSParametersRegistryQueueConfigTest is
    CSParametersRegistryBaseTestInitialized,
    ParametersTest
{
    function test_setDefault() public override {
        uint32 priority = 3;
        uint32 maxDeposits = 42;

        vm.expectEmit(address(parametersRegistry));
        emit ICSParametersRegistry.DefaultQueueConfigSet(priority, maxDeposits);
        vm.prank(admin);
        parametersRegistry.setDefaultQueueConfig(priority, maxDeposits);

        (uint256 priorityOut, uint256 maxDepositsOut) = parametersRegistry
            .defaultQueueConfig();
        assertEq(priorityOut, priority);
        assertEq(maxDepositsOut, maxDeposits);
    }

    function test_setDefault_RevertWhen_notAdmin() public override {
        uint32 priority = 3;
        uint32 maxDeposits = 42;

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.setDefaultQueueConfig(priority, maxDeposits);
    }

    function test_setDefault_RevertWhen_QueuePriorityIsLegacyQueue() public {
        uint32 priority = uint32(parametersRegistry.QUEUE_LEGACY_PRIORITY());
        uint32 maxDeposits = 42;

        vm.expectRevert(ICSParametersRegistry.QueueCannotBeUsed.selector);
        vm.prank(admin);
        parametersRegistry.setDefaultQueueConfig(priority, maxDeposits);
    }

    function test_setDefault_RevertWhen_QueuePriorityAboveLimit() public {
        uint32 priority = uint32(parametersRegistry.QUEUE_LOWEST_PRIORITY()) +
            1;
        uint32 maxDeposits = 42;

        vm.expectRevert(ICSParametersRegistry.QueueCannotBeUsed.selector);
        vm.prank(admin);
        parametersRegistry.setDefaultQueueConfig(priority, maxDeposits);
    }

    function test_setDefault_RevertWhen_ZeroMaxDeposits() public {
        uint32 priority = 1;
        uint32 maxDeposits = 0;

        vm.expectRevert(ICSParametersRegistry.ZeroMaxDeposits.selector);
        vm.prank(admin);
        parametersRegistry.setDefaultQueueConfig(priority, maxDeposits);
    }

    function test_set() public override {
        uint256 curveId = 11;
        uint32 priority = 3;
        uint32 maxDeposits = 42;

        vm.expectEmit(address(parametersRegistry));
        emit ICSParametersRegistry.QueueConfigSet(
            curveId,
            priority,
            maxDeposits
        );
        vm.prank(admin);
        parametersRegistry.setQueueConfig(
            curveId,
            ICSParametersRegistry.QueueConfig(priority, maxDeposits)
        );

        (uint256 priorityOut, uint256 maxDepositsOut) = parametersRegistry
            .getQueueConfig(curveId);
        assertEq(priorityOut, priority);
        assertEq(maxDepositsOut, maxDeposits);
    }

    function test_set_RevertWhen_notAdmin() public override {
        uint256 curveId = 11;
        uint32 priority = 3;
        uint32 maxDeposits = 42;

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.setQueueConfig(
            curveId,
            ICSParametersRegistry.QueueConfig(priority, maxDeposits)
        );
    }

    function test_unset() public override {
        uint256 curveId = 11;
        uint32 priority = 3;
        uint32 maxDeposits = 42;

        vm.prank(admin);
        parametersRegistry.setQueueConfig(
            curveId,
            ICSParametersRegistry.QueueConfig(priority, maxDeposits)
        );

        (uint256 priorityOut, uint256 maxDepositsOut) = parametersRegistry
            .getQueueConfig(curveId);
        assertEq(priorityOut, priority);
        assertEq(maxDepositsOut, maxDeposits);

        vm.expectEmit(address(parametersRegistry));
        emit ICSParametersRegistry.QueueConfigUnset(curveId);
        vm.prank(admin);
        parametersRegistry.unsetQueueConfig(curveId);

        (priorityOut, maxDepositsOut) = parametersRegistry.getQueueConfig(
            curveId
        );
        assertEq(priorityOut, defaultInitData.defaultQueuePriority);
        assertEq(maxDepositsOut, defaultInitData.defaultQueueMaxDeposits);
    }

    function test_unset_RevertWhen_notAdmin() public override {
        uint256 curveId = 11;
        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.unsetQueueConfig(curveId);
    }

    function test_get_usualData() public override {
        uint256 curveId = 11;
        uint32 priority = 3;
        uint32 maxDeposits = 42;

        vm.expectEmit(address(parametersRegistry));
        emit ICSParametersRegistry.QueueConfigSet(
            curveId,
            priority,
            maxDeposits
        );
        vm.prank(admin);
        parametersRegistry.setQueueConfig(
            curveId,
            ICSParametersRegistry.QueueConfig(priority, maxDeposits)
        );

        (uint256 priorityOut, uint256 maxDepositsOut) = parametersRegistry
            .getQueueConfig(curveId);
        assertEq(priorityOut, priority);
        assertEq(maxDepositsOut, maxDeposits);
    }

    function test_get_defaultData() public view override {
        uint256 curveId = 11;

        (uint256 priorityOut, uint256 maxDepositsOut) = parametersRegistry
            .getQueueConfig(curveId);
        assertEq(priorityOut, defaultInitData.defaultQueuePriority);
        assertEq(maxDepositsOut, defaultInitData.defaultQueueMaxDeposits);
    }

    function test_set_RevertWhen_QueuePriorityIsLegacyQueue() public {
        uint256 curveId = 11;
        uint32 priority = uint32(parametersRegistry.QUEUE_LEGACY_PRIORITY());
        uint32 maxDeposits = 42;

        vm.expectRevert(ICSParametersRegistry.QueueCannotBeUsed.selector);
        vm.prank(admin);
        parametersRegistry.setQueueConfig(
            curveId,
            ICSParametersRegistry.QueueConfig(priority, maxDeposits)
        );
    }

    function test_set_RevertWhen_QueuePriorityAboveLimit() public {
        uint256 curveId = 11;
        uint32 priority = uint32(parametersRegistry.QUEUE_LOWEST_PRIORITY()) +
            1;
        uint32 maxDeposits = 42;

        vm.expectRevert(ICSParametersRegistry.QueueCannotBeUsed.selector);
        vm.prank(admin);
        parametersRegistry.setQueueConfig(
            curveId,
            ICSParametersRegistry.QueueConfig(priority, maxDeposits)
        );
    }

    function test_set_RevertWhen_ZeroMaxDeposits() public {
        uint256 curveId = 11;
        uint32 priority = 1;
        uint32 maxDeposits = 0;

        vm.expectRevert(ICSParametersRegistry.ZeroMaxDeposits.selector);
        vm.prank(admin);
        parametersRegistry.setQueueConfig(
            curveId,
            ICSParametersRegistry.QueueConfig(priority, maxDeposits)
        );
    }
}

contract CSParametersRegistryAllowedExitDelayTest is
    CSParametersRegistryBaseTestInitialized,
    ParametersTest
{
    function test_setDefault() public override {
        uint256 delay = 7 days;

        vm.expectEmit(address(parametersRegistry));
        emit ICSParametersRegistry.DefaultAllowedExitDelaySet(delay);
        vm.prank(admin);
        parametersRegistry.setDefaultAllowedExitDelay(delay);

        assertEq(parametersRegistry.defaultAllowedExitDelay(), delay);
    }

    function test_setDefault_RevertWhen_notAdmin() public override {
        uint256 delay = 7 days;

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.setDefaultAllowedExitDelay(delay);
    }

    function test_set() public override {
        uint256 curveId = 1;
        uint256 delay = 3 days;

        vm.expectEmit(address(parametersRegistry));
        emit ICSParametersRegistry.AllowedExitDelaySet(curveId, delay);
        vm.prank(admin);
        parametersRegistry.setAllowedExitDelay(curveId, delay);
    }

    function test_set_RevertWhen_notAdmin() public override {
        uint256 curveId = 1;
        uint256 delay = 3 days;

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.setAllowedExitDelay(curveId, delay);
    }

    function test_unset() public override {
        uint256 curveId = 1;
        uint256 delay = 3 days;

        vm.prank(admin);
        parametersRegistry.setAllowedExitDelay(curveId, delay);

        uint256 delayOut = parametersRegistry.getAllowedExitDelay(curveId);

        assertEq(delayOut, delay);

        vm.prank(admin);
        parametersRegistry.unsetAllowedExitDelay(curveId);

        delayOut = parametersRegistry.getAllowedExitDelay(curveId);

        assertEq(delayOut, defaultInitData.defaultAllowedExitDelay);
    }

    function test_unset_RevertWhen_notAdmin() public override {
        uint256 curveId = 1;

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.unsetAllowedExitDelay(curveId);
    }

    function test_get_usualData() public override {
        uint256 curveId = 1;
        uint256 delay = 3 days;

        vm.prank(admin);
        parametersRegistry.setAllowedExitDelay(curveId, delay);

        uint256 delayOut = parametersRegistry.getAllowedExitDelay(curveId);

        assertEq(delayOut, delay);
    }

    function test_get_defaultData() public view override {
        uint256 curveId = 10;
        uint256 delayOut = parametersRegistry.getAllowedExitDelay(curveId);

        assertEq(delayOut, defaultInitData.defaultAllowedExitDelay);
    }
}
