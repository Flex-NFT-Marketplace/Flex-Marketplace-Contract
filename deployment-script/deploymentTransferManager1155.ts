import { Account, hash, Contract, json, Calldata, CallData, RpcProvider, shortString } from "starknet"
import fs from 'fs'
import dotenv from 'dotenv'

dotenv.config()

const ethAddress = "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7"
const strkAddress = "0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d"
const marketplaceAddress = "0x1ad73c66d2f526e8ffed6db27652b658c0351f58c355e33a4c784a977caec4"
const transferSelectorAddress = "0x6ff00cf55c7a0bb534aa6f4f78fbd7923168c60b3f9b80df7f9c7ffd8a007e"

async function deploy() {
    // connect provider
    const providerUrl = process.env.PROVIDER_URL
    console.log("providerUrl", providerUrl);
    const provider = new RpcProvider({ nodeUrl: providerUrl! })
    // connect your account. To adapt to your own account :
    const privateKey0 = process.env.ACCOUNT_PRIVATE
    console.log("privateKey0", privateKey0);
    const account0Address = process.env.ACCOUNT_PUBLIC
    console.log("account0Address", account0Address);
    const account0 = new Account(provider, account0Address!, privateKey0!)
    console.log("🚀 Deploying with Account: " + account0Address)

    const compiledMarketplaceSierra = json.parse(fs.readFileSync("../target/dev/flex_MarketPlace.contract_class.json").toString("ascii"))
    const marketplaceContract = new Contract(compiledMarketplaceSierra.abi, marketplaceAddress, provider)
    marketplaceContract.connect(account0);

    console.log("\n📦 Deploying TransferManagerERC1155...")
    const compiledERC1155TransferManagerCasm = json.parse(fs.readFileSync("../target/dev/flex_ERC1155TransferManager.compiled_contract_class.json").toString("ascii"))
    const compiledERC1155TransferManagerSierra = json.parse(fs.readFileSync("../target/dev/flex_ERC1155TransferManager.contract_class.json").toString("ascii"))
    const ERC1155TransferManagerCallData: CallData = new CallData(compiledERC1155TransferManagerSierra.abi)
    const ERC1155TransferManagerConstructor: Calldata = ERC1155TransferManagerCallData.compile("constructor", { marketplace: marketplaceAddress, owner: account0.address })
    const deployERC1155TransferManagerResponse = await account0.declareAndDeploy({
        contract: compiledERC1155TransferManagerSierra,
        casm: compiledERC1155TransferManagerCasm,
        constructorCalldata: ERC1155TransferManagerConstructor
    })
    console.log("✅ ERC1155TransferManager Deployed: ", deployERC1155TransferManagerResponse.deploy.contract_address)
    // const deployERC1155TransferManagerResponse = await account0.estimateDeclareFee({
    //     contract: compiledERC1155TransferManagerSierra,
    //     casm: compiledERC1155TransferManagerCasm
    // })
    // console.log("✅ ERC1155TransferManager Deployed: ", deployERC1155TransferManagerResponse)

    const compiledTransferSelectorNFTSierra = json.parse(fs.readFileSync("../target/dev/flex_TransferSelectorNFT.contract_class.json").toString("ascii"))
    const transferSelectorNFTContract = new Contract(compiledTransferSelectorNFTSierra.abi, transferSelectorAddress, provider)
    transferSelectorNFTContract.connect(account0);

    console.log("\n📦 update_TRANSFER_MANAGER_ERC1155 in TransferSelectorNFT...")
    const transferSelectorCall = transferSelectorNFTContract.populate("update_TRANSFER_MANAGER_ERC1155", [deployERC1155TransferManagerResponse.deploy.contract_address])
    const add_transferSelector_tx = await transferSelectorNFTContract.update_TRANSFER_MANAGER_ERC1155(transferSelectorCall.calldata)
    await provider.waitForTransaction(add_transferSelector_tx.transaction_hash)
    console.log("✅ Updated TRANSFER_MANAGER_ERC1155 in TransferSelectorNFT")
}

deploy()