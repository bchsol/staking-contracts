// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@klaytn/contracts/contracts/KIP/token/KIP17/extensions/KIP17Enumerable.sol";
import "@klaytn/contracts/contracts/access/Ownable.sol";

contract NFTStaking is KIP17Enumerable, Ownable{

  uint256 public totalSup;

  constructor() KIP17("StakingTest","ST") {

  }

  function safeMint(address to) public {
    totalSup++;
    _safeMint(to, totalSup);
  }

}