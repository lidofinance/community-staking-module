// SPDX-FileCopyrightText: 2025 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

import { Test } from "forge-std/Test.sol";

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Math } from "@openzeppelin/contracts/utils/math/Math.sol";

import { MinFirstAllocationStrategy } from "../src/lib/MinFirstAllocationStrategy.sol";

import { Utilities } from "./helpers/Utilities.sol";

// Wrap the library internal methods to make an actual call to them.
// Supposed to be used with `expectRevert` cheatcode and to pass
// calldata arguments.
contract Library {
    function allocate(
        uint256[] memory buckets,
        uint256[] memory capacities,
        uint256 allocationSize
    )
        external
        pure
        returns (
            uint256 allocated,
            uint256[] memory newBuckets,
            uint256[] memory newCapacities
        )
    {
        allocated = MinFirstAllocationStrategy.allocate(
            buckets,
            capacities,
            allocationSize
        );
        newBuckets = buckets;
        newCapacities = capacities;
    }

    function allocateToBestCandidate(
        uint256[] memory buckets,
        uint256[] memory capacities,
        uint256 allocationSize
    )
        external
        pure
        returns (
            uint256 allocated,
            uint256[] memory newBuckets,
            uint256[] memory newCapacities
        )
    {
        allocated = MinFirstAllocationStrategy.allocateToBestCandidate(
            buckets,
            capacities,
            allocationSize
        );
        newBuckets = buckets;
        newCapacities = capacities;
    }
}

contract MinFirstAllocationStrategyTest is Test, Utilities {
    Library internal lib;

    function setUp() public {
        lib = new Library();
    }

    function test_allocateToBestCandidate_ReturnsZeroWhenAllocationSizeIsZero()
        public
    {
        uint256[] memory buckets = UintArr(0);
        uint256[] memory capacities = UintArr(0);
        uint256 allocationSize = 0;

        (uint256 allocated, , ) = lib.allocateToBestCandidate(
            buckets,
            capacities,
            allocationSize
        );

        assertEq(allocated, 0, "Expected allocated to be zero");
    }

    function test_allocate_AllocatesIntoSingleLeastFilledBucket() public {
        uint256[] memory buckets = UintArr(9_998, 70, 0);
        uint256[] memory capacities = UintArr(10_000, 101, 100);
        uint256 allocationSize = 101;

        (uint256 allocated, uint256[] memory newBuckets, ) = lib.allocate(
            buckets,
            capacities,
            allocationSize
        );

        assertEq(allocated, 101, "Invalid allocated value");
        assertEq(newBuckets[0], 9998, "Invalid bucket value");
        assertEq(newBuckets[1], 86, "Invalid bucket value");
        assertEq(newBuckets[2], 85, "Invalid bucket value");
    }
}

contract MinFirstAllocationStrategyFuzz is Test {
    using Strings for uint256;

    uint256 public constant MAX_BUCKETS_COUNT = 32;
    uint256 public constant MAX_BUCKET_VALUE = 8192;
    uint256 public constant MAX_CAPACITY_VALUE = 8192;
    uint256 public constant MAX_ALLOCATION_SIZE = 1024;

    Library internal lib;

    function setUp() public {
        lib = new Library();
    }

    function testFuzz_allocation(
        uint256[] memory inBuckets,
        uint256[] memory inCapacities,
        uint256 allocationSize
    ) public {
        allocationSize = _boundAllocationInputs(
            inBuckets,
            inCapacities,
            allocationSize
        );
        uint256 bucketsCount = inBuckets.length;

        uint256[] memory buckets = new uint256[](bucketsCount);
        uint256[] memory capacities = new uint256[](bucketsCount);

        for (uint256 i = 0; i < bucketsCount; ++i) {
            capacities[i] = inCapacities[i];
            buckets[i] = inBuckets[i];
        }

        (
            uint256 outAllocated,
            uint256[] memory outBuckets,
            uint256[] memory outCapacities
        ) = lib.allocate(buckets, capacities, allocationSize);

        uint256 allocated = NaiveMinFirstAllocationStrategy.allocate(
            buckets, // modified
            capacities, // modified
            allocationSize
        );

        assertEq(outAllocated, allocated, "Unexpected allocated value");

        uint256 inSum;
        uint256 outSum;

        for (uint256 i; i < bucketsCount; ++i) {
            assertEq(
                outBuckets[i],
                buckets[i],
                string.concat("Invalid bucket value at index=", i.toString())
            );

            // NOTE: When bucket initially overfilled skip it from the check.
            if (inBuckets[i] < inCapacities[i]) {
                assertTrue(
                    outBuckets[i] <= outCapacities[i],
                    string.concat(
                        "Bucket value at index=",
                        i.toString(),
                        " exceeds capacity"
                    )
                );
            }

            // NOTE: We passed value greater than available capacities.
            if (allocated < allocationSize) {
                assertGe(
                    outBuckets[i],
                    outCapacities[i],
                    string.concat(
                        "Bucket in index=",
                        i.toString(),
                        " left unfilled"
                    )
                );
            }

            inSum += inBuckets[i];
            outSum += outBuckets[i];
        }

        assertEq(outSum, inSum + allocated, "Invalid buckets sum");
    }

    function _boundAllocationInputs(
        uint256[] memory inBuckets,
        uint256[] memory inCapacities,
        uint256 allocationSize
    ) internal returns (uint256 boundAllocationSize) {
        allocationSize = bound(allocationSize, 1, MAX_ALLOCATION_SIZE);

        vm.assume(inBuckets.length > 0);
        vm.assume(inCapacities.length > 0);

        uint256 bucketsCount = Math.min(inBuckets.length, inCapacities.length) %
            MAX_BUCKETS_COUNT;

        for (uint256 i = 0; i < bucketsCount; ++i) {
            inBuckets[i] = inBuckets[i] % MAX_BUCKET_VALUE;
            inCapacities[i] = inCapacities[i] % MAX_CAPACITY_VALUE;
        }

        assembly ("memory-safe") {
            mstore(inBuckets, bucketsCount)
            mstore(inCapacities, bucketsCount)
        }
    }
}

library NaiveMinFirstAllocationStrategy {
    function allocate(
        uint256[] memory buckets,
        uint256[] memory capacities,
        uint256 allocationSize
    ) internal pure returns (uint256 allocated) {
        while (allocated < allocationSize) {
            uint256 bestCandidateIndex = type(uint256).max;
            uint256 bestCandidateAllocation = type(uint256).max;
            for (uint256 i = 0; i < buckets.length; ++i) {
                if (buckets[i] >= capacities[i]) continue;
                if (buckets[i] < bestCandidateAllocation) {
                    bestCandidateAllocation = buckets[i];
                    bestCandidateIndex = i;
                }
            }
            if (bestCandidateIndex == type(uint256).max) break;
            buckets[bestCandidateIndex] += 1;
            allocated += 1;
        }
    }
}
