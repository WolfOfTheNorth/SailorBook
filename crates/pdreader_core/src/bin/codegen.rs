use flutter_rust_bridge_codegen::{
    config_parse, frb_codegen, get_symbols_if_no_duplicates, RawOpts,
};

const RUST_INPUT_PATH: &str = "src/lib.rs";
const DART_OUTPUT_PATH: &str = "../../apps/app_flutter/lib/generated/native.dart";

fn main() {
    let raw_opts = RawOpts {
        rust_input: vec![RUST_INPUT_PATH.to_string()],
        dart_output: vec![DART_OUTPUT_PATH.to_string()],
        dart_format_line_length: 80,
        ..Default::default()
    };

    let configs = config_parse(raw_opts);
    let all_symbols = get_symbols_if_no_duplicates(&configs).unwrap();
    
    for config in configs.iter() {
        frb_codegen(config, &all_symbols).unwrap();
    }
}