use starknet::ContractAddress;

use snforge_std::{declare, ContractClassTrait};
use snforge_std::{start_prank, CheatTarget, stop_prank};

use openzeppelin::token::erc721::interface::{IERC721Dispatcher, IERC721DispatcherTrait};

use offset_certificate::contract::{IOffsetCertificateDispatcher, IOffsetCertificateDispatcherTrait};


#[test]
fn test_mint_certificate() {
    let contract = declare('OffsetCertificatePoc');

    let contract_address = contract.deploy(@array![]).unwrap();

    let certificate_nft = IOffsetCertificateDispatcher { contract_address };
    let erc721 = IERC721Dispatcher { contract_address };

    let token_ids: Span<u256> = array![1, 2, 3, 4].span();
    let values: Span<u256> = array![10, 20, 30, 40].span();
    let token = certificate_nft.mint('0xUser'.try_into().unwrap(), token_ids, values);
    assert_eq!(token, 1);

    let bal = erc721.balance_of('0xUser'.try_into().unwrap());
    assert_eq!(bal, 1);

    let metadata = certificate_nft.token_uri(token);
    println!("{:}", metadata);
    assert_eq!((metadata[0], metadata[1], metadata[2], metadata[3]), ('d', 'a', 't', 'a'));
}
