// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract Ownable {
    address public immutable owner;

    error NotOwner();

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert NotOwner();
        }

        _;
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function mint(address to, uint256 amount) external;
    function burn(uint256 amount) external;
}

contract PortoToken is Ownable, IERC20 {
    string public name;
    string public symbol;

    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) private balances;
    mapping(address => mapping(address => uint256)) private allowances;

    error InvalidAddress();
    error NotEnoughtAmount();
    error NotEnoughtAllowance();
    error ZeroAmount();

    constructor() {
        name = "PortoToken";
        symbol = "PORTO";

        totalSupply = 1_000_000 * (10 ** uint256(decimals));
        balances[msg.sender] = totalSupply;
    }

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    function balanceOf(address account) external view override returns (uint256) {
        if (account == address(0)) {
            revert InvalidAddress();
        }

        return balances[account];
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        if (to == address(0)) {
            revert InvalidAddress();
        }

        if (balances[msg.sender] < amount) {
            revert NotEnoughtAmount();
        }

        balances[msg.sender] -= amount;
        balances[to] += amount;

        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        if (spender == address(0)) {
            revert InvalidAddress();
        }

        allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) external view override returns (uint256) {
        if (owner == address(0)) {
            revert InvalidAddress();
        }

        if (spender == address(0)) {
            revert InvalidAddress();
        }

        return allowances[owner][spender];
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        if (from == address(0)) {
            revert InvalidAddress();
        }

        if (to == address(0)) {
            revert InvalidAddress();
        }

        if (balances[from] < amount) {
            revert NotEnoughtAmount();
        }

        if (allowances[from][msg.sender] < amount) {
            revert NotEnoughtAllowance();
        }

        balances[from] -= amount;
        balances[to] += amount;
        allowances[from][msg.sender] -= amount;

        emit Transfer(from, to, amount);
        return true;
    }

    function mint(address to, uint256 amount) external override onlyOwner {
        if (to == address(0)) {
            revert InvalidAddress();
        }

        if (amount == 0) {
            revert ZeroAmount();
        }

        totalSupply += amount;
        balances[to] += amount;

        emit Transfer(address(0), to, amount);
    }

    function burn(uint256 amount) external {
        if (amount == 0) {
            revert ZeroAmount();
        }

        if (balances[msg.sender] < amount) {
            revert NotEnoughtAmount();
        }

        balances[msg.sender] -= amount;
        totalSupply -= amount;

        emit Transfer(msg.sender, address(0), amount);
    }
}
