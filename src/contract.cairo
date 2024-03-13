use starknet::ContractAddress;

#[starknet::interface]
trait IOffsetCertificate<ContractState> {
    fn mint(
        ref self: ContractState, to: ContractAddress, token_ids: Span<u256>, values: Span<u256>
    ) -> u256;
    fn name(self: @ContractState) -> ByteArray;
    fn symbol(self: @ContractState) -> ByteArray;
    fn token_uri(self: @ContractState, token_id: u256) -> ByteArray;
    fn tokenURI(self: @ContractState, tokenId: u256) -> ByteArray;
    fn get_certificate(self: @ContractState, token_id: u256) -> (Span<u256>, Span<u256>);
}

#[starknet::contract]
mod OffsetCertificatePoc {
    use core::traits::Into;
    use openzeppelin::token::erc721::interface::IERC721Metadata;
    use openzeppelin::introspection::src5::SRC5Component;
    use openzeppelin::token::erc721::ERC721Component;

    use alexandria_storage::list::{List, ListTrait};

    use starknet::ContractAddress;

    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);

    // ERC721
    #[abi(embed_v0)]
    impl ERC721Impl = ERC721Component::ERC721Impl<ContractState>;
    #[abi(embed_v0)]
    impl ERC721CamelOnly = ERC721Component::ERC721CamelOnlyImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    // SRC5
    #[abi(embed_v0)]
    impl SRC5Impl = SRC5Component::SRC5Impl<ContractState>;
    #[abi(embed_v0)]
    impl SRC5CamelImpl = SRC5Component::SRC5CamelImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        certificate_tokens: LegacyMap<u256, List<u256>>,
        certificate_values: LegacyMap<u256, List<u256>>,
        total_supply: u256
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {}


    mod Errors {
        const LENGTH_MISMATCH: felt252 = 'OC: length mismatch';
        const INVALID_CERTIFICATE: felt252 = 'OC: invalid certificate';
    }

    // Custom Metadata
    use offset_certificate::metadata::template::generate;


    #[abi(embed_v0)]
    impl IOffsetCertifImpl of super::IOffsetCertificate<ContractState> {
        fn mint(
            ref self: ContractState, to: ContractAddress, token_ids: Span<u256>, values: Span<u256>
        ) -> u256 {
            assert(token_ids.len() == values.len(), Errors::LENGTH_MISMATCH);
            let minted_token_id = self.total_supply.read() + 1;
            self.erc721._mint(to, minted_token_id);
            self.total_supply.write(minted_token_id);
            let mut certificate_tokens = self.certificate_tokens.read(minted_token_id.into());
            let mut certificate_values = self.certificate_values.read(minted_token_id.into());
            let _ = certificate_tokens.append_span(token_ids);
            let _ = certificate_values.append_span(values);

            minted_token_id
        }

        fn name(self: @ContractState) -> ByteArray {
            "OffsetCertificatePoc"
        }
        fn symbol(self: @ContractState) -> ByteArray {
            "OCP"
        }
        fn token_uri(self: @ContractState, token_id: u256) -> ByteArray {
            generate::generate_uri(token_id)
        }
        fn tokenURI(self: @ContractState, tokenId: u256) -> ByteArray {
            self.token_uri(tokenId)
        }

        fn get_certificate(self: @ContractState, token_id: u256) -> (Span<u256>, Span<u256>) {
            let certificate_tokens = self.certificate_tokens.read(token_id.into());
            let certificate_values = self.certificate_values.read(token_id.into());
            (
                certificate_tokens.array().expect(Errors::INVALID_CERTIFICATE).span(),
                certificate_values.array().expect(Errors::INVALID_CERTIFICATE).span()
            )
        }
    }
}
