// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

interface IValidatorExitBus {
    struct ValidatorExitData {
        uint256 stakingModuleId;
        uint256 nodeOperatorId;
        uint256 validatorIndex;
        bytes validatorPubkey;
    }

    function DIRECT_EXIT_HASH_ROLE() external view returns (bytes32);

    function triggerExitsDirectly(
        ValidatorExitData calldata validator
    ) external payable returns (uint256 refund);
}
