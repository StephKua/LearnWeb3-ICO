// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICryptoDevs.sol";

contract CryptoDevToken is ERC20, Ownable {
    
    uint256 public constant tokenPrice = 0.001 ether;

    uint256 public constant tokensPerNFT = 10 * 10**18;

    uint256 public constant maxTotalSupply = 10000 * 10 ** 18;

    ICryptoDevs CryptoDevsNFT;

    mapping(uint256 => bool) public tokenIdsClaimed;

    constructor(address _cryptoDevsContract) ERC20("Crypto Dev Token", "CD") {
        CryptoDevsNFT = ICryptoDevs(_cryptoDevsContract);
    }

    // mint tokens by paying a fee
    // msg.value will be equal or greater than tokenPrice * amount
    function mint(uint256 amount) public payable {

        uint256 _requiredAmount = tokenPrice * amount;
        require(msg.value >= _requiredAmount, "Ether sent is incorrect");

        uint256 amountWithDecimals = amount * 10**18;
        
        require((totalSupply() + amountWithDecimals) <= maxTotalSupply, "Exceeds the max total supply available.");

        // use internal open zeppelin ERC20 contract to mint it
        _mint(msg.sender, amountWithDecimals);

    }

    // mint tokens based on number of NFT held by sender
    function claim() public {

        address sender = msg.sender;

        // get number of NFT in this account
        uint256 balance = CryptoDevsNFT.balanceOf(sender);

        require(balance > 0, "You dont own any Crypto Dev NFT's");

        uint256 amount = 0;

        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = CryptoDevsNFT.tokenOfOwnerByIndex(sender, i);

            if (!tokenIdsClaimed[tokenId]) {
                amount += 1;
                tokenIdsClaimed[tokenId] = true;
            }
        }

        require(amount > 0, "You have already claimed all the tokens");

        // mint  amount * 10 tokens for each NFT
        _mint(msg.sender, amount * tokensPerNFT);

    }

    // Withdraw all ETH and tokens in this contract
    function withdraw() public onlyOwner {
        
        address _owner = owner();
        uint256 amount = address(this).balance;

        (bool sent, ) = _owner.call{value: amount}("");

        require(sent, "Failed to send Ether");

    }

    receive() external payable {}

    fallback() external payable {}

}