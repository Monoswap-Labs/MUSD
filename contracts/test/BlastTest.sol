// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interface/IBlast.sol";

contract BlastTest is IBlast {
    // configure
    function configureContract(address, YieldMode, GasMode, address) external {}
    function configure(YieldMode, GasMode, address) external {}

    // base configuration options
    function configureClaimableYield() external {}
    function configureClaimableYieldOnBehalf(address) external {}
    function configureAutomaticYield() external {}
    function configureAutomaticYieldOnBehalf(address) external {}
    function configureVoidYield() external {}
    function configureVoidYieldOnBehalf(address) external {}
    function configureClaimableGas() external {}
    function configureClaimableGasOnBehalf(address) external {}
    function configureVoidGas() external {}
    function configureVoidGasOnBehalf(address) external {}
    function configureGovernor(address) external {}
    function configureGovernorOnBehalf(address, address) external {}

    // claim yield
    function claimYield(address, address, uint256) external returns (uint256) {
        return 0;
    }
    function claimAllYield(address, address) external returns (uint256) {
        return 0;
    }

    // claim gas
    function claimAllGas(address, address) external returns (uint256) {
        return 0;
    }
    function claimGasAtMinClaimRate(
        address,
        address,
        uint256
    ) external returns (uint256) {
        return 0;
    }
    function claimMaxGas(address, address) external returns (uint256) {
        return 0;
    }
    function claimGas(
        address,
        address,
        uint256,
        uint256
    ) external returns (uint256) {
        return 0;
    }

    // read functions
    function readClaimableYield(address) external view returns (uint256) {
        return 0;
    }
    function readYieldConfiguration(address) external view returns (uint8) {
        return 0;
    }
    function readGasParams(
        address
    )
        external
        view
        returns (
            uint256 etherSeconds,
            uint256 etherBalance,
            uint256 lastUpdated,
            GasMode
        )
    {
        return (0, 0, 0, GasMode.CLAIMABLE);
    }
}
