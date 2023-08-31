// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "../../src/CommunityStakingModule.sol";

contract CSMInitTest is Test {
    CommunityStakingModule public csm;

    function setUp() public {
        csm = new CommunityStakingModule("community-staking-module");
    }

    function testInit() public {
        assertEq(csm.getType(), "community-staking-module");
        assertEq(csm.getNodeOperatorsCount(), 0);
    }
}
