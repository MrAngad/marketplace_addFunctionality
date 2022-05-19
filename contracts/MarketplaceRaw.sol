/*  SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Counters.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "hardhat/console.sol";

contract marketPlaceBoilerPlate is ReentrancyGuard {
    using SafeMath for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold;
    
     address public owner;
     address public ADMIN_WALLLET = 0x69Ba7E86bbB074Cd5f72693DEb6ADc508D83A6bF;

     constructor() {
         owner = msg.sender;
     }
     
     struct MarketItem {
         uint itemId;
         address nftContract;
         uint256 tokenId;
         address payable seller;
         address payable owner;
         uint256 price;
         bool sold;
     }
     
     mapping(uint256 => MarketItem) private idToMarketItem;
     
     event MarketItemCreated (
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
     );
     
     event MarketItemSold (
         uint indexed itemId,
         address owner
         );
     
    function createMarketItem(
        address nftContract,
        uint256 tokenId,
        uint256 price
        ) public payable nonReentrant {
            require(price > 0, "Price must be greater than 0");

            _itemIds.increment();
            uint256 itemId = _itemIds.current();
            console.log("counter", itemId);
            idToMarketItem[itemId] =  MarketItem(
                itemId,
                nftContract,
                tokenId,
                payable(msg.sender),
                payable(address(0)),
                price,
                false
            );

            IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
                
            emit MarketItemCreated(
                itemId,
                nftContract,
                tokenId,
                msg.sender,
                address(0),
                price,
                false
            );
        }
        
    function createMarketSale(
        address nftContract,
        uint256 itemId
        ) public payable nonReentrant {
            uint price = idToMarketItem[itemId].price;
            uint tokenId = idToMarketItem[itemId].tokenId;
            bool sold = idToMarketItem[itemId].sold;

            require(price == msg.value, "Please submit the asking price in order to complete the purchase");
            require(sold != true, "This Sale has already finished");
            emit MarketItemSold(
                itemId,
                msg.sender
                );

            uint amount = msg.value;
            uint fee    = amount.mul(400).div(10000);

            payable(ADMIN_WALLLET).transfer(fee);
            idToMarketItem[itemId].seller.transfer(amount.sub(fee));

            IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
            idToMarketItem[itemId].owner = payable(msg.sender);
            _itemsSold.increment();
            idToMarketItem[itemId].sold = true;
        }

    function removeMarketItem(uint256 itemId) external nonReentrant {
        bool sold           = idToMarketItem[itemId].sold;
        address nftContract = idToMarketItem[itemId].nftContract;
        uint256 tokenId     = idToMarketItem[itemId].tokenId;
        address seller      = idToMarketItem[itemId].seller;

        require(msg.sender == seller, "Only the seller can remove his listed NFT");
        require(sold != true, "Cannot remove NFT, This Sale has already finished");

        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);
        delete idToMarketItem[itemId];
        _itemIds.decrement();
    }

    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint itemCount = _itemIds.current();
        uint unsoldItemCount = _itemIds.current() - _itemsSold.current();
        uint currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        for (uint i = 0; i < itemCount; i++) {
            if (idToMarketItem[i + 1].owner == address(0)) {
                uint currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
}

/// Thanks for inspiration: https://github.com/dabit3/polygon-ethereum-nextjs-marketplace/ */