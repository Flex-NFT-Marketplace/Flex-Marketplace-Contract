import { Account, hash, Contract, json, Calldata, CallData, RpcProvider, shortString } from "starknet"
import fs from 'fs'
import dotenv from 'dotenv'
import path from 'path'

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
const providerUrl = process.env.PROVIDER_URL as string
const provider = new RpcProvider({ nodeUrl: providerUrl! })

// connect your account. To adapt to your own account :
const privateKey0: string = process.env.ACCOUNT_PRIVATE as string
const account0Address: string = process.env.ACCOUNT_PUBLIC as string
const account0 = new Account(provider, account0Address!, privateKey0!)

console.log("My account here: ",account0.address)

// Utility function to parse json file
function buildPath(fileName: string) {
    const basePath = "../target/dev/"
    const sierraFilePath = path.join(__dirname, `${basePath}${fileName}.contract_class.json`)
    const casmFilePath = path.join(__dirname, `${basePath}${fileName}.compiled_contract_class.json`)
    return [sierraFilePath, casmFilePath]
}

// Utility function to deploy contracts
async function deployContract(sierraFilePath: any, casmFilePath: any, constructorArgs: any) {
    const compiledContract = json.parse(fs.readFileSync(sierraFilePath).toString("ascii"))
    const compiledCasm = json.parse(fs.readFileSync(casmFilePath).toString("ascii"))
    const callData: CallData = new CallData(compiledContract.abi)
    const constructorCalldata: Calldata = callData.compile("constructor", {...constructorArgs})

    const deployResponse = await account0.declareAndDeploy({
        contract: compiledContract,
        casm: compiledCasm,
        constructorCalldata: constructorCalldata
    })

    const contractName = compiledContract.abi[0].name.slice(0, -4)

    console.log(`✅ ${contractName} Deployed: ${deployResponse.deploy.contract_address}`)

    return [deployResponse.deploy.contract_address, compiledContract.abi]
}

// Utility function to whitelist a contract
async function whitelistContract(name: string, contract: Contract, methodName: string, args: any) {
    console.log(`\n📦 Whitelist ${name}...`)
    const contractCall = contract.populate(methodName, [args])
    const tx = await account0.execute(contractCall)
    await provider.waitForTransaction(tx.transaction_hash)
    console.log(`✅ ${name} whitelisted.`)
}

// Utility function to set protocol fee recipient
async function setProtocolFeeRecipient(contract: Contract, args: any) {
    const contractCall = contract.populate("set_protocol_fee_recipient", [args])
    const tx = await account0.execute(contractCall)
    await provider.waitForTransaction(tx.transaction_hash)
    console.log("✅ ProtocolFeeRecipient set.")
}

