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

    console.log("\n📦 Deploying RoyaltyFeeManager...")
    const compiledRoyaltyFeeManagerCasm = json.parse(fs.readFileSync("../target/dev/flex_RoyaltyFeeManager.compiled_contract_class.json").toString("ascii"))
    const compiledRoyaltyFeeManagerSierra = json.parse(fs.readFileSync("../target/dev/flex_RoyaltyFeeManager.contract_class.json").toString("ascii"))
    const royaltyFeeManagerCallData: CallData = new CallData(compiledRoyaltyFeeManagerSierra.abi)
    const royaltyFeeManagerConstructor: Calldata = royaltyFeeManagerCallData.compile("constructor", { fee_registry: "0x112eb334d8e3f06b3d55909c1b642cb6e077f191e37ddc789ab335302e42e7d", owner: account0.address })
    const deployRoyaltyFeeManagerResponse = await account0.declareAndDeploy({
        contract: compiledRoyaltyFeeManagerSierra,
        casm: compiledRoyaltyFeeManagerCasm,
        constructorCalldata: royaltyFeeManagerConstructor
    })
    console.log("✅ RoyaltyFeeManager Deployed: ", deployRoyaltyFeeManagerResponse.deploy.contract_address)
}

deploy()