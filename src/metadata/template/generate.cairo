use core::array::SpanTrait;
use graffiti::json::JsonImpl;
use starknet::get_contract_address;
use offset_certificate::contract::{IOffsetCertificateDispatcher, IOffsetCertificateDispatcherTrait};

fn get_description(token_id: u256) -> ByteArray {
    format!("Dummy description for token #{}", token_id)
}

fn generate_uri(token_id: u256) -> ByteArray {
    let contract_address = get_contract_address();
    let contract = IOffsetCertificateDispatcher { contract_address };
    let name = contract.name();
    let project_name = "test";

    let metadata = JsonImpl::new()
        .add("name", format!("{} #{}", name, token_id))
        .add("description", get_description(token_id))
        .add("project", project_name);

    let mut attributes: Array<ByteArray> = Default::default();

    let certificate = contract.get_certificate(token_id);
    let (mut token_ids, mut values) = certificate;

    loop {
        match token_ids.pop_front() {
            Option::Some(id) => {
                let value = values.pop_front().unwrap();
                attributes
                    .append(
                        JsonImpl::new()
                            .add("trait_type", format!("{}", id))
                            .add("value", format!("{}", value))
                            .build()
                    );
            },
            Option::None => { break (); },
        };
    };
    let metadata: ByteArray = metadata.add_array("attributes", attributes.span()).build();
    format!("data:application/json,{}", metadata)
}

