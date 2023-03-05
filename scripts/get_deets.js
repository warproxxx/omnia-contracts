const { ethers } = require("hardhat");
const {ORACLE, VAULT_MANAGER, VAULTMANAGER_ABI, ORACLE_ABI, VAULT, VAULT_ABI, ERC20_ABI } = require("../config_goerli")


async function main(){
    let [signer] = await ethers.getSigners();
    let contract = new ethers.Contract( VAULT, VAULT_ABI, signer);
    let token_contract = new ethers.Contract( '0x307b2db2E2F12a9979175b0867C59963fC0e8064', ERC20_ABI, signer);

    console.log("Approved")
    await token_contract.approve(VAULT, ethers.constants.MaxUint256);

    console.log("Adding liquidity")
    await contract.addLiquidity(10, '0x307b2db2E2F12a9979175b0867C59963fC0e8064')
    console.log("Removing liquidty")
    await contract.withdrawLiquidity(10, '0x307b2db2E2F12a9979175b0867C59963fC0e8064')
}

main()
