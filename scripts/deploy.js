const util = require('util');
const exec = util.promisify(require('child_process').exec);

const hre = require("hardhat");
const { promises: { readdir } } = require('fs')
const fs = require("fs");
const { ethers } = require("hardhat");

let abis = {}
abis['ERC20_ABI'] = '[{"constant":true,"inputs":[],"name":"name","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_spender","type":"address"},{"name":"_value","type":"uint256"}],"name":"approve","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"totalSupply","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_from","type":"address"},{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transferFrom","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[],"name":"decimals","outputs":[{"name":"","type":"uint8"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"}],"name":"balanceOf","outputs":[{"name":"balance","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[],"name":"symbol","outputs":[{"name":"","type":"string"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_to","type":"address"},{"name":"_value","type":"uint256"}],"name":"transfer","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"name":"_owner","type":"address"},{"name":"_spender","type":"address"}],"name":"allowance","outputs":[{"name":"","type":"uint256"}],"payable":false,"stateMutability":"view","type":"function"},{"payable":true,"stateMutability":"payable","type":"fallback"},{"anonymous":false,"inputs":[{"indexed":true,"name":"owner","type":"address"},{"indexed":true,"name":"spender","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"from","type":"address"},{"indexed":true,"name":"to","type":"address"},{"indexed":false,"name":"value","type":"uint256"}],"name":"Transfer","type":"event"}]'

function getGenericVaultParams(pairs) {

    let whitelisted = []
    let addys = []
    
    for (const [key, value] of Object.entries(pairs)) {
        let params = {}
        params['collection'] = value.address

        //everything is *100
        if (key == 'WETH') {
            params['MAX_LTV'] = 80
            params['MAX_DURATION'] = 6000
            params['MAX_APR'] = 2000
            params['MIN_APR'] = 500
            params['slope'] = 10 * 100
            params['intercept'] = 400
            params['MAX_EXPOSURE'] = 5
            params['HEDGE_AT'] = 2
            params['MAX_DELTA_DIVERGENCE'] = 1
            params['HEDGE_PERCENTAGE'] = 100

        } else if (key == 'WBTC') {
            params['MAX_LTV'] = 90
            params['MAX_DURATION'] = 9000
            params['MAX_APR'] = 1000
            params['MIN_APR'] = 500
            params['slope'] = 10 * 100
            params['intercept'] = 400
            params['MAX_EXPOSURE'] = 5
            params['HEDGE_AT'] = 2
            params['MAX_DELTA_DIVERGENCE'] = 1
            params['HEDGE_PERCENTAGE'] = 100

        } else if (key == 'USDC') {
            params['MAX_LTV'] = 100
            params['MAX_DURATION'] = 18000
            params['MAX_APR'] = 500
            params['MIN_APR'] = 500
            params['slope'] = 10 * 100
            params['intercept'] = 400
            params['MAX_EXPOSURE'] = 100
            params['HEDGE_AT'] = 500 //ie never hedge
            params['MAX_DELTA_DIVERGENCE'] = 2
            params['HEDGE_PERCENTAGE'] = 0
        }

        params['COLLATERAL_SIZE'] = 0;

        whitelisted.push(params)

        addys.push(value.address)
    }

    return [{
        VAULT_NAME: "Omnia Vault",
        VAULT_DESCRIPTION: "The Default Vault Provides balance Loans", 
        ORACLE_CONTRACT: '0x0000000000000000000000000000000000000000',
        MAX_LEVERAGE: 500
    }, addys, whitelisted]

}

async function deployContracts(testnet=true){

    let [signer] = await ethers.getSigners();
    let addresses = {}
    let pairs = {};
    let AGGREGATOR = "0xf4030086522a5beea4988f8ca5b36dbc97bee88c";
    let WETH_CONTRACT = "";

    if (testnet == true) {
        const ERC20 = await ethers.getContractFactory("ERC20");

        usdc = await ERC20.deploy(signer.address, BigInt(200000) * BigInt(10**18));
        await usdc.deployed();  
        console.log("USDC Contract Deployed at " + usdc.address);
        pairs['USDC'] = usdc

        
        weth = await ERC20.deploy(signer.address, BigInt(1) * BigInt(10**18));
        await weth.deployed();  
        console.log("WETH Contract Deployed at " + weth.address);
        pairs['WETH'] = weth

        wbtc = await ERC20.deploy(signer.address, BigInt(3) * BigInt(10**17));
        await wbtc.deployed();  
        console.log("WBTC Contract Deployed at " + wbtc.address);
        pairs['WBTC'] = wbtc



        await weth.mint(signer.address);
        await wbtc.mint(signer.address);
        await usdc.mint(signer.address);

    }
   
    const Oracle = await ethers.getContractFactory("Oracle");
    or = await Oracle.deploy(signer.address);
    await or.deployed(); 
    console.log("Oracle Contract Deployed at " + or.address);
    addresses['Oracle'] = or.address
    
    const GMX = await ethers.getContractFactory("GMX");
    gmx = await GMX.deploy(or.address);
    await gmx.deployed(); 
    console.log("GMX Contract Deployed at " + gmx.address);
    addresses['GMX'] = or.address

    if (testnet == true) {
        await weth.mint(gmx.address);
        await wbtc.mint(gmx.address);
        await usdc.mint(gmx.address);
    }

    const Vault = await ethers.getContractFactory("Vault");
    vb = await Vault.deploy()
    await vb.deployed();  
    
    const VaultManager = await ethers.getContractFactory("VaultManager");
    let vm = await VaultManager.deploy(vb.address, or.address, signer.address);
    await vm.deployed();  
    console.log("Vault Manager Contract Deployed at " + vm.address);
    addresses['VM'] = vm.address

    let [_VAULT_DETAILS, _WHITELISTED_ASSETS, _WHITELISTED_DETAILS] = getGenericVaultParams(pairs)
    _VAULT_DETAILS['GMX_CONTRACT'] = gmx.address

    
    await vm.createVault(_VAULT_DETAILS, _WHITELISTED_ASSETS, _WHITELISTED_DETAILS, vb.address)

    console.log("Vault created")

    if (testnet == true) {
        await or.updatePrices([pairs['WBTC'].address], [BigInt(24000) * BigInt(10**18)]);
        await or.updatePrices([pairs['WETH'].address], [BigInt(1600) * BigInt(10**18)]);
        await or.updatePrices([pairs['USDC'].address], [BigInt(10**18)]);
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
    
    let pair_dict = {}

    for (const [key, value] of Object.entries(pairs)) {
        pair_dict[key] = value.address
    }

    ABI_STRING = ABI_STRING + "let PAIRS=" + JSON.stringify(pair_dict) + "\n\n"


    export_string = export_string + "ORACLE,VAULT_MANAGER,PAIRS}"

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