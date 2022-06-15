// SPDX-License-Identifier: MIT
// @title Brick Buidlers
// @author bouncePass Labs
// @custom:security-contact kbetzjr@gmail.com

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract BrickBuidlers is ERC721, ERC721Enumerable, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;


    constructor() ERC721("Brick Buidlers", "BRICK") {}


    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721: invalid token ID");
        return "data:application/json;base64,ewogICAgInRpdGxlIjogIkJyaWNrIEJ1aWRsZXJzIiwKICAgICJ0eXBlIjogIm9iamVjdCIsCiAgICAicHJvcGVydGllcyI6IHsKICAgICAgICAibmFtZSI6IHsKICAgICAgICAgICAgInR5cGUiOiAic3RyaW5nIiwKICAgICAgICAgICAgImRlc2NyaXB0aW9uIjogIkJSSUNLIgogICAgICAgIH0sCiAgICAgICAgImRlc2NyaXB0aW9uIjogewogICAgICAgICAgICAidHlwZSI6ICJzdHJpbmciLAogICAgICAgICAgICAiZGVzY3JpcHRpb24iOiAi8J+nsSIKICAgICAgICB9LAogICAgICAgICJpbWFnZSI6IHsKICAgICAgICAgICJ0eXBlIjogInN0cmluZyIsCiAgICAgICAgICAiZGVzY3JpcHRpb24iOiAiaHR0cHM6Ly9yYXcuZ2l0aHVidXNlcmNvbnRlbnQuY29tL2JvdW5jZVBhc3NPTkUvbGFicy9tYWluL2ltYWdlcy9CUklDSy5wbmciCiAgICAgICAgfSwKICAgICAgICAiZXh0ZXJuYWxfdXJsIjogewogICAgICAgICAgICAidHlwZSI6ICJzdHJpbmciLAogICAgICAgICAgICAiZGVzY3JpcHRpb24iOiAiaHR0cHM6Ly9ib3VuY2VwYXNzb25lLmdpdGh1Yi5pby9sYWJzLyIKICAgICAgICB9CiAgICB9Cn0=";
    }


    function tokenIdAt() external view returns(uint256) {
        return(_tokenIdCounter.current());
    }

    function safeMint(address to) external payable {

        require(balanceOf(to) == 0);
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint( to, tokenId);
    }

    // The following functions are overrides required by Solidity.

    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
