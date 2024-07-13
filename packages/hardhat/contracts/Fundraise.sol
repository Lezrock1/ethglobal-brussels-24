// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract FundraiseNFT is ERC721, Ownable(msg.sender) {
	uint256 private _nextTokenId = 1;

	string[] public imageURIs;

	constructor(
		string memory _name,
		string memory _symbol,
		string[] memory _imageURIs
	) ERC721(_name, _symbol) {
		imageURIs = _imageURIs;
	}

	function mint(address _to) public onlyOwner {
		uint256 tokenId = _nextTokenId++;
		_safeMint(_to, tokenId);
	}

	function tokenURI(
		uint256 _tokenId
	) public view override returns (string memory) {
		return imageURIs[_tokenId % imageURIs.length];
	}
}
