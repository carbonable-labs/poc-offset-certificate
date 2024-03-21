#[starknet::contract]
mod LoremIpsumMetadata {
    use offset_certificate::metadata::template::generate;
    #[storage]
    struct Storage {}

    #[generate_trait]
    #[abi(per_item)]
    impl LasDeliciasTokenMetadata of ITokenMetadata {
        #[external(v0)]
        fn token_uri(self: @ContractState, token_id: u256) -> ByteArray {
            generate::generate_uri(token_id)
        }
    }
}
