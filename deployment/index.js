const {
  Account,
  hash,
  Contract,
  json,
  Calldata,
  CallData,
  RpcProvider,
  shortString,
  eth,
} = require('starknet');
const fs = require('fs');

const ethAddress =
  '0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7';

const RPC = 'https://starknet-sepolia.public.blastapi.io/rpc/v0_7';
const provider = new RpcProvider({ nodeUrl: RPC });

const PRIVATE_KEY =
  '0x066b7a9451c9c95a14343d4b98b5ece5f8fd4aa671a73494bf6f38ee0a9598f2';
const ACCOUNT_ADDRESS =
  '0x070B17dd4ca449Ad789839ebA91B74Ebbd9A0217960161E120f8Ce3f39E08bfD';

const ETH_ADDRESS =
  '0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7';

const account = new Account(provider, ACCOUNT_ADDRESS, PRIVATE_KEY);

async function deployCurrencyManager() {
  console.log('🚀 Deploying with Account: ' + account.address);

  const compiledContractCasm = json.parse(
    fs
      .readFileSync(
        '../target/dev/flex_CurrencyManager.compiled_contract_class.json'
      )
      .toString('ascii')
  );
  const compiledContractSierra = json.parse(
    fs
      .readFileSync('../target/dev/flex_CurrencyManager.contract_class.json')
      .toString('ascii')
  );

  const contractCallData = new CallData(compiledContractSierra.abi);
  const contractConstructor = contractCallData.compile('constructor', {
    owner: account.address,
  });

  const deployCurrencyManagerResponse = await account.declareAndDeploy({
    contract: compiledContractSierra,
    casm: compiledContractCasm,
    constructorCalldata: contractConstructor,
  });
  console.log(
    '✅ CurrencyManager Deployed: ',
    deployCurrencyManagerResponse.deploy.contract_address
  );
} // 0x7e62ef3e98ab77fc0634aff9d208c0c658b15127cc4b5a0b180b89b2cdf7ab0

async function deployExecutionManager() {
  console.log('🚀 Deploying with Account: ' + account.address);

  const compiledContractCasm = json.parse(
    fs
      .readFileSync(
        '../target/dev/flex_ExecutionManager.compiled_contract_class.json'
      )
      .toString('ascii')
  );
  const compiledContractSierra = json.parse(
    fs
      .readFileSync('../target/dev/flex_ExecutionManager.contract_class.json')
      .toString('ascii')
  );

  const contractCallData = new CallData(compiledContractSierra.abi);
  const contractConstructor = contractCallData.compile('constructor', {
    owner: account.address,
  });

  const deployExecutionManagerResponse = await account.declareAndDeploy({
    contract: compiledContractSierra,
    casm: compiledContractCasm,
    constructorCalldata: contractConstructor,
  });
  console.log(
    '✅ ExecutionManager Deployed: ',
    deployExecutionManagerResponse.deploy.contract_address
  );
} // 0x4e23fc3548b691836fcb55ff7566f1f3f6b0fc84e0aff4c67e236a840842391

async function deployRoyaltyRegistry() {
  console.log('🚀 Deploying with Account: ' + account.address);

  const compiledContractCasm = json.parse(
    fs
      .readFileSync(
        '../target/dev/flex_RoyaltyFeeRegistry.compiled_contract_class.json'
      )
      .toString('ascii')
  );
  const compiledContractSierra = json.parse(
    fs
      .readFileSync('../target/dev/flex_RoyaltyFeeRegistry.contract_class.json')
      .toString('ascii')
  );

  const contractCallData = new CallData(compiledContractSierra.abi);
  const contractConstructor = contractCallData.compile('constructor', {
    fee_limit: 500,
    owner: account.address,
  });

  const deployExecutionManagerResponse = await account.declareAndDeploy({
    contract: compiledContractSierra,
    casm: compiledContractCasm,
    constructorCalldata: contractConstructor,
  });
  console.log(
    '✅ RoyaltyRegistry Deployed: ',
    deployExecutionManagerResponse.deploy.contract_address
  );
} // 0x928e33b4ce3576f2d370d978d76ab4bb746d3c27772d5f0e238da1f64121cc

