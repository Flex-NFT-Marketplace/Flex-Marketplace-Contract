const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("ERC5173 - NFT Future Rewards", function () {
  let MyNFT, myNFT, owner, addr1, addr2, addr3, addr4;

  beforeEach(async () => {
    [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();

    // Deploy the NFT contract
    MyNFT = await ethers.getContractFactory("MyNFT");
    myNFT = await MyNFT.deploy(owner.address);
  });

  describe("Minting", () => {
    it("Should allow the owner to mint tokens", async () => {
      await myNFT.mint(addr1.address, 1);
      expect(await myNFT.ownerOf(1)).to.equal(addr1.address);
    });

    it("Should initialize FRInfo for the minted token", async () => {
      await myNFT.mint(addr1.address, 1);

      const frInfo = await myNFT.retrieveFRInfo(1);
      expect(frInfo.numGenerations).to.equal(10);
      expect(frInfo.percentOfProfit).to.equal(ethers.utils.parseEther("0.05"));
      expect(frInfo.successiveRatio).to.equal(ethers.utils.parseEther("0.8"));
    });
  });

  describe("Listing and Unlisting", () => {
    it("Should allow the owner to list a token for sale", async () => {
      await myNFT.mint(addr1.address, 1);
      await myNFT.connect(addr1).list(1, ethers.utils.parseEther("1"));

      const listInfo = await myNFT.retrieveListInfo(1);
      expect(listInfo.salePrice).to.equal(ethers.utils.parseEther("1"));
      expect(listInfo.isListed).to.equal(true);
    });

    it("Should allow the lister to unlist a token", async () => {
      await myNFT.mint(addr1.address, 1);
      await myNFT.connect(addr1).list(1, ethers.utils.parseEther("1"));
      await myNFT.connect(addr1).unlist(1);

      const listInfo = await myNFT.retrieveListInfo(1);
      expect(listInfo.isListed).to.equal(false);
    });

    it("Should not allow non-owners to list a token", async () => {
      await myNFT.mint(addr1.address, 1);
      await expect(
        myNFT.connect(addr2).list(1, ethers.utils.parseEther("1"))
      ).to.be.revertedWith("Not authorized");
    });
  });

  describe("Buying Tokens", () => {
    it("Should allow a buyer to purchase a listed token", async () => {
      await myNFT.mint(addr1.address, 1);
      await myNFT.connect(addr1).list(1, ethers.utils.parseEther("1"));

      await myNFT
        .connect(addr2)
        .buy(1, { value: ethers.utils.parseEther("1") });

      expect(await myNFT.ownerOf(1)).to.equal(addr2.address);

      const listInfo = await myNFT.retrieveListInfo(1);
      expect(listInfo.isListed).to.equal(false);
    });

    it("Should distribute future rewards (FR) on token sale", async () => {
      // Mint and set up multiple generations
      await myNFT.mint(addr1.address, 1);
      await myNFT.mint(addr2.address, 2);

      // Add some generations for testing
      await myNFT.connect(addr1).transferFrom(addr1.address, addr3.address, 1);
      await myNFT.connect(addr3).transferFrom(addr3.address, addr4.address, 1);

      await myNFT.connect(addr4).list(1, ethers.utils.parseEther("2"));
      await myNFT
        .connect(addr2)
        .buy(1, { value: ethers.utils.parseEther("2") });

      const frInfo = await myNFT.retrieveFRInfo(1);
      const rewardsAddr1 = await myNFT.retrieveAllottedFR(addr1.address);
      const rewardsAddr3 = await myNFT.retrieveAllottedFR(addr3.address);

      expect(frInfo.lastSoldPrice).to.equal(ethers.utils.parseEther("2"));
      expect(rewardsAddr1).to.be.gt(0); // First owner should get some rewards
      expect(rewardsAddr3).to.be.gt(rewardsAddr1); // Closer in provenance chain gets more
    });

    it("Should revert if buyer sends incorrect payment amount", async () => {
      await myNFT.mint(addr1.address, 1);
      await myNFT.connect(addr1).list(1, ethers.utils.parseEther("1"));

      await expect(
        myNFT.connect(addr2).buy(1, { value: ethers.utils.parseEther("0.5") })
      ).to.be.revertedWith("Incorrect value sent");
    });

    it("Should revert if the token is not listed", async () => {
      await myNFT.mint(addr1.address, 1);

      await expect(
        myNFT.connect(addr2).buy(1, { value: ethers.utils.parseEther("1") })
      ).to.be.revertedWith("Token not listed");
    });
  });

  describe("Claiming Future Rewards (FR)", () => {
    it("Should allow previous owners to claim rewards", async () => {
      await myNFT.mint(addr1.address, 1);
      await myNFT.connect(addr1).transferFrom(addr1.address, addr3.address, 1);
      await myNFT.connect(addr3).list(1, ethers.utils.parseEther("1"));

      await myNFT
        .connect(addr4)
        .buy(1, { value: ethers.utils.parseEther("1") });

      const beforeClaimBalance = await ethers.provider.getBalance(
        addr1.address
      );
      await myNFT.connect(addr1).releaseFR(addr1.address);
      const afterClaimBalance = await ethers.provider.getBalance(addr1.address);

      expect(afterClaimBalance).to.be.gt(beforeClaimBalance); // Rewards should be transferred
    });

    it("Should revert if there are no rewards to claim", async () => {
      await expect(
        myNFT.connect(addr1).releaseFR(addr1.address)
      ).to.be.revertedWith("No funds to claim");
    });
  });
});
