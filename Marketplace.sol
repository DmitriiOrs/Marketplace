// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address);
}

contract NFTMarketplace {
    struct Listing {
        address seller;
        address nftContract;
        uint256 tokenId;
        uint256 price;
    }

    mapping(address => mapping(uint256 => Listing)) public listings;

    event Listed(address indexed seller, address indexed nftContract, uint256 indexed tokenId, uint256 price);
    event Purchased(address indexed buyer, address indexed nftContract, uint256 indexed tokenId, uint256 price);
    event Cancelled(address indexed seller, address indexed nftContract, uint256 indexed tokenId);

    function listNFT(address _nftContract, uint256 _tokenId, uint256 _price) external {
        require(_price > 0, "Price must be greater than zero");

        IERC721 nft = IERC721(_nftContract);
        require(nft.getApproved(_tokenId) == address(this), "Marketplace not approved");

        listings[_nftContract][_tokenId] = Listing(msg.sender, _nftContract, _tokenId, _price);

        emit Listed(msg.sender, _nftContract, _tokenId, _price);
    }

    function cancelListing(address _nftContract, uint256 _tokenId) external {
        Listing memory item = listings[_nftContract][_tokenId];
        require(item.seller == msg.sender, "Not the seller");

        delete listings[_nftContract][_tokenId];
        emit Cancelled(msg.sender, _nftContract, _tokenId);
    }

    function buyNFT(address _nftContract, uint256 _tokenId) external payable {
        Listing memory item = listings[_nftContract][_tokenId];
        require(item.price > 0, "NFT not listed");
        require(msg.value >= item.price, "Not enough ETH");

        delete listings[_nftContract][_tokenId];

        payable(item.seller).transfer(item.price);
        IERC721(item.nftContract).safeTransferFrom(item.seller, msg.sender, item.tokenId);

        emit Purchased(msg.sender, _nftContract, _tokenId, item.price);
    }

    function getListing(address _nftContract, uint256 _tokenId) external view returns (Listing memory) {
        return listings[_nftContract][_tokenId];
    }
}