async function deployRoyaltyManager() {
  console.log('🚀 Deploying with Account: ' + account.address);

  const compiledContractCasm = json.parse(
    fs
      .readFileSync(
        '../target/dev/flex_RoyaltyFeeManager.compiled_contract_class.json'
      )
      .toString('ascii')
  );
  const compiledContractSierra = json.parse(
    fs
      .readFileSync('../target/dev/flex_RoyaltyFeeManager.contract_class.json')
      .toString('ascii')
  );

  const contractCallData = new CallData(compiledContractSierra.abi);
  const contractConstructor = contractCallData.compile('constructor', {
    fee_registry:
      '0x928e33b4ce3576f2d370d978d76ab4bb746d3c27772d5f0e238da1f64121cc',
    owner: account.address,
  });

  const deployContractResponse = await account.declareAndDeploy({
    contract: compiledContractSierra,
    casm: compiledContractCasm,
    constructorCalldata: contractConstructor,
  });
  console.log(
    '✅ RoyaltyManager Deployed: ',
    deployContractResponse.deploy.contract_address
  );
} // 0x1901b811ad20d3428bef269874d1eaad4ded11fe5f0deb9fb887eed309ff63d

async function deploySignatureChecker() {
  console.log('🚀 Deploying with Account: ' + account.address);

  const compiledContractCasm = json.parse(
    fs
      .readFileSync(
        '../target/dev/flex_SignatureChecker2.compiled_contract_class.json'
      )
      .toString('ascii')
  );
  const compiledContractSierra = json.parse(
    fs
      .readFileSync('../target/dev/flex_SignatureChecker2.contract_class.json')
      .toString('ascii')
  );

  const deployContractResponse = await account.declareAndDeploy({
    contract: compiledContractSierra,
    casm: compiledContractCasm,
  });

  console.log(
    '✅ SignatureChecker Deployed: ',
    deployContractResponse.deploy.contract_address
  );
} // 0x7b273d41ecdaa4dd96f72835f6c84a4064703e05729d9110518c37506499717

async function deployStrategySaleForFixPrice() {
  console.log('🚀 Deploying with Account: ' + account.address);

  const compiledContractCasm = json.parse(
    fs
      .readFileSync(
        '../target/dev/flex_StrategyStandardSaleForFixedPrice.compiled_contract_class.json'
      )
      .toString('ascii')
  );
  const compiledContractSierra = json.parse(
    fs
      .readFileSync(
        '../target/dev/flex_StrategyStandardSaleForFixedPrice.contract_class.json'
      )
      .toString('ascii')
  );

  const contractCallData = new CallData(compiledContractSierra.abi);
  const contractConstructor = contractCallData.compile('constructor', {
    fee: 200,
    owner: account.address,
  });

  const deployExecutionManagerResponse = await account.declareAndDeploy({
    contract: compiledContractSierra,
    casm: compiledContractCasm,
    constructorCalldata: contractConstructor,
  });
  console.log(
    '✅ StrategyStandardSaleForFixedPrice Deployed: ',
    deployExecutionManagerResponse.deploy.contract_address
  );
} // 0x734e0c06969c247594d8e07d778a36b5219fb0b2510af5fb23e8234e3ed7a78

async function deployFlexDrop() {
  console.log('🚀 Deploying with Account: ' + account.address);

  const compiledContractCasm = json.parse(
    fs
      .readFileSync(
        '../flex_marketplace/target/dev/flex_FlexDrop.compiled_contract_class.json'
      )
      .toString('ascii')
  );
  const compiledContractSierra = json.parse(
    fs
      .readFileSync(
        '../flex_marketplace/target/dev/flex_FlexDrop.contract_class.json'
      )
      .toString('ascii')
  );

  const contractCallData = new CallData(compiledContractSierra.abi);
  const contractConstructor = contractCallData.compile('constructor', {
    owner: account.address,
    currency_manager:
      '0x46e3093c6e03847f77c8fdfb1f47e76fa38ddeecf9dd8cfb89c7e0a7f6decc3',
    fee_bps: 1000,
  });

  const deployContractResponse = await account.declareAndDeploy({
    contract: compiledContractSierra,
    casm: compiledContractCasm,
    constructorCalldata: contractConstructor,
  });
  console.log(
    '✅ CurrencyManager Deployed: ',
    deployContractResponse.deploy.contract_address
  );
} // 0x49e94b002a114dc5506d172c0a9872099fe6cab608ed844993aafe382a78f9a

