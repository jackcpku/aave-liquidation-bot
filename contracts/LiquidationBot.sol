//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "./FlashLoanReceiverBase.sol";

contract LiquidationBot is FlashLoanReceiverBase, Ownable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    constructor(address _provider) FlashLoanReceiverBase(_provider) {}

    event GasIn(uint256 indexed gas);

    event ReceiveAsset(
        address indexed asset,
        uint256 indexed amount,
        uint256 indexed premium
    );

    event WithParams(bytes indexed params);

    function withdrawAssets(
        address[] calldata assets,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(
            assets.length == amounts.length,
            "LiquiadationBot: invalid input"
        );

        for (uint256 i = 0; i < assets.length; i++) {
            IERC20(assets[i]).safeTransferFrom(
                address(this),
                msg.sender,
                amounts[i]
            );
        }
    }

    /**
     * This function is called directly by the backend moniter.
     */
    function requestFlashLoan(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        bytes calldata params
    ) external onlyOwner {
        emit GasIn(gasleft());

        require(
            assets.length == amounts.length && amounts.length == modes.length,
            "LiquiadationBot: invalid input"
        );

        address receiverAddress = address(this);
        address onBehalfOf = address(this);
        uint16 referralCode = 0;

        LENDING_POOL.flashLoan(
            receiverAddress, // receiverAddress
            assets, // address[] The addresses of the assets being flash-borrowed
            amounts, // uint256[] The amounts being flash-borrowed
            modes, // uint256[] modes: Don't open any debt, just revert if funds can't be transferred from the receiver
            onBehalfOf, // The address that will receive the debt in the case of using on `modes` 1 or 2
            params, // Extra params passed to the receiver
            referralCode //  0 if the action is executed directly by the user, without any middle-man
        );
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        for (uint256 i = 0; i < assets.length; i++) {
            emit ReceiveAsset(assets[i], amounts[i], premiums[i]);
        }

        emit WithParams(params);

        // Approve the LendingPool contract allowance to *pull* the owed amount
        for (uint256 i = 0; i < assets.length; i++) {
            uint256 amountOwing = amounts[i].add(premiums[i]);
            IERC20(assets[i]).approve(address(LENDING_POOL), amountOwing);
        }

        return true;
    }
}
