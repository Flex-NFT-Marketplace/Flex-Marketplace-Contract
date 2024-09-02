import { Account, RpcProvider, Contract, json, CallData } from 'starknet';
import fs from 'fs';
import * as dotenv from 'dotenv';
dotenv.config();

const ethAddress = "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7";
const starkAddress = "0x0307784111703d85B35Ff9542ED0b9FB959aBBe193e12662D079715D2C1c1864";

let provider: RpcProvider;
let account: Account;

// Initialize the provider and account
async function setupProvider() {
    provider = new RpcProvider({ nodeUrl: process.env.RPC_ENDPOINT as string });
    account = new Account(provider, process.env.DEPLOYER_ADDRESS as string, process.env.DEPLOYER_PRIVATE_KEY as string);
}

// Deploy a contract with or without a constructor
async function deployContract(name: string, constructorArgs: any = null) {
    console.log(`\n Declaring and deploying 🚀 [${name}]${constructorArgs ? " with constructor" : ""}...`);
    
    const compiledSierra = json.parse(fs.readFileSync(`../target/dev/marketplace_${name}.contract_class.json`).toString('ascii'));
    const compiledCasm = json.parse(fs.readFileSync(`../target/dev/marketplace_${name}.compiled_contract_class.json`).toString('ascii'));

    const deployOptions: any = { contract: compiledSierra, casm: compiledCasm };
    if (constructorArgs) {
        const calldata = new CallData(compiledSierra.abi);
        deployOptions.constructorCalldata = calldata.compile("constructor", constructorArgs);
    }

    const deployResponse = await account.declareAndDeploy(deployOptions);
    const contract = new Contract(compiledSierra.abi, deployResponse.deploy.contract_address, provider);
    console.log(` Deployed ✅ [${name}] -> (${deployResponse.deploy.contract_address})`);

    return { contract, deployResponse };
}

// Initialize a contract
async function initializeContract(contract: Contract, calldata: any) {
    console.log(`\n Initializing 🚀 [${contract.address}]...`);
    const initializeResponse = await account.execute([{ 
        contractAddress: contract.address, 
        entrypoint: "initializer", 
        calldata: CallData.compile(calldata) 
    }]);
    console.log(` Initialized ✅ [${contract.address}] -> (${initializeResponse.transaction_hash})`);
    await provider.waitForTransaction(initializeResponse.transaction_hash);
}

// Connect the contract to the account
function connectContract(contract: Contract) {
    contract.connect(account);
}

// Generalized function to handle contract actions
async function handleContractAction(action: string, contract: Contract, address: string) {
    console.log(`\n ${action} 🚀 [${address}]`);
    try {
        const actionResponse = await contract[action](address);
        console.log(` ${action.replace('_', ' ')} Updated ✅ [${actionResponse.transaction_hash}]`);
        await provider.waitForTransaction(actionResponse.transaction_hash);
    } catch (error) {
        console.error(`Error ${action.replace('_', ' ').toLowerCase()}:`, error);
    }
}

// Main deployment process
async function deploy() {
    await setupProvider();

    const contractsToDeploy = [
        { name: "CurrencyManager", initArgs: { owner: account.address, proxy_admin: account.address } },
        { name: "StrategyStandardSaleForFixedPrice", initArgs: { fee: 0, owner: account.address } },
        { name: "ExecutionManager", initArgs: { owner: account.address } },
        { name: "RoyaltyFeeRegistry", initArgs: { fee_limit: 9500, owner: account.address } },
        { name: "RoyaltyFeeManager", initArgs: { fee_registry: "", owner: account.address }, afterDeploy: (contract) => contract.address },
        { name: "SignatureChecker2", constructorArgs: {} },
        { name: "MarketPlace", initArgs: {} }, // Will be initialized with multiple dependencies
        { name: "TransferManagerNFT", initArgs: { marketplace: "", owner: account.address } },
        { name: "ERC1155TransferManager", initArgs: { marketplace: "", owner: account.address } },
        { name: "TransferSelectorNFT", initArgs: { transfer_manager_ERC721: "", transfer_manager_ERC1155: "", owner: account.address } }
    ];

    let deployedContracts: Record<string, Contract> = {};

    for (const { name, initArgs, constructorArgs, afterDeploy } of contractsToDeploy) {
        const { contract, deployResponse } = await deployContract(name, constructorArgs);
        if (initArgs) {
            if (name === "MarketPlace") {
                Object.assign(initArgs, {
                    hash: deployResponse.deploy.classHash,
                    recepient: account.address,
                    currency: deployedContracts["CurrencyManager"].address,
                    execution: deployedContracts["ExecutionManager"].address,
                    fee_manager: deployedContracts["RoyaltyFeeManager"].address,
                    checker: deployedContracts["SignatureChecker2"].address,
                    owner: account.address,
                    proxy_admin: account.address
                });
            } else if (name === "TransferManagerNFT" || name === "ERC1155TransferManager") {
                initArgs.marketplace = deployedContracts["MarketPlace"].address;
            }
            await initializeContract(contract, initArgs);
        }
        if (afterDeploy) afterDeploy(contract);
        connectContract(contract);
        deployedContracts[name] = contract;
    }

    // Additional actions
    await handleContractAction("add_currency", deployedContracts["CurrencyManager"], ethAddress);
    await handleContractAction("add_currency", deployedContracts["CurrencyManager"], starkAddress);
    await handleContractAction("update_transfer_selector_NFT", deployedContracts["MarketPlace"], deployedContracts["TransferSelectorNFT"].address);
    await handleContractAction("update_protocol_fee_recepient", deployedContracts["MarketPlace"], account.address);
}

deploy().catch(console.error);
