// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.21;
import {Test, console2} from "forge-std/Test.sol";
import {MultiSigWallet} from "../src/MultiSigWallet.sol";
import {TestContract} from "../src/MultiSigWallet.sol";

contract TestMultiSigWallet is Test {
    MultiSigWallet public wallet;
    TestContract public walletTest;
    address[] sigwallet;

    function setWallet() internal {
        for (uint256 i = 1; i < 4; i++) {
            sigwallet.push(address(uint160(i)));
        }
    }

    function setUp() external {
        setWallet();
        uint256 walletNum = sigwallet.length - 1;
        wallet = new MultiSigWallet(sigwallet, walletNum);
        walletTest = new TestContract();
    }

    function testAddress() external {
        address[] memory tempSigner = wallet.getAllSigner();
        for (uint256 i = 0; i < tempSigner.length; i++) {
            assertEq(tempSigner[i], sigwallet[i]);
            console2.log("address is : ", sigwallet[i]);
        }
    }

    function submit(uint256 _data) public returns (uint256) {
        bytes memory data = walletTest.getData(_data);
        uint256 id = wallet.submitTransaction(address(walletTest), data);
        return id;
    }

    function testSubmit() external {
        vm.startPrank(address(1));
        uint256 id = submit(123);
        uint256 tranId = wallet.getTransactionId();
        assertEq(id, tranId);
        vm.stopPrank();
        console2.log();
    }

    function testConfirmAndExecute() external {
        vm.startPrank(address(1));
        uint256 id = submit(123);
        wallet.confirmTransaction(id);
        vm.stopPrank();
        vm.startPrank(address(2));
        wallet.confirmTransaction(id);
        uint256 returnValue = walletTest.i();
        assertEq(returnValue, 123);

        vm.stopPrank();
    }
}
