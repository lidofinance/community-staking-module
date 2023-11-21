// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.21;

import "forge-std/Test.sol";

import { CSAccountingBase, CSAccounting } from "../src/CSAccounting.sol";
import { CSBondCurve } from "../src/CSBondCurve.sol";
import { PermitTokenBase } from "./helpers/Permit.sol";
import { Stub } from "./helpers/mocks/Stub.sol";
import { LidoMock } from "./helpers/mocks/LidoMock.sol";
import { WstETHMock } from "./helpers/mocks/WstETHMock.sol";
import { LidoLocatorMock } from "./helpers/mocks/LidoLocatorMock.sol";
import { CommunityStakingModuleMock } from "./helpers/mocks/CommunityStakingModuleMock.sol";
import { CommunityStakingFeeDistributorMock } from "./helpers/mocks/CommunityStakingFeeDistributorMock.sol";
import { WithdrawalQueueMockBase, WithdrawalQueueMock } from "./helpers/mocks/WithdrawalQueueMock.sol";

import { Fixtures } from "./helpers/Fixtures.sol";

contract CSAccounting_revealed is CSAccounting {
    constructor(
        uint256[] memory bondCurve,
        address admin,
        address lidoLocator,
        address wstETH,
        address communityStakingModule,
        uint256 blockedBondRetentionPeriod,
        uint256 blockedBondManagementPeriod
    )
        CSAccounting(
            bondCurve,
            admin,
            lidoLocator,
            wstETH,
            communityStakingModule,
            blockedBondRetentionPeriod,
            blockedBondManagementPeriod
        )
    {}

    function setBondCurve() public {
        uint256[] memory _bondCurve = new uint256[](11);
        _bondCurve[0] = 2 ether;
        _bondCurve[1] = 3.90 ether; // 1.9
        _bondCurve[2] = 5.70 ether; // 1.8
        _bondCurve[3] = 7.40 ether; // 1.7
        _bondCurve[4] = 9.00 ether; // 1.6
        _bondCurve[5] = 10.50 ether; // 1.5
        _bondCurve[6] = 11.90 ether; // 1.4
        _bondCurve[7] = 13.10 ether; // 1.3
        _bondCurve[8] = 14.30 ether; // 1.2
        _bondCurve[9] = 15.40 ether; // 1.1
        _bondCurve[10] = 16.40 ether; // 1.0
        bondCurve = _bondCurve;
    }
}

