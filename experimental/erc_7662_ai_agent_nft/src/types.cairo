#[derive(Drop, starknet::Store, Serde, Clone, PartialEq)]
pub struct Agent {
    pub name: ByteArray,
    pub description: ByteArray,
    pub model: ByteArray,
    pub user_prompt_uri: ByteArray,
    pub system_prompt_uri: ByteArray,
    pub image_uri: ByteArray,
    pub category: ByteArray,
    pub prompts_encrypted: bool,
}
