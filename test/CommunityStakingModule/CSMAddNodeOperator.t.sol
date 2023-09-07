// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "../../src/CommunityStakingModule.sol";
import "../../src/CommunityStakingBondManager.sol";
import "../../src/test_helpers/StETHMock.sol";
import "../../src/test_helpers/CommunityStakingFeeDistributorMock.sol";
import "../../src/test_helpers/LidoLocatorMock.sol";

contract CSMAddNodeOperator is Test {
    CommunityStakingModule public csm;
    CommunityStakingBondManager public bondManager;

    StETHMock public stETH;
    CommunityStakingFeeDistributorMock public communityStakingFeeDistributor;
    LidoLocatorMock public locator;

    address internal stranger;
    address internal alice;
    address internal burner;
    address internal nodeOperator;

    function setUp() public {
        alice = address(1);
        nodeOperator = address(2);
        address[] memory penalizeRoleMembers = new address[](1);
        penalizeRoleMembers[0] = alice;
        stETH = new StETHMock(8013386371917025835991984);
        stETH.mintShares(address(stETH), 7059313073779349112833523);
        stETH.mintShares(address(nodeOperator), 32 * 10 ** 18);
        locator = new LidoLocatorMock(address(stETH), burner);
        communityStakingFeeDistributor = new CommunityStakingFeeDistributorMock(
            address(locator)
        );

        csm = new CommunityStakingModule("community-staking-module");
        bondManager = new CommunityStakingBondManager(
            2 ether,
            alice,
            address(locator),
            address(csm),
            address(communityStakingFeeDistributor),
            penalizeRoleMembers
        );
        csm.setBondManager(address(bondManager));
    }

    function test_AddNodeOperator() public {
        vm.prank(nodeOperator);
        csm.addNodeOperator("test", nodeOperator, 1, "", "");
        assertEq(csm.getNodeOperatorsCount(), 1);
    }
}
