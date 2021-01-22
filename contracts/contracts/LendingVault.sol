// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

import { IERC20, IERC721, ILendingPool, IProtocolDataProvider, IStableDebtToken } from './Interfaces.sol';
import { SafeERC20, SafeMath } from './Libraries.sol';

/**
 * This is a proof of concept starter contract, showing how uncollaterised loans are possible
 * using Aave v2 credit delegation.
 * This example supports stable interest rate borrows.
 * It is not production ready (!). User permissions and user accounting of loans should be implemented.
 * See @dev comments
 */
 
contract MyV2CreditDelegation {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    
    ILendingPool constant lendingPool = ILendingPool(address(0x9FE532197ad76c5a68961439604C037EB79681F0)); // Kovan
    IProtocolDataProvider constant dataProvider = IProtocolDataProvider(address(0x744C1aaA95232EeF8A9994C4E0b3a89659D9AB79)); // Kovan
    
    address owner;

    // Track balances by asset address
    mapping (address => mapping (address => uint256)) public balances;

    // Map NFT addresses to limits
    mapping ( address => uint256 ) public limits;

    mapping ( address => mapping (uint256 => bool)) public burnedApprovals;

    constructor () public {
        owner = msg.sender;
        limits[0x1] = 1 ether; //Placeholder - limit arg should be an NFT address
        limits[0x2] = 5 ether; // Placeholder - limit arg should be an NFT address
    }

    /**
     * Deposits collateral into the Aave, to enable credit delegation
     * This would be called by the delegator.
     * @param asset The asset to be deposited as collateral
     * @param amount The amount to be deposited as collateral
     *  User must have approved this contract
     * 
     */
    function depositCollateral(address asset, uint256 amount) public {
        // TODO insert storage track collateral from multiple investors
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(asset).safeApprove(address(lendingPool), amount);
        // aTokens go to this contract
        lendingPool.deposit(asset, amount, address(this), 0);
        // Track how much collateral the investor has supplied
        balances[asset][msg.sender] += amount;
        // Track how much total collateral of this asset type has been supplied
        balances[asset][this] += amount;
    }

    /**
     * Checks if sender is approved, and if so opens a credit delegation line
     * @param approvalNFT The NFT address representing the creditworthiness
     * @param tokenId The NFT ID of the approval being used
     * @param asset The asset they are allowed to borrow
     * 
     * Add permissions to this call, e.g. only the owner should be able to approve borrowers!
     */
    function requestCredit(address approvalNFT, uint256 tokenId, address asset) public {
        require(IERC721(approvalNFT).ownerOf(tokenId) == msg.sender);
        burnedApprovals[approvalNFT][tokenId] = true;

        (, address stableDebtTokenAddress,) = dataProvider.getReserveTokensAddresses(asset);
        IStableDebtToken(stableDebtTokenAddress).approveDelegation(borrower, limits[approvalNFT]);
    }
    
    /**
     * Repay an uncollaterised loan
     * @param amount The amount to repay
     * @param asset The asset to be repaid
     * 
     * User calling this function must have approved this contract with an allowance to transfer the tokens
     * 
     * You should keep internal accounting of borrowers, if your contract will have multiple borrowers
     */
    function repayBorrower(uint256 amount, address asset) public {
        IERC20(asset).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(asset).safeApprove(address(lendingPool), amount);

        // Repaying has to be done at the aave rate
        // This is where we would extract the margin for the investors
        lendingPool.repay(asset, amount, 1, address(this));
    }
    
    /**
     * Withdraw all of a collateral as the underlying asset, if no outstanding loans delegated
     * @param asset The underlying asset to withdraw
     * 
     * Add permissions to this call, e.g. only the owner should be able to withdraw the collateral!
     */
    function withdrawCollateral(address asset) public {
        (address aTokenAddress,,) = dataProvider.getReserveTokensAddresses(asset);
        uint256 assetBalance = IERC20(aTokenAddress).balanceOf(address(this));
        uint256 senderCollateral = balances[asset][msg.sender];
        uint256 totalCollateral = balances[asset][this];
        uint256 senderBalanceRatio = senderCollateral.div(totalCollateral);
        uint256 senderBalance = assetBalance.mul(senderBalanceRatio);
        balances[asset][msg.sender] -= senderCollateral;
        balances[asset][this] -= senderCollateral;
        lendingPool.withdraw(asset, senderBalance, msg.sender);
    }
}