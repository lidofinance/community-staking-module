// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "../src/CSModule.sol";
import "../src/CSAccounting.sol";
import "./helpers/Fixtures.sol";
import "./helpers/mocks/StETHMock.sol";
import "./helpers/mocks/CommunityStakingFeeDistributorMock.sol";
import "./helpers/mocks/LidoLocatorMock.sol";
import "./helpers/mocks/LidoMock.sol";
import "./helpers/mocks/WstETHMock.sol";

contract CSMInitTest is Test, Fixtures {
    LidoLocatorMock public locator;
    WstETHMock public wstETH;
    LidoMock public stETH;
    Stub public burner;

    CSModule public csm;
    CSAccounting public accounting;
    CommunityStakingFeeDistributorMock public communityStakingFeeDistributor;

    address internal stranger;
    address internal alice;

    function setUp() public {
        alice = address(1);
        address[] memory penalizeRoleMembers = new address[](1);
        penalizeRoleMembers[0] = alice;

        (locator, wstETH, stETH, burner) = initLido();

        csm = new CSModule("community-staking-module", address(locator));
        communityStakingFeeDistributor = new CommunityStakingFeeDistributorMock(
            address(locator),
            address(accounting)
        );
        accounting = new CSAccounting(
            2 ether,
            alice,
            address(locator),
            address(wstETH),
            address(csm),
            8 weeks
        );
    }

    function test_InitContract() public {
        assertEq(csm.getType(), "community-staking-module");
        assertEq(csm.getNodeOperatorsCount(), 0);
    }

    function test_SetAccounting() public {
        csm.setAccounting(address(accounting));
        assertEq(address(csm.accounting()), address(accounting));
    }
}
