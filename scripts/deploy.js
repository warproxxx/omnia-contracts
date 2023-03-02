const util = require('util');
const exec = util.promisify(require('child_process').exec);

const hre = require("hardhat");
const { promises: { readdir } } = require('fs')
const fs = require("fs");
const { ethers } = require("hardhat");

let abis = {}
abis['ERC20_ABI'] = '[{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_value","type":"uint256"}],"name":"approve","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_from","type":"address"},{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transferFrom","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transfer","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"},{"name":"_spender","type":"address"}],"name":"allowance","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"payable":true,"stateMutability":"payable","type":"fallback"},{"anonymous":false,"inputs":[{"indexed":true,"name":"owner","type":"address"},{"indexed":true,"name":"spender","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Transfer","type":"event"}]'

function getGenericVaultParams() {
    let vaultDetails = { 
        VAULT_NAME: "Basic Vault", 
        VAULT_DESCRIPTION: "Low Risk yield parking", 
    }

    return vaultDetails

}

async function deployContracts(testnet=true, receivers=[]){
    let [signer] = await ethers.getSigners();
    let addresses = {}
    let pairs = {};

    if (testnet == true) {
        const ERC20 = await ethers.getContractFactory("ERC20");

        weth = await ERC20.deploy(signer.addres_at_onces, 1 * 10**18);
        await weth.deployed();  
        console.log("WETH Contract Deployed at " + weth.address);
        pairs['WETH'] = weth

        wbtc = await ERC20.deploy(signer.address, 0.1 * 10**18);
        await wbtc.deployed();  
        console.log("WBTC Contract Deployed at " + wbtc.address);
        pairs['WBTC'] = wbtc

        usdc = await ERC20.deploy(signer.address, 1000 * 10**18);
        await usdc.deployed();  
        console.log("USDC Contract Deployed at " + usdc.address);
        pairs['USDC'] = usdc
        
    }
    

   
    const Oracle = await ethers.getContractFactory("Oracle");
    or = await Oracle.deploy(signer.address);
    await or.deployed(); 
    console.log("Oracle Contract Deployed at " + or.address);
    addresses['Oracle'] = or.address
    

    const Vault = await ethers.getContractFactory("Vault");
    vb = await Vault.deploy()
    await vb.deployed();  
    
    const VaultManager = await ethers.getContractFactory("VaultManager");
    let vm = await VaultManager.deploy({ASSET: WETH_CONTRACT, AUCTION_CONTRACT: pe.address, BASE_VAULT: vb.address, ORACLE_CONTRACT: or.address, PEPEFI_ADMIN: signer.address, VAULT_MANAGER: '0x0000000000000000000000000000000000000000'} );
    await vm.deployed();  
    console.log("Vault Manager Contract Deployed at " + vm.address);
    addresses['VM'] = vm.address


    let [params] = getGenericVaultParams()
    await vm.createVault(params)

    console.log("Vault created")

    if (testnet == true) {
        await or.updatePrices([pairs['WBTC'].address], [24 * 10**18]);
        await or.updatePrices([pairs['WETH'].address], [16 * 10**18]);
        await or.updatePrices([pairs['USDC'].address], [10**18]);
    }

    let vaults = await vm.getVaults()

    return [pairs, addresses, or, vb, vm]
}

async function deploy(){

    let [pairs, addresses, or, vb, vm] = await deployContracts()


    let ABI_STRING = ""
    let export_string = "module.exports = {"


    await exec("yarn run hardhat export-abi")
    let path = './abi/contracts'
    let dir = await readdir(path, { withFileTypes: true })

    dir.forEach((value) => {
        let name = value.name

        if (name.includes(".sol")){
            let full_path = path + "/" + name + "/" + name.replace(".sol", ".json");
            let contents = fs.readFileSync(full_path).toString().replace(/(\r\n|\n|\r)/gm,"")

            let var_name = name.replace(".sol", "").toUpperCase()
            
            ABI_STRING = ABI_STRING + "let " + var_name + "_ABI" + " = " + contents.replace(/\s/g, '') + "\n"  
            export_string = export_string + var_name + "_ABI,"
         
        }
    })

    ABI_STRING = ABI_STRING + "\n\n"

    ABI_STRING = ABI_STRING + "let VAULT_MANAGER='" + vm.address + "'\n"
    ABI_STRING = ABI_STRING + "let ORACLE='" + or.address + "'\n\n"

    export_string = export_string + "ORACLE,VAULT_MANAGER}"

    ABI_STRING = ABI_STRING + export_string

    if (process.env.HARDHAT_NETWORK == 'goerli'){
        fs.writeFileSync('config_goerli.js', ABI_STRING);   
        fs.writeFileSync('data_goerli.json', JSON.stringify(addresses, null, 2) , 'utf-8');
    }
    else{
        fs.writeFileSync('config.js', ABI_STRING);
        fs.writeFileSync('data.json', JSON.stringify(addresses, null, 2) , 'utf-8');
    }
}


if (require.main === module) {
    deploy()
}



module.exports = {deployContracts, getGenericVaultParams};