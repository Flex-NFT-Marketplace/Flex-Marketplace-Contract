#[starknet::interface]
pub trait INftRender<TContractState> {
    fn tokenURI(self: @TContractState, token_id: u256) -> ByteArray;
    fn metadata(self: @TContractState, token_id: u256) -> ByteArray;
}

#[starknet::contract]
mod NftRender {
    use super::INftRender;
    use base64_nft::common::base64_encode;

    #[storage]
    struct Storage {}

    #[abi(embed_v0)]
    impl INftRenderImpl of INftRender<ContractState> {
        fn tokenURI(self: @ContractState, token_id: u256) -> ByteArray {
            let mut uri: ByteArray = "data:text/plain,";
            uri.append(@(self.metadata(token_id)));
            uri
        }

        fn metadata(self: @ContractState, token_id: u256) -> ByteArray {
            let mut animation: ByteArray =
                "<!DOCTYPE html> <html lang='en'> <head> <meta charset='UTF-8'> <meta name='viewport' content='width=device-width, initial-scale=1.0'> <title>Conway's Game of Life</title> <style> body { display: flex; justify-content: center; align-items: center; min-height: 100vh; margin: 0; background: #f0f0f0; } canvas { border: 1px solid #333; background: #000; } </style> <script> ";

            animation.append(@"const initialState = BigInt('");
            animation.append(@format!("{}", token_id));
            animation
                .append(
                    @"'); </script> </head> <body> <canvas id='gameCanvas'></canvas> <script src='data:text/javascript;base64,IC8vIFVzaW5nIEJpZ0ludCBzaW5jZSByZWd1bGFyIE51bWJlcnMgaW4gSmF2YVNjcmlwdCBjYW4ndCBzYWZlbHkgaGFuZGxlIDIyNSBiaXRzCiAgICAgICAgY29uc3QgR1JJRF9TSVpFID0gMTY7CiAgICAgICAgY29uc3QgZnBzID0gMTsgLy8gRnJhbWVzIHBlciBzZWNvbmQKCiAgICAgICAgLy8gQ29uZmlndXJhdGlvbgogICAgICAgIGNvbnN0IGNlbGxTaXplID0gMTA7IC8vIFNpemUgb2YgZWFjaCBjZWxsIGluIHBpeGVscwoKICAgICAgICAvLyBDYW52YXMgU2V0dXAKICAgICAgICBjb25zdCBjYW52YXMgPSBkb2N1bWVudC5nZXRFbGVtZW50QnlJZCgiZ2FtZUNhbnZhcyIpOwogICAgICAgIGNvbnN0IGN0eCA9IGNhbnZhcy5nZXRDb250ZXh0KCIyZCIpOwogICAgICAgIGNhbnZhcy53aWR0aCA9IDE2MDsKICAgICAgICBjYW52YXMuaGVpZ2h0ID0gMTYwOwoKICAgICAgICAvLy8gUGFja2luZyBmdW5jdGlvbnMKICAgICAgICBmdW5jdGlvbiBwYWNrR3JpZFRvQmlnSW50KGdyaWQpIHsKICAgICAgICAgICAgLy8gSW5wdXQgdmFsaWRhdGlvbgogICAgICAgICAgICBpZiAoIUFycmF5LmlzQXJyYXkoZ3JpZCkgfHwgZ3JpZC5sZW5ndGggIT09IEdSSURfU0laRSkgewogICAgICAgICAgICAgICAgdGhyb3cgbmV3IEVycm9yKGBHcmlkIG11c3QgYmUgYSAke0dSSURfU0laRX14JHtHUklEX1NJWkV9IGFycmF5YCk7CiAgICAgICAgICAgIH0KICAgICAgICAgICAgaWYgKCFncmlkLmV2ZXJ5KHJvdyA9PiBBcnJheS5pc0FycmF5KHJvdykgJiYgcm93Lmxlbmd0aCA9PT0gR1JJRF9TSVpFKSkgewogICAgICAgICAgICAgICAgdGhyb3cgbmV3IEVycm9yKGBFYWNoIHJvdyBtdXN0IGNvbnRhaW4gJHtHUklEX1NJWkV9IGVsZW1lbnRzYCk7CiAgICAgICAgICAgIH0KCiAgICAgICAgICAgIGxldCBwYWNrZWRTdGF0ZSA9IDBuOyAgLy8gVXNpbmcgMG4gZm9yIEJpZ0ludCBsaXRlcmFsCiAgICAgICAgICAgIGxldCBwb3dlciA9IDFuOwoKICAgICAgICAgICAgZm9yIChsZXQgcm93ID0gMDsgcm93IDwgR1JJRF9TSVpFOyByb3crKykgewogICAgICAgICAgICAgICAgZm9yIChsZXQgY29sID0gMDsgY29sIDwgR1JJRF9TSVpFOyBjb2wrKykgewogICAgICAgICAgICAgICAgICAgIGlmIChncmlkW3Jvd11bY29sXSA9PT0gdHJ1ZSkgewogICAgICAgICAgICAgICAgICAgICAgICBwYWNrZWRTdGF0ZSArPSBwb3dlcjsKICAgICAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgICAgICAgICAgcG93ZXIgKj0gMm47CiAgICAgICAgICAgICAgICB9CiAgICAgICAgICAgIH0KCiAgICAgICAgICAgIHJldHVybiBwYWNrZWRTdGF0ZTsKICAgICAgICB9CgogICAgICAgIGZ1bmN0aW9uIHVucGFja0JpZ0ludFRvR3JpZChzdGF0ZSkgewogICAgICAgICAgICAvLyBJbnB1dCB2YWxpZGF0aW9uCiAgICAgICAgICAgIGlmICh0eXBlb2Ygc3RhdGUgIT09ICdiaWdpbnQnKSB7CiAgICAgICAgICAgICAgICB0aHJvdyBuZXcgRXJyb3IoJ0lucHV0IG11c3QgYmUgYSBCaWdJbnQnKTsKICAgICAgICAgICAgfQogICAgICAgICAgICBpZiAoc3RhdGUgPj0gMm4gKiogQmlnSW50KEdSSURfU0laRSAqIEdSSURfU0laRSkpIHsKICAgICAgICAgICAgICAgIHRocm93IG5ldyBFcnJvcignSW5wdXQgdmFsdWUgdG9vIGxhcmdlIGZvciBncmlkIHNpemUnKTsKICAgICAgICAgICAgfQoKICAgICAgICAgICAgY29uc3QgZ3JpZCA9IEFycmF5KEdSSURfU0laRSkuZmlsbCgpLm1hcCgoKSA9PiBBcnJheShHUklEX1NJWkUpLmZpbGwoZmFsc2UpKTsKICAgICAgICAgICAgbGV0IHN0YXRlQ29weSA9IHN0YXRlOwoKICAgICAgICAgICAgZm9yIChsZXQgcm93ID0gMDsgcm93IDwgR1JJRF9TSVpFOyByb3crKykgewogICAgICAgICAgICAgICAgZm9yIChsZXQgY29sID0gMDsgY29sIDwgR1JJRF9TSVpFOyBjb2wrKykgewogICAgICAgICAgICAgICAgICAgIGdyaWRbcm93XVtjb2xdID0gKHN0YXRlQ29weSAmIDFuKSA9PT0gMW47CiAgICAgICAgICAgICAgICAgICAgc3RhdGVDb3B5ID0gc3RhdGVDb3B5ID4+IDFuOyAgLy8gU2hpZnQgcmlnaHQgdG8gY2hlY2sgbmV4dCBiaXQKICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgfQoKICAgICAgICAgICAgcmV0dXJuIGdyaWQ7CiAgICAgICAgfQoKICAgICAgICAvLy8gRGlzcGxheSBmdW5jdGlvbgogICAgICAgIGZ1bmN0aW9uIGRpc3BsYXlHcmlkKGdyaWQpIHsKICAgICAgICAgICAgY3R4LmNsZWFyUmVjdCgwLCAwLCBjYW52YXMud2lkdGgsIGNhbnZhcy5oZWlnaHQpOwogICAgICAgICAgICBjdHguZmlsbFN0eWxlID0gIndoaXRlIjsKICAgICAgICAgICAgZm9yIChsZXQgcm93ID0gMDsgcm93IDwgZ3JpZC5sZW5ndGg7IHJvdysrKSB7CiAgICAgICAgICAgICAgICBmb3IgKGxldCBjb2wgPSAwOyBjb2wgPCBncmlkW3Jvd10ubGVuZ3RoOyBjb2wrKykgewogICAgICAgICAgICAgICAgICAgIGlmIChncmlkW3Jvd11bY29sXSkgewogICAgICAgICAgICAgICAgICAgICAgICBjdHguZmlsbFJlY3QoY29sICogY2VsbFNpemUsIHJvdyAqIGNlbGxTaXplLCBjZWxsU2l6ZSwgY2VsbFNpemUpOwogICAgICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgfQogICAgICAgIH0KCiAgICAgICAgZnVuY3Rpb24gaW5maW5pdGVEaXNwbGF5TG9vcChpbml0aWFsU3RhdGUpIHsKICAgICAgICAgICAgY29uc3QgZ3JpZCA9IHVucGFja0JpZ0ludFRvR3JpZChpbml0aWFsU3RhdGUpOwogICAgICAgICAgICBkaXNwbGF5R3JpZChncmlkKTsKICAgICAgICAgICAgc2V0VGltZW91dCgoKSA9PiBpbmZpbml0ZURpc3BsYXlMb29wKGl0ZXJhdGVMaWZlT25jZShpbml0aWFsU3RhdGUpKSwgMTAwMCAvIGZwcyk7CiAgICAgICAgfQoKICAgICAgICAvLy8gR09MIEZ1bmN0aW9ucwogICAgICAgIGZ1bmN0aW9uIGl0ZXJhdGVMaWZlT25jZShpbml0aWFsU3RhdGUpIHsKICAgICAgICAgICAgLy8gRmlyc3QgdW5wYWNrIHRoZSBzdGF0ZSB0byBhIGdyaWQKICAgICAgICAgICAgY29uc3QgZ3JpZCA9IHVucGFja0JpZ0ludFRvR3JpZChpbml0aWFsU3RhdGUpOwoKICAgICAgICAgICAgLy8gQ3JlYXRlIG5ldyBncmlkIGZvciB0aGUgbmV4dCBzdGF0ZQogICAgICAgICAgICBjb25zdCBuZXh0R3JpZCA9IEFycmF5KEdSSURfU0laRSkuZmlsbCgpLm1hcCgoKSA9PiBBcnJheShHUklEX1NJWkUpLmZpbGwoZmFsc2UpKTsKCiAgICAgICAgICAgIC8vIEdvIHRocm91Z2ggZWFjaCBjZWxsCiAgICAgICAgICAgIGZvciAobGV0IHJvdyA9IDA7IHJvdyA8IEdSSURfU0laRTsgcm93KyspIHsKICAgICAgICAgICAgICAgIGZvciAobGV0IGNvbCA9IDA7IGNvbCA8IEdSSURfU0laRTsgY29sKyspIHsKICAgICAgICAgICAgICAgICAgICBsZXQgbmVpZ2hib3Vyc0NvdW50ID0gMDsKCiAgICAgICAgICAgICAgICAgICAgLy8gQ2FsY3VsYXRlIHdyYXBwZWQgaW5kaWNlcwogICAgICAgICAgICAgICAgICAgIGNvbnN0IHJvd0Fib3ZlID0gKChyb3cgKyBHUklEX1NJWkUgLSAxKSAlIEdSSURfU0laRSk7CiAgICAgICAgICAgICAgICAgICAgY29uc3Qgcm93QmVsb3cgPSAoKHJvdyArIDEpICUgR1JJRF9TSVpFKTsKICAgICAgICAgICAgICAgICAgICBjb25zdCBjb2xMZWZ0ID0gKChjb2wgKyBHUklEX1NJWkUgLSAxKSAlIEdSSURfU0laRSk7CiAgICAgICAgICAgICAgICAgICAgY29uc3QgY29sUmlnaHQgPSAoKGNvbCArIDEpICUgR1JJRF9TSVpFKTsKCiAgICAgICAgICAgICAgICAgICAgLy8gQ291bnQgYWxsIDggbmVpZ2hib3JzCiAgICAgICAgICAgICAgICAgICAgLy8gMyBjZWxscyBhYm92ZQogICAgICAgICAgICAgICAgICAgIGlmIChncmlkW3Jvd0Fib3ZlXVtjb2xMZWZ0XSkgbmVpZ2hib3Vyc0NvdW50Kys7CiAgICAgICAgICAgICAgICAgICAgaWYgKGdyaWRbcm93QWJvdmVdW2NvbF0pIG5laWdoYm91cnNDb3VudCsrOwogICAgICAgICAgICAgICAgICAgIGlmIChncmlkW3Jvd0Fib3ZlXVtjb2xSaWdodF0pIG5laWdoYm91cnNDb3VudCsrOwoKICAgICAgICAgICAgICAgICAgICAvLyBDZWxscyB0byB0aGUgc2lkZXMKICAgICAgICAgICAgICAgICAgICBpZiAoZ3JpZFtyb3ddW2NvbExlZnRdKSBuZWlnaGJvdXJzQ291bnQrKzsKICAgICAgICAgICAgICAgICAgICBpZiAoZ3JpZFtyb3ddW2NvbFJpZ2h0XSkgbmVpZ2hib3Vyc0NvdW50Kys7CgogICAgICAgICAgICAgICAgICAgIC8vIDMgY2VsbHMgYmVsb3cKICAgICAgICAgICAgICAgICAgICBpZiAoZ3JpZFtyb3dCZWxvd11bY29sTGVmdF0pIG5laWdoYm91cnNDb3VudCsrOwogICAgICAgICAgICAgICAgICAgIGlmIChncmlkW3Jvd0JlbG93XVtjb2xdKSBuZWlnaGJvdXJzQ291bnQrKzsKICAgICAgICAgICAgICAgICAgICBpZiAoZ3JpZFtyb3dCZWxvd11bY29sUmlnaHRdKSBuZWlnaGJvdXJzQ291bnQrKzsKCiAgICAgICAgICAgICAgICAgICAgLy8gQXBwbHkgR2FtZSBvZiBMaWZlIHJ1bGVzCiAgICAgICAgICAgICAgICAgICAgY29uc3QgaXNBbGl2ZSA9IGdyaWRbcm93XVtjb2xdOwogICAgICAgICAgICAgICAgICAgIG5leHRHcmlkW3Jvd11bY29sXSA9IGlzQWxpdmUgPwogICAgICAgICAgICAgICAgICAgICAgICAobmVpZ2hib3Vyc0NvdW50ID09PSAyIHx8IG5laWdoYm91cnNDb3VudCA9PT0gMykgOiAvLyBTdXJ2aXZhbAogICAgICAgICAgICAgICAgICAgICAgICAobmVpZ2hib3Vyc0NvdW50ID09PSAzKTsgLy8gQmlydGgKICAgICAgICAgICAgICAgIH0KICAgICAgICAgICAgfQoKICAgICAgICAgICAgLy8gUGFjayB0aGUgbmV3IGdyaWQgYmFjayB0byBhIEJpZ0ludAogICAgICAgICAgICByZXR1cm4gcGFja0dyaWRUb0JpZ0ludChuZXh0R3JpZCk7CiAgICAgICAgfQoKICAgICAgICBmdW5jdGlvbiBpdGVyYXRlTGlmZVNldmVyYWxUaW1lcyhpbml0aWFsU3RhdGUsIGl0ZXJhdGlvbnMpIHsKICAgICAgICAgICAgbGV0IGN1cnJlbnRTdGF0ZSA9IGluaXRpYWxTdGF0ZTsKICAgICAgICAgICAgZm9yIChsZXQgaSA9IDA7IGkgPCBpdGVyYXRpb25zOyBpKyspIHsKICAgICAgICAgICAgICAgIGN1cnJlbnRTdGF0ZSA9IGl0ZXJhdGVMaWZlT25jZShjdXJyZW50U3RhdGUpOwogICAgICAgICAgICAgICAgY29uc3QgZ3JpZCA9IHVucGFja0JpZ0ludFRvR3JpZChjdXJyZW50U3RhdGUpOwogICAgICAgICAgICAgICAgZGlzcGxheUdyaWQoZ3JpZCk7CiAgICAgICAgICAgIH0KICAgICAgICAgICAgcmV0dXJuIGN1cnJlbnRTdGF0ZTsKICAgICAgICB9CgogICAgICAgIGZ1bmN0aW9uIHJ1bigpIHsKICAgICAgICAgICAgY29uc29sZS5sb2coJ0luaXRpYWwgdmFsdWU6JywgaW5pdGlhbFN0YXRlLnRvU3RyaW5nKCkpOwoKICAgICAgICAgICAgLy8gVW5wYWNrIHRvIGdyaWQKICAgICAgICAgICAgY29uc3QgdW5wYWNrZWQgPSB1bnBhY2tCaWdJbnRUb0dyaWQoaW5pdGlhbFN0YXRlKTsKICAgICAgICAgICAgY29uc29sZS5sb2coJ1VucGFja2VkIGdyaWQ6JywgdW5wYWNrZWQpOwoKICAgICAgICAgICAgLy8gUGFjayBiYWNrIHRoZSBncmlkCiAgICAgICAgICAgIGNvbnN0IHBhY2tlZCA9IHBhY2tHcmlkVG9CaWdJbnQodW5wYWNrZWQpOwogICAgICAgICAgICBjb25zb2xlLmxvZygnUGFja2VkIHZhbHVlOicsIHBhY2tlZC50b1N0cmluZygpKTsKCiAgICAgICAgICAgIC8vIFN0YXJ0IHRoZSBpbmZpbml0ZSBhbmltYXRpb24KICAgICAgICAgICAgaW5maW5pdGVEaXNwbGF5TG9vcChpbml0aWFsU3RhdGUpOwogICAgICAgIH0KCiAgICAgICAgLy8gU3RhcnQgdGhlIGdhbWUKICAgICAgICBydW4oKTs='> </script> </body> </html>",
                );
            let mut json: ByteArray = "{\"name\": \"Arborithm #";
            json.append(@format!("{}\",", token_id));
            json.append(@"\"description\": \"\",");
            json.append(@"\"image\":\"data:text/html,");
            json.append(@animation);
            // TODO: add base64 encode image
            json.append(@"\",");
            json.append(@"\"animation_url\":\"data:text/html,");
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
