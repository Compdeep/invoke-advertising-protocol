//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract EngageToken is ERC20, AccessControlEnumerable {

    // access control roles
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant GOVERNMENT_ROLE = keccak256("GOVERNMENT_ROLE");

    struct Supply {
        uint256 max; // single limit of each mint
        uint256 cap; // total limit of all mint
        uint256 total; // total minted minus burned
    }

    // placeholder for minter supply
    mapping(address => Supply) public minterSupply;

    // Wei per token
    uint8 constant DECIMALS = 18;

    // Set a Max and Min Supply
    uint256 constant MIN_SUPPLY = 500000000 * 10**uint256(DECIMALS);
    uint256 constant MAX_SUPPLY = 2000000000 * 10**uint256(DECIMALS);

    // 1 Bln Initial Supply
    uint256 constant INITIAL_SUPPLY = 1000000000 * 10**uint256(DECIMALS);

    // Support for EIP-712
    bytes32 private DOMAIN_SEPARATOR;
    bytes32 private constant DOMAIN_NAME_HASH = keccak256("Invoke Network Engage Token");
    bytes32 private constant DOMAIN_VERSION_HASH = keccak256("0");
    bytes32 private constant DOMAIN_TYPE_HASH = keccak256("EIP712Domain(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    mapping(address => uint256) public nonces;

    /*
     * @dev Invoke Network Engage Token Contract Constructor.
     * @param _government address
     */
    constructor(address _government) ERC20("Invoke Network Engage Token", "ENGAGE") {

        // Creator(owner) initial mintable token supply
        _grantRole(MINTER_ROLE, msg.sender);
        _mint(msg.sender, INITIAL_SUPPLY);
        _revokeRole(MINTER_ROLE, msg.sender);

        // Enable government (uncapped)
        _grantRole(GOVERNMENT_ROLE, _government);
        _grantRole(MINTER_ROLE, _government);

        // Generate the EIP-712 domain separator
        DOMAIN_SEPARATOR = _buildDomainSeparator(DOMAIN_TYPE_HASH, DOMAIN_NAME_HASH, DOMAIN_VERSION_HASH);
    }

    function addMinter(address minter, uint256 cap, uint256 max) external onlyRole(GOVERNMENT_ROLE) {
        _grantRole(MINTER_ROLE, minter);
        minterSupply[minter].cap = cap;
        minterSupply[minter].max = max;
    }

    function removeMinter(address minter) external onlyRole(GOVERNMENT_ROLE) {
        _revokeRole(MINTER_ROLE, minter);
        minterSupply[minter].cap = 0;
        minterSupply[minter].max = 0;
    }

    // Set Minter Caps

    function setMinterCap(address minter, uint256 cap) external onlyRole(GOVERNMENT_ROLE) {
        require(hasRole(MINTER_ROLE, minter), "not minter");
        minterSupply[minter].cap = cap;
    }

    function setMinterMax(address minter, uint256 max) external onlyRole(GOVERNMENT_ROLE) {
        require(hasRole(MINTER_ROLE, minter), "not minter");
        minterSupply[minter].max = max;
    }

    function setMinterTotal(address minter, uint256 total, bool force) external onlyRole(GOVERNMENT_ROLE) {
        require(force || hasRole(MINTER_ROLE, minter), "not minter");
        minterSupply[minter].total = total;
    }
 
    /**
     * @dev EIP712 approval for token allowance
     * @param _owner Address of the token holder
     * @param _spender Address of the approved spender
     * @param _value Amount of tokens to approve the spender
     * @param _deadline Expiration time of the signed approval
     * @param _v Signature version
     * @param _r Signature r value
     * @param _s Signature s value
     */
    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external {
        require(_deadline == 0 || block.timestamp <= _deadline, "NGE: approval expired");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(DOMAIN_TYPE_HASH, _owner, _spender, _value, nonces[_owner]++, _deadline)
                )
            )
        );

        address recoveredAddress = ecrecover(digest, _v, _r, _s);
        require(recoveredAddress != address(0) && _owner == recoveredAddress, "ENGAGE: Invalid EIP712 Approval");

        _approve(_owner, _spender, _value);
    }

    // Views

    function _buildDomainSeparator(bytes32 _typeHash, bytes32 _name, bytes32 _version) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                _typeHash,
                _name,
                _version,
                block.chainid,
                address(this)
            )
        );
    }

    function getOwner() external view returns (address) {
        return getRoleMember(GOVERNMENT_ROLE, 0);
    }

    function underlying() external view virtual returns (address) {
        return address(0);
    }

}
