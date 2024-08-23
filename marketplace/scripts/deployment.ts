import { Account, hash, Contract, json, Calldata, CallData, RpcProvider, shortString } from "starknet"
import fs from 'fs'
import dotenv from 'dotenv'
import { parse } from "path"

dotenv.config()

// Marketplace Deployment Steps

// Here are the steps to deploy the Flex Marketplace contracts:

// 1. Deploy `Proxy`
// 2. Deploy `CurrencyManager`
// 3. Whitelist `ETH` and `STRK` on `CurrencyManager`
// 4. Deploy `StrategyStandardSaleForFixedPrice`
// 5. Deploy `ExecutionManager`
// 6. Whitelist `StrategyStandardSaleForFixedPrice` on `ExecutionManager`
// 7. Deploy `RoyaltyFeeRegistry`
// 8. Deploy `RoyaltyFeeManager`
// 9. Deploy `SignatureChecker2`
// 10. Deploy `Marketplace`
// 11. Deploy `TransferManagerERC721`
// 12. Deploy `TransferManagerERC1155`
// 13. Deploy `TransferSelectorNFT`
// 14. Update `TransferSelectorNFT` on `Marketplace`

const ethAddress = "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7"
const strkAddress = "0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d"

// connect provider
const providerUrl = process.env.PROVIDER_URL 
const provider = new RpcProvider({ nodeUrl: providerUrl! })

// connect your account. To adapt to your own account :
const privateKey0: string = process.env.ACCOUNT_PRIVATE as string
const account0Address: string = process.env.ACCOUNT_PUBLIC as string
const account0 = new Account(provider, account0Address!, privateKey0!)

// Utility function to parse json file
function parseJsonFile(fileName: string) {
    const basePath = "../target/dev"
    const filePath = `${basePath}/${fileName}.json`
    const fileContent = fs.readFileSync(filePath).toString("ascii")
    return json.parse(fileContent)
}

// Utility function to deploy contracts
async function deployContract(contractFilePath: string, casmFilePath: string, constructorArgs = {}) {
    const compiledContract = parseJsonFile(contractFilePath)
    const compiledCasm = parseJsonFile(casmFilePath)
    const callData: CallData = new CallData(compiledContract.abi)
    const constructorCalldata: Calldata = callData.compile("constructor", constructorArgs)

    const deployResponse = await account0.declareAndDeploy({
        contract: compiledContract,
        casm: compiledCasm,
        constructorCalldata: constructorCalldata
    })

    const contractName = contractFilePath.split("/")[3].split(".")[0]

    console.log(`✅ ${contractName} Deployed: ${deployResponse.deploy.contract_address}`)

    return deployResponse
}

// Utility function to whitelist a contract
async function whitelistContract(contract: Contract, methodName: string, args: any) {
    const contractCall = contract.populate(methodName, [args])
    const tx = await contract[methodName](contractCall.calldata)
    await provider.waitForTransaction(tx.transaction_hash)
}

// Utility function to set protocol fee recipient
async function setProtocolFeeRecipient(contract: Contract, args: any) {
    const contractCall = contract.populate("set_protocol_fee_recipient", [args])
    const tx = await contract.set_protocol_fee_recipient(contractCall.calldata)
    await provider.waitForTransaction(tx.transaction_hash)
    console.log("✅ ProtocolFeeRecipient set.")
}

