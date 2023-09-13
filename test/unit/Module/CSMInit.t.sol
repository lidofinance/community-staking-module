// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "../../../src/CommunityStakingModule.sol";
import "../../../src/CommunityStakingBondManager.sol";
import "../../helpers/mocks/StETHMock.sol";
import "../../helpers/mocks/CommunityStakingFeeDistributorMock.sol";
import "../../helpers/mocks/LidoLocatorMock.sol";
import "../../helpers/mocks/LidoMock.sol";
import "../../helpers/mocks/WstETHMock.sol";

contract CSMInitTest is Test {
    CommunityStakingModule public csm;
    CommunityStakingBondManager public bondManager;

    LidoMock public lidoStETH;
    WstETHMock public wstETH;
    CommunityStakingFeeDistributorMock public communityStakingFeeDistributor;
    LidoLocatorMock public locator;

    address internal stranger;
    address internal alice;
    address internal burner;

    function setUp() public {
        alice = address(1);
        address[] memory penalizeRoleMembers = new address[](1);
        penalizeRoleMembers[0] = alice;

        lidoStETH = new LidoMock(8013386371917025835991984);
        lidoStETH.mintShares(address(lidoStETH), 7059313073779349112833523);
        locator = new LidoLocatorMock(address(lidoStETH), burner);
        csm = new CommunityStakingModule(
            "community-staking-module",
            address(locator)
        );
        wstETH = new WstETHMock(address(lidoStETH));
        communityStakingFeeDistributor = new CommunityStakingFeeDistributorMock(
            address(locator),
            address(bondManager)
        );
        bondManager = new CommunityStakingBondManager(
            2 ether,
            alice,
            address(locator),
            address(wstETH),
            address(csm),
            penalizeRoleMembers
        );
    }

    function test_InitContract() public {
        assertEq(csm.getType(), "community-staking-module");
        assertEq(csm.getNodeOperatorsCount(), 0);
    }

    function test_SetBondManager() public {
        csm.setBondManager(address(bondManager));
        assertEq(address(csm.bondManagerAddress()), address(bondManager));
    }
}
