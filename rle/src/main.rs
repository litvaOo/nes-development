use std::env;
use std::fs::File;
use std::io::{Read, Write};
use std::path::Path;

fn main() -> std::io::Result<()> {
    let args: Vec<String> = env::args().collect();
    let mut file = File::open(&args[1])?;
    let mut buffer: Vec<u8> = vec![];
    file.read_to_end(&mut buffer).unwrap();
    let buffer_length = buffer.len();
    let mut output_buffer: Vec<u8> = vec![];
    let mut current_counter: u8 = 0;
    let mut current_byte: u8 = buffer[0];
    for byte in buffer {
        if current_byte == byte && current_byte != 255 {
            current_counter += 1;
        } else {
            output_buffer.push(current_counter);
            output_buffer.push(current_byte);
            current_counter = 1;
            current_byte = byte;
        }
    }
    output_buffer.push(current_counter);
    output_buffer.push(current_byte);
    output_buffer.push(00);
    let output_file_name = Path::new(&args[1]).with_extension("rle");
    let mut output_file = File::create(output_file_name)?;
    output_file.write_all(&output_buffer)?;
    println!(
        "Compressed {} bytes to {}",
        buffer_length,
        output_buffer.len()
    );
    Ok(())
}
