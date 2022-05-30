//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

//import "./interfaces/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./EngageToken.sol";

contract AccountsEscrow is Initializable, OwnableUpgradeable {

    address engage;
    mapping (address => uint256) balance;
    mapping (address => uint) index;

    // address list.
    address[] store;

    // events
    event transferEvent(address _from, address _to, uint256 _amount);
    event balanceEvent(address _account, uint256 _amount);

    /*
     * @dev constructor
     * @params engage token contract address
     */
    function initialize(address _engage) public initializer {
        engage = _engage;
    }

    /*
     * @dev update user balance
     * @params _amount to add, campaign address to credit
     * @emit to(owner), from(this), _amount to transfer
     */
    function addToBalance(uint256 _amount, address _account) public {
        require(_amount > 0, "Please provide a positive amount");
        EngageToken et = EngageToken(engage);
        require(et.allowance(msg.sender, address(this)) >= _amount, "Insuficient Allowance");
        require(et.transferFrom(msg.sender, address(this), _amount), "token transfer failed");
        _appendAccount(_account);
        _addAccountBalance(_account, _amount);
        emit balanceEvent(_account, balance[_account]);
        emit transferEvent(address(this), msg.sender, _amount);
    }

    /*
     * @dev transfer funds out to owner wallet.
     * @params _amount to transfer
     * @emit from(this), to(owner), amount to transfer
     */
    function retrieveFunds(uint256 _amount) public {
        require(_amount > balance[msg.sender], "insufficient balance");
        EngageToken et = EngageToken(engage);
        _remAccountBalance(msg.sender, _amount);
        require(et.transferFrom(address(this), msg.sender, _amount), "token transfer failed");
        emit transferEvent(address(this), msg.sender, _amount);
    }

    /*
     * @dev process accounts
     * @params _accounts to process, _amount to credit for each
     */
    function process(address[] memory _accounts, uint256[] memory _amounts) external {
        for(uint i=0; i<_accounts.length; i++) {
            _moveFunds(_accounts[i], _amounts[i]);
        }
    }
    
    /*
     * @dev adjust balances ensuring accounts have enoug
     * @params _account to process, _amount to credit.
     */
    function _moveFunds(address _account, uint256 _amount) private {
        require(balance[msg.sender] > 0, "insufficient balance");
        require(balance[msg.sender] >= _amount, "insufficient balance");
        _appendAccount(_account);
        _remAccountBalance(msg.sender, _amount);
        _addAccountBalance(_account, _amount);
    }

    function _appendAccount(address _addr) private {
        if (!exists(_addr)) {
            index[_addr] = store.length;
            store.push(_addr);
        }
    }

    function _addAccountBalance(address _addr, uint256 amount) private {
        if (exists(_addr)) {
            balance[_addr] += amount;
        }
    }

    function _remAccountBalance(address _addr, uint256 amount) private {
        if (exists(_addr)) {
            balance[_addr] -= amount;
        }
    }

    function exists(address _addr) private view returns (bool) {
        if (index[_addr] > 0) {
            return true;
        }
        return false;
    }
    
    /*
     * ----------- Setters -----------
     */

    function resetAccountBalance(address _addr) public onlyOwner {
        if (exists(_addr)) {
            balance[_addr] = 0;
        }
    }

    /*
     * ----------- Getters (View) -----------
     */
    
    function getAccountsLength() public view returns (uint) {
        return store.length;
    }

    function getAccountAddress(uint i) public view returns (address) {
        return store[i];
    }

    function getAccountBalance(address _addr) public view returns (uint256) {
        return balance[_addr];
    }

}