async function deployNonFungibleFlexDropToken() {
  console.log('🚀 Deploying with Account: ' + account.address);

  const compiledContractCasm = json.parse(
    fs
      .readFileSync(
        '../flex_marketplace/target/dev/flex_flex_marketplace_openedition_ERC721_open_edition_ERC721.compiled_contract_class.json'
      )
      .toString('ascii')
  );
  const compiledContractSierra = json.parse(
    fs
      .readFileSync(
        '../flex_marketplace/target/dev/flex_flex_marketplace_openedition_ERC721_open_edition_ERC721.contract_class.json'
      )
      .toString('ascii')
  );

  const contractCallData = new CallData(compiledContractSierra.abi);
  const contractConstructor = contractCallData.compile('constructor', {
    owner: account.address,
    name: 'Brian',
    symbol: 'BRN',
    token_base_uri: '0x0',
    allowed_flex_drop: [
      '0x49e94b002a114dc5506d172c0a9872099fe6cab608ed844993aafe382a78f9a',
    ],
  });

  const deployContractResponse = await account.declareAndDeploy({
    contract: compiledContractSierra,
    casm: compiledContractCasm,
    constructorCalldata: contractConstructor,
  });
  console.log(
    '✅ CurrencyManager Deployed: ',
    deployContractResponse.deploy.contract_address
  );
} // 0x1226f18d9ae9c1959c02f790da10c33028ba2048266a760aeceac6ad4ed2608

async function deployMarketplace() {
  console.log('🚀 Deploying with Account: ' + account.address);

  const compiledContractCasm = json.parse(
    fs
      .readFileSync(
        '../target/dev/flex_MarketPlace.compiled_contract_class.json'
      )
      .toString('ascii')
  );
  const compiledContractSierra = json.parse(
    fs
      .readFileSync('../target/dev/flex_MarketPlace.contract_class.json')
      .toString('ascii')
  );

  const contractCallData = new CallData(compiledContractSierra.abi);
  const contractConstructor = contractCallData.compile('constructor', {
    domain_name: 'Flex',
    domain_ver: '1',
    recipient: ACCOUNT_ADDRESS,
    currency:
      '0x7e62ef3e98ab77fc0634aff9d208c0c658b15127cc4b5a0b180b89b2cdf7ab0',
    execution:
      '0x4e23fc3548b691836fcb55ff7566f1f3f6b0fc84e0aff4c67e236a840842391',
    royalty_manager:
      '0x1901b811ad20d3428bef269874d1eaad4ded11fe5f0deb9fb887eed309ff63d',
    checker:
      '0x7b273d41ecdaa4dd96f72835f6c84a4064703e05729d9110518c37506499717',
    owner: account.address,
  });

  const deployContractResponse = await account.declareAndDeploy({
    contract: compiledContractSierra,
    casm: compiledContractCasm,
    constructorCalldata: contractConstructor,
  });
  console.log(
    '✅ MarketplaceContract Deployed: ',
    deployContractResponse.deploy.contract_address
  );
} // 0x499f67cb362b9366d2859fa766395a19e57ea05fb49efe269dcb80480500cc7

async function deployTransferManagerERC721() {
  console.log('🚀 Deploying with Account: ' + account.address);

  const compiledContractCasm = json.parse(
    fs
      .readFileSync(
        '../target/dev/flex_TransferManagerNFT.compiled_contract_class.json'
      )
      .toString('ascii')
  );
  const compiledContractSierra = json.parse(
    fs
      .readFileSync('../target/dev/flex_TransferManagerNFT.contract_class.json')
      .toString('ascii')
  );

  const contractCallData = new CallData(compiledContractSierra.abi);
  const contractConstructor = contractCallData.compile('constructor', {
    marketplace:
      '0x499f67cb362b9366d2859fa766395a19e57ea05fb49efe269dcb80480500cc7',
    owner: account.address,
  });

  const deployExecutionManagerResponse = await account.declareAndDeploy({
    contract: compiledContractSierra,
    casm: compiledContractCasm,
    constructorCalldata: contractConstructor,
  });
  console.log(
    '✅ TransferManagerERC721 Deployed: ',
    deployExecutionManagerResponse.deploy.contract_address
  );
} // 0x3fa016190d64446b24fc4704b2b48f01e4eed70d1dae4ba1d59dec0b7b47861

