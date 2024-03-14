import { Account, hash, Contract, json, Calldata, CallData, RpcProvider, shortString } from "starknet"
import fs from 'fs'
import dotenv from 'dotenv'

dotenv.config()

const ethAddress = "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7"
const strkAddress = "0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d"

async function deploy() {
    // connect provider
    const providerUrl = process.env.PROVIDER_URL
    const provider = new RpcProvider({ nodeUrl: providerUrl! })
    // connect your account. To adapt to your own account :
    const privateKey0: string = process.env.ACCOUNT_PRIVATE as string
    const account0Address: string = process.env.ACCOUNT_PUBLIC as string
    const account0 = new Account(provider, account0Address!, privateKey0!)
    console.log("🚀 Deploying with Account: " + account0Address)

    // console.log("\n📦 Deploying CurrencyManager...")
    // const compiledCurrencyManagerCasm = json.parse(fs.readFileSync("../target/dev/flex_CurrencyManager.compiled_contract_class.json").toString("ascii"))
    // const compiledCurrencyManagerSierra = json.parse(fs.readFileSync("../target/dev/flex_CurrencyManager.contract_class.json").toString("ascii"))
    // const currencyManagerCallData: CallData = new CallData(compiledCurrencyManagerSierra.abi)
    // const currencyManagerConstructor: Calldata = currencyManagerCallData.compile("constructor", { owner: account0.address })
    // const deployCurrencyManagerResponse = await account0.declareAndDeploy({
    //     contract: compiledCurrencyManagerSierra,
    //     casm: compiledCurrencyManagerCasm,
    //     constructorCalldata: currencyManagerConstructor
    // })
    // console.log("✅ CurrencyManager Deployed: ", deployCurrencyManagerResponse.deploy.contract_address)

    // const currencyManagerContract = new Contract(compiledCurrencyManagerSierra.abi, deployCurrencyManagerResponse.deploy.contract_address, provider)
    // currencyManagerContract.connect(account0);

    // console.log("\n📦 Whitelist ETH...")
    // const roleCall = currencyManagerContract.populate("add_currency", [ethAddress])
    // const add_currency_tx = await currencyManagerContract.add_currency(roleCall.calldata)
    // await provider.waitForTransaction(add_currency_tx.transaction_hash)
    // console.log("✅ ETH whitelisted.")

    // // console.log("\n📦 Whitelist STRK...")
    // // const roleCall2 = currencyManagerContract.populate("add_currency", [strkAddress])
    // // const add_currency_tx2 = await currencyManagerContract.add_currency(roleCall2.calldata)
    // // await provider.waitForTransaction(add_currency_tx2.transaction_hash)
    // // console.log("✅ STRK whitelisted.")

    // console.log("\n📦 Deploying StrategyStandardSaleForFixedPrice...")
    // const compiledStrategyStandardSaleForFixedPriceCasm = json.parse(fs.readFileSync("../target/dev/flex_StrategyStandardSaleForFixedPrice.compiled_contract_class.json").toString("ascii"))
    // const compiledStrategyStandardSaleForFixedPriceSierra = json.parse(fs.readFileSync("../target/dev/flex_StrategyStandardSaleForFixedPrice.contract_class.json").toString("ascii"))
    // const strategyStandardSaleForFixedPriceCallData: CallData = new CallData(compiledStrategyStandardSaleForFixedPriceSierra.abi)
    // const strategyStandardSaleForFixedPriceConstructor: Calldata = strategyStandardSaleForFixedPriceCallData.compile("constructor", { fee: 0, owner: account0.address })
    // const deployStrategyStandardSaleForFixedPriceResponse = await account0.declareAndDeploy({
    //     contract: compiledStrategyStandardSaleForFixedPriceSierra,
    //     casm: compiledStrategyStandardSaleForFixedPriceCasm,
    //     constructorCalldata: strategyStandardSaleForFixedPriceConstructor
    // })
    // console.log("✅ StrategyStandardSaleForFixedPrice Deployed: ", deployStrategyStandardSaleForFixedPriceResponse.deploy.contract_address)

    // console.log("\n📦 Deploying ExecutionManager...")
    // const compiledExecutionManagerCasm = json.parse(fs.readFileSync("../target/dev/flex_ExecutionManager.compiled_contract_class.json").toString("ascii"))
    // const compiledExecutionManagerSierra = json.parse(fs.readFileSync("../target/dev/flex_ExecutionManager.contract_class.json").toString("ascii"))
    // const executionManagerCallData: CallData = new CallData(compiledExecutionManagerSierra.abi)
    // const executionManagerConstructor: Calldata = executionManagerCallData.compile("constructor", { owner: account0.address })
    // const deployExecutionManagerResponse = await account0.declareAndDeploy({
    //     contract: compiledExecutionManagerSierra,
    //     casm: compiledExecutionManagerCasm,
    //     constructorCalldata: executionManagerConstructor
    // })
    // console.log("✅ ExecutionManager Deployed: ", deployExecutionManagerResponse.deploy.contract_address)

    // const executionManagerContract = new Contract(compiledExecutionManagerSierra.abi, deployExecutionManagerResponse.deploy.contract_address, provider)
    // executionManagerContract.connect(account0);

    // console.log("\n📦 Whitelist StrategyStandardSaleForFixedPrice...")
    // const strategyCall = executionManagerContract.populate("add_strategy", [deployStrategyStandardSaleForFixedPriceResponse.deploy.contract_address])
    // const add_strategy_tx = await executionManagerContract.add_strategy(strategyCall.calldata)
    // await provider.waitForTransaction(add_strategy_tx.transaction_hash)
    // console.log("✅ StrategyStandardSaleForFixedPrice whitelisted.")

    // console.log("\n📦 Deploying RoyaltyFeeRegistry...")
    // const compiledRoyaltyFeeRegistryCasm = json.parse(fs.readFileSync("../target/dev/flex_RoyaltyFeeRegistry.compiled_contract_class.json").toString("ascii"))
    // const compiledRoyaltyFeeRegistrySierra = json.parse(fs.readFileSync("../target/dev/flex_RoyaltyFeeRegistry.contract_class.json").toString("ascii"))
    // const royaltyFeeRegistryCallData: CallData = new CallData(compiledRoyaltyFeeRegistrySierra.abi)
    // const royaltyFeeRegistryConstructor: Calldata = royaltyFeeRegistryCallData.compile("constructor", { fee_limit: 9500, owner: account0.address })
    // const deployRoyaltyFeeRegistryResponse = await account0.declareAndDeploy({
    //     contract: compiledRoyaltyFeeRegistrySierra,
    //     casm: compiledRoyaltyFeeRegistryCasm,
    //     constructorCalldata: royaltyFeeRegistryConstructor
    // })
    // console.log("✅ RoyaltyFeeRegistry Deployed: ", deployRoyaltyFeeRegistryResponse.deploy.contract_address)

    // console.log("\n📦 Deploying RoyaltyFeeManager...")
    // const compiledRoyaltyFeeManagerCasm = json.parse(fs.readFileSync("../target/dev/flex_RoyaltyFeeManager.compiled_contract_class.json").toString("ascii"))
    // const compiledRoyaltyFeeManagerSierra = json.parse(fs.readFileSync("../target/dev/flex_RoyaltyFeeManager.contract_class.json").toString("ascii"))
    // const royaltyFeeManagerCallData: CallData = new CallData(compiledRoyaltyFeeManagerSierra.abi)
    // const royaltyFeeManagerConstructor: Calldata = royaltyFeeManagerCallData.compile("constructor", { fee_registry: deployRoyaltyFeeRegistryResponse.deploy.contract_address, owner: account0.address })
    // const deployRoyaltyFeeManagerResponse = await account0.declareAndDeploy({
    //     contract: compiledRoyaltyFeeManagerSierra,
    //     casm: compiledRoyaltyFeeManagerCasm,
    //     constructorCalldata: royaltyFeeManagerConstructor
    // })
    // console.log("✅ RoyaltyFeeManager Deployed: ", deployRoyaltyFeeManagerResponse.deploy.contract_address)

    // console.log("\n📦 Deploying SignatureChecker2...")
    // const compiledSignatureChecker2Casm = json.parse(fs.readFileSync("../target/dev/flex_SignatureChecker2.compiled_contract_class.json").toString("ascii"))
    // const compiledSignatureChecker2Sierra = json.parse(fs.readFileSync("../target/dev/flex_SignatureChecker2.contract_class.json").toString("ascii"))
    // const signatureChecker2CallData: CallData = new CallData(compiledSignatureChecker2Sierra.abi)
    // const signatureChecker2Constructor: Calldata = signatureChecker2CallData.compile("constructor", {})
    // const deploySignatureChecker2Response = await account0.declareAndDeploy({
    //     contract: compiledSignatureChecker2Sierra,
    //     casm: compiledSignatureChecker2Casm,
    //     constructorCalldata: signatureChecker2Constructor
    // })
    // console.log("✅ SignatureChecker2 Deployed: ", deploySignatureChecker2Response.deploy.contract_address)

    // console.log("\n📦 Deploying MarketPlace...")
    // const compiledMarketplaceCasm = json.parse(fs.readFileSync("../target/dev/flex_MarketPlace.compiled_contract_class.json").toString("ascii"))
    // const compiledMarketplaceSierra = json.parse(fs.readFileSync("../target/dev/flex_MarketPlace.contract_class.json").toString("ascii"))
    // const marketplaceCallData: CallData = new CallData(compiledMarketplaceSierra.abi)
    // const marketplaceConstructor: Calldata = marketplaceCallData.compile("constructor", {
    //     domain_name: "Flex",
    //     domain_ver: "1",
    //     recipient: account0.address,
    //     currency: deployCurrencyManagerResponse.deploy.contract_address,
    //     execution: deployExecutionManagerResponse.deploy.contract_address,
    //     royalty_manager: deployRoyaltyFeeManagerResponse.deploy.contract_address,
    //     checker: deploySignatureChecker2Response.deploy.contract_address,
    //     owner: account0.address
    // })
    // const deployMarketplaceResponse = await account0.declareAndDeploy({
    //     contract: compiledMarketplaceSierra,
    //     casm: compiledMarketplaceCasm,
    //     constructorCalldata: marketplaceConstructor
    // })
    // console.log("✅ MarketPlace Deployed: ", deployMarketplaceResponse.deploy.contract_address)

    console.log("\n📦 Deploying MarketPlace...")
    const compiledMarketplaceCasm = json.parse(fs.readFileSync("../target/dev/flex_MarketPlace.compiled_contract_class.json").toString("ascii"))
    const compiledMarketplaceSierra = json.parse(fs.readFileSync("../target/dev/flex_MarketPlace.contract_class.json").toString("ascii"))
    const marketplaceCallData: CallData = new CallData(compiledMarketplaceSierra.abi)
    const marketplaceConstructor: Calldata = marketplaceCallData.compile("constructor", {
        domain_name: "Flex",
        domain_ver: "1",
        recipient: account0.address,
        currency: "0x0",
        execution: "0x0",
        royalty_manager: "0x0",
        checker: "0x0",
        owner: account0.address
    })
    const deployMarketplaceResponse = await account0.declareAndDeploy({
        contract: compiledMarketplaceSierra,
        casm: compiledMarketplaceCasm,
        constructorCalldata: marketplaceConstructor
    })
    console.log("✅ MarketPlace Deployed: ", deployMarketplaceResponse.deploy.contract_address)

    // const marketplaceContract = new Contract(compiledMarketplaceSierra.abi, deployMarketplaceResponse.deploy.contract_address, provider)
    // marketplaceContract.connect(account0);

    // console.log("\n📦 Deploying TransferManagerERC721...")
    // const compiledTransferManagerNFTCasm = json.parse(fs.readFileSync("../target/dev/flex_TransferManagerNFT.compiled_contract_class.json").toString("ascii"))
    // const compiledTransferManagerNFTSierra = json.parse(fs.readFileSync("../target/dev/flex_TransferManagerNFT.contract_class.json").toString("ascii"))
    // const transferManagerNFTCallData: CallData = new CallData(compiledTransferManagerNFTSierra.abi)
    // const transferManagerNFTConstructor: Calldata = transferManagerNFTCallData.compile("constructor", { marketplace: deployMarketplaceResponse.deploy.contract_address, owner: account0.address })
    // const deployTransferManagerNFTResponse = await account0.declareAndDeploy({
    //     contract: compiledTransferManagerNFTSierra,
    //     casm: compiledTransferManagerNFTCasm,
    //     constructorCalldata: transferManagerNFTConstructor
    // })
    // console.log("✅ TransferManagerERC721 Deployed: ", deployTransferManagerNFTResponse.deploy.contract_address)

    // console.log("\n📦 Deploying TransferManagerERC1155...")
    // const compiledERC1155TransferManagerCasm = json.parse(fs.readFileSync("../target/dev/flex_ERC1155TransferManager.compiled_contract_class.json").toString("ascii"))
    // const compiledERC1155TransferManagerSierra = json.parse(fs.readFileSync("../target/dev/flex_ERC1155TransferManager.contract_class.json").toString("ascii"))
    // const ERC1155TransferManagerCallData: CallData = new CallData(compiledERC1155TransferManagerSierra.abi)
    // const ERC1155TransferManagerConstructor: Calldata = ERC1155TransferManagerCallData.compile("constructor", { marketplace: deployMarketplaceResponse.deploy.contract_address, owner: account0.address })
    // const deployERC1155TransferManagerResponse = await account0.declareAndDeploy({
    //     contract: compiledERC1155TransferManagerSierra,
    //     casm: compiledERC1155TransferManagerCasm,
    //     constructorCalldata: ERC1155TransferManagerConstructor
    // })
    // console.log("✅ ERC1155TransferManager Deployed: ", deployERC1155TransferManagerResponse.deploy.contract_address)

    // console.log("\n📦 Deploying TransferSelectorNFT...")
    // const compiledTransferSelectorNFTCasm = json.parse(fs.readFileSync("../target/dev/flex_TransferSelectorNFT.compiled_contract_class.json").toString("ascii"))
    // const compiledTransferSelectorNFTSierra = json.parse(fs.readFileSync("../target/dev/flex_TransferSelectorNFT.contract_class.json").toString("ascii"))
    // const transferSelectorNFTCallData: CallData = new CallData(compiledTransferSelectorNFTSierra.abi)
    // const transferSelectorNFTConstructor: Calldata = transferSelectorNFTCallData.compile("constructor", { transfer_manager_ERC721: deployTransferManagerNFTResponse.deploy.contract_address, transfer_manager_ERC1155: deployERC1155TransferManagerResponse.deploy.contract_address, owner: account0.address })
    // const deployTransferSelectorNFTResponse = await account0.declareAndDeploy({
    //     contract: compiledTransferSelectorNFTSierra,
    //     casm: compiledTransferSelectorNFTCasm,
    //     constructorCalldata: transferSelectorNFTConstructor
    // })
    // console.log("✅ TransferSelectorNFT Deployed: ", deployTransferSelectorNFTResponse.deploy.contract_address)

    // console.log("\n📦 Whitelist TransferSelectorNFT...")
    // const transferSelectorCall = marketplaceContract.populate("update_transfer_selector_NFT", [deployTransferSelectorNFTResponse.deploy.contract_address])
    // const add_transferSelector_tx = await marketplaceContract.update_transfer_selector_NFT(transferSelectorCall.calldata)
    // await provider.waitForTransaction(add_transferSelector_tx.transaction_hash)
    // console.log("✅ TransferSelectorNFT whitelisted.")

    // console.log("\n📦 Set ProtocolFeeRecipient...")
    // const protocolFeeRecipientCall = marketplaceContract.populate("update_protocol_fee_recipient", [account0.address])
    // const set_protocolFeeRecipient_tx = await marketplaceContract.update_protocol_fee_recipient(protocolFeeRecipientCall.calldata)
    // await provider.waitForTransaction(set_protocolFeeRecipient_tx.transaction_hash)
    // console.log("✅ ProtocolFeeRecipient set.")
}

deploy()