// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.24;

import "forge-std/Test.sol";

import { CSBenefitsRegistry } from "../src/CSBenefitsRegistry.sol";
import { ICSBenefitsRegistry } from "../src/interfaces/ICSBenefitsRegistry.sol";

import { Utilities } from "./helpers/Utilities.sol";
import { Fixtures } from "./helpers/Fixtures.sol";

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract CSBenefitsRegistryBaseTest is Test, Utilities, Fixtures {
    address internal admin;
    address internal stranger;

    CSBenefitsRegistry internal benefitsRegistry;

    function setUp() public virtual {
        admin = nextAddress("ADMIN");
        stranger = nextAddress("STRANGER");

        benefitsRegistry = new CSBenefitsRegistry();
    }
}

contract CSBenefitsRegistryInitTest is CSBenefitsRegistryBaseTest {
    function test_constructor_RevertWhen_InitOnImpl() public {
        vm.expectRevert(Initializable.InvalidInitialization.selector);
        benefitsRegistry.initialize(admin);
    }

    function test_initialize_happyPath() public {
        _enableInitializers(address(benefitsRegistry));

        benefitsRegistry.initialize(admin);

        assertTrue(
            benefitsRegistry.hasRole(
                benefitsRegistry.DEFAULT_ADMIN_ROLE(),
                admin
            )
        );
    }

    function test_initialize_RevertWhen_ZeroAdminAddress() public {
        _enableInitializers(address(benefitsRegistry));
        vm.expectRevert(ICSBenefitsRegistry.ZeroAdminAddress.selector);
        benefitsRegistry.initialize(address(0));
    }
}

contract CSBenefitsRegistryRewardShareDataTest is CSBenefitsRegistryBaseTest {
    function setUp() public virtual override {
        super.setUp();
        _enableInitializers(address(benefitsRegistry));
        benefitsRegistry.initialize(admin);
    }

    function test_setRewardShareData_set_valid_data() public {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](1);
        keyPivots[0] = 10;

        uint256[] memory rewardShares = new uint256[](2);
        rewardShares[0] = 10000;
        rewardShares[1] = 8000;

        vm.expectEmit(true, true, true, true, address(benefitsRegistry));
        emit ICSBenefitsRegistry.RewardShareDataSet(curveId);
        vm.prank(admin);
        benefitsRegistry.setRewardShareData(curveId, keyPivots, rewardShares);
    }

    function test_setRewardShareData_RevertWhen_not_admin() public {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](1);
        keyPivots[0] = 10;

        uint256[] memory rewardShares = new uint256[](2);
        rewardShares[0] = 10000;
        rewardShares[1] = 8000;

        bytes32 role = benefitsRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        benefitsRegistry.setRewardShareData(curveId, keyPivots, rewardShares);
    }

    function test_setRewardShareData_RevertWhen_invalid_data_length() public {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](2);
        keyPivots[0] = 10;
        keyPivots[1] = 100;

        uint256[] memory rewardShares = new uint256[](2);
        rewardShares[0] = 10000;
        rewardShares[1] = 8000;

        vm.expectRevert(ICSBenefitsRegistry.InvalidRewardShareData.selector);
        vm.prank(admin);
        benefitsRegistry.setRewardShareData(curveId, keyPivots, rewardShares);
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

        vm.expectRevert(ICSBenefitsRegistry.InvalidRewardShareData.selector);
        vm.prank(admin);
        benefitsRegistry.setRewardShareData(curveId, keyPivots, rewardShares);
    }

    function test_setRewardShareData_RevertWhen_invalid_bp_values() public {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](1);
        keyPivots[0] = 10;

        uint256[] memory rewardShares = new uint256[](2);
        rewardShares[0] = 100000;
        rewardShares[1] = 8000;

        vm.expectRevert(ICSBenefitsRegistry.InvalidRewardShareData.selector);
        vm.prank(admin);
        benefitsRegistry.setRewardShareData(curveId, keyPivots, rewardShares);
    }

    function test_getRewardShareData_usual_data() public {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](1);
        keyPivots[0] = 10;

        uint256[] memory rewardShares = new uint256[](2);
        rewardShares[0] = 10000;
        rewardShares[1] = 8000;

        vm.prank(admin);
        benefitsRegistry.setRewardShareData(curveId, keyPivots, rewardShares);

        (
            uint256[] memory keyPivotsOut,
            uint256[] memory rewardSharesOut
        ) = benefitsRegistry.getRewardShareData(curveId);

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
        benefitsRegistry.setRewardShareData(curveId, keyPivots, rewardShares);

        (
            uint256[] memory keyPivotsOut,
            uint256[] memory rewardSharesOut
        ) = benefitsRegistry.getRewardShareData(curveId);

        assertEq(keyPivotsOut.length, keyPivots.length);

        assertEq(rewardSharesOut.length, rewardShares.length);
        for (uint256 i = 0; i < rewardSharesOut.length; ++i) {
            assertEq(rewardSharesOut[i], rewardShares[i]);
        }
    }

    function test_getRewardShareData_RevertWhen_no_data() public {
        uint256 curveId = 0;
        vm.expectRevert(ICSBenefitsRegistry.NoData.selector);
        (
            uint256[] memory keyPivotsOut,
            uint256[] memory rewardSharesOut
        ) = benefitsRegistry.getRewardShareData(curveId);
    }
}

