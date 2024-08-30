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