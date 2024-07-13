// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract FundraiseNFT is ERC721, Ownable {
	using Counters for Counters.Counter;
	Counters.Counter private _tokenIdCounter;

	string[] public imageURIs;

	constructor(
		string memory _name,
		string memory _symbol,
		string[] memory _imageURIs
	) ERC721(_name, _symbol) {
		imageURIs = _imageURIs;
	}

	function mint(address _to) public onlyOwner {
		uint256 tokenId = _tokenIdCounter.current();
		_tokenIdCounter.increment();
		_safeMint(_to, tokenId);
	}

	function tokenURI(
		uint256 _tokenId
	) public view override returns (string memory) {
		require(_exists(_tokenId), "Token does not exist");
		return imageURIs[_tokenId % imageURIs.length];
	}
}
