// SPDX-FileCopyrightText: 2024 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.24;

interface IConsensusContract {
    function getIsMember(address addr) external view returns (bool);

    function getCurrentFrame()
        external
        view
        returns (uint256 refSlot, uint256 reportProcessingDeadlineSlot);

    function getChainConfig()
        external
        view
        returns (
            uint256 slotsPerEpoch,
            uint256 secondsPerSlot,
            uint256 genesisTime
        );

    function getFrameConfig()
        external
        view
        returns (uint256 initialEpoch, uint256 epochsPerFrame);

    function getInitialRefSlot() external view returns (uint256);
}