async function deploy() {

    console.log("🚀 Deploying with Account: " + account0Address)

    console.log("\n📦 Deploying CurrencyManager...")
    const compiledCurrencyManagerCasm = parseJsonFile("marketplace_CurrencyManager.compiled_contract_class")
    const compiledCurrencyManagerSierra = parseJsonFile("marketplace_CurrencyManager.contract_class")
    const deployCurrencyManagerResponse = await deployContract(compiledCurrencyManagerSierra, compiledCurrencyManagerCasm, { owner: account0.address })

    const currencyManagerContract = new Contract(compiledCurrencyManagerSierra.abi, deployCurrencyManagerResponse.deploy.contract_address, provider)
    currencyManagerContract.connect(account0);

    console.log("\n📦 Whitelist ETH...")
    await whitelistContract(currencyManagerContract, "add_currency", ethAddress)
    console.log("✅ ETH whitelisted.")

    console.log("\n📦 Whitelist STRK...")
    await whitelistContract(currencyManagerContract, "add_currency", strkAddress)
    console.log("✅ STRK whitelisted.")

    console.log("\n📦 Deploying StrategyStandardSaleForFixedPrice...")
    const compiledStrategyStandardSaleForFixedPriceCasm = parseJsonFile("marketplace_StrategyStandardSaleForFixedPrice.compiled_contract_class")
    const compiledStrategyStandardSaleForFixedPriceSierra = parseJsonFile("marketplace_StrategyStandardSaleForFixedPrice.contract_class")
    const deployStrategyStandardSaleForFixedPriceResponse = await deployContract(compiledStrategyStandardSaleForFixedPriceSierra, compiledStrategyStandardSaleForFixedPriceCasm, { fee: 0, owner: account0.address })
    deployStrategyStandardSaleForFixedPriceResponse.deploy.contract_address

    console.log("\n📦 Deploying ExecutionManager...")
    const compiledExecutionManagerCasm = parseJsonFile("marketplace_ExecutionManager.compiled_contract_class")
    const compiledExecutionManagerSierra = parseJsonFile("marketplace_ExecutionManager.contract_class")
    const deployExecutionManagerResponse = await deployContract(compiledExecutionManagerSierra, compiledExecutionManagerCasm, { owner: account0.address })

    const executionManagerContract = new Contract(compiledExecutionManagerSierra.abi, deployExecutionManagerResponse.deploy.contract_address, provider)
    executionManagerContract.connect(account0);

    console.log("\n📦 Whitelist StrategyStandardSaleForFixedPrice...")
    await whitelistContract(executionManagerContract, "add_strategy", deployStrategyStandardSaleForFixedPriceResponse.deploy.contract_address)
    console.log("✅ StrategyStandardSaleForFixedPrice whitelisted.")

    console.log("\n📦 Deploying RoyaltyFeeRegistry...")
    const compiledRoyaltyFeeRegistryCasm = parseJsonFile("marketplace_RoyaltyFeeRegistry.compiled_contract_class")
    const compiledRoyaltyFeeRegistrySierra = parseJsonFile("marketplace_RoyaltyFeeRegistry.contract_class")
    const deployRoyaltyFeeRegistryResponse = await deployContract(compiledRoyaltyFeeRegistrySierra, compiledRoyaltyFeeRegistryCasm, { fee_limit: 9500, owner: account0.address })

    console.log("\n📦 Deploying RoyaltyFeeManager...")
    const compiledRoyaltyFeeManagerCasm = parseJsonFile("marketplace_RoyaltyFeeManager.compiled_contract_class")
    const compiledRoyaltyFeeManagerSierra = parseJsonFile("marketplace_RoyaltyFeeManager.contract_class")
    const deployRoyaltyFeeManagerResponse = await deployContract(compiledRoyaltyFeeManagerSierra, compiledRoyaltyFeeManagerCasm, { fee_registry: deployRoyaltyFeeRegistryResponse.deploy.contract_address, owner: account0.address })

    console.log("\n📦 Deploying SignatureChecker2...")
    const compiledSignatureChecker2Casm = parseJsonFile("marketplace_SignatureChecker2.compiled_contract_class")
    const compiledSignatureChecker2Sierra = parseJsonFile("marketplace_SignatureChecker2.contract_class")
    const deploySignatureChecker2Response = await deployContract(compiledSignatureChecker2Sierra, compiledSignatureChecker2Casm, { owner: account0.address })

    console.log("\n📦 Deploying MarketPlace...")
    const compiledMarketplaceCasm = parseJsonFile("marketplace_MarketPlace.compiled_contract_class")
    const compiledMarketplaceSierra = parseJsonFile("marketplace_MarketPlace.contract_class")
    const deployMarketplaceResponse = await deployContract(compiledMarketplaceSierra, compiledMarketplaceCasm, {
        domain_name: "Flex",
        domain_ver: "1",
        recipient: account0.address,
        currency: deployCurrencyManagerResponse.deploy.contract_address,
        execution: deployExecutionManagerResponse.deploy.contract_address,
        royalty_manager: deployRoyaltyFeeManagerResponse.deploy.contract_address,
        checker: deploySignatureChecker2Response.deploy.contract_address,
        owner: account0.address
    })

    const marketplaceContract = new Contract(compiledMarketplaceSierra.abi, deployMarketplaceResponse.deploy.contract_address, provider)
    marketplaceContract.connect(account0);

    console.log("\n📦 Deploying TransferManagerERC721...")
    const compiledTransferManagerNFTCasm = parseJsonFile("marketplace_TransferManagerNFT.compiled_contract_class")
    const compiledTransferManagerNFTSierra = parseJsonFile("marketplace_TransferManagerNFT.contract_class")
    const deployTransferManagerNFTResponse = await deployContract(compiledTransferManagerNFTSierra, compiledTransferManagerNFTCasm, { marketplace: deployMarketplaceResponse.deploy.contract_address, owner: account0.address })

    console.log("\n📦 Deploying TransferManagerERC1155...")
    const compiledERC1155TransferManagerCasm = parseJsonFile("marketplace_ERC1155TransferManager.compiled_contract_class")
    const compiledERC1155TransferManagerSierra = parseJsonFile("marketplace_ERC1155TransferManager.contract_class")
    const deployERC1155TransferManagerResponse = await deployContract(compiledERC1155TransferManagerSierra, compiledERC1155TransferManagerCasm, { marketplace: deployMarketplaceResponse.deploy.contract_address, owner: account0.address })

    console.log("\n📦 Deploying TransferSelectorNFT...")
    const compiledTransferSelectorNFTCasm = parseJsonFile("marketplace_TransferSelectorNFT.compiled_contract_class")
    const compiledTransferSelectorNFTSierra = parseJsonFile("marketplace_TransferSelectorNFT.contract_class")
    const deployTransferSelectorNFTResponse = await deployContract(compiledTransferSelectorNFTSierra, compiledTransferSelectorNFTCasm, { transfer_manager_ERC721: deployTransferManagerNFTResponse.deploy.contract_address, transfer_manager_ERC1155: deployERC1155TransferManagerResponse.deploy.contract_address, owner: account0.address })

    console.log("\n📦 Whitelist TransferSelectorNFT...")
    await whitelistContract(marketplaceContract, "update_transfer_selector_NFT", deployTransferSelectorNFTResponse.deploy.contract_address)
    console.log("✅ TransferSelectorNFT whitelisted.")

    console.log("\n📦 Set ProtocolFeeRecipient...")
    await setProtocolFeeRecipient(marketplaceContract, account0.address)
}

deploy()