contract CSBenefitsRegistryPerformanceLeewayDataTest is
    CSBenefitsRegistryBaseTest
{
    function setUp() public virtual override {
        super.setUp();
        _enableInitializers(address(benefitsRegistry));
        benefitsRegistry.initialize(admin);
    }

    function test_setPerformanceLeewayData_set_valid_data() public {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](1);
        keyPivots[0] = 100;

        uint256[] memory performanceLeeways = new uint256[](2);
        performanceLeeways[0] = 500;
        performanceLeeways[1] = 400;

        vm.expectEmit(true, true, true, true, address(benefitsRegistry));
        emit ICSBenefitsRegistry.PerformanceLeewayDataSet(curveId);
        vm.prank(admin);
        benefitsRegistry.setPerformanceLeewayData(
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

        bytes32 role = benefitsRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        benefitsRegistry.setPerformanceLeewayData(
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

        vm.expectRevert(ICSBenefitsRegistry.InvalidRewardShareData.selector);
        vm.prank(admin);
        benefitsRegistry.setPerformanceLeewayData(
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

        vm.expectRevert(ICSBenefitsRegistry.InvalidRewardShareData.selector);
        vm.prank(admin);
        benefitsRegistry.setPerformanceLeewayData(
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

        vm.expectRevert(ICSBenefitsRegistry.InvalidRewardShareData.selector);
        vm.prank(admin);
        benefitsRegistry.setPerformanceLeewayData(
            curveId,
            keyPivots,
            performanceLeeways
        );
    }

    function test_getPerformanceLeewayData_usual_data() public {
        uint256 curveId = 1;
        uint256[] memory keyPivots = new uint256[](1);
        keyPivots[0] = 100;

        uint256[] memory performanceLeeways = new uint256[](2);
        performanceLeeways[0] = 500;
        performanceLeeways[1] = 400;

        vm.prank(admin);
        benefitsRegistry.setPerformanceLeewayData(
            curveId,
            keyPivots,
            performanceLeeways
        );

        (
            uint256[] memory keyPivotsOut,
            uint256[] memory performanceLeewaysOut
        ) = benefitsRegistry.getPerformanceLeewayData(curveId);

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
        benefitsRegistry.setPerformanceLeewayData(
            curveId,
            keyPivots,
            performanceLeeways
        );

        (
            uint256[] memory keyPivotsOut,
            uint256[] memory performanceLeewaysOut
        ) = benefitsRegistry.getPerformanceLeewayData(curveId);

        assertEq(keyPivotsOut.length, keyPivots.length);

        assertEq(performanceLeewaysOut.length, performanceLeeways.length);
        for (uint256 i = 0; i < performanceLeewaysOut.length; ++i) {
            assertEq(performanceLeewaysOut[i], performanceLeeways[i]);
        }
    }

    function test_getPerformanceLeewayData_RevertWhen_no_data() public {
        uint256 curveId = 0;
        vm.expectRevert(ICSBenefitsRegistry.NoData.selector);
        (
            uint256[] memory keyPivotsOut,
            uint256[] memory performanceLeewaysOut
        ) = benefitsRegistry.getPerformanceLeewayData(curveId);
    }
}

contract CSBenefitsRegistryPriorityQueueLimitTest is
    CSBenefitsRegistryBaseTest
{
    function setUp() public virtual override {
        super.setUp();
        _enableInitializers(address(benefitsRegistry));
        benefitsRegistry.initialize(admin);
    }

    function test_setPriorityQueueLimit_set_valid_data() public {
        uint256 curveId = 1;
        uint256 limit = 20;

        vm.expectEmit(true, true, true, true, address(benefitsRegistry));
        emit ICSBenefitsRegistry.PriorityQueueLimitSet(curveId, limit);
        vm.prank(admin);
        benefitsRegistry.setPriorityQueueLimit(curveId, limit);
    }

    function test_setPriorityQueueLimit_RevertWhen_not_admin() public {
        uint256 curveId = 1;
        uint256 limit = 20;

        bytes32 role = benefitsRegistry.DEFAULT_ADMIN_ROLE();
        expectRoleRevert(stranger, role);
        vm.prank(stranger);
        benefitsRegistry.setPriorityQueueLimit(curveId, limit);
    }

    function test_getPerformanceLeewayData_usual_data() public {
        uint256 curveId = 1;
        uint256 limit = 20;

        vm.prank(admin);
        benefitsRegistry.setPriorityQueueLimit(curveId, limit);

        uint256 limitOut = benefitsRegistry.getPriorityQueueLimit(curveId);

        assertEq(limitOut, limit);
    }

    function test_getPerformanceLeewayData_default_return() public {
        uint256 curveId = 0;
        uint256 limitOut = benefitsRegistry.getPriorityQueueLimit(curveId);

        assertEq(limitOut, 0);
    }
}