async function deploy() {

    console.log("🚀 Deploying with Account: " + account0Address)

    console.log("\n📦 Deploying CurrencyManager...")
    const [compiledCurrencyManagerSierraPath, compiledCurrencyManagerCasmPath] = buildPath("marketplace_CurrencyManager")


    const [deployCurrencyManagerResponse, compiledCurrencyManagerSierraAbi] = await deployContract(compiledCurrencyManagerSierraPath, compiledCurrencyManagerCasmPath, { owner: account0.address })

    const currencyManagerContract = new Contract(compiledCurrencyManagerSierraAbi, deployCurrencyManagerResponse, provider)

    currencyManagerContract.connect(account0)

    // await whitelistContract("ETH", currencyManagerContract, "add_currency", ethAddress)

    // await whitelistContract("STRK", currencyManagerContract, "add_currency", strkAddress)

    console.log("\n📦 Deploying StrategyStandardSaleForFixedPrice...")

    const [compiledStrategyStandardSaleForFixedPriceSierraPath, compiledStrategyStandardSaleForFixedPriceCasmPath] = buildPath("marketplace_StrategyStandardSaleForFixedPrice")

    const [deployStrategyStandardSaleForFixedPriceResponse] = await deployContract(compiledStrategyStandardSaleForFixedPriceSierraPath, compiledStrategyStandardSaleForFixedPriceCasmPath, { fee: 0, owner: account0.address })

    console.log("\n📦 Deploying ExecutionManager...")

    const [compiledExecutionManagerSierraPath, compiledExecutionManagerCasmPath] = buildPath("marketplace_ExecutionManager")
    const [deployExecutionManagerResponse, compiledExecutionManagerSierraAbi] = await deployContract(compiledExecutionManagerSierraPath, compiledExecutionManagerCasmPath, { owner: account0.address })

    const executionManagerContract = new Contract(compiledExecutionManagerSierraAbi, deployExecutionManagerResponse, provider)
    executionManagerContract.connect(account0);

    // await whitelistContract("StrategyStandardSaleForFixedPrice", executionManagerContract, "add_strategy", deployStrategyStandardSaleForFixedPriceResponse)

    console.log("\n📦 Deploying RoyaltyFeeRegistry...")

    const [compiledRoyaltyFeeRegistrySierraPath, compiledRoyaltyFeeRegistryCasmPath] = buildPath("marketplace_RoyaltyFeeRegistry")

    const [deployRoyaltyFeeRegistryResponse] = await deployContract(compiledRoyaltyFeeRegistrySierraPath, compiledRoyaltyFeeRegistryCasmPath, { fee_limit: 9500, owner: account0.address })

    console.log("\n📦 Deploying RoyaltyFeeManager...")

    const [compiledRoyaltyFeeManagerSierraPath, compiledRoyaltyFeeManagerCasmPath] = buildPath("marketplace_RoyaltyFeeManager")
    const [deployRoyaltyFeeManagerResponse] = await deployContract(compiledRoyaltyFeeManagerSierraPath, compiledRoyaltyFeeManagerCasmPath, { fee_registry: deployRoyaltyFeeRegistryResponse, owner: account0.address })

    console.log("\n📦 Deploying SignatureChecker2...")

    const [compiledSignatureChecker2SierraPath, compiledSignatureChecker2CasmPath] = buildPath("marketplace_SignatureChecker2")

    const [deploySignatureChecker2Response] = await deployContract(compiledSignatureChecker2SierraPath, compiledSignatureChecker2CasmPath, { owner: account0.address })

    console.log("\n📦 Deploying MarketPlace...")

    const [compiledMarketplaceSierraPath, compiledMarketplaceCasmPath] = buildPath("marketplace_MarketPlace")

    const [deployMarketplaceResponse, compiledMarketplaceSierraAbi] = await deployContract(compiledMarketplaceSierraPath, compiledMarketplaceCasmPath, {
        domain_name: "marketplace",
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

    const [compiledTransferManagerNFTSierraPath, compiledTransferManagerNFTCasmPath] = buildPath("marketplace_TransferManagerNFT")

    const [deployTransferManagerNFTResponse] = await deployContract(compiledTransferManagerNFTSierraPath, compiledTransferManagerNFTCasmPath, { marketplace: deployMarketplaceResponse, owner: account0.address })

    console.log("\n📦 Deploying TransferManagerERC1155...")

    const [compiledERC1155TransferManagerSierraPath, compiledERC1155TransferManagerCasmPath] = buildPath("marketplace_ERC1155TransferManager")

    const [deployERC1155TransferManagerResponse] = await deployContract(compiledERC1155TransferManagerSierraPath, compiledERC1155TransferManagerCasmPath, { marketplace: deployMarketplaceResponse, owner: account0.address })

    console.log("\n📦 Deploying TransferSelectorNFT...")

    const [compiledTransferSelectorNFTSierraPath, compiledTransferSelectorNFTCasmPath] = buildPath("marketplace_TransferSelectorNFT")

    const [deployTransferSelectorNFTResponse] = await deployContract(compiledTransferSelectorNFTSierraPath, compiledTransferSelectorNFTCasmPath, { transfer_manager_ERC721: deployTransferManagerNFTResponse, transfer_manager_ERC1155: deployERC1155TransferManagerResponse, owner: account0.address })

    await whitelistContract("TransferSelectorNFT", marketplaceContract, "update_transfer_selector_NFT", deployTransferSelectorNFTResponse)

    console.log("\n📦 Set ProtocolFeeRecipient...")
    await setProtocolFeeRecipient(marketplaceContract, account0.address)
}

deploy()