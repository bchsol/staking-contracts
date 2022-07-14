// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@klaytn/contracts/contracts/KIP/token/KIP7/KIP7.sol";
import "@klaytn/contracts/contracts/KIP/token/KIP17/utils/KIP17Holder.sol";
import "@klaytn/contracts/contracts/KIP/token/KIP17/IKIP17.sol";
import "@klaytn/contracts/contracts/access/Ownable.sol";

contract RewardToken is KIP7,KIP17Holder, Ownable {
  IKIP17 public nft;
  
  //mapping(uint256=>uint256) public tokenStakeAt;

  uint256 public maxSupply = 10000000000000000;
  uint256 public rate = 8640*10**decimals() / 1 days; // 1days == 86400 seconds 1seconds == 0.1 token

  constructor(address _nft, string memory _name, string memory _symbol) KIP7(_name, _symbol) {
    nft = IKIP17(_nft);
  }

  struct StakedToken {
    address staker;
    uint256 tokenId;
  }

  struct Staker {
    // 스테이킹한 토큰의 양
    uint256 amountStaked;

    // 스테이킹된 토큰 ID
    StakedToken[] stakedTokens;

    // 스테이킹한 시간
    uint256 tokenStakeAt;

    // 청구되지 않은 보상
    //uint256 unclaimedRewards;
  }

  // 토큰ID를 주소에 매핑
  mapping(uint256=>address) public tokenOwner;

  // 사용자 주소를 Staker에 매핑
  mapping(address => Staker) public stakers;
  
  function stake(uint256 tokenId) external {
    //require(totalSupply() == maxSupply, "Supply is maximum");

    // 이미 스테이킹한 토큰이 있으면 보상을 계산
    if(stakers[msg.sender].amountStaked > 0) {
      //uint256 rewards = calcTokens(msg.sender);
      //stakers[msg.sender].unclaimedRewards += rewards;
      _mint(msg.sender, calcTokens(msg.sender));
    }
    require(nft.ownerOf(tokenId) == msg.sender, "You don't own this token!");

    nft.safeTransferFrom(msg.sender, address(this), tokenId);

    StakedToken memory stakedToken = StakedToken(msg.sender, tokenId);

    stakers[msg.sender].stakedTokens.push(stakedToken);

    stakers[msg.sender].amountStaked++;

    stakers[msg.sender].tokenStakeAt = block.timestamp;

    tokenOwner[tokenId] = msg.sender;
  }

  // 스테이킹 해제시 보상을 계산하고 토큰을 전송
  function unstake(uint256 tokenId) external {
    require(stakers[msg.sender].amountStaked > 0, "You have no tokens staked");
    require(tokenOwner[tokenId] == msg.sender, "You can't unstake");

    //uint256 rewards = calcTokens(msg.sender);
    //stakers[msg.sender].unclaimedRewards += rewards;
    _mint(msg.sender, calcTokens(msg.sender));

    uint256 index = 0;
    for(uint256 i = 0; i < stakers[msg.sender].stakedTokens.length; i++) {
      if(stakers[msg.sender].stakedTokens[i].tokenId == tokenId) {
        index = i;
        break;
      }
    }

    stakers[msg.sender].stakedTokens[index].staker = address(0);

    stakers[msg.sender].amountStaked--;

    delete tokenOwner[tokenId];

    nft.transferFrom(address(this), msg.sender, tokenId);

    stakers[msg.sender].tokenStakeAt = block.timestamp;
  }

  // msg.sender에 대한 보상을 확인,계산 후 전송
  function claim() external {
    //uint256 rewards = calcTokens(msg.sender) + stakers[msg.sender].unclaimedRewards;
    uint256 rewards = calcTokens(msg.sender);
    require(rewards > 0, "You have no rewards to claim");

    stakers[msg.sender].tokenStakeAt = block.timestamp;
    //stakers[msg.sender].unclaimedRewards = 0;

    _mint(msg.sender, rewards);
  }


  // View
  function getStakedTokens(address _user) public view returns(StakedToken[] memory) {
    if(stakers[_user].amountStaked > 0) {
      StakedToken[] memory _stakedTokens = new StakedToken[](stakers[_user].amountStaked);
      uint256 _index = 0;


      for(uint256 i = 0; i<stakers[_user].stakedTokens.length; i++) {
        if(stakers[_user].stakedTokens[i].staker != (address(0))) {
          _stakedTokens[_index] = stakers[_user].stakedTokens[i];
          _index++;
        }
      }
      return _stakedTokens;
    }
    else {
      return new StakedToken[](0);
    }
  }


  // 경과 시간에 따른 보상 계산
  function calcTokens(address _staker) public view returns (uint256 _rewards) {
    uint256 timeElapsed = (block.timestamp - stakers[_staker].tokenStakeAt) * stakers[_staker].amountStaked;
    return timeElapsed * rate;
  }
}
