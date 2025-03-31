#[starknet::interface]
pub trait INftRender<TContractState> {
    fn tokenURI(self: @TContractState, token_id: u256) -> ByteArray;
    fn metadata(self: @TContractState, token_id: u256) -> ByteArray;
}

#[starknet::contract]
mod NftRender {
    use super::INftRender;

    const UNIT: u256 = 1_000_000_000_000_000_000;
    const goldenRatio: u256 = (1618033988749895 * UNIT);

    #[storage]
    struct Storage {}

    #[derive(Drop, Copy, Serde)]
    struct Star {
        x: i128,
        y: i128,
        size: u256,
        opacity: u256,
        // uint256 angle;
    // uint256 distance;
    // uint256 jitter;
    // uint256 angleJitter;
    }

    #[abi(embed_v0)]
    impl INftRenderImpl of INftRender<ContractState> {
        fn tokenURI(self: @ContractState, token_id: u256) -> ByteArray {
            let mut uri: ByteArray = "data:text/plain,";
            uri.append(@(self.metadata(token_id)));
            uri
        }

        fn metadata(self: @ContractState, token_id: u256) -> ByteArray {
            let animation: ByteArray =
                "PCFET0NUWVBFIGh0bWw+DQo8aHRtbD4NCjxoZWFkPg0KICAgIDx0aXRsZT5UaHJlZS5qcyBUZXh0IEN1YmUgd2l0aCBTbW9vdGggQ29sb3IgVHJhbnNpdGlvbjwvdGl0bGU+DQogICAgPHN0eWxlPg0KICAgICAgICBib2R5IHsgbWFyZ2luOiAwOyB9DQogICAgICAgIGNhbnZhcyB7IGRpc3BsYXk6IGJsb2NrOyB9DQogICAgPC9zdHlsZT4NCjwvaGVhZD4NCjxib2R5Pg0KICAgIDxzY3JpcHQgc3JjPSJodHRwczovL2NkbmpzLmNsb3VkZmxhcmUuY29tL2FqYXgvbGlicy90aHJlZS5qcy9yMTM0L3RocmVlLm1pbi5qcyI+PC9zY3JpcHQ+DQogICAgPHNjcmlwdD4NCiAgICAgICAgY29uc3Qgc2NlbmUgPSBuZXcgVEhSRUUuU2NlbmUoKTsNCiAgICAgICAgY29uc3QgY2FtZXJhID0gbmV3IFRIUkVFLlBlcnNwZWN0aXZlQ2FtZXJhKDc1LCB3aW5kb3cuaW5uZXJXaWR0aCAvIHdpbmRvdy5pbm5lckhlaWdodCwgMC4xLCAxMDAwKTsNCiAgICAgICAgY29uc3QgcmVuZGVyZXIgPSBuZXcgVEhSRUUuV2ViR0xSZW5kZXJlcigpOw0KICAgICAgICByZW5kZXJlci5zZXRTaXplKHdpbmRvdy5pbm5lcldpZHRoLCB3aW5kb3cuaW5uZXJIZWlnaHQpOw0KICAgICAgICBkb2N1bWVudC5ib2R5LmFwcGVuZENoaWxkKHJlbmRlcmVyLmRvbUVsZW1lbnQpOw0KDQogICAgICAgIGNvbnN0IGNhbnZhcyA9IGRvY3VtZW50LmNyZWF0ZUVsZW1lbnQoJ2NhbnZhcycpOw0KICAgICAgICBjb25zdCBjb250ZXh0ID0gY2FudmFzLmdldENvbnRleHQoJzJkJyk7DQogICAgICAgIGNhbnZhcy53aWR0aCA9IDUxMjsNCiAgICAgICAgY2FudmFzLmhlaWdodCA9IDUxMjsNCg0KICAgICAgICBjb25zdCBjb2xvcnMgPSBbJyMxRTkwRkYnLCAnI0ZGNDUwMCcsICcjMzJDRDMyJywgJyNGRkQ3MDAnLCAnIzk5MzJDQyddOw0KICAgICAgICBsZXQgY29sb3JJbmRleCA9IDA7DQogICAgICAgIGxldCBuZXh0Q29sb3JJbmRleCA9IDE7DQogICAgICAgIGxldCB0cmFuc2l0aW9uUHJvZ3Jlc3MgPSAwOw0KICAgICAgICBsZXQgaXNGbGV4ID0gdHJ1ZTsgDQogICAgICAgIGNvbnN0IHRyYW5zaXRpb25EdXJhdGlvbiA9IDIwMDA7IA0KDQoNCiAgICAgICAgZnVuY3Rpb24gaW50ZXJwb2xhdGVDb2xvcihjb2xvcjEsIGNvbG9yMiwgZmFjdG9yKSB7DQogICAgICAgICAgICBjb25zdCBjMSA9IG5ldyBUSFJFRS5Db2xvcihjb2xvcjEpOw0KICAgICAgICAgICAgY29uc3QgYzIgPSBuZXcgVEhSRUUuQ29sb3IoY29sb3IyKTsNCiAgICAgICAgICAgIHJldHVybiBuZXcgVEhSRUUuQ29sb3IoDQogICAgICAgICAgICAgICAgYzEuciArIChjMi5yIC0gYzEucikgKiBmYWN0b3IsDQogICAgICAgICAgICAgICAgYzEuZyArIChjMi5nIC0gYzEuZykgKiBmYWN0b3IsDQogICAgICAgICAgICAgICAgYzEuYiArIChjMi5iIC0gYzEuYikgKiBmYWN0b3INCiAgICAgICAgICAgICkuZ2V0SGV4U3RyaW5nKCk7DQogICAgICAgIH0NCg0KICAgICAgICBmdW5jdGlvbiB1cGRhdGVUZXh0dXJlKCkgew0KDQogICAgICAgICAgICBjb25zdCBjdXJyZW50Q29sb3IgPSBpbnRlcnBvbGF0ZUNvbG9yKA0KICAgICAgICAgICAgICAgIGNvbG9yc1tjb2xvckluZGV4XSwNCiAgICAgICAgICAgICAgICBjb2xvcnNbbmV4dENvbG9ySW5kZXhdLA0KICAgICAgICAgICAgICAgIHRyYW5zaXRpb25Qcm9ncmVzcw0KICAgICAgICAgICAgKTsNCg0KICAgICAgICAgICAgY29udGV4dC5maWxsU3R5bGUgPSAnIycgKyBjdXJyZW50Q29sb3I7DQogICAgICAgICAgICBjb250ZXh0LmZpbGxSZWN0KDAsIDAsIGNhbnZhcy53aWR0aCwgY2FudmFzLmhlaWdodCk7DQogICAgICAgICAgICBjb250ZXh0LmZvbnQgPSAnYm9sZCA4MHB4IEFyaWFsJzsNCiAgICAgICAgICAgIGNvbnRleHQuZmlsbFN0eWxlID0gJ3doaXRlJzsNCiAgICAgICAgICAgIGNvbnRleHQudGV4dEFsaWduID0gJ2NlbnRlcic7DQogICAgICAgICAgICBjb250ZXh0LnRleHRCYXNlbGluZSA9ICdtaWRkbGUnOw0KDQogICAgICAgICAgICBpZiAoaXNGbGV4KSB7DQogICAgICAgICAgICAgICAgY29udGV4dC5maWxsVGV4dCgnRmxleCcsIGNhbnZhcy53aWR0aC8yLCBjYW52YXMuaGVpZ2h0LzIgLSA0MCk7DQogICAgICAgICAgICAgICAgY29udGV4dC5maWxsVGV4dCgnTWFya2V0cGxhY2UnLCBjYW52YXMud2lkdGgvMiwgY2FudmFzLmhlaWdodC8yICsgNDApOw0KICAgICAgICAgICAgfSBlbHNlIHsNCiAgICAgICAgICAgICAgICBjb250ZXh0LmZvbnQgPSAnYm9sZCAxMDBweCBBcmlhbCc7DQogICAgICAgICAgICAgICAgY29udGV4dC5maWxsVGV4dCgnU3RhcmtuZXQnLCBjYW52YXMud2lkdGgvMiwgY2FudmFzLmhlaWdodC8yKTsNCiAgICAgICAgICAgIH0NCg0KICAgICAgICAgICAgdGV4dHVyZS5uZWVkc1VwZGF0ZSA9IHRydWU7DQogICAgICAgIH0NCg0KDQogICAgICAgIGNvbnN0IHRleHR1cmUgPSBuZXcgVEhSRUUuQ2FudmFzVGV4dHVyZShjYW52YXMpOw0KDQoNCiAgICAgICAgY29uc3QgZ2VvbWV0cnkgPSBuZXcgVEhSRUUuQm94R2VvbWV0cnkoMiwgMiwgMik7DQogICAgICAgIGNvbnN0IG1hdGVyaWFsID0gbmV3IFRIUkVFLk1lc2hCYXNpY01hdGVyaWFsKHsgbWFwOiB0ZXh0dXJlIH0pOw0KICAgICAgICBjb25zdCBtYXRlcmlhbHMgPSBbDQogICAgICAgICAgICBtYXRlcmlhbCwgDQogICAgICAgICAgICBtYXRlcmlhbCwgDQogICAgICAgICAgICBtYXRlcmlhbCwgDQogICAgICAgICAgICBtYXRlcmlhbCwgDQogICAgICAgICAgICBtYXRlcmlhbCwgDQogICAgICAgICAgICBtYXRlcmlhbCAgDQogICAgICAgIF07DQogICAgICAgIGNvbnN0IGN1YmUgPSBuZXcgVEhSRUUuTWVzaChnZW9tZXRyeSwgbWF0ZXJpYWxzKTsNCiAgICAgICAgc2NlbmUuYWRkKGN1YmUpOw0KDQogICAgICAgIGNhbWVyYS5wb3NpdGlvbi56ID0gNTsNCg0KICAgICAgICBsZXQgbGFzdFRpbWUgPSBEYXRlLm5vdygpOw0KICAgICAgICBmdW5jdGlvbiBhbmltYXRlKCkgew0KICAgICAgICAgICAgcmVxdWVzdEFuaW1hdGlvbkZyYW1lKGFuaW1hdGUpOw0KICAgICAgICAgICAgDQogICAgICAgICAgICBjdWJlLnJvdGF0aW9uLnggKz0gMC4wMTsNCiAgICAgICAgICAgIGN1YmUucm90YXRpb24ueSArPSAwLjAxOw0KDQogICAgICAgICAgICBjb25zdCBub3cgPSBEYXRlLm5vdygpOw0KICAgICAgICAgICAgY29uc3QgZGVsdGFUaW1lID0gbm93IC0gbGFzdFRpbWU7DQogICAgICAgICAgICBsYXN0VGltZSA9IG5vdzsNCg0KICAgICAgICAgICAgdHJhbnNpdGlvblByb2dyZXNzICs9IGRlbHRhVGltZSAvIHRyYW5zaXRpb25EdXJhdGlvbjsNCiAgICAgICAgICAgIGlmICh0cmFuc2l0aW9uUHJvZ3Jlc3MgPj0gMSkgew0KICAgICAgICAgICAgICAgIHRyYW5zaXRpb25Qcm9ncmVzcyA9IDA7DQogICAgICAgICAgICAgICAgY29sb3JJbmRleCA9IG5leHRDb2xvckluZGV4Ow0KICAgICAgICAgICAgICAgIG5leHRDb2xvckluZGV4ID0gKG5leHRDb2xvckluZGV4ICsgMSkgJSBjb2xvcnMubGVuZ3RoOw0KICAgICAgICAgICAgICAgIGlzRmxleCA9ICFpc0ZsZXg7DQogICAgICAgICAgICB9DQogICAgICAgICAgICB1cGRhdGVUZXh0dXJlKCk7DQogICAgICAgICAgICByZW5kZXJlci5yZW5kZXIoc2NlbmUsIGNhbWVyYSk7DQogICAgICAgIH0NCg0KICAgICAgICB1cGRhdGVUZXh0dXJlKCk7DQoNCiAgICAgICAgd2luZG93LmFkZEV2ZW50TGlzdGVuZXIoJ3Jlc2l6ZScsICgpID0+IHsNCiAgICAgICAgICAgIGNhbWVyYS5hc3BlY3QgPSB3aW5kb3cuaW5uZXJXaWR0aCAvIHdpbmRvdy5pbm5lckhlaWdodDsNCiAgICAgICAgICAgIGNhbWVyYS51cGRhdGVQcm9qZWN0aW9uTWF0cml4KCk7DQogICAgICAgICAgICByZW5kZXJlci5zZXRTaXplKHdpbmRvdy5pbm5lcldpZHRoLCB3aW5kb3cuaW5uZXJIZWlnaHQpOw0KICAgICAgICB9KTsNCg0KICAgICAgICBhbmltYXRlKCk7DQogICAgPC9zY3JpcHQ+DQo8L2JvZHk+DQo8L2h0bWw+";
            let mut json: ByteArray = "{\"name\": \"Arborithm #";
            json.append(@format!("{}\",", token_id));
            json.append(@"\"description\": \"\",");
            json.append(@"\"image\":\"data:text/html;base64,");
            json.append(@animation);
            // TODO: add base64 encode image
            json.append(@"\",");
            json.append(@"\"animation_url\":\"data:text/html;base64,");
            // TODO: add base64 encode animation
            // json.append(@(base64_encode(animation)));  // error here
            json.append(@animation);
            json.append(@"\",");
            json
                .append(
                    @"\"attributes\":[{\"trait_type\":\"background\",\"value\":\"#000000\"},{\"trait_type\":\"body\",\"value\":\"#000000\"},{\"trait_type\":\"eyes\",\"value\":\"#000000\"},{\"trait_type\":\"mouth\",\"value\":\"#000000\"},{\"trait_type\":\"hair\",\"value\":\"#000000\"},{\"trait_type\":\"head\",\"value\":\"#000000\"}]}",
                );

            json
        }
    }
}
