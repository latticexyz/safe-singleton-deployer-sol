// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {SafeSingletonDeployer} from "../src/SafeSingletonDeployer.sol";

import {Mock} from "./Mock.sol";
import {MockReverting} from "./MockReverting.sol";

contract SafeSingletonDeployerTest is Test {
    function test_deploy_createsAtExpectedAddress() public {
        address expectedAddress =
            SafeSingletonDeployer.computeAddress(type(Mock).creationCode, abi.encode(1), bytes32("0x1234"));
        assertEq(expectedAddress.code, "");
        address returnAddress = SafeSingletonDeployer.deploy({
            creationCode: type(Mock).creationCode,
            args: abi.encode(1),
            salt: bytes32("0x1234")
        });
        assertEq(returnAddress, expectedAddress);
        assertNotEq(expectedAddress.code, "");
    }

    function test_deploy_createsContractCorrectly() public {
        uint256 startValue = 1;
        address mock = SafeSingletonDeployer.deploy({
            creationCode: type(Mock).creationCode,
            args: abi.encode(1),
            salt: bytes32("0x1234")
        });
        assertEq(startValue, Mock(mock).value());
        uint256 newValue = 2;
        Mock(mock).setValue(newValue);
        assertEq(newValue, Mock(mock).value());
    }

    function test_deploy_reverts() public {
        vm.expectRevert();
        SafeSingletonDeployer.deploy({
            creationCode: type(MockReverting).creationCode,
            args: abi.encode(1),
            salt: bytes32("0x1234")
        });
    }

    function test_deploy_chainWithoutFactory() public {
        vm.chainId(1);
        vm.expectRevert(SafeSingletonDeployer.MissingSafeSingletonFactory.selector);
        SafeSingletonDeployer.deploy({
            creationCode: type(Mock).creationCode,
            args: abi.encode(1),
            salt: bytes32("0x1234")
        });
    }
}
