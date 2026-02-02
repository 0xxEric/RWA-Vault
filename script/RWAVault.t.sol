// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/RWAVault.sol";
import "../src/MockUSDC.sol";
import "../src/RWAOracle.sol";

contract RWAVaultTest is Test {
    RWAVault vault;
    MockUSDC usdc;
    RWAOracle oracle;


    address user = address(0xCAFE);

    function setUp() public {
        usdc = new MockUSDC();
        oracle = new RWAOracle(1e18);
        vault = new RWAVault(
            IERC20(usdc),
            "RWA Vault",
            "RWAV",
            oracle
        );

        usdc.mint(user, 1_000_000e6);


        vault.updateNAV(0);
        
    }

    /*//////////////////////////////////////////////////////////////
                                BASIC
    //////////////////////////////////////////////////////////////*/

    function testDepositAndMint() public {
        vm.startPrank(user);

        usdc.approve(address(vault), 100e6);
        vault.deposit(100e6, user);

        assertEq(vault.balanceOf(user), 100e6);
        assertEq(usdc.balanceOf(address(vault)), 100e6);
    }

    function testNAVIncrease() public {

        vault.updateNAV(200e6);

        assertEq(vault.totalAssets(), 200e6);
    }

    /*//////////////////////////////////////////////////////////////
                            WITHDRAW
    //////////////////////////////////////////////////////////////*/

    function testWithdraw() public {
        vm.startPrank(user);
        usdc.approve(address(vault), 100e6);
        vault.deposit(100e6, user);

        vault.withdraw(50e6, user, user);
        assertEq(usdc.balanceOf(user), 1_000_000e6 - 50e6);
    }

    /*//////////////////////////////////////////////////////////////
                            ACCESS CONTROL
    //////////////////////////////////////////////////////////////*/

    function testOracleOnly() public {
        vm.expectRevert();
        vault.updateNAV(100e6);
    }

    /*//////////////////////////////////////////////////////////////
                                FUZZ
    //////////////////////////////////////////////////////////////*/

    function testFuzzDeposit(uint256 amount) public {
        amount = bound(amount, 1e6, 1_000e6);

        vm.startPrank(user);
        usdc.approve(address(vault), amount);
        vault.deposit(amount, user);

        assertEq(vault.balanceOf(user), amount);
    }
}
