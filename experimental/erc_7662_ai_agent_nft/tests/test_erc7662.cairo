use snforge_std::{
    start_cheat_caller_address, stop_cheat_caller_address, declare, ContractClassTrait
};

use starknet::{ContractAddress, get_block_timestamp};

use erc_7662_ai_agent_nft::interfaces::{IERC7662Dispatcher, IERC7662DispatcherTrait};

fn NAME() -> ByteArray {
    let name: ByteArray = "AgentNFT";
    name
}
fn SYMBOL() -> ByteArray {
    let symbol: ByteArray = "ANFT";
    symbol
}
fn BASE_URI() -> ByteArray {
    let base_uri: ByteArray = "https://base.uri/";
    base_uri
}

fn OWNER() -> ContractAddress {
    'owner'.try_into().unwrap()
}

fn BOB() -> ContractAddress {
    'bob'.try_into().unwrap()
}

fn setup() -> IERC7662Dispatcher {
    let contract_class = declare("ERC7662").unwrap();

    let mut calldata = array![];
    NAME().serialize(ref calldata);
    SYMBOL().serialize(ref calldata);
    BASE_URI().serialize(ref calldata);

    let (contract_address, _) = contract_class.deploy(@calldata).unwrap();

    IERC7662Dispatcher { contract_address }
}

#[test]
fn test_mint_agent() {
    let dispatcher = setup();

    let token_id = dispatcher
        .mint_agent(
            OWNER(),
            "AgentName",
            "AgentDescription",
            "AgentModel",
            "https://user.prompt.uri/",
            "https://system.prompt.uri/",
            "https://image.uri/",
            "AgentCategory"
        );

    let agent = dispatcher.get_agent(token_id);
    assert(agent.name == "AgentName", 'Invalid agent name');
    assert(agent.description == "AgentDescription", 'Invalid agent description');
    assert(agent.model == "AgentModel", 'Invalid agent model');
}

#[test]
fn test_add_encrypted_prompts() {
    let dispatcher = setup();

    let token_id = dispatcher
        .mint_agent(
            OWNER(),
            "AgentName",
            "AgentDescription",
            "AgentModel",
            "https://user.prompt.uri/",
            "https://system.prompt.uri/",
            "https://image.uri/",
            "AgentCategory"
        );

    dispatcher
        .add_encrypted_prompts(
            token_id, "https://encrypted.user.prompt.uri/", "https://encrypted.system.prompt.uri/"
        );

    let agent = dispatcher.get_agent(token_id);
    assert(agent.prompts_encrypted == true, 'Prompts should be encrypted');
    assert(
        agent.user_prompt_uri == "https://encrypted.user.prompt.uri/",
        'Invalid encrypted user prompt'
    );
    assert(
        agent.system_prompt_uri == "https://encrypted.system.prompt.uri/",
        'Invalid encrypted system prompt'
    );
}

#[test]
fn test_get_collection_ids() {
    let dispatcher = setup();

    let token_id_1 = dispatcher
        .mint_agent(
            OWNER(),
            "Agent1",
            "Description1",
            "Model1",
            "https://user1.prompt.uri/",
            "https://system1.prompt.uri/",
            "https://image1.uri/",
            "Category1"
        );

    let token_id_2 = dispatcher
        .mint_agent(
            OWNER(),
            "Agent2",
            "Description2",
            "Model2",
            "https://user2.prompt.uri/",
            "https://system2.prompt.uri/",
            "https://image2.uri/",
            "Category2"
        );

    let collection_ids = dispatcher.get_collection_ids(OWNER());
    assert(collection_ids.len() == 2, 'Wrong number of tokens');
    assert(*collection_ids.at(0) == token_id_1, 'Wrong first token');
    assert(*collection_ids.at(1) == token_id_2, 'Wrong second token');
}


#[test]
fn test_get_agent_data() {
    let dispatcher = setup();

    let token_id = dispatcher
        .mint_agent(
            OWNER(),
            "AgentName",
            "AgentDescription",
            "AgentModel",
            "https://user.prompt.uri/",
            "https://system.prompt.uri/",
            "https://image.uri/",
            "AgentCategory"
        );

    let (name, description, model, user_prompt_uri, system_prompt_uri, prompts_encrypted) =
        dispatcher
        .get_agent_data(token_id);

    assert(name == "AgentName", 'Invalid agent name');
    assert(description == "AgentDescription", 'Invalid agent description');
    assert(model == "AgentModel", 'Invalid agent model');
    assert(user_prompt_uri == "https://user.prompt.uri/", 'Invalid user prompt uri');
    assert(system_prompt_uri == "https://system.prompt.uri/", 'Invalid system prompt uri');
    assert(prompts_encrypted == false, 'Prompts should not be encrypted');
}
