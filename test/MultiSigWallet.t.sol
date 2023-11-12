// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.21;
import {Test, console2} from "forge-std/Test.sol";
import {MultiSigWallet, TestContract} from "../src/MultiSigWallet.sol";

contract TestMultiSigWallet is Test {
    MultiSigWallet public wallet;
    TestContract public walletTest;
    address[] sigwallet;

    // struct Transaction {
    //     uint256 _transactionId;
    //     address _from;
    //     uint256 _value;
    //     bytes data;
    //     bool isExecuted;
    //     uint256 numberOfConfirmation;
    // }

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

    function submit(uint256 _data) public returns (uint256, bytes memory) {
        bytes memory data = walletTest.getData(_data);
        uint256 id = wallet.submitTransaction(address(walletTest), data);
        return (id, data);
    }

    function testSubmit() external {
        vm.startPrank(address(1));
        (uint256 id, ) = submit(123);
        uint256 tranId = wallet.getTransactionId();
        assertEq(id, tranId);
        vm.stopPrank();
        console2.log();
    }

    function testConfirmAndExecute() external {
        vm.startPrank(address(1));
        (uint256 id, ) = submit(123);
        wallet.confirmTransaction(id);
        vm.stopPrank();
        vm.startPrank(address(2));
        wallet.confirmTransaction(id);
        uint256 returnValue = walletTest.i();
        assertEq(returnValue, 123);

        vm.stopPrank();
    }

    function testConfirmAndExecuteFuzz(uint256 _id) external {
        vm.startPrank(address(1));
        (uint256 id, ) = submit(_id);
        wallet.confirmTransaction(id);
        vm.stopPrank();
        vm.prank(address(4));
        vm.expectRevert();
        wallet.confirmTransaction(id);
        vm.startPrank(address(2));
        wallet.confirmTransaction(id);

        uint256 returnValue = walletTest.i();
        assertEq(returnValue, _id);

        vm.stopPrank();
    }

    function testSignature() external {
        uint256 id = wallet.getSignature();
        assertEq(id, sigwallet.length - 1);
    }

    function testrevoke(uint256 _id) external {
        vm.startPrank(address(1));
        (uint256 id, ) = submit(_id);
        wallet.confirmTransaction(id);
        bool result = wallet.getConfirmation(id);
        assertEq(result, true);
        wallet.revokeConfirmation(id);
        result = wallet.getConfirmation(id);
        assertEq(result, false);
    }

    function testViewTransaction() external {
        vm.startPrank(address(1));
        (uint256 id, bytes memory data) = submit(123);
        MultiSigWallet.Transaction memory transaction = wallet.viewTransaction(
            id
        );
        // console2.log(transaction._transactionId);
        assertEq(transaction._transactionId, id);
        assertEq(transaction._from, address(walletTest));
        assertEq(transaction.data, data);
    }
}
