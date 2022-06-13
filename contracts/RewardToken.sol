// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@klaytn/contracts/contracts/KIP/token/KIP7/KIP7.sol";
import "@klaytn/contracts/contracts/KIP/token/KIP17/utils/KIP17Holder.sol";
import "@klaytn/contracts/contracts/KIP/token/KIP17/IKIP17.sol";
import "@klaytn/contracts/contracts/access/Ownable.sol";

contract RewardToken is KIP7,KIP17Holder, Ownable {
  IKIP17 public nft;
  mapping(uint256=>address) tokenOwner;
  mapping(uint256=>uint256) tokenStakeAt;

  uint256 totalSupply;
  uint256 maxSupply = 1000000000;
  uint256 public rate = 1000 / 1 days; // = 1000 / 86400 seconds

  constructor(address _nft) KIP7("TEST", "TT") {
    nft = IKIP17(_nft);
  }

  function stake(uint256 tokenId) external {
    require(totalSupply == maxSupply, "Supply is maximum");
    nft.safeTransferFrom(msg.sender, address(this), tokenId);
    tokenOwner[tokenId] = msg.sender;
    tokenStakeAt[tokenId] = block.timestamp;
  }

  function calcTokens(uint256 tokenId) public view returns (uint256) {
    uint256 timeElapsed = block.timestamp - tokenStakeAt[tokenId];
    return timeElapsed * rate;
  }

  function unstake(uint256 tokenId) external {
    require(tokenOwner[tokenId] == msg.sender, "You can't unstake");
    _mint(msg.sender, calcTokens(tokenId));
    nft.transferFrom(address(this), msg.sender, tokenId);
    delete tokenOwner[tokenId];
    delete tokenStakeAt[tokenId];
  }
}