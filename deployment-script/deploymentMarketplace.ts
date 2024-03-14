import { Account, hash, Contract, json, Calldata, CallData, RpcProvider, shortString } from "starknet"
import fs from 'fs'
import dotenv from 'dotenv'

dotenv.config()

const ethAddress = "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7"
const strkAddress = "0x04718f5a0fc34cc1af16a1cdee98ffb20c31f5cd61d6ab07201858f4287c938d"

async function deploy() {
    // connect provider
    const provider = new RpcProvider({ nodeUrl: process.env.PROVIDER_URL as string })
    // connect your account. To adapt to your own account :
    const privateKey0: string = process.env.ACCOUNT_PRIVATE as string
    const account0Address: string = process.env.ACCOUNT_PUBLIC as string
    const account0 = new Account(provider, account0Address!, privateKey0!)
    console.log("🚀 Deploying with Account: " + account0Address)

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

    console.log("\n📦 Deploying MarketPlace...")
    const compiledMarketplaceCasm = json.parse(fs.readFileSync("../target/dev/flex_MarketPlace.compiled_contract_class.json").toString("ascii"))
    const compiledMarketplaceSierra = json.parse(fs.readFileSync("../target/dev/flex_MarketPlace.contract_class.json").toString("ascii"))
    const marketplaceCallData: CallData = new CallData(compiledMarketplaceSierra.abi)
    const marketplaceConstructor: Calldata = marketplaceCallData.compile("constructor",
        {
            domain_name: "Flex",
            domain_ver: "1",
            recipient: account0.address,
            currency: "0x51437e199770c7dc068feeb415c7d4b11fb8bd85720ef4c2af21bcfdc1a8a0e",
            execution: "0x506e8991aa19400ea8d0e2170d32253592452c31928ca4255b3f0138a42753c",
            royalty_manager: "0x15847ab0292274d7c559e25bdf73b015d92c7d5be08bb1560aa0ff9380ec86a",
            checker: "0x03b6ae6c8f0c9042398b2692c655180610cba4a58fd49bef49a8cead68bf14f5",
            owner: account0.address
        })
    const deployMarketplaceResponse = await account0.declareAndDeploy({
        contract: compiledMarketplaceSierra,
        casm: compiledMarketplaceCasm,
        constructorCalldata: marketplaceConstructor
    })
    console.log("✅ MarketPlace Deployed: ", deployMarketplaceResponse.deploy.contract_address)

    const marketplaceContract = new Contract(compiledMarketplaceSierra.abi, deployMarketplaceResponse.deploy.contract_address, provider)
    marketplaceContract.connect(account0);

    console.log("\n📦 Whitelist TransferSelectorNFT...")
    const transferSelectorCall = marketplaceContract.populate("update_transfer_selector_NFT", ["0x2397c230d7a1c5a647d026344f2f5c5c2aba80d5aa19c3dd98a5bdba4f29fad"])
    const add_transferSelector_tx = await marketplaceContract.update_transfer_selector_NFT(transferSelectorCall.calldata)
    await provider.waitForTransaction(add_transferSelector_tx.transaction_hash)
    console.log("✅ TransferSelectorNFT whitelisted.")

    console.log("\n📦 Update Marketplace of TransferManagerERC721...")
    const compiledTransferManagerNFTSierra = json.parse(fs.readFileSync("../target/dev/flex_TransferManagerNFT.contract_class.json").toString("ascii"))
    const transferManagerNFTContract = new Contract(compiledTransferManagerNFTSierra.abi, "0x374710de50333c5ad1a1ed4dc2dcf9f1e64b05155cc12282839bbed43ddee72", provider)
    transferManagerNFTContract.connect(account0);

    const updateMarketplaceCall = transferManagerNFTContract.populate("update_marketplace", [deployMarketplaceResponse.deploy.contract_address])
    const update_marketplace_tx = await transferManagerNFTContract.update_marketplace(updateMarketplaceCall.calldata)
    await provider.waitForTransaction(update_marketplace_tx.transaction_hash)
    console.log("✅ Marketplace updated.")

    // console.log("\n📦 Set ProtocolFeeRecipient...")
    // const protocolFeeRecipientCall = marketplaceContract.populate("update_protocol_fee_recipient", [account0.address])
    // const set_protocolFeeRecipient_tx = await marketplaceContract.update_protocol_fee_recipient(protocolFeeRecipientCall.calldata)
    // await provider.waitForTransaction(set_protocolFeeRecipient_tx.transaction_hash)
    // console.log("✅ ProtocolFeeRecipient set.")
}

deploy()