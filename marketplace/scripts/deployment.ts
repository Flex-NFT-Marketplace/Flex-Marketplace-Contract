import { Account, RpcProvider, Contract, json, CallData, uint256, Call, Calldata } from 'starknet';
import fs from 'fs';
import * as dotenv from 'dotenv';
dotenv.config();

const ethAddress = "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7"
const starkAddress = "0x0307784111703d85B35Ff9542ED0b9FB959aBBe193e12662D079715D2C1c1864"

let provider: RpcProvider;
let account: Account;

async function setupProvider() {
    const myNodeUrl = process.env.RPC_ENDPOINT as string;
    provider = new RpcProvider({ nodeUrl: myNodeUrl });
    const privateKey = process.env.DEPLOYER_PRIVATE_KEY as string;
    const accountAddress = process.env.DEPLOYER_ADDRESS as string;
    account = new Account(provider, accountAddress, privateKey);
}

// Deploys the contract without a constructor
async function deployContract(name: string) {
    console.log(` Declaring and deploying 🚀 [${name}]...`);
    const compiledSierra = json.parse(
        fs.readFileSync(`../target/dev/marketplace_${name}.contract_class.json`).toString('ascii')
    );
    const compiledCasm = json.parse(
        fs.readFileSync(`../target/dev/marketplace_${name}.compiled_contract_class.json`).toString('ascii')
    );

    const deployResponse = await account.declareAndDeploy({
        contract: compiledSierra,
        casm: compiledCasm,
    });

    console.log(` Deployed ✅ [${name}] -> (${deployResponse.deploy.contract_address})`);
    return { contract: new Contract(compiledSierra.abi, deployResponse.deploy.contract_address, provider), response: deployResponse };
}

// Deploys the contract with a constructor
async function deployContractWithConstructor(name: string, constructorArgs: any = {}) {
    console.log(`\n Declaring and deploying 🚀 [${name}] with constructor...`);
    const compiledSierra = json.parse(
        fs.readFileSync(`../target/dev/marketplace_${name}.contract_class.json`).toString('ascii')
    );
    const compiledCasm = json.parse(
        fs.readFileSync(`../target/dev/marketplace_${name}.compiled_contract_class.json`).toString('ascii')
    );

    const calldata = new CallData(compiledSierra.abi);
    const constructorCalldata = calldata.compile("constructor", constructorArgs);

    const deployResponse = await account.declareAndDeploy({
        contract: compiledSierra,
        casm: compiledCasm,
        constructorCalldata
    });

    console.log(` Deployed ✅ [${name}] -> (${deployResponse.deploy.contract_address}):`);
    const contract = new Contract(compiledSierra.abi, deployResponse.deploy.contract_address, provider);
    return { contract: contract, provider, response: deployResponse };
}

// Initializes the contract with an initializer
async function initializeContract(contract: Contract, calldata: any) {
    console.log(`\n Initializing 🚀 [${contract.address}]...`);
    const initializeResponse = await account.execute([
        {
            contractAddress: contract.address,
            entrypoint: "initializer",
            calldata: CallData.compile(calldata)
        }
    ]);
    console.log(` Initialized ✅ [${contract.address}] -> (${initializeResponse.transaction_hash})`);
    await provider.waitForTransaction(initializeResponse.transaction_hash);
}

// Connects the contract
async function connectContract(contract: Contract) {
    contract.connect(account);
}

// Adds a currency to the contract
async function addCurrency(currencyManagerContract: Contract, address: string) {
    console.log(`\n Adding 🚀 [${address}]`);
    try {
        const addResponse = await currencyManagerContract.add_currency(address);
        console.log(` Added ✅ [${address}] -> (${addResponse.transaction_hash})`);
        await provider.waitForTransaction(addResponse.transaction_hash);
    } catch (error) {
        console.error(`Error adding ${address}:`, error);
    }
}

// Updates the transfer selector NFT
async function updateTransferSelectorNFT(marketPlaceContract: Contract, address: string) {
    console.log("\n Updating transfer selector NFT 🚀");
    try {
        const updateResponse = await marketPlaceContract.update_transfer_selector_NFT(address);
        console.log(` Transfer Selector NFT Updated ✅ [${updateResponse.transaction_hash}]`);
        await provider.waitForTransaction(updateResponse.transaction_hash);
    } catch (error) {
        console.error("Error Updating Transfer Selector NFT:", error);
    }
}

// Updates the protocol fee recipient
async function updateProtocolFeeRecipient(marketPlaceContract: Contract, address: string) {
    console.log("\n Seting ProtocolFeeRecipient 🚀");
    try {
        const updateResponse = await marketPlaceContract.update_protocol_fee_recepient(address);
        console.log(` Protocol Fee Recipient Updated ✅ [${updateResponse.transaction_hash}]`);
        await provider.waitForTransaction(updateResponse.transaction_hash);
    } catch (error) {
        console.error("Error Updating Protocol Fee Recipient:", error);
    }
}

