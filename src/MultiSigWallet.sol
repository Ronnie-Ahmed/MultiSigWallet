// Layout of Contract:
// version
// imports
// errors
// interfaces, libraries, contracts
// Type declarations
// State variables
// Events
// Modifiers
// Functions

// Layout of Functions:
// constructor
// receive function (if exists)
// fallback function (if exists)
// external
// public
// internal
// private
// internal & private view & pure functions
// external & public view & pure functions

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

contract MultiSigWallet {
    address[] signers;
    uint256 needSignature;
    mapping(address => bool) isValidSigner;
    uint256 transactionId = 0;
    mapping(uint256 => Transaction) getTransaction;
    mapping(uint256 => mapping(address => bool)) didIconfirm;

    event deposited(
        address indexed from,
        address indexed _to,
        uint256 indexed _value
    );

    struct Transaction {
        uint256 _transactionId;
        address _from;
        uint256 _value;
        bytes data;
        bool isExecuted;
        uint256 numberOfConfirmation;
    }

    modifier validTransaction(uint256 id) {
        require(id <= transactionId && id > 0, "Transaction Id Does Not Exist");
        _;
    }

    modifier onlyOwner() {
        require(isValidSigner[msg.sender]);
        _;
    }

    modifier isExecuted(uint256 id) {
        require(!getTransaction[id].isExecuted, "ALready got executed");
        _;
    }

    constructor(address[] memory _signers, uint256 _needSignature) {
        require(_needSignature > 0 && _needSignature <= _signers.length);
        for (uint256 i = 0; i < _signers.length; i++) {
            address _address = _signers[i];
            require(!isValidSigner[_address], "Already a signer");
            require(_address != address(0), "Need A valid Address");
            isValidSigner[_address] = true;
            signers.push(_address);
            needSignature = _needSignature;
        }
    }

    receive() external payable {
        emit deposited(msg.sender, address(this), msg.value);
    }

    function submitTransaction(
        address _from,
        bytes memory _data
    ) external payable onlyOwner returns (uint256) {
        transactionId += 1;
        getTransaction[transactionId] = Transaction(
            transactionId,
            _from,
            msg.value,
            _data,
            false,
            0
        );
        return transactionId;
    }

    function confirmTransaction(
        uint256 _txId
    ) external onlyOwner validTransaction(_txId) isExecuted(_txId) {
        require(!didIconfirm[_txId][msg.sender], "Already confirmed");
        getTransaction[_txId].numberOfConfirmation += 1;
        didIconfirm[_txId][msg.sender] = true;
        uint256 confirmNumber = getTransaction[_txId].numberOfConfirmation;

        if (confirmNumber == needSignature) {
            executeTransaction(_txId);
        }
    }

    function revokeConfirmation(
        uint256 _txId
    ) external onlyOwner validTransaction(_txId) isExecuted(_txId) {
        getTransaction[_txId].numberOfConfirmation -= 1;
        didIconfirm[_txId][msg.sender] = false;
    }

    // function sendEther(address _address) public payable {
    //     (bool success, ) = _address.call{value: msg.value}("");
    //     require(success,"Transfer Failed");
    // }

    function executeTransaction(uint256 _txId) internal {
        Transaction storage transaction = getTransaction[_txId];
        (bool success, ) = transaction._from.call{value: transaction._value}(
            transaction.data
        );
        require(success, "Transaction complete");
        transaction.isExecuted = true;
    }

    function getAllSigner() external view returns (address[] memory) {
        return signers;
    }

    function viewTransaction(
        uint256 _txId
    ) external view validTransaction(_txId) returns (Transaction memory) {
        return getTransaction[_txId];
    }

    function getTransactionId() external view returns (uint256) {
        return transactionId;
    }

    function getSignature() external view returns (uint256) {
        return needSignature;
    }

    function getConfirmation(uint256 _txId) external view returns (bool) {
        return didIconfirm[_txId][msg.sender];
    }
}

contract TestContract {
    uint public i;

    function callMe(uint j) public {
        i += j;
    }

    function getData(uint j) public pure returns (bytes memory) {
        return abi.encodeWithSignature("callMe(uint256)", j);
    }
}
