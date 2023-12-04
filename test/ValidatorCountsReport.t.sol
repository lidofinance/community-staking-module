// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Test.sol";

import { ValidatorCountsReport } from "../src/lib/ValidatorCountsReport.sol";

contract ReportCaller {
    function count(bytes calldata ids) public pure returns (uint256) {
        return ValidatorCountsReport.count(ids);
    }

    function validate(bytes calldata ids, bytes calldata counts) public pure {
        ValidatorCountsReport.validate(ids, counts);
    }

    function next(
        bytes calldata ids,
        bytes calldata counts,
        uint256 offset
    ) public returns (uint256 nodeOperatorId, uint256 count) {
        return ValidatorCountsReport.next(ids, counts, offset);
    }
}

contract ValidatorCountsReportTest is Test {
    ReportCaller caller;

    function setUp() public {
        caller = new ReportCaller();
    }

    function test_validate() public {
        (bytes memory ids, bytes memory counts) = (
            bytes.concat(bytes8(0x0000000000000001)),
            bytes.concat(bytes16(0x00000000000000000000000000000001))
        );

        caller.validate(ids, counts);
    }

    function test_validate_invalidIdsLength() public {
        (bytes memory ids, bytes memory counts) = (
            bytes.concat(bytes8(0x0000000000000001), bytes4(0x00000001)),
            bytes.concat(bytes16(0x00000000000000000000000000000001))
        );

        vm.expectRevert(ValidatorCountsReport.InvalidReportData.selector);
        caller.validate(ids, counts);
    }

    function test_validate_invalidCountsLength() public {
        (bytes memory ids, bytes memory counts) = (
            bytes.concat(bytes8(0x0000000000000001)),
            bytes.concat(
                bytes16(0x00000000000000000000000000000001),
                bytes4(0x00000001)
            )
        );

        vm.expectRevert(ValidatorCountsReport.InvalidReportData.selector);
        caller.validate(ids, counts);
    }

    function test_validate_differentItemsCount() public {
        (bytes memory ids, bytes memory counts) = (
            bytes.concat(
                bytes8(0x0000000000000001),
                bytes8(0x0000000000000002)
            ),
            bytes.concat(bytes16(0x00000000000000000000000000000001))
        );

        vm.expectRevert(ValidatorCountsReport.InvalidReportData.selector);
        caller.validate(ids, counts);
    }

    function test_count() public {
        (bytes memory ids, bytes memory counts) = (
            bytes.concat(bytes8(0x0000000000000001)),
            bytes.concat(bytes16(0x00000000000000000000000000000001))
        );

        assertEq(caller.count(ids), 1);
    }

    function test_next() public {
        (bytes memory ids, bytes memory counts) = (
            bytes.concat(bytes8(0x0000000000000001)),
            bytes.concat(bytes16(0x00000000000000000000000000000001))
        );

        (uint256 nodeOperatorId, uint256 count) = caller.next(ids, counts, 0);
        assertEq(nodeOperatorId, 1, "nodeOperatorId != 1");
        assertEq(count, 1, "count != 1");
    }

    function test_nextWithOffset() public {
        (bytes memory ids, bytes memory counts) = (
            bytes.concat(
                bytes8(0x0000000000000001),
                bytes8(0x0000000000000002)
            ),
            bytes.concat(
                bytes16(0x00000000000000000000000000000001),
                bytes16(0x00000000000000000000000000000002)
            )
        );

        (uint256 nodeOperatorId, uint256 count) = caller.next(ids, counts, 1);
        assertEq(nodeOperatorId, 2, "nodeOperatorId != 2");
        assertEq(count, 2, "count != 2");
    }
}