// Deploys all the contracts
async function deploy() {
    await setupProvider();

    // Deploy and initialize CurrencyManager
    console.log("\n\n[-------------------- 📦 CurrencyManager 📦 --------------------]\n");
    const { contract: currencyManagerContract } = await deployContract("CurrencyManager");
    await initializeContract(currencyManagerContract, { owner: account.address, proxy_admin: account.address });
    await connectContract(currencyManagerContract);

    // Add ETH and STARK as currencies
    console.log("\n\n[-------------------- 📦 Adding ETH as a Currency 📦 --------------------]\n");
    await addCurrency(currencyManagerContract, ethAddress);
    console.log("\n[-------------------- 📦 Adding STARK as a Currency 📦 --------------------]");
    await addCurrency(currencyManagerContract, starkAddress);

    // Deploy and initialize StrategyStandardSaleForFixedPrice
    console.log("\n\n[-------------------- 📦 StrategyStandardSalesForFixedPrice 📦 --------------------]\n");
    const { contract: strategyContract } = await deployContract("StrategyStandardSaleForFixedPrice");
    await initializeContract(strategyContract, { fee: 0, owner: account.address });

    // Deploy and initialize ExecutionManager
    console.log("\n\n[-------------------- 📦 ExecutionManager 📦 --------------------]\n");
    const { contract: executionManagerContract } = await deployContract("ExecutionManager");
    await initializeContract(executionManagerContract, { owner: account.address });
    await connectContract(executionManagerContract);
    await executionManagerContract.add_strategy(ethAddress);

    // Deploy and initialize RoyaltyFeeRegistry
    console.log("\n\n[-------------------- 📦 RoyaltyFeeRegistry 📦 --------------------]\n");
    const { contract: royaltyFeeRegistryContract } = await deployContract("RoyaltyFeeRegistry");
    await initializeContract(royaltyFeeRegistryContract, { fee_limit: 9500, owner: account.address });

    // Deploy and initialize RoyaltyFeeManager
    console.log("\n\n[-------------------- 📦 RoyaltyFeeManager 📦 --------------------]\n");
    const { contract: royaltyFeeManagerContract } = await deployContract("RoyaltyFeeManager");
    await initializeContract(royaltyFeeManagerContract, { fee_registry: royaltyFeeRegistryContract.address, owner: account.address });

    // Deploy SignatureChecker2 with constructor
    console.log("\n\n[-------------------- 📦 SignatureChecker2 📦 --------------------]\n");
    const { contract: signatureCheckerContract } = await deployContractWithConstructor("SignatureChecker2");

    // Deploy and initialize MarketPlace
    console.log("\n\n[-------------------- 📦 MarketPlace 📦 --------------------]\n");
    const { contract: marketPlaceContract, response: marketPlaceResponse } = await deployContract("MarketPlace");
    await initializeContract(marketPlaceContract, {
        hash: marketPlaceResponse.deploy.classHash,
        recepient: account.address,
        currency: currencyManagerContract.address,
        execution: executionManagerContract.address,
        fee_manager: royaltyFeeManagerContract.address,
        checker: signatureCheckerContract.address,
        owner: account.address,
        proxy_admin: account.address
    });
    await connectContract(marketPlaceContract);

    // Deploy and initialize TransferManagerNFT
    console.log("\n\n[-------------------- 📦 TransferManagerNFT 📦 --------------------]\n");
    const { contract: transferManagerNFTContract } = await deployContract("TransferManagerNFT");
    await initializeContract(transferManagerNFTContract, { marketplace: marketPlaceContract.address, owner: account.address });

    // Deploy and initialize ERC1155TransferManager
    console.log("\n\n[-------------------- 📦 ERC1155TransferManager 📦 --------------------]\n");
    const { contract: erc1155TransferManagerContract } = await deployContract("ERC1155TransferManager");
    await initializeContract(erc1155TransferManagerContract, { marketplace: marketPlaceContract.address, owner: account.address });

    // Deploy and initialize TransferSelectorNFT
    console.log("\n\n[-------------------- 📦 TransferSelectorNFT 📦 --------------------]\n");
    const { contract: transferSelectorNFTContract } = await deployContract("TransferSelectorNFT");
    await initializeContract(transferSelectorNFTContract, {
        transfer_manager_ERC721: transferManagerNFTContract.address,
        transfer_manager_ERC1155: erc1155TransferManagerContract.address,
        owner: account.address
    });
    await connectContract(transferSelectorNFTContract);

    // Update transfer selector NFT and protocol fee recipient
    console.log("\n\n[-------------------- 📦 Update Transfer Selector NFT 📦 --------------------]");
    await updateTransferSelectorNFT(marketPlaceContract, transferSelectorNFTContract.address);
    console.log("\n\n[-------------------- 📦 Protocol Fee Recipient 📦 --------------------]");
    await updateProtocolFeeRecipient(marketPlaceContract, account.address);
}

deploy().catch(console.error);