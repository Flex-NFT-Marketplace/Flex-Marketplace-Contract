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

    console.log("\n📦 Deploying SignatureChecker2...")
    const compiledSignatureChecker2Casm = json.parse(fs.readFileSync("../target/dev/flex_SignatureChecker2.compiled_contract_class.json").toString("ascii"))
    const compiledSignatureChecker2Sierra = json.parse(fs.readFileSync("../target/dev/flex_SignatureChecker2.contract_class.json").toString("ascii"))
    const signatureChecker2CallData: CallData = new CallData(compiledSignatureChecker2Sierra.abi)
    const signatureChecker2Constructor: Calldata = signatureChecker2CallData.compile("constructor", {})
    const deploySignatureChecker2Response = await account0.declareAndDeploy({
        contract: compiledSignatureChecker2Sierra,
        casm: compiledSignatureChecker2Casm,
        constructorCalldata: signatureChecker2Constructor
    })
    console.log("✅ SignatureChecker2 Deployed: ", deploySignatureChecker2Response.deploy.contract_address)
}

deploy()