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

        parametersRegistry = new CSParametersRegistry();

        defaultInitData = ICSParametersRegistry.InitializationData({
            keyRemovalCharge: 0.05 ether,
            elRewardsStealingAdditionalFine: 0.1 ether,
            priorityQueueLimit: 0,
            rewardShare: 8000,
            performanceLeeway: 500,
            strikesLifetime: 6,
            strikesThreshold: 3,
            badPerformancePenalty: 0.1 ether
        });
    }
}

contract CSParametersRegistryInitTest is CSParametersRegistryBaseTest {
    function test_constructor_RevertWhen_InitOnImpl() public {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        parametersRegistry.initialize(admin, defaultInitData);
    }

    function test_initialize_happyPath() public {
        _enableInitializers(address(parametersRegistry));

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
            parametersRegistry.defaultPriorityQueueLimit(),
            defaultInitData.priorityQueueLimit
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

        assertEq(
            parametersRegistry.defaultBadPerformancePenalty(),
            defaultInitData.badPerformancePenalty
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
        customInitData.strikesThreshold = 0;

        vm.expectRevert(ICSParametersRegistry.InvalidStrikesParams.selector);
        parametersRegistry.initialize(admin, customInitData);
    }

    function test_initialize_RevertWhen_InvalidStrikesParams_lifetimeLessThanThreshold()
        public
    {
        _enableInitializers(address(parametersRegistry));

        ICSParametersRegistry.InitializationData
            memory customInitData = defaultInitData;

        customInitData.strikesLifetime = 2;
        customInitData.strikesThreshold = 3;

        vm.expectRevert(ICSParametersRegistry.InvalidStrikesParams.selector);
        parametersRegistry.initialize(admin, customInitData);
    }
}

contract CSParametersRegistryRewardShareDataTest is
    CSParametersRegistryBaseTest
{
    function setUp() public virtual override {
        super.setUp();
        _enableInitializers(address(parametersRegistry));
        parametersRegistry.initialize(admin, defaultInitData);
    }

    function test_setDefaultRewardShare_set_valid_data() public {
        uint256 rewardShare = 700;
        vm.expectEmit(true, true, true, true, address(parametersRegistry));
        emit ICSParametersRegistry.DefaultRewardShareSet(rewardShare);
        vm.prank(admin);
        parametersRegistry.setDefaultRewardShare(rewardShare);

        assertEq(parametersRegistry.defaultRewardShare(), rewardShare);
    }

    function test_setDefaultRewardShare_RevertWhen_InvalidRewardShareData()
        public
    {
        uint256 rewardShare = 70001;
        vm.expectRevert(ICSParametersRegistry.InvalidRewardShareData.selector);
        vm.prank(admin);
        parametersRegistry.setDefaultRewardShare(rewardShare);
    }

    function test_setRewardShareData_set_valid_data() public {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](1);
        keyPivots[0] = 10;

        uint256[] memory rewardShares = new uint256[](2);
        rewardShares[0] = 10000;
        rewardShares[1] = 8000;

        vm.expectEmit(true, true, true, true, address(parametersRegistry));
        emit ICSParametersRegistry.RewardShareDataSet(curveId);
        vm.prank(admin);
        parametersRegistry.setRewardShareData(curveId, keyPivots, rewardShares);
    }

    function test_setRewardShareData_RevertWhen_not_admin() public {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](1);
        keyPivots[0] = 10;

        uint256[] memory rewardShares = new uint256[](2);
        rewardShares[0] = 10000;
        rewardShares[1] = 8000;

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.setRewardShareData(curveId, keyPivots, rewardShares);
    }

    function test_setRewardShareData_RevertWhen_invalid_data_length() public {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](2);
        keyPivots[0] = 10;
        keyPivots[1] = 100;

        uint256[] memory rewardShares = new uint256[](2);
        rewardShares[0] = 10000;
        rewardShares[1] = 8000;

        vm.expectRevert(ICSParametersRegistry.InvalidRewardShareData.selector);
        vm.prank(admin);
        parametersRegistry.setRewardShareData(curveId, keyPivots, rewardShares);
    }

    function test_setRewardShareData_RevertWhen_invalid_pivots_sort() public {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](2);
        keyPivots[0] = 100;
        keyPivots[1] = 10;

        uint256[] memory rewardShares = new uint256[](3);
        rewardShares[0] = 10000;
        rewardShares[1] = 8000;
        rewardShares[2] = 5000;

        vm.expectRevert(ICSParametersRegistry.InvalidRewardShareData.selector);
        vm.prank(admin);
        parametersRegistry.setRewardShareData(curveId, keyPivots, rewardShares);
    }

    function test_setRewardShareData_RevertWhen_first_pivot_is_zero() public {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](2);
        keyPivots[0] = 0;
        keyPivots[1] = 10;

        uint256[] memory rewardShares = new uint256[](3);
        rewardShares[0] = 10000;
        rewardShares[1] = 8000;
        rewardShares[2] = 5000;

        vm.expectRevert(ICSParametersRegistry.InvalidRewardShareData.selector);
        vm.prank(admin);
        parametersRegistry.setRewardShareData(curveId, keyPivots, rewardShares);
    }

    function test_setRewardShareData_RevertWhen_invalid_bp_values() public {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](1);
        keyPivots[0] = 10;

        uint256[] memory rewardShares = new uint256[](2);
        rewardShares[0] = 100000;
        rewardShares[1] = 8000;

        vm.expectRevert(ICSParametersRegistry.InvalidRewardShareData.selector);
        vm.prank(admin);
        parametersRegistry.setRewardShareData(curveId, keyPivots, rewardShares);
    }

    function test_unsetRewardShareData() public {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](1);
        keyPivots[0] = 10;

        uint256[] memory rewardShares = new uint256[](2);
        rewardShares[0] = 10000;
        rewardShares[1] = 8000;

        vm.prank(admin);
        parametersRegistry.setRewardShareData(curveId, keyPivots, rewardShares);

        (
            uint256[] memory keyPivotsOut,
            uint256[] memory rewardSharesOut
        ) = parametersRegistry.getRewardShareData(curveId);

        assertEq(keyPivotsOut.length, keyPivots.length);
        for (uint256 i = 0; i < keyPivotsOut.length; ++i) {
            assertEq(keyPivotsOut[i], keyPivots[i]);
        }

        assertEq(rewardSharesOut.length, rewardShares.length);
        for (uint256 i = 0; i < rewardSharesOut.length; ++i) {
            assertEq(rewardSharesOut[i], rewardShares[i]);
        }

        vm.prank(admin);
        parametersRegistry.unsetRewardShareData(curveId);

        (keyPivotsOut, rewardSharesOut) = parametersRegistry.getRewardShareData(
            curveId
        );

        assertEq(keyPivotsOut.length, 0);

        assertEq(rewardSharesOut.length, 1);
        assertEq(rewardSharesOut[0], defaultInitData.rewardShare);
    }

    function test_getRewardShareData_usual_data() public {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](1);
        keyPivots[0] = 10;

        uint256[] memory rewardShares = new uint256[](2);
        rewardShares[0] = 10000;
        rewardShares[1] = 8000;

        vm.prank(admin);
        parametersRegistry.setRewardShareData(curveId, keyPivots, rewardShares);

        (
            uint256[] memory keyPivotsOut,
            uint256[] memory rewardSharesOut
        ) = parametersRegistry.getRewardShareData(curveId);

        assertEq(keyPivotsOut.length, keyPivots.length);
        for (uint256 i = 0; i < keyPivotsOut.length; ++i) {
            assertEq(keyPivotsOut[i], keyPivots[i]);
        }

        assertEq(rewardSharesOut.length, rewardShares.length);
        for (uint256 i = 0; i < rewardSharesOut.length; ++i) {
            assertEq(rewardSharesOut[i], rewardShares[i]);
        }
    }

    function test_getRewardShareData_no_pivots_data() public {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](0);

        uint256[] memory rewardShares = new uint256[](1);
        rewardShares[0] = 8000;

        vm.prank(admin);
        parametersRegistry.setRewardShareData(curveId, keyPivots, rewardShares);

        (
            uint256[] memory keyPivotsOut,
            uint256[] memory rewardSharesOut
        ) = parametersRegistry.getRewardShareData(curveId);

        assertEq(keyPivotsOut.length, keyPivots.length);

        assertEq(rewardSharesOut.length, rewardShares.length);
        for (uint256 i = 0; i < rewardSharesOut.length; ++i) {
            assertEq(rewardSharesOut[i], rewardShares[i]);
        }
    }

    function test_getRewardShareData_default_data() public view {
        uint256 curveId = 10;

        (
            uint256[] memory keyPivotsOut,
            uint256[] memory rewardSharesOut
        ) = parametersRegistry.getRewardShareData(curveId);

        assertEq(keyPivotsOut.length, 0);

        assertEq(rewardSharesOut.length, 1);
        assertEq(rewardSharesOut[0], defaultInitData.rewardShare);
    }
}

