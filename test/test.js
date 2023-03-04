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
        expect(BigInt(await pairs['WETH'].balanceOf(owner.address)) >= BigInt(10**16)).to.be.true;
        expect(BigInt(await pairs['WBTC'].balanceOf(owner.address)) >= BigInt(10**16)).to.be.true;
        expect(BigInt(await pairs['USDC'].balanceOf(owner.address)) >= BigInt(10**16)).to.be.true;

        expect(await vault.checkBalanced(pairs['WETH'].address, 1)).to.be.true;
        expect(await vault.checkBalanced(pairs['WBTC'].address, 1)).to.be.true;
        expect(await vault.checkBalanced(pairs['USDC'].address, 1)).to.be.true;

    })

    it("Add and remove liquidity", async function () {
        amt = BigInt(100000) * BigInt(10**18)
        await pairs['USDC'].approve(vault.address, ethers.constants.MaxUint256);
        await vault.addLiquidity(amt, pairs['USDC'].address);
        
        expect(BigInt(await vault.balanceOf(owner.address, 0))).to.equal(amt);
        expect(BigInt(await pairs['USDC'].balanceOf(vault.address)) >= amt).to.equal(true);

        let [usd_balance, delta] = await vault.getUSDBalanceAndDelta()
        expect(BigInt(usd_balance) / BigInt(10**18) >= BigInt(1500))  
        await vault.withdrawLiquidity(amt, pairs['USDC'].address);

        
        await vault.addLiquidity(amt, pairs['USDC'].address);

        await pairs['WBTC'].approve(vault.address, ethers.constants.MaxUint256);

        console.log(await pairs['WBTC'].balanceOf(owner.address))
        await vault.addLiquidity(BigInt(10**15), pairs['WBTC'].address);
    })

    it("Take and Repay Loan", async function () {
        let currDate = Math.floor((new Date()).getTime() / 1000)
        let repaymentDate = currDate + (30 * 86400)

        await vault.createLoan(pairs['WBTC'].address, pairs['USDC'].address,  BigInt(10**17), BigInt(1000) * BigInt(10**17) , repaymentDate)

        let loanDetails = await vault._loans(1)

        expect(parseInt(loanDetails.repayment / 10**18 )).to.equal(104);
        expect(parseInt(loanDetails.principal / 10**18 )).to.equal(100);

        await pairs['USDC'].approve(vault.address, ethers.constants.MaxUint256);
        await vault.repayLoan(1)
    })

    it("Swap", async function() {
        let signer_wbtc1 = await pairs['WBTC'].balanceOf(owner.address)
        let signer_usdc1 = await pairs['USDC'].balanceOf(owner.address)

        let vault_wbtc1 = await pairs['WBTC'].balanceOf(vault.address)
        let vault_usdc1 = await pairs['USDC'].balanceOf(vault.address)

        await vault.swap(pairs['WBTC'].address, pairs['USDC'].address, BigInt(10**14))

        let signer_wbtc2 = await pairs['WBTC'].balanceOf(owner.address)
        let signer_usdc2 = await pairs['USDC'].balanceOf(owner.address)

        let vault_wbtc2 = await pairs['WBTC'].balanceOf(vault.address)
        let vault_usdc2 = await pairs['USDC'].balanceOf(vault.address)

        
        expect(signer_wbtc1 > signer_wbtc2).to.be.true;
        expect(vault_wbtc1 < vault_wbtc2).to.be.true;

        expect(signer_usdc1 < signer_usdc2).to.be.true;
        expect(vault_usdc1 > vault_usdc2).to.be.true;

    })

    // it("Hedging", async function() {

    //     let currDate = Math.floor((new Date()).getTime() / 1000)
    //     let repaymentDate = currDate + (30 * 86400)

    //     await vault.createLoan(pairs['WBTC'].address, pairs['USDC'].address,  BigInt(10**14), BigInt(1000) * BigInt(10**14) , repaymentDate)

    //     await or.updatePrices([pairs['WBTC'].address], [BigInt(10) * BigInt(10**14)]);
    //     await vault.hedgePositions()

    //     await or.updatePrices([pairs['WBTC'].address], [BigInt(10) * BigInt(10**18)]);
    //     await vault.hedgePositions()
        
    //     let loanDetails = await vault._loans(2)

    //     expect(parseInt(loanDetails.hedgeId) != 0).to.equal(true);

    //     await or.updatePrices([pairs['WBTC'].address], [BigInt(24000) * BigInt(10**18)]);

    //     await vault.hedgePositions()
    //     let loanDetails2 = await vault._loans(2)
    //     expect(parseInt(loanDetails2.hedgeId) == 0).to.equal(true);
    // })



})  