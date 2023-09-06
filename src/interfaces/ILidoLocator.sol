// SPDX-FileCopyrightText: 2023 Lido <info@lido.fi>
// SPDX-License-Identifier: GPL-3.0

// See contracts/COMPILERS.md
// solhint-disable-next-line
pragma solidity 0.8.21;

interface ILidoLocator {
    error ZeroAddress();

    function accountingOracle() external view returns (address);

    function burner() external view returns (address);

    function coreComponents()
        external
        view
        returns (address, address, address, address, address, address);

    function depositSecurityModule() external view returns (address);

    function elRewardsVault() external view returns (address);

    function legacyOracle() external view returns (address);

    function lido() external view returns (address);

    function oracleDaemonConfig() external view returns (address);

    function oracleReportComponentsForLido()
        external
        view
        returns (address, address, address, address, address, address, address);

    function oracleReportSanityChecker() external view returns (address);

    function postTokenRebaseReceiver() external view returns (address);

    function stakingRouter() external view returns (address);

    function treasury() external view returns (address);

    function validatorsExitBusOracle() external view returns (address);

    function withdrawalQueue() external view returns (address);

    function withdrawalVault() external view returns (address);
}

interface LidoLocator {
    struct Config {
        address accountingOracle;
        address depositSecurityModule;
        address elRewardsVault;
        address legacyOracle;
        address lido;
        address oracleReportSanityChecker;
        address postTokenRebaseReceiver;
        address burner;
        address stakingRouter;
        address treasury;
        address validatorsExitBusOracle;
        address withdrawalQueue;
        address withdrawalVault;
        address oracleDaemonConfig;
    }
}
