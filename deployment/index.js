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

  const compiledCurrencyManagerCasm = json.parse(
    fs
      .readFileSync(
        '../flex_marketplace/target/dev/flex_CurrencyManager.compiled_contract_class.json'
      )
      .toString('ascii')
  );
  const compiledCurrencyManagerSierra = json.parse(
    fs
      .readFileSync(
        '../flex_marketplace/target/dev/flex_CurrencyManager.contract_class.json'
      )
      .toString('ascii')
  );

  const deployCurrencyManagerResponse = await account.declareAndDeploy({
    contract: compiledCurrencyManagerSierra,
    casm: compiledCurrencyManagerCasm,
  });
  console.log(
    '✅ CurrencyManager Deployed: ',
    deployCurrencyManagerResponse.deploy.contract_address
  );
} // 0x46e3093c6e03847f77c8fdfb1f47e76fa38ddeecf9dd8cfb89c7e0a7f6decc3

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
        '../flex_marketplace/target/dev/flex_MarketPlace.compiled_contract_class.json'
      )
      .toString('ascii')
  );
  const compiledContractSierra = json.parse(
    fs
      .readFileSync(
        '../flex_marketplace/target/dev/flex_MarketPlace.contract_class.json'
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
}

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

buyPublicSale();
