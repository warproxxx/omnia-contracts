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

        const Vault = await ethers.getContractFactory("Vault");
        vault = await Vault.attach(vaults[0]);
    })

    it("Basic Stuff", async function () {
        //check sufficient balance
        expect(BigInt(await pairs['WETH'].balanceOf(owner.address)) >= BigInt(10**18)).to.be.true;
        expect(BigInt(await pairs['WBTC'].balanceOf(owner.address)) >= BigInt(10**18)).to.be.true;
        expect(BigInt(await pairs['USDC'].balanceOf(owner.address)) >= BigInt(10**18)).to.be.true;
    })

    it("Add and remove liquidity", async function () {
        amt = BigInt(10**18)
        await pairs['WETH'].approve(vault.address, ethers.constants.MaxUint256);
        await vault.addLiquidity(amt, pairs['WETH'].address);
        
        expect(BigInt(await vault.balanceOf(owner.address, 0))).to.equal(amt);
        expect(BigInt(await pairs['WETH'].balanceOf(vault.address)) >= amt).to.equal(true);

        console.log(await vault.getUSDBalance())  

        // await vault.withdrawLiquidity(amt, pairs['WETH'].address);

        // await vault.addLiquidity(amt, pairs['WETH'].address);
    })

    it("Take and Repay Loan", async function () {
        
    })

})  