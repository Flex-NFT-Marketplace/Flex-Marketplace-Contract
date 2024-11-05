# calculate_interface_id.py

from starkware.starknet.public.abi import starknet_keccak

extended_function_selector_signatures_list_metadata = [
    'name()->ByteArray',
    'symbol()->ByteArray',
    'token_uri(u256)->ByteArray',
    'privilegeURI(u256)->ByteArray',
]

extended_function_selector_signatures_list = [
    'balance_of(ContractAddress)->u256',
    'owner_of(u256)->ContractAddress',
    'safe_transfer_from(ContractAddress,ContractAddress,u256,Span<felt252>)->()',
    'transfer_from(ContractAddress,ContractAddress,u256)->()',
    'approve(ContractAddress,u256)->()',
    'set_approval_for_all(ContractAddress,bool)->()',
    'get_approved(u256)->ContractAddress',
    'is_approved_for_all(ContractAddress,ContractAddress)->bool',
    'is_exercisable(u256,u256)->bool',
    'is_exercised(u256,u256)->bool',
    'get_privilege_ids(u256)->Array<u256>',
    'exercise_privilege(u256,ContractAddress,u256)->()',
]

extended_function_selector_signatures_list_receiver = [
    'on_erc7765_received(ContractAddress,ContractAddress,u256,Span<felt252>)->felt252'
]

def generate(arr):
    interface_id = 0x0
    for function_signature in arr:
        function_id = starknet_keccak(function_signature.encode())
        interface_id ^= function_id
    return hex(interface_id)


def main():
    # interface_id = 0x0
    # for function_signature in extended_function_selector_signatures_list:
    #     function_id = starknet_keccak(function_signature.encode())
    #     interface_id ^= function_id

    print('ERC7765 ID:')
    print(generate(extended_function_selector_signatures_list))    
    
    print('ERC7765Metadata ID:')
    print(generate(extended_function_selector_signatures_list_metadata))    
    
    print('ERC7765Receiver ID:')
    print(generate(extended_function_selector_signatures_list_receiver))    


main()