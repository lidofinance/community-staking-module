// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "../../src/CommunityStakingModule.sol";
import "../../src/CommunityStakingBondManager.sol";
import "../../src/test_helpers/LidoLocatorMock.sol";
import "../../src/test_helpers/CommunityStakingFeeDistributorMock.sol";
import "../../src/test_helpers/StETHMock.sol";
import "../../src/test_helpers/CommunityStakingModuleMock.sol";

contract CSMInitTest is Test {
    CommunityStakingModule public csm;
    CommunityStakingBondManager public bondManager;

    StETHMock public stETH;
    CommunityStakingFeeDistributorMock public communityStakingFeeDistributor;
    LidoLocatorMock public locator;

    address internal stranger;
    address internal alice;
    address internal burner;

    function setUp() public {
        alice = address(1);
        address[] memory penalizeRoleMembers = new address[](1);
        penalizeRoleMembers[0] = alice;
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
