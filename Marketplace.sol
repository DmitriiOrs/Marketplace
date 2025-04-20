// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC721 {
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address);
}

contract NFTMarketplace {
    address public owner;
    uint256 public platformFeeBasisPoints = 250; // 2.5%
    address public feeRecipient;

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
    event PlatformFeeUpdated(uint256 newFeeBP);
    event FeeRecipientUpdated(address newRecipient);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier onlySeller(address _nftContract, uint256 _tokenId) {
        require(listings[_nftContract][_tokenId].seller == msg.sender, "Not the seller");
        _;
    }

    constructor() {
        owner = msg.sender;
        feeRecipient = msg.sender;
    }

    function listNFT(address _nftContract, uint256 _tokenId, uint256 _price) external {
        require(_price > 0, "Price must be greater than zero");

        IERC721 nft = IERC721(_nftContract);
        require(nft.getApproved(_tokenId) == address(this), "Marketplace not approved");

        listings[_nftContract][_tokenId] = Listing(msg.sender, _nftContract, _tokenId, _price);

        emit Listed(msg.sender, _nftContract, _tokenId, _price);
    }

    function cancelListing(address _nftContract, uint256 _tokenId) external onlySeller(_nftContract, _tokenId) {
        delete listings[_nftContract][_tokenId];
        emit Cancelled(msg.sender, _nftContract, _tokenId);
    }

    function buyNFT(address _nftContract, uint256 _tokenId) external payable {
        Listing memory item = listings[_nftContract][_tokenId];
        require(item.price > 0, "NFT not listed");
        require(msg.value >= item.price, "Not enough ETH");

        uint256 fee = (item.price * platformFeeBasisPoints) / 10000;
        uint256 sellerAmount = item.price - fee;

        delete listings[_nftContract][_tokenId];

        payable(item.seller).transfer(sellerAmount);
        payable(feeRecipient).transfer(fee);
        IERC721(item.nftContract).safeTransferFrom(item.seller, msg.sender, item.tokenId);

        emit Purchased(msg.sender, _nftContract, _tokenId, item.price);
    }

    function updatePlatformFee(uint256 _newFeeBP) external onlyOwner {
        require(_newFeeBP <= 1000, "Fee too high"); // Max 10%
        platformFeeBasisPoints = _newFeeBP;
        emit Platform
