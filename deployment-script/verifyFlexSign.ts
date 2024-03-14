import { Account, RpcProvider, shortString, stark, typedData, uint256 } from "starknet";
import dotenv from 'dotenv'

dotenv.config()

async function verifyFlexSignMainnet() {
    const accountAddress: string = process.env.ACCOUNT_PUBLIC as string
    const privateKey: string = process.env.ACCOUNT_PRIVATE as string
    const provider = new RpcProvider({
        nodeUrl: process.env.PROVIDER_URL as string,
    });

    const accountAx = new Account(provider, accountAddress, privateKey);

    const typeMessage = {
        domain: {
            chainId: shortString.encodeShortString('SN_MAIN'),
            name: 'Flex',
            version: '2',
        },
        message: {
            collection:
                '0x02e6c908da3d1ced80d81085ed9374b7c5048f86799e1f35e54daca4d70832d7',
            currency:
                '0x049d36570d4e46f48e99674bd3fcc84644ddd6b96f7c741b1562b82f9e004dc7',
            end_time: 1712465304,
            is_order_ask: 1,
            min_percentage_to_ask: '8500',
            salt_nonce: 30041,
            params: '0',
            amount: '1',
            price: '1000000000000000',
            signer: accountAddress,
            start_time: '0',
            strategy:
                '0x74a197a2554c2198dca9c0e0e9973b984145381d7e8be4a343a62a4bea73e2a',
            token_id: uint256.bnToUint256(16065),
        },
        primaryType: 'MakerOrder',
        types: {
            MakerOrder: [
                {
                    name: 'is_order_ask',
                    type: 'u8',
                },
                {
                    name: 'signer',
                    type: 'felt',
                },
                {
                    name: 'collection',
                    type: 'felt',
                },
                {
                    name: 'price',
                    type: 'u128',
                },
                {
                    name: 'token_id',
                    type: 'u256',
                },
                {
                    name: 'amount',
                    type: 'u128',
                },
                {
                    name: 'strategy',
                    type: 'felt',
                },
                {
                    name: 'currency',
                    type: 'felt',
                },
                {
                    name: 'salt_nonce',
                    type: 'u128',
                },
                {
                    name: 'start_time',
                    type: 'u64',
                },
                {
                    name: 'end_time',
                    type: 'u64',
                },
                {
                    name: 'min_percentage_to_ask',
                    type: 'u128',
                },
                {
                    name: 'params',
                    type: 'felt',
                },
            ],
            u256: [
                { name: 'low', type: 'felt' },
                { name: 'high', type: 'felt' },
            ],
            StarkNetDomain: [
                {
                    name: 'name',
                    type: 'felt',
                },
                {
                    name: 'version',
                    type: 'felt',
                },
                {
                    name: 'chainId',
                    type: 'felt',
                },
            ],
        },
    };

    console.log(typeMessage);
    const hashMsg = typedData.getMessageHash(typeMessage, accountAx.address);
    console.log({ hashMsg });

    const signature = await accountAx.signMessage(typeMessage);
    const arr = stark.formatSignature(signature);
    console.log("signature:", arr);

    const verify = await accountAx.verifyMessage(typeMessage, arr);
    console.log({ verify });
}

verifyFlexSignMainnet();