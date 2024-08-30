import { Account, RpcProvider, Contract, json, CallData, uint256, Call, Calldata } from 'starknet';
import fs from 'fs';
import * as dotenv from 'dotenv';
dotenv.config();

const ethAddress = "0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7"
const starkAddress = "0x0307784111703d85B35Ff9542ED0b9FB959aBBe193e12662D079715D2C1c1864"

let provider: RpcProvider;
let account: Account;