async function deployTransferManagerERC1155() {
  console.log('🚀 Deploying with Account: ' + account.address);

  const compiledContractCasm = json.parse(
    fs
      .readFileSync(
        '../target/dev/flex_ERC1155TransferManager.compiled_contract_class.json'
      )
      .toString('ascii')
  );
  const compiledContractSierra = json.parse(
    fs
      .readFileSync(
        '../target/dev/flex_ERC1155TransferManager.contract_class.json'
      )
      .toString('ascii')
  );

  const deployExecutionManagerResponse = await account.declareAndDeploy({
    contract: compiledContractSierra,
    casm: compiledContractCasm,
  });
  console.log(
    '✅ TransferManagerERC1155 Deployed: ',
    deployExecutionManagerResponse.deploy.contract_address
  );
} // 0x114539e3af2192698a6ed3cb9158447c2a81c8cf4b8d29c0950ca2de26be795

async function deployTransferSelectorNFT() {
  console.log('🚀 Deploying with Account: ' + account.address);

  const compiledContractCasm = json.parse(
    fs
      .readFileSync(
        '../target/dev/flex_TransferSelectorNFT.compiled_contract_class.json'
      )
      .toString('ascii')
  );
  const compiledContractSierra = json.parse(
    fs
      .readFileSync(
        '../target/dev/flex_TransferSelectorNFT.contract_class.json'
      )
      .toString('ascii')
  );

  const deployExecutionManagerResponse = await account.declareAndDeploy({
    contract: compiledContractSierra,
    casm: compiledContractCasm,
  });
  console.log(
    '✅ TransferSelectorNFT Deployed: ',
    deployExecutionManagerResponse.deploy.contract_address
  );
} //0x460cefd38c83dfe2afe9e7a17879d6c442198a393984a19cfed9bb6862f5323

async function interactNFT() {
  const compiledContractSierra = json.parse(
    fs
      .readFileSync(
        '../flex_marketplace/target/dev/flex_flex_marketplace_openedition_ERC721_open_edition_ERC721.contract_class.json'
      )
      .toString('ascii')
  );

  const NFTContract = new Contract(
    compiledContractSierra.abi,
    '0x1226f18d9ae9c1959c02f790da10c33028ba2048266a760aeceac6ad4ed2608',
    provider
  );

  NFTContract.connect(account);
  const rollCall = NFTContract.populate('multi_configure', [
    {
      max_supply: 0,
      base_uri: '0x0',
      contract_uri: '0x0',
      flex_drop:
        '0x49e94b002a114dc5506d172c0a9872099fe6cab608ed844993aafe382a78f9a',
      public_drop: {
        mint_price: '10000000000000000',
        start_time: 1710399596,
        end_time: 1710405596,
        max_mint_per_wallet: 10,
        restrict_fee_recipients: true,
      },
      creator_payout_address: account.address,
      allowed_fee_recipients: [
        '0x03B3793b6Da7d28187320FD920b0ACAC4cF2Db41162B5d61e285d3E54aE6ff07',
      ],
      disallowed_fee_recipients: [],
      allowed_payers: [],
      disallowed_payers: [],
    },
  ]);

  const res = await NFTContract.multi_configure(rollCall.calldata);
  await provider.waitForTransaction(res.transaction_hash);
  console.log(res);
}

async function approveETH() {
  const { abi: ethAbi } = await account.getClassAt(ETH_ADDRESS);

  const ETHContract = new Contract(ethAbi, ETH_ADDRESS, provider);
  ETHContract.connect(account);

  const rollCall = ETHContract.populate('approve', [
    '0x49e94b002a114dc5506d172c0a9872099fe6cab608ed844993aafe382a78f9a',
    '1000000000000000000',
  ]);

  const res = await ETHContract.approve(rollCall.calldata);
  await provider.waitForTransaction(res.transaction_hash);
  console.log(res);
}

async function buyPublicSale() {
  const compiledContractSierra = json.parse(
    fs
      .readFileSync(
        '../flex_marketplace/target/dev/flex_FlexDrop.contract_class.json'
      )
      .toString('ascii')
  );

  const FlexDropContract = new Contract(
    compiledContractSierra.abi,
    '0x49e94b002a114dc5506d172c0a9872099fe6cab608ed844993aafe382a78f9a',
    provider
  );

  FlexDropContract.connect(account);
  const rollCall = FlexDropContract.populate('mint_public', [
    '0x1226f18d9ae9c1959c02f790da10c33028ba2048266a760aeceac6ad4ed2608',
    '0x03B3793b6Da7d28187320FD920b0ACAC4cF2Db41162B5d61e285d3E54aE6ff07',
    '0x0',
    1,
    ETH_ADDRESS,
  ]);

  const res = await FlexDropContract.mint_public(rollCall.calldata);
  await provider.waitForTransaction(res.transaction_hash);
  console.log(res);
}

deployTransferManagerERC1155();
