import { Account, hash, Contract, json, Calldata, CallData, RpcProvider, shortString } from "starknet"
import fs from 'fs'
import dotenv from 'dotenv'

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
function buildPath(fileName: string) {
    const basePath = "../target/dev/"
    const filePath = basePath + fileName + '.json'
    return filePath
}

// Utility function to deploy contracts
async function deployContract(contractFilePath: any, casmFilePath: any, constructorArgs = {}) {
    const compiledContract = json.parse(fs.readFileSync(contractFilePath).toString("ascii"))
    const compiledCasm = json.parse(fs.readFileSync(casmFilePath).toString("ascii"))
    const callData: CallData = new CallData(compiledContract.abi)
    const constructorCalldata: Calldata = callData.compile("constructor", constructorArgs)

    const deployResponse = await account0.declareAndDeploy({
        contract: compiledContract,
        casm: compiledCasm,
        constructorCalldata: constructorCalldata
    })

    const contractName = compiledContract.contract_name

    console.log(`✅ ${contractName} Deployed: ${deployResponse.deploy.contract_address}`)

    return [deployResponse.deploy.contract_address, compiledContract.abi]
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
    const compiledCurrencyManagerCasmPath = buildPath("marketplace_CurrencyManager.compiled_contract_class")
    const compiledCurrencyManagerSierraPath = buildPath("marketplace_CurrencyManager.contract_class")


    const [deployCurrencyManagerResponse, compiledCurrencyManagerSierraAbi] = await deployContract(compiledCurrencyManagerSierraPath, compiledCurrencyManagerCasmPath, { owner: account0.address })

    console.log("I am working: ", deployCurrencyManagerResponse)

    const currencyManagerContract = new Contract(compiledCurrencyManagerSierraAbi, deployCurrencyManagerResponse, provider)
    currencyManagerContract.connect(account0);

    console.log("\n📦 Whitelist ETH...")
    await whitelistContract(currencyManagerContract, "add_currency", ethAddress)
    console.log("✅ ETH whitelisted.")

    console.log("\n📦 Whitelist STRK...")
    await whitelistContract(currencyManagerContract, "add_currency", strkAddress)
    console.log("✅ STRK whitelisted.")

    console.log("\n📦 Deploying StrategyStandardSaleForFixedPrice...")
    const compiledStrategyStandardSaleForFixedPriceCasmPath = buildPath("marketplace_StrategyStandardSaleForFixedPrice.compiled_contract_class")
    const compiledStrategyStandardSaleForFixedPriceSierraPath = buildPath("marketplace_StrategyStandardSaleForFixedPrice.contract_class")
    const [deployStrategyStandardSaleForFixedPriceResponse] = await deployContract(compiledStrategyStandardSaleForFixedPriceSierraPath, compiledStrategyStandardSaleForFixedPriceCasmPath, { fee: 0, owner: account0.address })

    console.log("\n📦 Deploying ExecutionManager...")
    const compiledExecutionManagerCasmPath = buildPath("marketplace_ExecutionManager.compiled_contract_class")
    const compiledExecutionManagerSierraPath = buildPath("marketplace_ExecutionManager.contract_class")
    const [deployExecutionManagerResponse, compiledExecutionManagerSierraAbi] = await deployContract(compiledExecutionManagerSierraPath, compiledExecutionManagerCasmPath, { owner: account0.address })

    const executionManagerContract = new Contract(compiledExecutionManagerSierraAbi, deployExecutionManagerResponse, provider)
    executionManagerContract.connect(account0);

    console.log("\n📦 Whitelist StrategyStandardSaleForFixedPrice...")
    await whitelistContract(executionManagerContract, "add_strategy", deployStrategyStandardSaleForFixedPriceResponse)
    console.log("✅ StrategyStandardSaleForFixedPrice whitelisted.")

    console.log("\n📦 Deploying RoyaltyFeeRegistry...")
    const compiledRoyaltyFeeRegistryCasmPath = buildPath("marketplace_RoyaltyFeeRegistry.compiled_contract_class")
    const compiledRoyaltyFeeRegistrySierraPath = buildPath("marketplace_RoyaltyFeeRegistry.contract_class")
    const [deployRoyaltyFeeRegistryResponse] = await deployContract(compiledRoyaltyFeeRegistrySierraPath, compiledRoyaltyFeeRegistryCasmPath, { fee_limit: 9500, owner: account0.address })

    console.log("\n📦 Deploying RoyaltyFeeManager...")
    const compiledRoyaltyFeeManagerCasmPath = buildPath("marketplace_RoyaltyFeeManager.compiled_contract_class")
    const compiledRoyaltyFeeManagerSierraPath = buildPath("marketplace_RoyaltyFeeManager.contract_class")
    const [deployRoyaltyFeeManagerResponse] = await deployContract(compiledRoyaltyFeeManagerSierraPath, compiledRoyaltyFeeManagerCasmPath, { fee_registry: deployRoyaltyFeeRegistryResponse, owner: account0.address })

    console.log("\n📦 Deploying SignatureChecker2...")
    const compiledSignatureChecker2CasmPath = buildPath("marketplace_SignatureChecker2.compiled_contract_class")
    const compiledSignatureChecker2SierraPath = buildPath("marketplace_SignatureChecker2.contract_class")
    const [deploySignatureChecker2Response] = await deployContract(compiledSignatureChecker2SierraPath, compiledSignatureChecker2CasmPath, { owner: account0.address })

    console.log("\n📦 Deploying MarketPlace...")
    const compiledMarketplaceCasmPath = buildPath("marketplace_MarketPlace.compiled_contract_class")
    const compiledMarketplaceSierraPath = buildPath("marketplace_MarketPlace.contract_class")
    const [deployMarketplaceResponse, compiledMarketplaceSierraAbi] = await deployContract(compiledMarketplaceSierraPath, compiledMarketplaceCasmPath, {
        domain_name: "Flex",
        domain_ver: "1",
        recipient: account0.address,
        currency: deployCurrencyManagerResponse,
        execution: deployExecutionManagerResponse,
        royalty_manager: deployRoyaltyFeeManagerResponse,
        checker: deploySignatureChecker2Response,
        owner: account0.address
    })

    const marketplaceContract = new Contract(compiledMarketplaceSierraAbi, deployMarketplaceResponse, provider)
    marketplaceContract.connect(account0);

    console.log("\n📦 Deploying TransferManagerERC721...")
    const compiledTransferManagerNFTCasmPath = buildPath("marketplace_TransferManagerNFT.compiled_contract_class")
    const compiledTransferManagerNFTSierraPath = buildPath("marketplace_TransferManagerNFT.contract_class")
    const [deployTransferManagerNFTResponse] = await deployContract(compiledTransferManagerNFTSierraPath, compiledTransferManagerNFTCasmPath, { marketplace: deployMarketplaceResponse, owner: account0.address })

    console.log("\n📦 Deploying TransferManagerERC1155...")
    const compiledERC1155TransferManagerCasmPath = buildPath("marketplace_ERC1155TransferManager.compiled_contract_class")
    const compiledERC1155TransferManagerSierraPath = buildPath("marketplace_ERC1155TransferManager.contract_class")
    const [deployERC1155TransferManagerResponse] = await deployContract(compiledERC1155TransferManagerSierraPath, compiledERC1155TransferManagerCasmPath, { marketplace: deployMarketplaceResponse, owner: account0.address })

    console.log("\n📦 Deploying TransferSelectorNFT...")
    const compiledTransferSelectorNFTCasmPath = buildPath("marketplace_TransferSelectorNFT.compiled_contract_class")
    const compiledTransferSelectorNFTSierraPath = buildPath("marketplace_TransferSelectorNFT.contract_class")
    const [deployTransferSelectorNFTResponse] = await deployContract(compiledTransferSelectorNFTSierraPath, compiledTransferSelectorNFTCasmPath, { transfer_manager_ERC721: deployTransferManagerNFTResponse, transfer_manager_ERC1155: deployERC1155TransferManagerResponse, owner: account0.address })

    console.log("\n📦 Whitelist TransferSelectorNFT...")
    await whitelistContract(marketplaceContract, "update_transfer_selector_NFT", deployTransferSelectorNFTResponse)
    console.log("✅ TransferSelectorNFT whitelisted.")

    console.log("\n📦 Set ProtocolFeeRecipient...")
    await setProtocolFeeRecipient(marketplaceContract, account0.address)
}

deploy()