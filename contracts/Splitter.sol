// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract Splitter is Context {
    using SafeERC20 for IERC20;

    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);
    event ERC20PaymentReleased(IERC20 indexed token, address to, uint256 amount);
    event PaymentReceived(address from, uint256 amount);
    event ReleaseRequested(address indexed account);
    event ReleaseApproved(address indexed guardian, address indexed account);
    event ReleaseRevoked(address indexed guardian, address indexed account);

    uint256 private _totalShares;
    uint256 private _totalReleased;
    address private _daoAddress = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;

    mapping(address => uint256) public _shares;
    mapping(address => uint256) private _released;
    address[] public _payees;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(address => uint256)) private _erc20Released;

    address[] private _guardians;
    mapping(address => bool) public isGuardian;
    mapping(address => bool) public releaseRequests;
    mapping(address => uint256) public releaseApprovals;

    constructor(address[] memory payees, uint256[] memory shares_, address[] memory guardians) payable {
        require(payees.length == shares_.length, "Splitter: payees and shares length mismatch");
        require(payees.length > 0, "Splitter: no payees");
        require(guardians.length == 3, "Splitter: Requires exactly three guardians");

        for (uint256 i = 0; i < payees.length; i++) {
            _addPayee(payees[i], shares_[i]);
        }

        for (uint256 i = 0; i < guardians.length; i++) {
            _guardians.push(guardians[i]);
            isGuardian[guardians[i]] = true;
        }
    }

    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    function requestRelease() public {
        require(_shares[msg.sender] > 0, "Splitter: You have no shares to release");
        require(!releaseRequests[msg.sender], "Splitter: Release already requested");

        releaseRequests[msg.sender] = true;
        emit ReleaseRequested(msg.sender);
    }

    function approveRelease(address payable account) public {
        require(isGuardian[msg.sender], "Splitter: Only guardians can approve");
        require(releaseRequests[account], "Splitter: Release not requested for this account");

        releaseApprovals[account]++;
        emit ReleaseApproved(msg.sender, account);
    }

    function revokeApproval(address payable account) public {
        require(isGuardian[msg.sender], "Splitter: Only guardians can revoke approval");
        require(releaseApprovals[account] > 0, "Splitter: No approvals to revoke for this account");

        releaseApprovals[account]--;
        emit ReleaseRevoked(msg.sender, account);
    }

    function release(address payable account) public virtual {
        require(releaseRequests[account], "Splitter: Release not requested for this account");
        require(releaseApprovals[account] >= 2, "Splitter: Not approved by at least 2 guardians");

        uint256 payment = releasable(account);
        require(payment != 0, "Splitter: account is not due payment");
        uint256 daoFee = payment / 100;
        payment -= daoFee;

        _totalReleased += payment;
        _released[account] += payment;

        Address.sendValue(payable(_daoAddress), daoFee);
        Address.sendValue(account, payment);
        emit PaymentReleased(account, payment);

        delete releaseRequests[account];
        delete releaseApprovals[account];
    }

    function getPendingRequests() public view returns (address[] memory) {
        uint256 count = 0;
        for (uint256 i = 0; i < _payees.length; i++) {
            if (releaseRequests[_payees[i]]) count++;
        }

        address[] memory pendingRequests = new address[](count);
        uint256 index = 0;
        for (uint256 i = 0; i < _payees.length; i++) {
            if (releaseRequests[_payees[i]]) {
                pendingRequests[index] = _payees[i];
                index++;
            }
        }
        return pendingRequests;
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an account.
     */
    function shares(address account) public view returns (uint256) {
        return _shares[account];
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee.
     */
    function released(address account) public view returns (uint256) {
        return _released[account];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee. `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20 token, address account) public view returns (uint256) {
        return _erc20Released[token][account];
    }

    /**
     * @dev Getter for the address of the payee number `index`.
     */
    function payee(uint256 index) public view returns (address) {
        return _payees[index];
    }

    /**
     * @dev Getter for the amount of payee's releasable Ether.


    /**
     * @dev Getter for the amount of payee's releasable `token` tokens. `token` should be the address of an
     * IERC20 contract.
     */
    function releasable(IERC20 token, address account) public view returns (uint256) {
        uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token);
        return _pendingPayment(account, totalReceived, released(token, account));
    }
    function releasable(address account) public view returns (uint256) {
        uint256 totalReceived = address(this).balance + _totalReleased;
        return _pendingPayment(account, totalReceived, _released[account]);
    }

    function _pendingPayment(address account, uint256 totalReceived, uint256 alreadyReleased) private view returns (uint256) {
        return (totalReceived * _shares[account]) / _totalShares - alreadyReleased;
    }

    function _addPayee(address account, uint256 shares_) private {
        require(account != address(0), "Splitter: account is the zero address");
        require(shares_ > 0, "Splitter: shares are 0");
        require(_shares[account] == 0, "Splitter: account already has shares");

        _payees.push(account);
        _shares[account] = shares_;
        _totalShares += shares_;
        emit PayeeAdded(account, shares_);
    }
}
