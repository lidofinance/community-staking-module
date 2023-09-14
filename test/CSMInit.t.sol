// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "../src/CommunityStakingModule.sol";
import "../src/CommunityStakingBondManager.sol";
import "./helpers/Fixtures.sol";
import "./helpers/mocks/StETHMock.sol";
import "./helpers/mocks/CommunityStakingFeeDistributorMock.sol";
import "./helpers/mocks/LidoLocatorMock.sol";
import "./helpers/mocks/LidoMock.sol";
import "./helpers/mocks/WstETHMock.sol";

contract CSMInitTest is Test, Fixtures {
    CommunityStakingModule public csm;
    CommunityStakingBondManager public bondManager;
    CommunityStakingFeeDistributorMock public communityStakingFeeDistributor;

    address internal stranger;
    address internal alice;
    address internal burner;

    function setUp() public withLido {
        alice = address(1);
        address[] memory penalizeRoleMembers = new address[](1);
        penalizeRoleMembers[0] = alice;

        csm = new CommunityStakingModule(
            "community-staking-module",
            address(lido.locator)
        );
        communityStakingFeeDistributor = new CommunityStakingFeeDistributorMock(
            address(lido.locator),
            address(bondManager)
        );
        bondManager = new CommunityStakingBondManager(
            2 ether,
            alice,
            address(lido.locator),
            address(lido.wstETH),
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
