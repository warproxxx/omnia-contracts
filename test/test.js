const { expect } = require("chai");
const { ethers } = require("hardhat");

const {deployContracts, getGenericVaultParams} =  require("../scripts/deploy.js")
let owner;
let vault;



//Use testnet NFT to take and repay loan
describe('Contract tests', () => {

    before('Deploy Contract and Transfer Tokens', async () => {
        [owner] = await ethers.getSigners();
        [pairs, addresses, or, vb, vm] = await deployContracts(testnet=true, receivers=[owner.address]);


        let vaults = await vm.getVaults()

        // const Vault = await ethers.getContractFactory("Vault");
        // vault = await Vault.attach(vaults[0]);
    })

    it("Basic Stuff", async function () {
        
    })

})