contract CSParametersRegistryPerformanceLeewayDataTest is
    CSParametersRegistryBaseTest
{
    function setUp() public virtual override {
        super.setUp();
        _enableInitializers(address(parametersRegistry));
        parametersRegistry.initialize(admin, defaultInitData);
    }

    function test_setDefaultPerformanceLeewayData_set_valid_data() public {
        uint256 leeway = 700;
        vm.expectEmit(true, true, true, true, address(parametersRegistry));
        emit ICSParametersRegistry.DefaultPerformanceLeewaySet(leeway);
        vm.prank(admin);
        parametersRegistry.setDefaultPerformanceLeeway(leeway);

        assertEq(parametersRegistry.defaultPerformanceLeeway(), leeway);
    }

    function test_setDefaultPerformanceLeewayData_RevertWhen_InvalidRewardShareData()
        public
    {
        uint256 leeway = 20001;
        vm.expectRevert(
            ICSParametersRegistry.InvalidPerformanceLeewayData.selector
        );
        vm.prank(admin);
        parametersRegistry.setDefaultPerformanceLeeway(leeway);
    }

    function test_setPerformanceLeewayData_set_valid_data() public {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](1);
        keyPivots[0] = 100;

        uint256[] memory performanceLeeways = new uint256[](2);
        performanceLeeways[0] = 500;
        performanceLeeways[1] = 400;

        vm.expectEmit(true, true, true, true, address(parametersRegistry));
        emit ICSParametersRegistry.PerformanceLeewayDataSet(curveId);
        vm.prank(admin);
        parametersRegistry.setPerformanceLeewayData(
            curveId,
            keyPivots,
            performanceLeeways
        );
    }

    function test_setPerformanceLeewayData_RevertWhen_not_admin() public {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](1);
        keyPivots[0] = 100;

        uint256[] memory performanceLeeways = new uint256[](2);
        performanceLeeways[0] = 500;
        performanceLeeways[1] = 400;

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.setPerformanceLeewayData(
            curveId,
            keyPivots,
            performanceLeeways
        );
    }

    function test_setPerformanceLeewayData_RevertWhen_invalid_data_length()
        public
    {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](2);
        keyPivots[0] = 10;
        keyPivots[1] = 100;

        uint256[] memory performanceLeeways = new uint256[](2);
        performanceLeeways[0] = 500;
        performanceLeeways[1] = 400;

        vm.expectRevert(
            ICSParametersRegistry.InvalidPerformanceLeewayData.selector
        );
        vm.prank(admin);
        parametersRegistry.setPerformanceLeewayData(
            curveId,
            keyPivots,
            performanceLeeways
        );
    }

    function test_setPerformanceLeewayData_RevertWhen_invalid_pivots_sort()
        public
    {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](2);
        keyPivots[0] = 100;
        keyPivots[1] = 10;

        uint256[] memory performanceLeeways = new uint256[](3);
        performanceLeeways[0] = 500;
        performanceLeeways[1] = 400;
        performanceLeeways[2] = 300;

        vm.expectRevert(
            ICSParametersRegistry.InvalidPerformanceLeewayData.selector
        );
        vm.prank(admin);
        parametersRegistry.setPerformanceLeewayData(
            curveId,
            keyPivots,
            performanceLeeways
        );
    }

    function test_setPerformanceLeewayData_RevertWhen_first_pivot_is_zero()
        public
    {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](2);
        keyPivots[0] = 0;
        keyPivots[1] = 10;

        uint256[] memory performanceLeeways = new uint256[](3);
        performanceLeeways[0] = 500;
        performanceLeeways[1] = 400;
        performanceLeeways[2] = 300;

        vm.expectRevert(
            ICSParametersRegistry.InvalidPerformanceLeewayData.selector
        );
        vm.prank(admin);
        parametersRegistry.setPerformanceLeewayData(
            curveId,
            keyPivots,
            performanceLeeways
        );
    }

    function test_setPerformanceLeewayData_RevertWhen_invalid_bp_values()
        public
    {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](1);
        keyPivots[0] = 100;

        uint256[] memory performanceLeeways = new uint256[](2);
        performanceLeeways[0] = 50000;
        performanceLeeways[1] = 400;

        vm.expectRevert(
            ICSParametersRegistry.InvalidPerformanceLeewayData.selector
        );
        vm.prank(admin);
        parametersRegistry.setPerformanceLeewayData(
            curveId,
            keyPivots,
            performanceLeeways
        );
    }

    function test_unsetPerformanceLeewayData() public {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](1);
        keyPivots[0] = 100;

        uint256[] memory performanceLeeways = new uint256[](2);
        performanceLeeways[0] = 500;
        performanceLeeways[1] = 400;

        vm.prank(admin);
        parametersRegistry.setPerformanceLeewayData(
            curveId,
            keyPivots,
            performanceLeeways
        );

        (
            uint256[] memory keyPivotsOut,
            uint256[] memory performanceLeewaysOut
        ) = parametersRegistry.getPerformanceLeewayData(curveId);

        assertEq(keyPivotsOut.length, keyPivots.length);
        for (uint256 i = 0; i < keyPivotsOut.length; ++i) {
            assertEq(keyPivotsOut[i], keyPivots[i]);
        }

        assertEq(performanceLeewaysOut.length, performanceLeeways.length);
        for (uint256 i = 0; i < performanceLeewaysOut.length; ++i) {
            assertEq(performanceLeewaysOut[i], performanceLeeways[i]);
        }

        vm.prank(admin);
        parametersRegistry.unsetPerformanceLeewayData(curveId);

        (keyPivotsOut, performanceLeewaysOut) = parametersRegistry
            .getPerformanceLeewayData(curveId);

        assertEq(keyPivotsOut.length, 0);

        assertEq(performanceLeewaysOut.length, 1);
        assertEq(performanceLeewaysOut[0], defaultInitData.performanceLeeway);
    }

    function test_getPerformanceLeewayData_usual_data() public {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](1);
        keyPivots[0] = 100;

        uint256[] memory performanceLeeways = new uint256[](2);
        performanceLeeways[0] = 500;
        performanceLeeways[1] = 400;

        vm.prank(admin);
        parametersRegistry.setPerformanceLeewayData(
            curveId,
            keyPivots,
            performanceLeeways
        );

        (
            uint256[] memory keyPivotsOut,
            uint256[] memory performanceLeewaysOut
        ) = parametersRegistry.getPerformanceLeewayData(curveId);

        assertEq(keyPivotsOut.length, keyPivots.length);
        for (uint256 i = 0; i < keyPivotsOut.length; ++i) {
            assertEq(keyPivotsOut[i], keyPivots[i]);
        }

        assertEq(performanceLeewaysOut.length, performanceLeeways.length);
        for (uint256 i = 0; i < performanceLeewaysOut.length; ++i) {
            assertEq(performanceLeewaysOut[i], performanceLeeways[i]);
        }
    }

    function test_getPerformanceLeewayData_no_pivots_data() public {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](0);

        uint256[] memory performanceLeeways = new uint256[](1);
        performanceLeeways[0] = 500;

        vm.prank(admin);
        parametersRegistry.setPerformanceLeewayData(
            curveId,
            keyPivots,
            performanceLeeways
        );

        (
            uint256[] memory keyPivotsOut,
            uint256[] memory performanceLeewaysOut
        ) = parametersRegistry.getPerformanceLeewayData(curveId);

        assertEq(keyPivotsOut.length, keyPivots.length);

        assertEq(performanceLeewaysOut.length, performanceLeeways.length);
        for (uint256 i = 0; i < performanceLeewaysOut.length; ++i) {
            assertEq(performanceLeewaysOut[i], performanceLeeways[i]);
        }
    }

    function test_getPerformanceLeewayData_default_data() public view {
        uint256 curveId = 10;

        (
            uint256[] memory keyPivotsOut,
            uint256[] memory leewaysOut
        ) = parametersRegistry.getPerformanceLeewayData(curveId);

        assertEq(keyPivotsOut.length, 0);

        assertEq(leewaysOut.length, 1);
        assertEq(leewaysOut[0], defaultInitData.performanceLeeway);
    }
}

