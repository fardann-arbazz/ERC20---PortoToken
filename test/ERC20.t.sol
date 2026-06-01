// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {PortoToken} from "../src/ERC20.sol";

contract ERC20Test is Test {
    PortoToken public token;

    address public owner;
    address public alice;
    address public bob;
    address public charlie;

    uint8 constant DECIMALS = 18;
    uint256 constant INITIAL_SUPPLY = 1_000_000 * (10 ** DECIMALS);

    // Events
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    // SetUp
    function setUp() public {
        owner = address(this);
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");

        token = new PortoToken();
    }

    // ===================== Deploy/Constructor Test =========================

    // Test Token Name
    function test_InitialName() public view {
        assertEq(token.name(), "PortoToken");
    }

    // Test Token Symbol
    function test_InitialSymbol() public view {
        assertEq(token.symbol(), "PORTO");
    }

    // Test Token Decimals
    function test_InitialDecimals() public view {
        assertEq(token.decimals(), 18);
    }

    // Test Token TotalSupply
    function test_InitialTotalSupply() public view {
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
    }

    // Test Initial Balance Owner
    function test_InitialBalanceOwner() public view {
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
    }

    // Test Owner Is Deploy
    function test_OwnerIsDeployer() public view {
        assertEq(token.owner(), owner);
    }

    // ===================== BalanceOf Test =========================

    // Test BalanceOf Berhasil
    function test_BalanceOf_ZeroForNewAddress() public view {
        assertEq(token.balanceOf(alice), 0);
    }

    // Test BalanceOf Revert InvalidAddress
    function test_BalanceOf_RevertsOnZeroAddress() public {
        vm.expectRevert(PortoToken.InvalidAddress.selector);
        token.balanceOf(address(0));
    }

    // ===================== Transfer Test =========================

    // Test Transfer Success
    function test_Transfer_Success() public {
        uint256 amount = 100 * 10 ** DECIMALS;

        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, alice, amount);

        bool ok = token.transfer(alice, amount);
        assertTrue(ok);
        assertEq(token.balanceOf(alice), amount);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - amount);
    }

    // Test Transfer Revert Invalid Address
    function test_Transfer_RevertsOnZeroAddress() public {
        vm.expectRevert(PortoToken.InvalidAddress.selector);
        token.transfer(address(0), 1);
    }

    // Test Transfer Revert NotEnoughtAmount
    function test_Transfer_RevertsOnInsufficientBalance() public {
        vm.prank(alice); // alice has 0 tokens
        vm.expectRevert(PortoToken.NotEnoughtAmount.selector);
        token.transfer(bob, 1);
    }

    // Test Transfer FullBalance
    function test_Transfer_FullBalance() public {
        bool ok = token.transfer(alice, INITIAL_SUPPLY);
        assertTrue(ok);
        assertEq(token.balanceOf(owner), 0);
        assertEq(token.balanceOf(alice), INITIAL_SUPPLY);
    }

    // Test Transfer 0 Amount
    function test_Transfer_ZeroAmount() public {
        // Transfer 0 tidak harus revert (ERC-20 standar memperbolehkan)
        bool ok = token.transfer(alice, 0);
        assertTrue(ok);
    }

    // Test Transfer Self
    function test_Transfer_ToSelf() public {
        uint256 amount = 500;
        bool ok = token.transfer(owner, amount);
        assertTrue(ok);
        // Saldo tidak berubah
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
    }

    // Test Fuzz Transfer
    function testFuzz_Transfer(uint256 amount) public {
        amount = bound(amount, 0, INITIAL_SUPPLY);
        token.transfer(alice, amount);
        assertEq(token.balanceOf(alice), amount);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - amount);
    }

    // ===================== Approve & Allowance Test =========================

    // Test Approve Success
    function test_Approve_Success() public {
        uint256 amount = 500;

        vm.expectEmit(true, true, false, true);
        emit Approval(owner, alice, amount);

        bool ok = token.approve(alice, amount);
        assertTrue(ok);
        assertEq(token.allowance(owner, alice), amount);
    }

    // Test Approve Revert InvalidAddress
    function test_Approve_RevertsOnZeroSpender() public {
        vm.expectRevert(PortoToken.InvalidAddress.selector);
        token.approve(address(0), 100);
    }

    // Test Allowance Revert InvalidAddress Owner
    function test_Allowance_RevertsOnZeroOwner() public {
        vm.expectRevert(PortoToken.InvalidAddress.selector);
        token.allowance(address(0), alice);
    }

    // Test Allowance Revert InvalidAddress Spender
    function test_Allowance_RevertsOnZeroSpender() public {
        vm.expectRevert(PortoToken.InvalidAddress.selector);
        token.allowance(owner, address(0));
    }

    // Test Allowance Default Value
    function test_Allowance_DefaultIsZero() public view {
        assertEq(token.allowance(alice, bob), 0);
    }

    // Test Approve Overwrite
    function test_Approve_Overwrite() public {
        token.approve(alice, 100);
        token.approve(alice, 200);
        assertEq(token.allowance(owner, alice), 200);
    }

    // Test Approve Reset
    function test_Approve_ZeroResetsAllowance() public {
        token.approve(alice, 500);
        token.approve(alice, 0);
        assertEq(token.allowance(owner, alice), 0);
    }

    // ===================== TransferFrom Test =========================

    // Test TransferFrom Success
    function test_TransferFrom_Success() public {
        uint256 amount = 200 * 10 ** DECIMALS;
        token.transfer(alice, amount); // owner -> alice
        vm.prank(alice);
        token.approve(bob, amount); // alice approves bob

        vm.expectEmit(true, true, false, true);
        emit Transfer(alice, charlie, amount);

        vm.prank(bob);
        bool ok = token.transferFrom(alice, charlie, amount);
        assertTrue(ok);
        assertEq(token.balanceOf(charlie), amount);
        assertEq(token.balanceOf(alice), 0);
        assertEq(token.allowance(alice, bob), 0); // allowance berkurang
    }

    // Test TransferFrom Revert to InvalidAddress
    function test_TransferFrom_RevertsOnZeroTo() public {
        token.transfer(alice, 100);
        vm.prank(alice);
        token.approve(bob, 100);

        vm.prank(bob);
        vm.expectRevert(PortoToken.InvalidAddress.selector);
        token.transferFrom(alice, address(0), 100);
    }

    // Test TransferFrom Revert from and to InvalidAddress
    function test_TransferFrom_ShouldRevertOnZeroFrom() public {
        vm.expectRevert(PortoToken.InvalidAddress.selector);
        token.transferFrom(address(0), alice, 0);
    }

    // Test TransferFrom Revert NotEnoughtAmount
    function test_TransferFrom_RevertsOnInsufficientBalance() public {
        vm.prank(alice);
        token.approve(bob, 100);

        vm.prank(bob);
        vm.expectRevert(PortoToken.NotEnoughtAmount.selector);
        token.transferFrom(alice, charlie, 100);
    }

    // Test TransferFrom Revert NotEnoughtAllowance
    function test_TransferFrom_RevertsOnInsufficientAllowance() public {
        token.transfer(alice, 1000);
        vm.prank(alice);
        token.approve(bob, 50);

        vm.prank(bob);
        vm.expectRevert(PortoToken.NotEnoughtAllowance.selector);
        token.transferFrom(alice, charlie, 100);
    }

    // Test TranferFrom Pengurangan Allowance
    function test_TransferFrom_DecreasesAllowance() public {
        uint256 approveAmount = 500;
        uint256 transferAmount = 200;
        token.transfer(alice, approveAmount);
        vm.prank(alice);
        token.approve(bob, approveAmount);

        vm.prank(bob);
        token.transferFrom(alice, charlie, transferAmount);
        assertEq(token.allowance(alice, bob), approveAmount - transferAmount);
    }

    // ===================== Mint Test =========================

    // Test Mint Success
    function test_Mint_Success() public {
        uint256 amount = 1000 * 10 ** DECIMALS;

        // Konvensi ERC-20: mint harus emit Transfer(address(0), to, amount)
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), alice, amount);

        token.mint(alice, amount);
        assertEq(token.balanceOf(alice), amount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY + amount);
    }

    // Test Mint Revert InvalidAddress
    function test_Mint_RevertsOnZeroAddress() public {
        vm.expectRevert(PortoToken.InvalidAddress.selector);
        token.mint(address(0), 100);
    }

    // Test Mint Revert ZeroAmount
    function test_Mint_RevertsOnZeroAmount() public {
        vm.expectRevert(PortoToken.ZeroAmount.selector);
        token.mint(alice, 0);
    }

    // Test Mint Increasing Total Supply
    function test_Mint_IncreasesTotalSupply() public {
        uint256 amount = 5000;
        token.mint(alice, amount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY + amount);
    }

    // Test Mint OnlyOwner
    function test_Mint_ShouldRevertIfNotOwner() public {
        vm.prank(alice); // alice bukan owner
        vm.expectRevert(abi.encodeWithSignature("NotOwner()"));
        token.mint(bob, 1000);
    }

    // Test Mint Event
    function test_Mint_EmitShouldUseZeroAddressAsFrom() public {
        uint256 amount = 100;
        vm.expectEmit(true, true, false, true);
        emit Transfer(address(0), alice, amount);
        token.mint(alice, amount);
    }

    // Test Fuzz Mint
    function testFuzz_Mint(uint256 amount) public {
        amount = bound(amount, 1, type(uint128).max);
        token.mint(alice, amount);
        assertEq(token.balanceOf(alice), amount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY + amount);
    }

    // ===================== Burn Test =========================

    // Test Burn Succeess
    function test_Burn_Success() public {
        uint256 amount = 100 * 10 ** DECIMALS;

        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, address(0), amount);

        token.burn(amount);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - amount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY - amount);
    }

    // Test Burn Revert NotEnoughtAmount
    function test_Burn_RevertsOnInsufficientBalance() public {
        vm.prank(alice); // alice balance = 0
        vm.expectRevert(PortoToken.NotEnoughtAmount.selector);
        token.burn(1);
    }

    // Test Burn Revert ZeroAmount
    function test_Burn_RevertsOnZeroAmount() public {
        vm.expectRevert(PortoToken.ZeroAmount.selector);
        token.burn(0);
    }

    // Test Burn Full
    function test_Burn_FullBalance() public {
        token.burn(INITIAL_SUPPLY);
        assertEq(token.balanceOf(owner), 0);
        assertEq(token.totalSupply(), 0);
    }

    // Test Burn Reduce TotalSupply
    function test_Burn_DecreasesTotalSupply() public {
        uint256 burnAmount = 1000;
        token.burn(burnAmount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY - burnAmount);
    }

    // Test Burn Revert ZeroAmount
    function test_Burn_ZeroAmountWithSufficientBalance() public {
        // Owner punya INITIAL_SUPPLY, burn 0 harus selalu revert ZeroAmount
        vm.expectRevert(PortoToken.ZeroAmount.selector);
        token.burn(0);
    }

    // Test Fuzz Burn
    function testFuzz_Burn(uint256 amount) public {
        amount = bound(amount, 1, INITIAL_SUPPLY);
        token.burn(amount);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - amount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY - amount);
    }

    // ===================== Test Skenario =========================

    function test_Integration_MintTransferBurn() public {
        // 1. Mint ke alice
        uint256 mintAmount = 500 * 10 ** DECIMALS;
        token.mint(alice, mintAmount);
        assertEq(token.balanceOf(alice), mintAmount);

        // 2. Alice transfer ke bob
        uint256 transferAmount = 200 * 10 ** DECIMALS;
        vm.prank(alice);
        token.transfer(bob, transferAmount);
        assertEq(token.balanceOf(alice), mintAmount - transferAmount);
        assertEq(token.balanceOf(bob), transferAmount);

        // 3. Bob burn sebagian
        uint256 burnAmount = 50 * 10 ** DECIMALS;
        vm.prank(bob);
        token.burn(burnAmount);
        assertEq(token.balanceOf(bob), transferAmount - burnAmount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY + mintAmount - burnAmount);
    }

    function test_Integration_ApproveAndTransferFrom() public {
        uint256 amount = 300 * 10 ** DECIMALS;

        // Owner approves alice sebagai spender
        token.approve(alice, amount);

        // Alice transfer dari owner ke bob
        vm.prank(alice);
        token.transferFrom(owner, bob, amount);

        assertEq(token.balanceOf(bob), amount);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - amount);
        assertEq(token.allowance(owner, alice), 0);
    }

    function test_Integration_MultipleTransfers() public {
        uint256 chunk = INITIAL_SUPPLY / 4;

        token.transfer(alice, chunk);
        token.transfer(bob, chunk);
        token.transfer(charlie, chunk);

        assertEq(token.balanceOf(alice), chunk);
        assertEq(token.balanceOf(bob), chunk);
        assertEq(token.balanceOf(charlie), chunk);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - chunk * 3);
        // Total supply tidak berubah karena hanya transfer
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
    }

    function test_Integration_BurnReducesTotalSupplyNotOthers() public {
        uint256 sendAmount = 100;
        token.transfer(alice, sendAmount);

        uint256 burnAmount = 50;
        token.burn(burnAmount); // owner burn

        assertEq(token.totalSupply(), INITIAL_SUPPLY - burnAmount);
        // Alice tidak terpengaruh
        assertEq(token.balanceOf(alice), sendAmount);
    }
}