contract CSAccountingTest is
    Test,
    Fixtures,
    PermitTokenBase,
    CSAccountingBase,
    WithdrawalQueueMockBase
{
    LidoLocatorMock internal locator;
    WstETHMock internal wstETH;
    LidoMock internal stETH;
    WithdrawalQueueMock internal wq;

    Stub internal burner;

    CSAccounting_revealed public accounting;
    CommunityStakingModuleMock public stakingModule;
    CommunityStakingFeeDistributorMock public feeDistributor;

    address internal admin;
    address internal user;
    address internal stranger;

    function setUp() public {
        admin = address(1);

        user = address(2);
        stranger = address(777);

        (locator, wstETH, stETH, burner) = initLido();

        stakingModule = new CommunityStakingModuleMock();
        uint256[] memory curve = new uint256[](2);
        curve[0] = 2 ether;
        curve[1] = 4 ether;
        accounting = new CSAccounting_revealed(
            curve,
            admin,
            address(locator),
            address(wstETH),
            address(stakingModule),
            8 weeks,
            1 days
        );
        feeDistributor = new CommunityStakingFeeDistributorMock(
            address(locator),
            address(accounting)
        );
        vm.startPrank(admin);
        accounting.setFeeDistributor(address(feeDistributor));
        accounting.grantRole(accounting.INSTANT_PENALIZE_BOND_ROLE(), admin);
        accounting.grantRole(
            accounting.EL_REWARDS_STEALING_PENALTY_INIT_ROLE(),
            admin
        );
        accounting.grantRole(
            accounting.EL_REWARDS_STEALING_PENALTY_SETTLE_ROLE(),
            admin
        );
        accounting.grantRole(accounting.SET_BOND_CURVE_ROLE(), admin);
        accounting.grantRole(accounting.SET_BOND_MULTIPLIER_ROLE(), admin);
        vm.stopPrank();
    }

    function test_setBondCurve() public {
        uint256[] memory _bondCurve = new uint256[](2);
        _bondCurve[0] = 2 ether;
        _bondCurve[1] = 4 ether;

        vm.prank(admin);
        accounting.setBondCurve(_bondCurve);

        assertEq(accounting.bondCurve(0), 2 ether);
        assertEq(accounting.bondCurve(1), 4 ether);
    }

    function test_setBondCurve_RevertWhen_DoesNotHaveRole() public {
        uint256[] memory _bondCurve = new uint256[](2);
        _bondCurve[0] = 2 ether;
        _bondCurve[1] = 4 ether;

        vm.expectRevert(
            "AccessControl: account 0x7fa9385be102ac3eac297483dd6233d62b3e1496 is missing role 0x645c9e6d2a86805cb5a28b1e4751c0dab493df7cf935070ce405489ba1a7bf72"
        );

        accounting.setBondCurve(_bondCurve);
    }

    function test_setBondMultiplier() public {
        vm.prank(admin);
        accounting.setBondMultiplier(0, 9500); // 0.95

        assertEq(accounting.getBondMultiplier(0), 9500);
    }

    function test_setBondMultiplier_RevertWhen_DoesNotHaveRole() public {
        vm.expectRevert(
            "AccessControl: account 0x7fa9385be102ac3eac297483dd6233d62b3e1496 is missing role 0x62131145aee19b18b85aa8ead52ba87f0efb6e61e249155edc68a2c24e8f79b5"
        );

        accounting.setBondMultiplier(0, 9500); // 0.95
    }

    function test_totalBondShares() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        accounting.depositETH{ value: 32 ether }(user, 0);
        uint256 sharesToDeposit = stETH.getSharesByPooledEth(32 ether);
        assertEq(accounting.totalBondShares(), sharesToDeposit);
    }

    function test_getRequiredBondETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        assertEq(accounting.getRequiredBondETH(0, 0), 32 ether);
    }

    function test_getRequiredBondStETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        assertEq(accounting.getRequiredBondStETH(0, 0), 32 ether);
    }

    function test_getRequiredBondWstETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        assertEq(
            accounting.getRequiredBondWstETH(0, 0),
            stETH.getSharesByPooledEth(32 ether)
        );
    }

    function test_getRequiredBondETH_OneWithdrawnValidator() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 1 });
        assertEq(accounting.getRequiredBondETH(0, 0), 30 ether);
    }

    function test_getRequiredBondStETH_OneWithdrawnValidator() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 1 });
        assertEq(accounting.getRequiredBondStETH(0, 0), 30 ether);
    }

    function test_getRequiredBondWstETH_OneWithdrawnValidator() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 1 });
        assertEq(
            accounting.getRequiredBondWstETH(0, 0),
            stETH.getSharesByPooledEth(30 ether)
        );
    }

    function test_getRequiredBondETH_OneWithdrawnOneAddedValidator() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 1 });
        assertEq(accounting.getRequiredBondETH(0, 1), 32 ether);
    }

    function test_getRequiredBondStETH_OneWithdrawnOneAddedValidator() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 1 });
        assertEq(accounting.getRequiredBondStETH(0, 1), 32 ether);
    }

    function test_getRequiredBondWstETH_OneWithdrawnOneAddedValidator() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 1 });
        assertEq(
            accounting.getRequiredBondWstETH(0, 1),
            stETH.getSharesByPooledEth(32 ether)
        );
    }

    function test_getRequiredBondETH_WithExcessBond() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 64 ether);
        vm.startPrank(user);
        accounting.depositETH{ value: 63 ether }(user, 0);
        assertApproxEqAbs(
            accounting.getRequiredBondETH(0, 16),
            1 ether,
            1, // max accuracy error
            "required ETH should be ~1 ether for the next 16 validators to deposit"
        );
    }

    function test_getRequiredBondStETH_WithExcessBond() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 64 ether);
        vm.startPrank(user);
        stETH.submit{ value: 64 ether }({ _referal: address(0) });
        accounting.depositStETH(user, 0, 63 ether);
        assertApproxEqAbs(
            accounting.getRequiredBondStETH(0, 16),
            1 ether,
            1, // max accuracy error
            "required stETH should be ~1 ether for the next 16 validators to deposit"
        );
    }

    function test_getRequiredBondWstETH_WithExcessBond() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 64 ether);
        vm.startPrank(user);
        stETH.submit{ value: 64 ether }({ _referal: address(0) });
        uint256 amount = wstETH.wrap(63 ether);
        accounting.depositWstETH(user, 0, amount);
        assertApproxEqAbs(
            accounting.getRequiredBondWstETH(0, 16),
            stETH.getSharesByPooledEth(1 ether),
            2, // max accuracy error
            "required wstETH should be ~1 ether for the next 16 validators to deposit"
        );
    }

    function test_getRequiredBondETHForKeys() public {
        assertEq(accounting.getRequiredBondETHForKeys(1), 2 ether);
    }

    function test_getRequiredBondStETHForKeys() public {
        assertEq(accounting.getRequiredBondStETHForKeys(1), 2 ether);
    }

    function test_getRequiredBondWstETHForKeys() public {
        assertEq(
            accounting.getRequiredBondWstETHForKeys(1),
            stETH.getSharesByPooledEth(2 ether)
        );
    }

    function test_depositETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 32 ether);
        uint256 sharesToDeposit = stETH.getSharesByPooledEth(32 ether);

        vm.expectEmit(true, true, true, true, address(accounting));
        emit ETHBondDeposited(0, user, 32 ether);

        vm.prank(user);
        accounting.depositETH{ value: 32 ether }(user, 0);

        assertEq(
            address(user).balance,
            0,
            "user balance should be 0 after deposit"
        );
        assertEq(
            accounting.getBondShares(0),
            sharesToDeposit,
            "bond shares should be equal to deposited shares"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            sharesToDeposit,
            "bond manager shares should be equal to deposited shares"
        );
    }

    function test_depositETH_CoverSeveralValidators() public {
        _createNodeOperator({ ongoingVals: 1, withdrawnVals: 0 });
        vm.deal(user, 32 ether);

        uint256 required = accounting.getRequiredBondETHForKeys(1);
        vm.startPrank(user);
        accounting.depositETH{ value: required }(user, 0);

        assertApproxEqAbs(
            accounting.getRequiredBondETH(0, 0),
            0,
            1, // max accuracy error
            "required ETH should be ~0 for 1 deposited validator"
        );

        required = accounting.getRequiredBondETH(0, 1);
        accounting.depositETH{ value: required }(user, 0);
        stakingModule.addValidator(0, 1);

        assertApproxEqAbs(
            accounting.getRequiredBondETH(0, 0),
            0,
            1, // max accuracy error
            "required ETH should be ~0 for 2 deposited validators"
        );
    }

    function test_depositStETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        uint256 sharesToDeposit = stETH.submit{ value: 32 ether }({
            _referal: address(0)
        });

        vm.expectEmit(true, true, true, true, address(accounting));
        emit StETHBondDeposited(0, user, 32 ether);

        accounting.depositStETH(user, 0, 32 ether);

        assertEq(
            stETH.balanceOf(user),
            0,
            "user balance should be 0 after deposit"
        );
        assertEq(
            accounting.getBondShares(0),
            sharesToDeposit,
            "bond shares should be equal to deposited shares"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            sharesToDeposit,
            "bond manager shares should be equal to deposited shares"
        );
    }

    function test_depositStETH_CoverSeveralValidators() public {
        _createNodeOperator({ ongoingVals: 1, withdrawnVals: 0 });
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });

        uint256 required = accounting.getRequiredBondStETHForKeys(1);
        accounting.depositStETH(user, 0, required);

        assertApproxEqAbs(
            accounting.getRequiredBondStETH(0, 0),
            0,
            1, // max accuracy error
            "required stETH should be ~0 for 1 deposited validator"
        );

        required = accounting.getRequiredBondStETH(0, 1);
        accounting.depositStETH(user, 0, required);
        stakingModule.addValidator(0, 1);
        assertApproxEqAbs(
            accounting.getRequiredBondStETH(0, 0),
            0,
            1, // max accuracy error
            "required stETH should be ~0 for 2 deposited validators"
        );
    }

    function test_depositWstETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        uint256 wstETHAmount = wstETH.wrap(32 ether);
        uint256 sharesToDeposit = stETH.getSharesByPooledEth(
            wstETH.getStETHByWstETH(wstETHAmount)
        );

        vm.expectEmit(true, true, true, true, address(accounting));
        emit WstETHBondDeposited(0, user, wstETHAmount);

        accounting.depositWstETH(user, 0, wstETHAmount);

        assertEq(
            wstETH.balanceOf(user),
            0,
            "user balance should be 0 after deposit"
        );
        assertEq(
            accounting.getBondShares(0),
            sharesToDeposit,
            "bond shares should be equal to deposited shares"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            sharesToDeposit,
            "bond manager shares should be equal to deposited shares"
        );
    }

    function test_depositWstETH_CoverSeveralValidators() public {
        _createNodeOperator({ ongoingVals: 1, withdrawnVals: 0 });
        vm.startPrank(user);
        vm.deal(user, 32 ether);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        wstETH.wrap(32 ether);

        uint256 required = accounting.getRequiredBondWstETHForKeys(1);
        accounting.depositWstETH(user, 0, required);

        assertApproxEqAbs(
            accounting.getRequiredBondWstETH(0, 0),
            0,
            1, // max accuracy error
            "required wstETH should be ~0 for 1 deposited validator"
        );

        required = accounting.getRequiredBondStETH(0, 1);
        accounting.depositWstETH(user, 0, required);
        stakingModule.addValidator(0, 1);

        assertApproxEqAbs(
            accounting.getRequiredBondWstETH(0, 0),
            0,
            1, // max accuracy error
            "required wstETH should be ~0 for 2 deposited validators"
        );
    }

    function test_depositStETHWithPermit() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 32 ether);
        vm.prank(user);
        uint256 sharesToDeposit = stETH.submit{ value: 32 ether }({
            _referal: address(0)
        });

        vm.expectEmit(true, true, true, true, address(stETH));
        emit Approval(user, address(accounting), 32 ether);
        vm.expectEmit(true, true, true, true, address(accounting));
        emit StETHBondDeposited(0, user, 32 ether);

        vm.prank(user);
        accounting.depositStETHWithPermit(
            user,
            0,
            32 ether,
            CSAccounting.PermitInput({
                value: 32 ether,
                deadline: type(uint256).max,
                // mock permit signature
                v: 0,
                r: 0,
                s: 0
            })
        );

        assertEq(
            stETH.balanceOf(user),
            0,
            "user balance should be 0 after deposit"
        );
        assertEq(
            accounting.getBondShares(0),
            sharesToDeposit,
            "bond shares should be equal to deposited shares"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            sharesToDeposit,
            "bond manager shares should be equal to deposited shares"
        );
    }

    function test_depositStETHWithPermit_alreadyPermitted() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 32 ether);
        vm.prank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });

        vm.expectEmit(true, true, true, true, address(accounting));
        emit StETHBondDeposited(0, user, 32 ether);

        vm.mockCall(
            address(stETH),
            abi.encodeWithSelector(
                stETH.allowance.selector,
                user,
                address(accounting)
            ),
            abi.encode(32 ether)
        );

        vm.recordLogs();

        vm.prank(user);
        accounting.depositStETHWithPermit(
            user,
            0,
            32 ether,
            CSAccounting.PermitInput({
                value: 32 ether,
                deadline: type(uint256).max,
                // mock permit signature
                v: 0,
                r: 0,
                s: 0
            })
        );

        assertEq(
            vm.getRecordedLogs().length,
            1,
            "should emit only one event about deposit"
        );
    }

    function test_depositWstETHWithPermit() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        uint256 wstETHAmount = wstETH.wrap(32 ether);
        uint256 sharesToDeposit = stETH.getSharesByPooledEth(
            wstETH.getStETHByWstETH(wstETHAmount)
        );
        vm.stopPrank();

        vm.expectEmit(true, true, true, true, address(wstETH));
        emit Approval(user, address(accounting), 32 ether);
        vm.expectEmit(true, true, true, true, address(accounting));
        emit WstETHBondDeposited(0, user, wstETHAmount);

        vm.prank(user);
        accounting.depositWstETHWithPermit(
            user,
            0,
            wstETHAmount,
            CSAccounting.PermitInput({
                value: 32 ether,
                deadline: type(uint256).max,
                // mock permit signature
                v: 0,
                r: 0,
                s: 0
            })
        );

        assertEq(
            wstETH.balanceOf(user),
            0,
            "user balance should be 0 after deposit"
        );
        assertEq(
            accounting.getBondShares(0),
            sharesToDeposit,
            "bond shares should be equal to deposited shares"
        );
        assertEq(
            accounting.totalBondShares(),
            sharesToDeposit,
            "bond manager shares should be equal to deposited shares"
        );
    }

    function test_depositWstETHWithPermit_alreadyPermitted() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        uint256 wstETHAmount = wstETH.wrap(32 ether);
        vm.stopPrank();

        vm.expectEmit(true, true, true, true, address(accounting));
        emit WstETHBondDeposited(0, user, wstETHAmount);

        vm.mockCall(
            address(wstETH),
            abi.encodeWithSelector(
                wstETH.allowance.selector,
                user,
                address(accounting)
            ),
            abi.encode(32 ether)
        );

        vm.recordLogs();

        vm.prank(user);
        accounting.depositWstETHWithPermit(
            user,
            0,
            wstETHAmount,
            CSAccounting.PermitInput({
                value: 32 ether,
                deadline: type(uint256).max,
                // mock permit signature
                v: 0,
                r: 0,
                s: 0
            })
        );

        assertEq(
            vm.getRecordedLogs().length,
            1,
            "should emit only one event about deposit"
        );
    }

    function test_depositETH_RevertIfNotExistedOperator() public {
        vm.expectRevert("node operator does not exist");
        vm.prank(user);
        accounting.depositETH{ value: 0 }(user, 0);
    }

    function test_depositStETH_RevertIfNotExistedOperator() public {
        vm.expectRevert("node operator does not exist");
        vm.prank(user);
        accounting.depositStETH(user, 0, 32 ether);
    }

    function test_depositETH_RevertIfInvalidSender() public {
        vm.expectRevert(InvalidSender.selector);
        vm.prank(stranger);
        accounting.depositETH{ value: 0 }(user, 0);
    }

    function test_depositStETH_RevertIfInvalidSender() public {
        vm.expectRevert(InvalidSender.selector);
        vm.prank(stranger);
        accounting.depositStETH(user, 0, 32 ether);
    }

    function test_depositStETHWithPermit_RevertIfInvalidSender() public {
        vm.expectRevert(InvalidSender.selector);
        vm.prank(stranger);
        accounting.depositStETHWithPermit(
            user,
            0,
            32 ether,
            CSAccounting.PermitInput({
                value: 32 ether,
                deadline: type(uint256).max,
                // mock permit signature
                v: 0,
                r: 0,
                s: 0
            })
        );
    }

    function test_depositWstETH_RevertIfInvalidSender() public {
        vm.expectRevert(InvalidSender.selector);
        vm.prank(stranger);
        accounting.depositWstETH(user, 0, 32 ether);
    }

    function test_depositWstETHWithPermit_RevertIfInvalidSender() public {
        vm.expectRevert(InvalidSender.selector);
        vm.prank(stranger);
        accounting.depositWstETHWithPermit(
            user,
            0,
            32 ether,
            CSAccounting.PermitInput({
                value: 32 ether,
                deadline: type(uint256).max,
                // mock permit signature
                v: 0,
                r: 0,
                s: 0
            })
        );
    }

    function test_getTotalRewardsETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(address(feeDistributor), 0.1 ether);
        vm.prank(address(feeDistributor));
        uint256 sharesAsFee = stETH.submit{ value: 0.1 ether }(address(0));
        uint256 ETHAsFee = stETH.getPooledEthByShares(sharesAsFee);
        vm.deal(user, 32 ether);
        vm.prank(user);
        accounting.depositETH{ value: 32 ether }(user, 0);

        uint256 totalRewards = accounting.getTotalRewardsETH(
            new bytes32[](1),
            0,
            sharesAsFee
        );

        assertEq(totalRewards, ETHAsFee);

        // set sophisticated curve
        accounting.setBondCurve();

        totalRewards = accounting.getTotalRewardsETH(
            new bytes32[](1),
            0,
            sharesAsFee
        );

        // fee + excess after curve
        assertEq(totalRewards, ETHAsFee + 10.6 ether);

        // set multiplier
        vm.prank(admin);
        accounting.setBondMultiplier(0, 9500); // 0.95

        totalRewards = accounting.getTotalRewardsETH(
            new bytes32[](1),
            0,
            sharesAsFee
        );

        // fee + excess after curve + multiplier
        assertEq(totalRewards, ETHAsFee + (32 ether - 21.4 ether * 0.95));
    }

    function test_getTotalRewardsStETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(address(feeDistributor), 0.1 ether);
        vm.prank(address(feeDistributor));
        uint256 sharesAsFee = stETH.submit{ value: 0.1 ether }(address(0));
        uint256 stETHAsFee = stETH.getPooledEthByShares(sharesAsFee);
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        accounting.depositStETH(user, 0, 32 ether);
        vm.stopPrank();

        uint256 totalRewards = accounting.getTotalRewardsStETH(
            new bytes32[](1),
            0,
            sharesAsFee
        );

        assertEq(totalRewards, stETHAsFee);

        // set sophisticated curve
        accounting.setBondCurve();
        totalRewards = accounting.getTotalRewardsStETH(
            new bytes32[](1),
            0,
            sharesAsFee
        );

        // fee + excess after curve
        assertEq(totalRewards, stETHAsFee + 10.6 ether);

        // set multiplier
        vm.prank(admin);
        accounting.setBondMultiplier(0, 9500); // 0.95

        totalRewards = accounting.getTotalRewardsStETH(
            new bytes32[](1),
            0,
            sharesAsFee
        );

        // fee + excess after curve + multiplier
        assertEq(totalRewards, stETHAsFee + (32 ether - 21.4 ether * 0.95));
    }

    function test_getTotalRewardsWstETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(address(feeDistributor), 0.1 ether);
        vm.prank(address(feeDistributor));
        uint256 sharesAsFee = stETH.submit{ value: 0.1 ether }(address(0));
        uint256 wstETHAsFee = wstETH.getWstETHByStETH(
            stETH.getPooledEthByShares(sharesAsFee)
        );
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        accounting.depositStETH(user, 0, 32 ether);
        vm.stopPrank();

        uint256 totalRewards = accounting.getTotalRewardsWstETH(
            new bytes32[](1),
            0,
            sharesAsFee
        );

        assertApproxEqAbs(totalRewards, wstETHAsFee, 1);

        // set sophisticated curve
        accounting.setBondCurve();
        totalRewards = accounting.getTotalRewardsWstETH(
            new bytes32[](1),
            0,
            sharesAsFee
        );

        // fee + excess after curve
        assertApproxEqAbs(
            totalRewards,
            wstETHAsFee + wstETH.getWstETHByStETH(10.6 ether),
            1
        );

        // set multiplier
        vm.prank(admin);
        accounting.setBondMultiplier(0, 9500); // 0.95

        totalRewards = accounting.getTotalRewardsWstETH(
            new bytes32[](1),
            0,
            sharesAsFee
        );

        // fee + excess after curve + multiplier
        assertEq(
            totalRewards,
            wstETHAsFee + wstETH.getWstETHByStETH(32 ether - 21.4 ether * 0.95)
        );
    }

    function test_getExcessBondETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 64 ether);
        vm.prank(user);
        accounting.depositETH{ value: 64 ether }(user, 0);

        assertApproxEqAbs(accounting.getExcessBondETH(0), 32 ether, 1);

        // set sophisticated curve
        accounting.setBondCurve();

        assertApproxEqAbs(accounting.getExcessBondETH(0), 42.6 ether, 1);

        // set multiplier
        vm.prank(admin);
        accounting.setBondMultiplier(0, 9500); // 0.95

        assertApproxEqAbs(
            accounting.getExcessBondETH(0),
            32 ether + (32 ether - 21.4 ether * 0.95),
            1
        );
    }

    function test_getExcessBondStETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 64 ether);
        vm.prank(user);
        accounting.depositETH{ value: 64 ether }(user, 0);

        assertApproxEqAbs(accounting.getExcessBondStETH(0), 32 ether, 1);

        // set sophisticated curve
        accounting.setBondCurve();

        assertApproxEqAbs(accounting.getExcessBondStETH(0), 42.6 ether, 1);

        // set multiplier
        vm.prank(admin);
        accounting.setBondMultiplier(0, 9500); // 0.95

        assertApproxEqAbs(
            accounting.getExcessBondStETH(0),
            32 ether + (32 ether - 21.4 ether * 0.95),
            1
        );
    }

    function test_getExcessBondWstETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 64 ether);
        vm.prank(user);
        accounting.depositETH{ value: 64 ether }(user, 0);

        assertApproxEqAbs(
            accounting.getExcessBondWstETH(0),
            wstETH.getWstETHByStETH(32 ether),
            1
        );

        // set sophisticated curve
        accounting.setBondCurve();

        assertApproxEqAbs(
            accounting.getExcessBondWstETH(0),
            wstETH.getWstETHByStETH(42.6 ether),
            1
        );

        // set multiplier
        vm.prank(admin);
        accounting.setBondMultiplier(0, 9500); // 0.95

        assertApproxEqAbs(
            accounting.getExcessBondWstETH(0),
            wstETH.getWstETHByStETH(32 ether + (32 ether - 21.4 ether * 0.95)),
            1
        );
    }

    function test_getMissingBondETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 16 ether);
        vm.prank(user);
        accounting.depositETH{ value: 16 ether }(user, 0);

        assertApproxEqAbs(accounting.getMissingBondETH(0), 16 ether, 1);

        // set sophisticated curve
        accounting.setBondCurve();

        assertApproxEqAbs(accounting.getMissingBondETH(0), 5.4 ether, 1);

        // set multiplier
        vm.prank(admin);
        accounting.setBondMultiplier(0, 9500); // 0.95

        assertApproxEqAbs(
            accounting.getMissingBondETH(0),
            16 ether - (32 ether - 21.4 ether * 0.95),
            1
        );
    }

    function test_getMissingBondStETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 16 ether);
        vm.prank(user);
        accounting.depositETH{ value: 16 ether }(user, 0);

        assertApproxEqAbs(accounting.getMissingBondStETH(0), 16 ether, 1);

        // set sophisticated curve
        accounting.setBondCurve();

        assertApproxEqAbs(accounting.getMissingBondStETH(0), 5.4 ether, 1);

        // set multiplier
        vm.prank(admin);
        accounting.setBondMultiplier(0, 9500); // 0.95

        assertApproxEqAbs(
            accounting.getMissingBondStETH(0),
            16 ether - (32 ether - 21.4 ether * 0.95),
            1
        );
    }

    function test_getMissingBondWstETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 16 ether);
        vm.prank(user);
        accounting.depositETH{ value: 16 ether }(user, 0);

        assertApproxEqAbs(
            accounting.getMissingBondWstETH(0),
            wstETH.getWstETHByStETH(16 ether),
            1
        );

        // set sophisticated curve
        accounting.setBondCurve();

        assertApproxEqAbs(
            accounting.getMissingBondWstETH(0),
            wstETH.getWstETHByStETH(5.4 ether),
            1
        );

        // set multiplier
        vm.prank(admin);
        accounting.setBondMultiplier(0, 9500); // 0.95

        assertApproxEqAbs(
            accounting.getMissingBondWstETH(0),
            wstETH.getWstETHByStETH(16 ether - (32 ether - 21.4 ether * 0.95)),
            1
        );
    }

    function test_getUnbondedKeysCount() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 32 ether);
        vm.prank(user);
        accounting.depositETH{ value: 11.57 ether }(user, 0);

        assertEq(accounting.getUnbondedKeysCount(0), 10);

        vm.prank(user);
        accounting.depositETH{ value: 2.43 ether }(user, 0);

        assertEq(accounting.getUnbondedKeysCount(0), 9);

        // set sophisticated curve
        accounting.setBondCurve();

        assertEq(accounting.getUnbondedKeysCount(0), 7);

        // set multiplier
        vm.prank(admin);
        accounting.setBondMultiplier(0, 9500); // 0.95

        assertEq(accounting.getUnbondedKeysCount(0), 6);
    }

    function test_getKeysCountByBondETH() public {
        assertEq(accounting.getKeysCountByBondETH(0), 0);
        assertEq(accounting.getKeysCountByBondETH(1.99 ether), 0);
        assertEq(accounting.getKeysCountByBondETH(2 ether), 1);
        assertEq(accounting.getKeysCountByBondETH(4 ether), 2);
        assertEq(accounting.getKeysCountByBondETH(16 ether), 8);

        // set sophisticated curve
        accounting.setBondCurve();

        assertEq(accounting.getKeysCountByBondETH(16 ether), 10);
    }

    function test_getKeysCountByBondStETH() public {
        assertEq(accounting.getKeysCountByBondStETH(0), 0);
        assertEq(accounting.getKeysCountByBondStETH(1.99 ether), 0);
        assertEq(accounting.getKeysCountByBondStETH(2 ether), 1);
        assertEq(accounting.getKeysCountByBondStETH(4 ether), 2);
        assertEq(accounting.getKeysCountByBondETH(16 ether), 8);

        // set sophisticated curve
        accounting.setBondCurve();

        assertEq(accounting.getKeysCountByBondStETH(16 ether), 10);
    }

    function test_getKeysCountByBondWstETH() public {
        assertEq(accounting.getKeysCountByBondWstETH(0), 0);
        assertEq(
            accounting.getKeysCountByBondWstETH(
                wstETH.getWstETHByStETH(1.99 ether)
            ),
            0
        );
        assertEq(
            accounting.getKeysCountByBondWstETH(
                wstETH.getWstETHByStETH(2 ether + 1 wei)
            ),
            1
        );
        assertEq(
            accounting.getKeysCountByBondWstETH(
                wstETH.getWstETHByStETH(4 ether + 1 wei)
            ),
            2
        );
        assertEq(
            accounting.getKeysCountByBondWstETH(
                wstETH.getWstETHByStETH(16 ether + 1 wei)
            ),
            8
        );

        // set sophisticated curve
        accounting.setBondCurve();

        assertEq(
            accounting.getKeysCountByBondWstETH(
                wstETH.getWstETHByStETH(16 ether + 1 wei)
            ),
            10
        );
    }

    function test_claimRewardsStETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(address(feeDistributor), 0.1 ether);
        vm.prank(address(feeDistributor));
        uint256 sharesAsFee = stETH.submit{ value: 0.1 ether }(address(0));
        uint256 stETHAsFee = stETH.getPooledEthByShares(sharesAsFee);
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        accounting.depositStETH(user, 0, 32 ether);

        vm.expectEmit(true, true, true, true, address(accounting));
        emit StETHRewardsClaimed(
            0,
            user,
            stETH.getPooledEthByShares(sharesAsFee)
        );

        uint256 bondSharesBefore = accounting.getBondShares(0);
        accounting.claimRewardsStETH(
            new bytes32[](1),
            0,
            sharesAsFee,
            UINT256_MAX
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);
        vm.stopPrank();

        assertEq(
            stETH.balanceOf(address(user)),
            stETHAsFee,
            "user balance should be equal to fee reward"
        );
        assertEq(
            bondSharesAfter,
            bondSharesBefore,
            "bond shares after claim should be equal to before"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            bondSharesAfter,
            "bond manager after claim should be equal to before"
        );

        // set sophisticated curve
        accounting.setBondCurve();

        vm.deal(address(feeDistributor), 0.1 ether);
        vm.prank(address(feeDistributor));
        stETH.submit{ value: 0.1 ether }(address(0));

        uint256 balanceBefore = stETH.balanceOf(address(user));
        vm.prank(user);
        accounting.claimRewardsStETH(
            new bytes32[](1),
            0,
            sharesAsFee,
            UINT256_MAX
        );

        // claimed fee before + fee + excess after curve
        assertEq(
            stETH.balanceOf(address(user)),
            balanceBefore + stETHAsFee + 10.6 ether,
            "user balance should be equal to fee reward + excess"
        );

        // set multiplier
        vm.prank(admin);
        accounting.setBondMultiplier(0, 9500); // 0.95

        vm.deal(address(feeDistributor), 0.1 ether);
        vm.prank(address(feeDistributor));
        stETH.submit{ value: 0.1 ether }(address(0));

        balanceBefore = stETH.balanceOf(address(user));
        vm.prank(user);
        accounting.claimRewardsStETH(
            new bytes32[](1),
            0,
            sharesAsFee,
            UINT256_MAX
        );

        // claimed fee before x2 + fee + excess after multiplier
        assertApproxEqAbs(
            stETH.balanceOf(address(user)),
            balanceBefore + stETHAsFee + (21.4 ether - 21.4 ether * 0.95),
            1,
            "user balance should be equal to fee reward + excess"
        );
    }

    function test_claimRewardsStETH_WithDesirableValue() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(address(feeDistributor), 0.1 ether);
        vm.prank(address(feeDistributor));
        uint256 sharesAsFee = stETH.submit{ value: 0.1 ether }(address(0));
        uint256 sharesToClaim = stETH.getSharesByPooledEth(0.05 ether);
        uint256 stETHToClaim = stETH.getPooledEthByShares(sharesToClaim);
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        accounting.depositStETH(user, 0, 32 ether);

        vm.expectEmit(true, true, true, true, address(accounting));
        emit StETHRewardsClaimed(0, user, stETHToClaim);

        uint256 bondSharesBefore = accounting.getBondShares(0);

        accounting.claimRewardsStETH(
            new bytes32[](1),
            0,
            sharesAsFee,
            0.05 ether
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            stETH.balanceOf(address(user)),
            stETHToClaim,
            "user balance should be equal to claimed"
        );
        assertEq(
            bondSharesAfter,
            (bondSharesBefore + sharesAsFee) - sharesToClaim,
            "bond shares after should be equal to before and fee minus claimed shares"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            bondSharesAfter,
            "bond manager after should be equal to before and fee minus claimed shares"
        );
    }

    function test_claimRewardsStETH_WhenAmountToClaimIsHigherThanRewards()
        public
    {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(address(feeDistributor), 0.1 ether);
        vm.prank(address(feeDistributor));
        uint256 sharesAsFee = stETH.submit{ value: 0.1 ether }(address(0));
        uint256 stETHAsFee = stETH.getPooledEthByShares(sharesAsFee);

        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        accounting.depositStETH(user, 0, 32 ether);

        vm.expectEmit(true, true, true, true, address(accounting));
        emit StETHRewardsClaimed(0, user, stETHAsFee);

        uint256 bondSharesBefore = accounting.getBondShares(0);
        accounting.claimRewardsStETH(
            new bytes32[](1),
            0,
            sharesAsFee,
            100 * 1e18
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            stETH.balanceOf(address(user)),
            stETHAsFee,
            "user balance should be equal to fee reward"
        );
        assertEq(
            bondSharesAfter,
            bondSharesBefore,
            "bond shares after should be equal to before"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            bondSharesAfter,
            "bond manager after should be equal to before"
        );
    }

    function test_claimRewardsStETH_WhenRequiredBondIsEqualActual() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(address(feeDistributor), 1 ether);
        vm.prank(address(feeDistributor));
        uint256 sharesAsFee = stETH.submit{ value: 1 ether }(address(0));

        vm.deal(user, 31 ether);
        vm.startPrank(user);
        stETH.submit{ value: 31 ether }({ _referal: address(0) });
        accounting.depositStETH(user, 0, 31 ether);

        vm.expectEmit(true, true, true, true, address(accounting));
        emit StETHRewardsClaimed(0, user, 0);

        uint256 bondSharesBefore = accounting.getBondShares(0);
        accounting.claimRewardsStETH(
            new bytes32[](1),
            0,
            sharesAsFee,
            UINT256_MAX
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(stETH.balanceOf(address(user)), 0, "user balance should be 0");
        assertEq(
            bondSharesAfter,
            bondSharesBefore + sharesAsFee,
            "bond shares should be increased by fee"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            bondSharesAfter,
            "bond manager shares should be increased by fee"
        );
    }

    function test_claimRewardsStETH_WhenRequiredBondIsHigherActual() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(address(feeDistributor), 1 ether);
        vm.prank(address(feeDistributor));
        uint256 sharesAsFee = stETH.submit{ value: 0.5 ether }(address(0));

        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 31 ether }({ _referal: address(0) });
        accounting.depositStETH(user, 0, 31 ether);

        vm.expectEmit(true, true, true, true, address(accounting));
        emit StETHRewardsClaimed(0, user, 0);

        uint256 bondSharesBefore = accounting.getBondShares(0);
        accounting.claimRewardsStETH(
            new bytes32[](1),
            0,
            sharesAsFee,
            UINT256_MAX
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(stETH.balanceOf(address(user)), 0, "user balance should be 0");
        assertEq(
            bondSharesAfter,
            bondSharesBefore + sharesAsFee,
            "bond shares should be increased by fee"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            bondSharesAfter,
            "bond manager shares should be increased by fee"
        );
    }

    function test_claimRewardsStETH_RevertWhenCallerIsNotRewardAddress()
        public
    {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });

        vm.expectRevert(
            abi.encodeWithSelector(NotOwnerToClaim.selector, stranger, user)
        );
        vm.prank(stranger);
        accounting.claimRewardsStETH(new bytes32[](1), 0, 1, 1 ether);
    }

    function test_claimRewardsWstETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(address(feeDistributor), 0.1 ether);
        vm.prank(address(feeDistributor));
        uint256 sharesAsFee = stETH.submit{ value: 0.1 ether }(address(0));
        uint256 wstETHAsFee = wstETH.getWstETHByStETH(
            stETH.getPooledEthByShares(sharesAsFee)
        );
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        accounting.depositStETH(user, 0, 32 ether);

        vm.expectEmit(true, true, true, true, address(accounting));
        emit WstETHRewardsClaimed(0, user, wstETHAsFee);

        uint256 bondSharesBefore = accounting.getBondShares(0);
        accounting.claimRewardsWstETH(
            new bytes32[](1),
            0,
            sharesAsFee,
            UINT256_MAX
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);
        vm.stopPrank();

        assertEq(
            wstETH.balanceOf(address(user)),
            wstETHAsFee,
            "user balance should be equal to fee reward"
        );
        assertEq(
            bondSharesAfter,
            bondSharesBefore + 1 wei,
            "bond shares after claim should contain wrapped fee accuracy error"
        );
        assertEq(
            wstETH.balanceOf(address(accounting)),
            0,
            "bond manager wstETH balance should be 0"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            bondSharesBefore + 1 wei,
            "bond manager after claim should contain wrapped fee accuracy error"
        );

        // set sophisticated curve
        accounting.setBondCurve();

        vm.deal(address(feeDistributor), 0.1 ether);
        vm.prank(address(feeDistributor));
        stETH.submit{ value: 0.1 ether }(address(0));

        uint256 balanceBefore = wstETH.balanceOf(address(user));
        vm.prank(user);
        accounting.claimRewardsWstETH(
            new bytes32[](1),
            0,
            sharesAsFee,
            UINT256_MAX
        );

        // claimed fee before + fee + excess after curve
        assertApproxEqAbs(
            wstETH.balanceOf(address(user)),
            balanceBefore +
                wstETH.getWstETHByStETH(
                    stETH.getPooledEthByShares(sharesAsFee) + 10.6 ether
                ),
            1,
            "user balance should be equal to fee reward + excess"
        );

        // set multiplier
        vm.prank(admin);
        accounting.setBondMultiplier(0, 9500); // 0.95

        vm.deal(address(feeDistributor), 0.1 ether);
        vm.prank(address(feeDistributor));
        stETH.submit{ value: 0.1 ether }(address(0));

        balanceBefore = wstETH.balanceOf(address(user));
        vm.prank(user);
        accounting.claimRewardsWstETH(
            new bytes32[](1),
            0,
            sharesAsFee,
            UINT256_MAX
        );

        // claimed fee before x2 + fee + excess after multiplier
        assertApproxEqAbs(
            wstETH.balanceOf(address(user)),
            balanceBefore +
                wstETH.getWstETHByStETH(
                    stETH.getPooledEthByShares(sharesAsFee) +
                        21.4 ether -
                        21.4 ether *
                        0.95
                ),
            1,
            "user balance should be equal to fee reward + excess"
        );
    }

    function test_claimRewardsWstETH_WithDesirableValue() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(address(feeDistributor), 0.1 ether);
        vm.prank(address(feeDistributor));
        uint256 sharesAsFee = stETH.submit{ value: 0.1 ether }(address(0));
        uint256 sharesToClaim = stETH.getSharesByPooledEth(0.05 ether);
        uint256 wstETHToClaim = wstETH.getWstETHByStETH(
            stETH.getPooledEthByShares(sharesToClaim)
        );
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        accounting.depositStETH(user, 0, 32 ether);

        vm.expectEmit(true, true, true, true, address(accounting));
        emit WstETHRewardsClaimed(0, user, wstETHToClaim);

        uint256 bondSharesBefore = accounting.getBondShares(0);
        accounting.claimRewardsWstETH(
            new bytes32[](1),
            0,
            sharesAsFee,
            stETH.getSharesByPooledEth(0.05 ether)
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(
            wstETH.balanceOf(address(user)),
            wstETHToClaim,
            "user balance should be equal to fee reward"
        );
        assertEq(
            bondSharesAfter,
            (bondSharesBefore + sharesAsFee) - wstETHToClaim,
            "bond shares after should be equal to before and fee minus claimed shares"
        );
        assertEq(
            wstETH.balanceOf(address(accounting)),
            0,
            "bond manager wstETH balance should be 0"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            (bondSharesBefore + sharesAsFee) - wstETHToClaim,
            "bond shares after should be equal to before and fee minus claimed shares"
        );
    }

    function test_claimRewardsWstETH_RevertWhenCallerIsNotRewardAddress()
        public
    {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });

        vm.expectRevert(
            abi.encodeWithSelector(NotOwnerToClaim.selector, stranger, user)
        );
        vm.prank(stranger);
        accounting.claimRewardsWstETH(new bytes32[](1), 0, 1, 1 ether);
    }

    function test_requestRewardsETH() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(address(feeDistributor), 0.1 ether);
        vm.prank(address(feeDistributor));
        uint256 sharesAsFee = stETH.submit{ value: 0.1 ether }(address(0));

        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        accounting.depositStETH(user, 0, 32 ether);

        uint256 requestedAsUnstETH = stETH.getPooledEthByShares(sharesAsFee);
        uint256 requestedAsUnstETHAsShares = stETH.getSharesByPooledEth(
            requestedAsUnstETH
        );

        vm.expectEmit(
            true,
            true,
            true,
            true,
            address(locator.withdrawalQueue())
        );
        emit WithdrawalRequested(
            1,
            address(accounting),
            user,
            requestedAsUnstETH,
            requestedAsUnstETHAsShares
        );
        vm.expectEmit(true, true, true, true, address(accounting));
        emit ETHRewardsRequested(
            0,
            user,
            stETH.getPooledEthByShares(sharesAsFee)
        );

        uint256 bondSharesBefore = accounting.getBondShares(0);
        uint256[] memory requestIds = accounting.requestRewardsETH(
            new bytes32[](1),
            0,
            sharesAsFee,
            UINT256_MAX
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);
        vm.stopPrank();

        assertEq(requestIds.length, 1, "request ids length should be 1");
        assertEq(
            bondSharesAfter,
            bondSharesBefore,
            "bond shares should not change after request"
        );
        assertEq(
            stETH.sharesOf(address(locator.withdrawalQueue())),
            requestedAsUnstETHAsShares,
            "shares of withdrawal queue should be equal to requested shares"
        );
        assertEq(stETH.sharesOf(address(user)), 0, "user shares should be 0");

        // set sophisticated curve
        accounting.setBondCurve();

        vm.deal(address(feeDistributor), 0.1 ether);
        vm.prank(address(feeDistributor));
        stETH.submit{ value: 0.1 ether }(address(0));

        uint256 balanceBefore = stETH.sharesOf(
            address(locator.withdrawalQueue())
        );
        vm.prank(user);
        accounting.requestRewardsETH(
            new bytes32[](1),
            0,
            sharesAsFee,
            UINT256_MAX
        );

        // requested fee before + fee + excess after curve
        assertEq(
            stETH.sharesOf(address(locator.withdrawalQueue())),
            balanceBefore +
                requestedAsUnstETHAsShares +
                stETH.getSharesByPooledEth(10.6 ether),
            "shares of withdrawal queue should be equal to requested shares + excess"
        );

        // set multiplier
        vm.prank(admin);
        accounting.setBondMultiplier(0, 9500); // 0.95

        vm.deal(address(feeDistributor), 0.1 ether);
        vm.prank(address(feeDistributor));
        stETH.submit{ value: 0.1 ether }(address(0));

        balanceBefore = stETH.sharesOf(address(locator.withdrawalQueue()));
        vm.prank(user);
        accounting.requestRewardsETH(
            new bytes32[](1),
            0,
            sharesAsFee,
            UINT256_MAX
        );

        // claimed fee before x2 + fee + excess after multiplier
        assertApproxEqAbs(
            stETH.sharesOf(address(locator.withdrawalQueue())),
            balanceBefore +
                requestedAsUnstETHAsShares +
                stETH.getSharesByPooledEth(21.4 ether - 21.4 ether * 0.95),
            1,
            "shares of withdrawal queue should be equal to requested shares + excess"
        );
    }

    function test_requestRewardsETH_WithDesirableValue() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(address(feeDistributor), 0.1 ether);
        vm.prank(address(feeDistributor));
        uint256 sharesAsFee = stETH.submit{ value: 0.1 ether }(address(0));

        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        accounting.depositStETH(user, 0, 32 ether);

        uint256 requestedAsShares = stETH.getSharesByPooledEth(0.05 ether);
        uint256 requestedAsUnstETH = stETH.getPooledEthByShares(
            requestedAsShares
        );
        uint256 requestedAsUnstETHAsShares = stETH.getSharesByPooledEth(
            requestedAsUnstETH
        );

        vm.expectEmit(
            true,
            true,
            true,
            true,
            address(locator.withdrawalQueue())
        );
        emit WithdrawalRequested(
            1,
            address(accounting),
            user,
            requestedAsUnstETH,
            requestedAsUnstETHAsShares
        );
        vm.expectEmit(true, true, true, true, address(accounting));
        emit ETHRewardsRequested(0, user, requestedAsUnstETH);

        uint256 bondSharesBefore = accounting.getBondShares(0);
        uint256[] memory requestIds = accounting.requestRewardsETH(
            new bytes32[](1),
            0,
            sharesAsFee,
            0.05 ether
        );
        uint256 bondSharesAfter = accounting.getBondShares(0);

        assertEq(requestIds.length, 1, "request ids length should be 1");
        assertEq(
            bondSharesAfter,
            (bondSharesBefore + sharesAsFee) - requestedAsShares,
            "bond shares after should be equal to before and fee minus requested shares"
        );
        assertEq(
            stETH.sharesOf(address(locator.withdrawalQueue())),
            requestedAsUnstETHAsShares,
            "shares of withdrawal queue should be equal to requested shares"
        );
        assertEq(stETH.sharesOf(address(user)), 0, "user shares should be 0");
    }

    function test_penalize_LessThanDeposit() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        accounting.depositStETH(user, 0, 32 ether);
        vm.stopPrank();

        uint256 shares = stETH.getSharesByPooledEth(1 ether);
        uint256 penalized = stETH.getPooledEthByShares(shares);
        vm.expectEmit(true, true, true, true, address(accounting));
        emit BondPenalized(0, penalized, penalized);

        uint256 bondSharesBefore = accounting.getBondShares(0);
        vm.prank(admin);
        accounting.penalize(0, 1 ether);

        assertEq(
            accounting.getBondShares(0),
            bondSharesBefore - shares,
            "bond shares should be decreased by penalty"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            bondSharesBefore - shares,
            "bond manager shares should be decreased by penalty"
        );
        assertEq(
            stETH.sharesOf(address(burner)),
            shares,
            "burner shares should be equal to penalty"
        );
    }

    function test_penalize_MoreThanDeposit() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        accounting.depositStETH(user, 0, 32 ether);
        vm.stopPrank();

        uint256 bondSharesBefore = accounting.getBondShares(0);
        uint256 penaltyShares = stETH.getSharesByPooledEth(33 ether);
        vm.expectEmit(true, true, true, true, address(accounting));
        emit BondPenalized(
            0,
            stETH.getPooledEthByShares(penaltyShares),
            stETH.getPooledEthByShares(bondSharesBefore)
        );

        vm.prank(admin);
        accounting.penalize(0, 33 ether);

        assertEq(
            accounting.getBondShares(0),
            0,
            "bond shares should be 0 after penalty"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            0,
            "bond manager shares should be 0 after penalty"
        );
        assertEq(
            stETH.sharesOf(address(burner)),
            bondSharesBefore,
            "burner shares should be equal to bond shares"
        );
    }

    function test_penalize_EqualToDeposit() public {
        _createNodeOperator({ ongoingVals: 16, withdrawnVals: 0 });
        vm.deal(user, 32 ether);
        vm.startPrank(user);
        stETH.submit{ value: 32 ether }({ _referal: address(0) });
        accounting.depositStETH(user, 0, 32 ether);
        vm.stopPrank();

        uint256 shares = stETH.getSharesByPooledEth(32 ether);
        uint256 penalized = stETH.getPooledEthByShares(shares);
        vm.expectEmit(true, true, true, true, address(accounting));
        emit BondPenalized(0, penalized, penalized);

        vm.prank(admin);
        accounting.penalize(0, 32 ether);

        assertEq(
            accounting.getBondShares(0),
            0,
            "bond shares should be 0 after penalty"
        );
        assertEq(
            stETH.sharesOf(address(accounting)),
            0,
            "bond manager shares should be 0 after penalty"
        );
        assertEq(
            stETH.sharesOf(address(burner)),
            shares,
            "burner shares should be equal to penalty"
        );
    }

    function test_penalize_RevertWhenCallerHasNoRole() public {
        vm.expectRevert(
            "AccessControl: account 0x0000000000000000000000000000000000000309 is missing role 0x9909cf24c2d3bafa8c229558d86a1b726ba57c3ef6350848dcf434a4181b56c7"
        );
        vm.prank(stranger);
        accounting.penalize(0, 20);
    }

    function _createNodeOperator(
        uint64 ongoingVals,
        uint64 withdrawnVals
    ) internal {
        stakingModule.setNodeOperator({
            _nodeOperatorId: 0,
            _active: true,
            _rewardAddress: user,
            _totalVettedValidators: ongoingVals,
            _totalExitedValidators: 0,
            _totalWithdrawnValidators: withdrawnVals,
            _totalAddedValidators: ongoingVals,
            _totalDepositedValidators: ongoingVals
        });
    }
}