contract CSParametersRegistryPriorityQueueLimitTest is
    CSParametersRegistryBaseTest
{
    function setUp() public virtual override {
        super.setUp();
        _enableInitializers(address(parametersRegistry));
        parametersRegistry.initialize(admin, defaultInitData);
    }

    function test_setDefaultPriorityQueueLimit() public {
        uint256 limit = 154;
        vm.expectEmit(true, true, true, true, address(parametersRegistry));
        emit ICSParametersRegistry.DefaultPriorityQueueLimitSet(limit);
        vm.prank(admin);
        parametersRegistry.setDefaultPriorityQueueLimit(limit);

        assertEq(parametersRegistry.defaultPriorityQueueLimit(), limit);
    }

    function test_setPriorityQueueLimit_set_valid_data() public {
        uint256 curveId = 1;
        uint256 limit = 20;

        vm.expectEmit(true, true, true, true, address(parametersRegistry));
        emit ICSParametersRegistry.PriorityQueueLimitSet(curveId, limit);
        vm.prank(admin);
        parametersRegistry.setPriorityQueueLimit(curveId, limit);
    }

    function test_setPriorityQueueLimit_RevertWhen_not_admin() public {
        uint256 curveId = 1;
        uint256 limit = 20;

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.setPriorityQueueLimit(curveId, limit);
    }

    function test_unsetPriorityQueueLimit() public {
        uint256 curveId = 1;
        uint256 limit = 20;

        vm.prank(admin);
        parametersRegistry.setPriorityQueueLimit(curveId, limit);

        uint256 limitOut = parametersRegistry.getPriorityQueueLimit(curveId);

        assertEq(limitOut, limit);

        vm.prank(admin);
        parametersRegistry.unsetPriorityQueueLimit(curveId);

        limitOut = parametersRegistry.getPriorityQueueLimit(curveId);

        assertEq(limitOut, defaultInitData.priorityQueueLimit);
    }

    function test_getPriorityQueueLimit_usual_data() public {
        uint256 curveId = 1;
        uint256 limit = 20;

        vm.prank(admin);
        parametersRegistry.setPriorityQueueLimit(curveId, limit);

        uint256 limitOut = parametersRegistry.getPriorityQueueLimit(curveId);

        assertEq(limitOut, limit);
    }

    function test_getPriorityQueueLimit_default_data() public view {
        uint256 curveId = 10;
        uint256 limitOut = parametersRegistry.getPriorityQueueLimit(curveId);

        assertEq(limitOut, defaultInitData.priorityQueueLimit);
    }
}

