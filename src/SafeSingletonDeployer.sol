// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {VmSafe, Vm} from "forge-std/Vm.sol";

/// @notice Library for deploying contracts using Safe's Singleton Factory
///         https://github.com/safe-global/safe-singleton-factory
library SafeSingletonDeployer {
    error MissingSafeSingletonFactory();
    error DeployFailed();

    address constant SAFE_SINGLETON_FACTORY = 0x914d7Fec6aaC8cd542e72Bca78B30650d45643d7;

    // cast code 0x914d7Fec6aaC8cd542e72Bca78B30650d45643d7 --rpc-url https://mainnet.base.org
    bytes constant factoryCode =
        hex"7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe03601600081602082378035828234f58015156039578182fd5b8082525050506014600cf3";

    VmSafe private constant VM = VmSafe(address(uint160(uint256(keccak256("hevm cheat code")))));

    function computeAddress(bytes memory creationCode, bytes32 salt) public pure returns (address) {
        return computeAddress(creationCode, "", salt);
    }

    function computeAddress(bytes memory creationCode, bytes memory args, bytes32 salt) public pure returns (address) {
        return VM.computeCreate2Address({
            salt: salt,
            initCodeHash: _hashInitCode(creationCode, args),
            deployer: SAFE_SINGLETON_FACTORY
        });
    }

    function broadcastDeploy(bytes memory creationCode, bytes memory args, bytes32 salt) internal returns (address) {
        VM.broadcast();
        return _deploy(creationCode, args, salt);
    }

    function broadcastDeploy(bytes memory creationCode, bytes32 salt) internal returns (address) {
        VM.broadcast();
        return _deploy(creationCode, "", salt);
    }

    function broadcastDeploy(address deployer, bytes memory creationCode, bytes memory args, bytes32 salt)
        internal
        returns (address)
    {
        VM.broadcast(deployer);
        return _deploy(creationCode, args, salt);
    }

    function broadcastDeploy(address deployer, bytes memory creationCode, bytes32 salt) internal returns (address) {
        VM.broadcast(deployer);
        return _deploy(creationCode, "", salt);
    }

    function broadcastDeploy(uint256 deployerPrivateKey, bytes memory creationCode, bytes memory args, bytes32 salt)
        internal
        returns (address)
    {
        VM.broadcast(deployerPrivateKey);
        return _deploy(creationCode, args, salt);
    }

    function broadcastDeploy(uint256 deployerPrivateKey, bytes memory creationCode, bytes32 salt)
        internal
        returns (address)
    {
        VM.broadcast(deployerPrivateKey);
        return _deploy(creationCode, "", salt);
    }

    /// @dev Allows calling without Forge broadcast
    function deploy(bytes memory creationCode, bytes memory args, bytes32 salt) internal returns (address) {
        return _deploy(creationCode, args, salt);
    }

    /// @dev Allows calling without Forge broadcast
    function deploy(bytes memory creationCode, bytes32 salt) internal returns (address) {
        return _deploy(creationCode, "", salt);
    }

    function _deploy(bytes memory creationCode, bytes memory args, bytes32 salt) private returns (address) {
        // ensure Safe Singleton Factory exists if we're deploying to anvil
        prepareAnvil();

        if (SAFE_SINGLETON_FACTORY.code.length == 0) {
            revert MissingSafeSingletonFactory();
        }

        bytes memory callData = abi.encodePacked(salt, creationCode, args);

        (bool success, bytes memory result) = SAFE_SINGLETON_FACTORY.call(callData);

        if (!success) {
            // contract does not pass on revert reason
            // https://github.com/Arachnid/deterministic-deployment-proxy/blob/master/source/deterministic-deployment-proxy.yul#L13
            revert DeployFailed();
        }

        return address(bytes20(result));
    }

    function _hashInitCode(bytes memory creationCode, bytes memory args) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(creationCode, args));
    }

    function prepareAnvil() public {
        if (block.chainid == 31337) {
            Vm(address(VM)).etch(SafeSingletonDeployer.SAFE_SINGLETON_FACTORY, factoryCode);
        }
    }
}
