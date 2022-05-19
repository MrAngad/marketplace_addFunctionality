const { ethers } = require("hardhat");
const HRE = require('hardhat');
const { expect } = require("chai");
require("bignumber.js");
const { utils } = require("ethers")

const ADMIN_WALLET           = "0xc1cCE69161Ebf6837f4F07c7d95a4badF30a7d41";

const listingPrice      = utils.parseEther("0.2");

describe("Quantum Token Scenario", function() {
    let marketPlace, nft, rewardToken, admin, users;

    before(async function() {
        await HRE.network.provider.request({method: 'hardhat_impersonateAccount', params: [ADMIN_WALLET]});
        admin = await ethers.provider.getSigner(ADMIN_WALLET);
        
        users = await ethers.getSigners();

        const MarketPlace = await HRE.ethers.getContractFactory("marketPlaceBoilerPlate");
        marketPlace       = await MarketPlace.deploy();
        await marketPlace.deployed();
        console.log(marketPlace.address);
        const NFT = await HRE.ethers.getContractFactory("DummyERC721");
        nft       = await NFT.deploy("MyNFT", "MNFT");
        await nft.deployed();
    });

    describe('Test basic NFT', () => {
        it('Should set the right name', async() => {
            const tokenName = "MyNFT"
            expect(await nft.name()).to.equal(tokenName);
        });

        it('Should set the right symbol', async() => {
            const tokenSymbol = "MNFT";
            expect(await nft.symbol()).to.equal(tokenSymbol);
        });

        it('Should mint 1 nft to user 1', async() => {
            await nft.connect(users[1]).mint(1);
            expect(await nft.totalSupply()).to.equal(1);
        });

        it('Should mint 1 nft to user 4', async() => {
            await nft.connect(users[4]).mint(1);
            expect(await nft.totalSupply()).to.equal(2);
            expect(await nft.balanceOf(users[4].address)).to.equal(1);
        });
    });

    describe('Test marketplace', () => {
        it('Should create market item', async() => {
            expect(await nft.balanceOf(users[1].address)).to.equal(1);
            nft.connect(users[1]).approve(marketPlace.address, 1);
            console.log(await nft.getApproved(1));
            //expect(await nft.getApproved(1)).to.equal(marketPlace.address);

            expect(await nft.ownerOf(1)).to.equal(users[1].address);
            await marketPlace.connect(users[1]).createMarketItem(nft.address, 1, listingPrice);
            let items = await marketPlace.fetchMarketItems();
            console.log(items[1]);

            expect(await nft.balanceOf(users[2].address)).to.equal(0);
            expect(await nft.balanceOf(marketPlace.address)).to.equal(1);
            expect(await nft.ownerOf(1)).to.equal(marketPlace.address);
        });

        it('Should create market sale', async() => {
            let origBalance = await ethers.provider.getBalance(users[1].address);

            await expect(marketPlace.connect(users[2]).createMarketSale(nft.address, 1, {
                value: ethers.utils.parseEther("0.1")
            })).to.be.revertedWith("Please submit the asking price in order to complete the purchase");

            await marketPlace.connect(users[2]).createMarketSale(nft.address, 1, {
                value: ethers.utils.parseEther("0.2")
            });
            let newBalance = await ethers.provider.getBalance(users[1].address);

            expect((newBalance-origBalance)/1000000000000000000).to.equal(0.2*0.96);
            
            expect(await ethers.provider.getBalance(ADMIN_WALLET)).to.equal(8000000000000000);

            expect(await nft.balanceOf(users[2].address)).to.equal(1);
            expect(await nft.balanceOf(marketPlace.address)).to.equal(0);

            expect(await nft.ownerOf(1)).to.equal(users[2].address);

            await expect(marketPlace.connect(users[2]).createMarketSale(nft.address, 1, {
                value: ethers.utils.parseEther("0.2")
            })).to.be.revertedWith("This Sale has already finished");
        });

        it('Should delist market item', async() => {
            expect(await nft.balanceOf(users[4].address)).to.equal(1);
            nft.connect(users[4]).approve(marketPlace.address, 2);
            expect(await nft.ownerOf(2)).to.equal(users[4].address);
            await marketPlace.connect(users[4]).createMarketItem(nft.address, 2, listingPrice);
            items = await marketPlace.fetchMarketItems();
            console.log(items[1]);

            expect(await nft.balanceOf(users[4].address)).to.equal(0);
            expect(await nft.balanceOf(marketPlace.address)).to.equal(1);
            
            expect(await nft.ownerOf(2)).to.equal(marketPlace.address);
            
            await expect(marketPlace.connect(users[1]).removeMarketItem(1)).to.be.revertedWith("Cannot remove NFT, This Sale has already finished");
            await expect(marketPlace.connect(users[3]).removeMarketItem(2)).to.be.revertedWith("Only the seller can remove his listed NFT");
            await marketPlace.connect(users[4]).removeMarketItem(2);
            expect(await nft.balanceOf(users[4].address)).to.equal(1);
            expect(await nft.balanceOf(marketPlace.address)).to.equal(0);
        });
    });
});