contract CSParametersRegistryKeyRemovalChargeTest is
    CSParametersRegistryBaseTest
{
    function setUp() public virtual override {
        super.setUp();
        _enableInitializers(address(parametersRegistry));
        parametersRegistry.initialize(admin, defaultInitData);
    }

    function test_setDefaultKeyRemovalCharge() public {
        uint256 charge = 1 ether;
        vm.expectEmit(true, true, true, true, address(parametersRegistry));
        emit ICSParametersRegistry.DefaultKeyRemovalChargeSet(charge);
        vm.prank(admin);
        parametersRegistry.setDefaultKeyRemovalCharge(charge);

        assertEq(parametersRegistry.defaultKeyRemovalCharge(), charge);
    }

    function test_setKeyRemovalCharge_set_valid_data() public {
        uint256 curveId = 1;
        uint256 charge = 1 ether;

        vm.expectEmit(true, true, true, true, address(parametersRegistry));
        emit ICSParametersRegistry.KeyRemovalChargeSet(curveId, charge);
        vm.prank(admin);
        parametersRegistry.setKeyRemovalCharge(curveId, charge);
    }

    function test_setKeyRemovalCharge_RevertWhen_not_admin() public {
        uint256 curveId = 1;
        uint256 charge = 1 ether;

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.setKeyRemovalCharge(curveId, charge);
    }

    function test_unsetKeyRemovalCharge() public {
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

    function test_getKeyRemovalCharge_usual_data() public {
        uint256 curveId = 1;
        uint256 charge = 1 ether;

        vm.prank(admin);
        parametersRegistry.setKeyRemovalCharge(curveId, charge);

        uint256 chargeOut = parametersRegistry.getKeyRemovalCharge(curveId);

        assertEq(chargeOut, charge);
    }

    function test_getKeyRemovalCharge_default_data() public view {
        uint256 curveId = 10;
        uint256 chargeOut = parametersRegistry.getKeyRemovalCharge(curveId);

        assertEq(chargeOut, defaultInitData.keyRemovalCharge);
    }
}

contract CSParametersRegistryElRewardsStealingAdditionalFineTest is
    CSParametersRegistryBaseTest
{
    function setUp() public virtual override {
        super.setUp();
        _enableInitializers(address(parametersRegistry));
        parametersRegistry.initialize(admin, defaultInitData);
    }

    function test_setDefaultElRewardsStealingAdditionalFine() public {
        uint256 fine = 1 ether;
        vm.expectEmit(true, true, true, true, address(parametersRegistry));
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

    function test_setElRewardsStealingAdditionalFine_set_valid_data() public {
        uint256 curveId = 1;
        uint256 fine = 1 ether;

        vm.expectEmit(true, true, true, true, address(parametersRegistry));
        emit ICSParametersRegistry.ElRewardsStealingAdditionalFineSet(
            curveId,
            fine
        );
        vm.prank(admin);
        parametersRegistry.setElRewardsStealingAdditionalFine(curveId, fine);
    }

    function test_setElRewardsStealingAdditionalFine_RevertWhen_not_admin()
        public
    {
        uint256 curveId = 1;
        uint256 fine = 1 ether;

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.setElRewardsStealingAdditionalFine(curveId, fine);
    }

    function test_unsetElRewardsStealingAdditionalFine() public {
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

    function test_getElRewardsStealingAdditionalFine_usual_data() public {
        uint256 curveId = 1;
        uint256 fine = 1 ether;

        vm.prank(admin);
        parametersRegistry.setElRewardsStealingAdditionalFine(curveId, fine);

        uint256 fineOut = parametersRegistry.getElRewardsStealingAdditionalFine(
            curveId
        );

        assertEq(fineOut, fine);
    }

    function test_getElRewardsStealingAdditionalFine_default_data()
        public
        view
    {
        uint256 curveId = 10;
        uint256 fineOut = parametersRegistry.getElRewardsStealingAdditionalFine(
            curveId
        );

        assertEq(fineOut, defaultInitData.elRewardsStealingAdditionalFine);
    }
}

contract CSParametersRegistryStrikesParamsTest is CSParametersRegistryBaseTest {
    function setUp() public virtual override {
        super.setUp();
        _enableInitializers(address(parametersRegistry));
        parametersRegistry.initialize(admin, defaultInitData);
    }

    function test_setDefaultStrikesParams_happyPath() public {
        uint256 lifetime = 12;
        uint256 threshold = 6;

        vm.expectEmit(true, true, true, true, address(parametersRegistry));
        emit ICSParametersRegistry.DefaultStrikesParamsSet(lifetime, threshold);
        vm.prank(admin);
        parametersRegistry.setDefaultStrikesParams(lifetime, threshold);

        (uint256 lifetimeOut, uint256 thresholdOut) = parametersRegistry
            .defaultStrikesParams();

        assertEq(lifetimeOut, lifetime);
        assertEq(thresholdOut, threshold);
    }

    function test_setDefaultStrikesParams_revertWhen_zeroLifetime() public {
        uint256 lifetime = 0;
        uint256 threshold = 0;

        vm.expectRevert(ICSParametersRegistry.InvalidStrikesParams.selector);
        vm.prank(admin);
        parametersRegistry.setDefaultStrikesParams(lifetime, threshold);
    }

    function test_setDefaultStrikesParams_revertWhen_lifetimeLessThanThreshold()
        public
    {
        uint256 lifetime = 1;
        uint256 threshold = 2;

        vm.expectRevert(ICSParametersRegistry.InvalidStrikesParams.selector);
        vm.prank(admin);
        parametersRegistry.setDefaultStrikesParams(lifetime, threshold);
    }

    function test_setStrikesParams_revertWhen_zeroLifetime() public {
        uint256 curveId = 1;
        uint256 lifetime = 0;
        uint256 threshold = 0;

        vm.expectRevert(ICSParametersRegistry.InvalidStrikesParams.selector);
        vm.prank(admin);
        parametersRegistry.setStrikesParams(curveId, lifetime, threshold);
    }

    function test_setStrikesParams_revertWhen_lifetimeLessThanThreshold()
        public
    {
        uint256 curveId = 1;
        uint256 lifetime = 2;
        uint256 threshold = 3;

        vm.expectRevert(ICSParametersRegistry.InvalidStrikesParams.selector);
        vm.prank(admin);
        parametersRegistry.setStrikesParams(curveId, lifetime, threshold);
    }

    function test_setStrikesParams_RevertWhen_not_admin() public {
        uint256 curveId = 1;
        uint256 lifetime = 3;
        uint256 threshold = 2;

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.setStrikesParams(curveId, lifetime, threshold);
    }

    function test_unsetStrikesParams() public {
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

    function test_getStrikesParams_usual_data() public {
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

    function test_getStrikesParams_default_data() public view {
        uint256 curveId = 10;
        (uint256 lifetimeOut, uint256 thresholdOut) = parametersRegistry
            .getStrikesParams(curveId);

        assertEq(lifetimeOut, defaultInitData.strikesLifetime);
        assertEq(thresholdOut, defaultInitData.strikesThreshold);
    }
}

contract CSParametersRegistryBadPerformancePenaltyTest is
    CSParametersRegistryBaseTest
{
    function setUp() public virtual override {
        super.setUp();
        _enableInitializers(address(parametersRegistry));
        parametersRegistry.initialize(admin, defaultInitData);
    }

    function test_setDefaultBadPerformancePenalty() public {
        uint256 penalty = 1 ether;
        vm.expectEmit(true, true, true, true, address(parametersRegistry));
        emit ICSParametersRegistry.DefaultBadPerformancePenaltySet(penalty);
        vm.prank(admin);
        parametersRegistry.setDefaultBadPerformancePenalty(penalty);

        assertEq(parametersRegistry.defaultBadPerformancePenalty(), penalty);
    }

    function test_setDefaultBadPerformancePenalty_RevertWhen_not_admin()
        public
    {
        uint256 penalty = 1 ether;

        bytes32 role = parametersRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        parametersRegistry.setDefaultBadPerformancePenalty(penalty);
    }
}
