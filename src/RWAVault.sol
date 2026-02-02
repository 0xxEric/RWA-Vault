// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title RWAVault
 * @notice ERC4626-compliant RWA vault
 *
 * asset  = USDC (or any ERC20 stablecoin)
 * share  = Vault shares representing claim on RWA NAV
 */

interface IOracle {
function nav() external view returns (uint256);
}
contract RWAVault is ERC4626, AccessControl {
    bytes32 public constant VAULT_ADMIN = keccak256("VAULT_ADMIN");
    bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");

    // Oracle-controlled NAV (in asset units)
    uint256 private _nav;
    IOracle public oracle;

    constructor(
        IERC20 asset_,
        string memory name_,
        string memory symbol_,
        IOracle oracle_
    )
        ERC20(name_, symbol_)
        ERC4626(asset_)
    {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(VAULT_ADMIN, msg.sender);
        oracle = oracle_;
    }

    /*//////////////////////////////////////////////////////////////
                                ORACLE
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Update NAV (Net Asset Value)
     * @dev In production: guarded by multi-oracle / rate limits
     */
    function updateNAV(uint256 newNAV) external onlyRole(ORACLE_ROLE) {
        require(newNAV >= _nav, "NAV cannot decrease");
        _nav = newNAV;
    }

    /**
     * @notice Total assets backing the vault
     * @dev ERC4626 hook used by convertToShares / convertToAssets
     */
    function totalAssets() public view override returns (uint256) {
        return _nav;
    }

    /*//////////////////////////////////////////////////////////////
                        ERC4626 OVERRIDES
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Conservative mint pricing
     */
    function convertToShares(uint256 assets)
        public
        view
        override
        returns (uint256)
    {
        uint256 supply = totalSupply();
        if (supply == 0 || _nav == 0) {
            return assets;
        }
        return assets * supply / _nav;
    }

    function convertToAssets(uint256 shares)
        public
        view
        override
        returns (uint256)
    {
        uint256 supply = totalSupply();
        if (supply == 0) return 0;
        return shares * _nav / supply;
    }
}
