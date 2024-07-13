// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./QSTToken.sol";
import "./FundraiseNFT.sol";
import "./MetaTransaction.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Fundraise is
	MetaTransaction("Fundraise", "1", block.chainid),
	Ownable(msg.sender)
{
	struct FundraiseDetails {
		string title;
		string description;
		uint256 fundingGoal;
		uint256 deadline;
		address creatorAddress;
		uint256 totalRaised;
		bool isActive;
		address nftCollectionAddress;
	}

	mapping(uint256 => FundraiseDetails) public fundraises;
	mapping(uint256 => mapping(address => uint256)) public contributions;

	uint256 public constant MINIMUM_NFT_CONTRIBUTION = 6.09 ether; // 6.09 QST tokens
	uint256 public constant NFT_IMAGE_COUNT = 69;
	uint256 private _nextFundraiseId = 1;
	QSTToken public token;

	constructor(address _tokenAddress) {
		token = QSTToken(_tokenAddress);
	}

	function createFundraise(
		string memory _title,
		string memory _description,
		uint256 _fundingGoal,
		uint256 _duration,
		string memory _nftName,
		string memory _nftSymbol,
		string[] memory _nftImageURIs
	) public {
		require(
			_nftImageURIs.length == NFT_IMAGE_COUNT,
			"Invalid number of NFT image URIs"
		);

		uint256 fundraiseId = _nextFundraiseId++;

		FundraiseNFT nftCollection = new FundraiseNFT(
			_nftName,
			_nftSymbol,
			_nftImageURIs
		);

		fundraises[fundraiseId] = FundraiseDetails({
			title: _title,
			description: _description,
			fundingGoal: _fundingGoal,
			deadline: block.timestamp + _duration,
			creatorAddress: msg.sender,
			totalRaised: 0,
			isActive: true,
			nftCollectionAddress: address(nftCollection)
		});
	}

	function contribute(uint256 _fundraiseId, uint256 _amount) public {
		FundraiseDetails storage fundraise = fundraises[_fundraiseId];
		require(fundraise.isActive, "Fundraise is not active");
		require(block.timestamp <= fundraise.deadline, "Fundraise has ended");

		contributions[_fundraiseId][msg.sender] += _amount;
		fundraise.totalRaised += _amount;
		token.transferFrom(msg.sender, address(this), _amount);

		if (_amount >= MINIMUM_NFT_CONTRIBUTION) {
			FundraiseNFT nftCollection = FundraiseNFT(
				fundraise.nftCollectionAddress
			);
			nftCollection.mint(msg.sender);
		}
	}

	function endFundraise(uint256 _fundraiseId) public {
		FundraiseDetails storage fundraise = fundraises[_fundraiseId];
		require(fundraise.isActive, "Fundraise is not active");
		require(
			block.timestamp > fundraise.deadline,
			"Fundraise has not ended"
		);

		fundraise.isActive = false;
		token.transfer(fundraise.creatorAddress, fundraise.totalRaised);
	}
}
