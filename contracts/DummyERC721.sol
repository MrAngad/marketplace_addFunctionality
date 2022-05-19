/* // SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import '@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import "hardhat/console.sol";
contract DummyERC721 is ERC721, ERC721Enumerable {
    using SafeMath for uint256;

    constructor(string memory _name, string memory _symbol) ERC721(_name, _symbol) {}

    function mint(uint256 _amount) external {
        uint mintIndex = totalSupply().add(1);
        
        for(uint count = 0; count < _amount; count++) {
            _safeMint(msg.sender, mintIndex.add(count));
        }
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, ERC721Enumerable) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, amount);
    }

} */