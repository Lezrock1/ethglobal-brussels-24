// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./QSTToken.sol";
import "./FundraiseNFT.sol";
import "./MetaTransaction.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Fundraise is
	MetaTransaction("Fundraise", "1", block.chainid),
	Ownable
{
	using Counters for Counters.Counter;

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
	Counters.Counter private _fundraiseIdCounter;
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

		uint256 fundraiseId = _fundraiseIdCounter.current();
		_fundraiseIdCounter.increment();

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

	function executeMetaTransaction(
		address userAddress,
		bytes memory functionSignature,
		bytes32 sigR,
		bytes32 sigS,
		uint8 sigV
	) public returns (bytes memory) {
		MetaTransactionStruct memory metaTx = MetaTransactionStruct({
			nonce: nonces[userAddress],
			from: userAddress,
			functionSignature: functionSignature
		});

		require(
			verify(userAddress, metaTx, sigR, sigS, sigV),
			"Signer and signature do not match"
		);

		nonces[userAddress] += 1;

		(bool success, bytes memory returnData) = address(this).call(
			abi.encodePacked(functionSignature, userAddress)
		);
		require(success, "Function call not successful");

		emit MetaTransactionExecuted(
			userAddress,
			msg.sender,
			functionSignature
		);

		return returnData;
	}
}
