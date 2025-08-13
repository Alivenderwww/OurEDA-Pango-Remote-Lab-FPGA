#!/usr/bin/env python3
"""
JPEG core output to JPG file conversion script
Convert JPEG encoder core 32-bit hex data to complete JPEG file
Author: AI Assistant
"""

import argparse
import os
import struct
from typing import List, Tuple

# JPEG文件头模板 (与参考JPEG文件完全匹配)
JPEG_HEADER_TEMPLATE = [
    # SOI (Start of Image)
    0xFF, 0xD8,
    
    # APP0 段
    0xFF, 0xE0,  # APP0 marker
    0x00, 0x10,  # Length (16 bytes)
    0x4A, 0x46, 0x49, 0x46, 0x00,  # "JFIF\0"
    0x01, 0x01,  # Version 1.1
    0x00,        # Units: 0 = no units
    0x00, 0x01,  # X density (1)
    0x00, 0x01,  # Y density (1)
    0x00,        # Thumbnail width
    0x00,        # Thumbnail height
    
    # DQT (Define Quantization Table) - Y table (standard JPEG)
    0xFF, 0xDB,  # DQT marker
    0x00, 0x43,  # Length (67 bytes)
    0x00,        # Table ID (0 = Y table)
    # Standard JPEG Y quantization table
    6, 4, 5, 6, 5, 4, 6, 6,
    5, 6, 7, 7, 6, 8, 10, 16,
    10, 10, 9, 9, 10, 20, 14, 15,
    12, 16, 23, 20, 24, 24, 23, 20,
    22, 22, 26, 29, 37, 31, 26, 27,
    35, 28, 22, 22, 32, 44, 32, 35,
    38, 39, 41, 42, 41, 25, 31, 45,
    48, 45, 40, 48, 37, 40, 41, 40,
    
    # DQT (Define Quantization Table) - CbCr table (standard JPEG)
    0xFF, 0xDB,  # DQT marker
    0x00, 0x43,  # Length (67 bytes)
    0x01,        # Table ID (1 = CbCr table)
    # Standard JPEG CbCr quantization table
    7, 7, 7, 10, 8, 10, 19, 10,
    10, 19, 40, 26, 22, 26, 40, 40,
    40, 40, 40, 40, 40, 40, 40, 40,
    40, 40, 40, 40, 40, 40, 40, 40,
    40, 40, 40, 40, 40, 40, 40, 40,
    40, 40, 40, 40, 40, 40, 40, 40,
    40, 40, 40, 40, 40, 40, 40, 40,
    40, 40, 40, 40, 40, 40, 40, 40,
    
    # SOF0 (Start of Frame)
    0xFF, 0xC0,  # SOF0 marker
    0x00, 0x11,  # Length (17 bytes)
    0x08,        # Precision (8 bits)
    # Height and width will be filled in later
    0x00, 0x00,  # Height (placeholder)
    0x00, 0x00,  # Width (placeholder)
    0x03,        # Number of components
    0x01, 0x11, 0x00,  # Y component
    0x02, 0x11, 0x01,  # Cb component
    0x03, 0x11, 0x01,  # Cr component
    
    # DHT (Define Huffman Table) - DC Y table
    0xFF, 0xC4,  # DHT marker
    0x00, 0x1F,  # Length
    0x00,        # Table class and ID (DC table 0)
    # DC Y Huffman table (matches reference)
    0x00, 0x03, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B,
    
    # DHT (Define Huffman Table) - AC Y table
    0xFF, 0xC4,  # DHT marker
    0x00, 0xB5,  # Length
    0x10,        # Table class and ID (AC table 0)
    # AC Y Huffman table (simplified)
    0x00, 0x02, 0x01, 0x03, 0x03, 0x02, 0x04, 0x03, 0x05, 0x05, 0x04, 0x04, 0x00, 0x00, 0x01, 0x7D,
    0x01, 0x02, 0x03, 0x00, 0x04, 0x11, 0x05, 0x12, 0x21, 0x31, 0x41, 0x06, 0x13, 0x51, 0x61, 0x07,
    0x22, 0x71, 0x14, 0x32, 0x81, 0x91, 0xA1, 0x08, 0x23, 0x42, 0xB1, 0xC1, 0x15, 0x52, 0xD1, 0xF0,
    0x24, 0x33, 0x62, 0x72, 0x82, 0x09, 0x0A, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x25, 0x26, 0x27, 0x28,
    0x29, 0x2A, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49,
    0x4A, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5A, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69,
    0x6A, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7A, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89,
    0x8A, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9A, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6, 0xA7,
    0xA8, 0xA9, 0xAA, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6, 0xB7, 0xB8, 0xB9, 0xBA, 0xC2, 0xC3, 0xC4, 0xC5,
    0xC6, 0xC7, 0xC8, 0xC9, 0xCA, 0xD2, 0xD3, 0xD4, 0xD5, 0xD6, 0xD7, 0xD8, 0xD9, 0xDA, 0xE1, 0xE2,
    0xE3, 0xE4, 0xE5, 0xE6, 0xE7, 0xE8, 0xE9, 0xEA, 0xF1, 0xF2, 0xF3, 0xF4, 0xF5, 0xF6, 0xF7, 0xF8,
    0xF9, 0xFA,
    
    # DHT (Define Huffman Table) - DC CbCr table
    0xFF, 0xC4,  # DHT marker
    0x00, 0x1F,  # Length
    0x01,        # Table class and ID (DC table 1)
    # DC CbCr Huffman table
    0x00, 0x03, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B,
    
    # DHT (Define Huffman Table) - AC CbCr table
    0xFF, 0xC4,  # DHT marker
    0x00, 0xB5,  # Length
    0x11,        # Table class and ID (AC table 1)
    # AC CbCr Huffman table (matches reference)
    0x00, 0x02, 0x01, 0x03, 0x03, 0x02, 0x04, 0x03, 0x05, 0x05, 0x04, 0x04, 0x00, 0x00, 0x01, 0x7D,
    0x01, 0x02, 0x03, 0x00, 0x04, 0x11, 0x05, 0x12, 0x21, 0x31, 0x41, 0x06, 0x13, 0x51, 0x61, 0x07,
    0x22, 0x71, 0x14, 0x32, 0x81, 0x91, 0xA1, 0x08, 0x23, 0x42, 0xB1, 0xC1, 0x15, 0x52, 0xD1, 0xF0,
    0x24, 0x33, 0x62, 0x72, 0x82, 0x09, 0x0A, 0x16, 0x17, 0x18, 0x19, 0x1A, 0x25, 0x26, 0x27, 0x28,
    0x29, 0x2A, 0x34, 0x35, 0x36, 0x37, 0x38, 0x39, 0x3A, 0x43, 0x44, 0x45, 0x46, 0x47, 0x48, 0x49,
    0x4A, 0x53, 0x54, 0x55, 0x56, 0x57, 0x58, 0x59, 0x5A, 0x63, 0x64, 0x65, 0x66, 0x67, 0x68, 0x69,
    0x6A, 0x73, 0x74, 0x75, 0x76, 0x77, 0x78, 0x79, 0x7A, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89,
    0x8A, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9A, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6, 0xA7,
    0xA8, 0xA9, 0xAA, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6, 0xB7, 0xB8, 0xB9, 0xBA, 0xC2, 0xC3, 0xC4, 0xC5,
    0xC6, 0xC7, 0xC8, 0xC9, 0xCA, 0xD2, 0xD3, 0xD4, 0xD5, 0xD6, 0xD7, 0xD8, 0xD9, 0xDA, 0xE1, 0xE2,
    0xE3, 0xE4, 0xE5, 0xE6, 0xE7, 0xE8, 0xE9, 0xEA, 0xF1, 0xF2, 0xF3, 0xF4, 0xF5, 0xF6, 0xF7, 0xF8,
    0xF9, 0xFA,
    
    # SOS (Start of Scan)
    0xFF, 0xDA,  # SOS marker
    0x00, 0x0C,  # Length (12 bytes)
    0x03,        # Number of components
    0x01, 0x00,  # Y component, DC/AC table
    0x02, 0x11,  # Cb component, DC/AC table
    0x03, 0x11,  # Cr component, DC/AC table
    0x00, 0x3F, 0x00,  # Start of spectral, End of spectral, Ah/Al
]

def parse_jpeg_output_file(filename: str) -> List[int]:
    """
    Parse JPEG encoder output file and extract 32-bit hex data
    Args:
        filename: Output file path
    Returns:
        hex_data: List of 32-bit integers
    """
    hex_data = []
    last_valid_bits = None
    
    try:
        with open(filename, 'r') as f:
            lines = f.readlines()
            
        for i, line in enumerate(lines):
            line = line.strip()
            
            # Check for valid bits comment
            if line.startswith('// Valid bits in above data:'):
                try:
                    last_valid_bits = int(line.split(':')[1].strip())
                    print(f"Found partial data info: last value has {last_valid_bits} valid bits")
                except:
                    pass
                continue
                
            # Skip other empty lines and comments
            if not line or line.startswith('//') or line.startswith('#'):
                continue
                
            # Find hex data (8-digit hexadecimal numbers)
            if len(line) == 8 and all(c in '0123456789abcdefABCDEF' for c in line):
                try:
                    value = int(line, 16)
                    hex_data.append(value)
                except ValueError:
                    continue
        
        # Handle partial data processing
        if last_valid_bits is not None and len(hex_data) > 0:
            last_value = hex_data[-1]
            # For partial data, we need to shift right to remove invalid bits
            # For example, if only 13 bits are valid out of 32, we need to shift by (32-13=19) bits
            shift_amount = 32 - last_valid_bits
            if shift_amount > 0:
                # Shift right to remove invalid low bits, then shift left to restore position
                valid_part = (last_value >> shift_amount) << shift_amount
                hex_data[-1] = valid_part
                print(f"Processed partial data: original={last_value:08x}, valid_bits={last_valid_bits}, processed={valid_part:08x}")
        
        print(f"Parsed {len(hex_data)} 32-bit hex values from file")
        return hex_data
        
    except FileNotFoundError:
        print(f"Error: Cannot find file {filename}")
        return []
    except Exception as e:
        print(f"Error parsing file: {e}")
        return []

def create_jpeg_header(width: int, height: int) -> bytes:
    """
    Create JPEG file header
    Args:
        width: Image width
        height: Image height
    Returns:
        header_bytes: JPEG header byte array
    """
    header = JPEG_HEADER_TEMPLATE.copy()
    
    # Find SOF0 marker position and update dimensions
    sof0_pos = None
    for i in range(len(header) - 1):
        if header[i] == 0xFF and header[i + 1] == 0xC0:
            sof0_pos = i
            break
    
    if sof0_pos is not None:
        # SOF0 format: FF C0 [length] [precision] [height] [width] ...
        height_pos = sof0_pos + 5  # FF C0 00 11 08 [height_high] [height_low]
        width_pos = sof0_pos + 7   # [width_high] [width_low]
        
        header[height_pos] = (height >> 8) & 0xFF
        header[height_pos + 1] = height & 0xFF
        header[width_pos] = (width >> 8) & 0xFF
        header[width_pos + 1] = width & 0xFF
    
    return bytes(header)

def convert_32bit_to_bytes(hex_values: List[int]) -> bytes:
    """
    Convert 32-bit hex values to byte array
    Args:
        hex_values: List of 32-bit integers
    Returns:
        byte_data: Byte array
    """
    byte_data = bytearray()
    
    for value in hex_values:
        # Convert 32-bit value to 4 bytes (big endian)
        byte_data.extend(struct.pack('>I', value))
    
    return bytes(byte_data)

def create_jpeg_file(hex_data: List[int], width: int, height: int, output_file: str):
    """
    Create complete JPEG file
    Args:
        hex_data: 32-bit hex data from JPEG encoder core output
        width: Image width
        height: Image height
        output_file: Output JPEG file path
    """
    try:
        # Create JPEG header
        header = create_jpeg_header(width, height)
        
        # Convert core data to bytes
        jpeg_data = convert_32bit_to_bytes(hex_data)
        
        # Add end of scan marker
        end_marker = bytes([0xFF, 0xD9])
        
        # Write complete JPEG file
        with open(output_file, 'wb') as f:
            f.write(header)
            f.write(jpeg_data)
            f.write(end_marker)
        
        print(f"Successfully created JPEG file: {output_file}")
        print(f"File size: {len(header) + len(jpeg_data) + len(end_marker)} bytes")
        print(f"  Header: {len(header)} bytes")
        print(f"  Data: {len(jpeg_data)} bytes")
        print(f"  End marker: {len(end_marker)} bytes")
        
    except Exception as e:
        print(f"Error creating JPEG file: {e}")

def parse_simulation_log(log_file: str) -> List[int]:
    """
    Parse simulation log file and extract JPEG data
    Args:
        log_file: ModelSim or other simulator log file
    Returns:
        hex_data: List of extracted 32-bit hex data
    """
    hex_data = []
    
    try:
        with open(log_file, 'r') as f:
            for line in f:
                line = line.strip()
                
                # Find lines like "# 12345678" or "12345678"
                # Remove possible prefix characters
                clean_line = line.lstrip('# \t')
                
                # Check if it's 8-digit hex number
                if len(clean_line) == 8 and all(c in '0123456789abcdefABCDEF' for c in clean_line):
                    try:
                        value = int(clean_line, 16)
                        hex_data.append(value)
                    except ValueError:
                        continue
        
        print(f"Extracted {len(hex_data)} 32-bit hex values from simulation log")
        return hex_data
        
    except Exception as e:
        print(f"Error parsing simulation log: {e}")
        return []

def main():
    parser = argparse.ArgumentParser(description='Convert JPEG encoder core output to JPEG file')
    parser.add_argument('input_file', help='JPEG encoder output file or simulation log file')
    parser.add_argument('-w', '--width', type=int, required=True, help='Image width')
    parser.add_argument('--height', type=int, required=True, help='Image height')
    parser.add_argument('-o', '--output', help='Output JPEG file path', default=None)
    parser.add_argument('--log-format', action='store_true', 
                       help='Input file is simulation log format (with # prefix etc)')
    
    args = parser.parse_args()
    
    # Determine output filename
    if args.output is None:
        base_name = os.path.splitext(args.input_file)[0]
        output_file = f"{base_name}_output.jpg"
    else:
        output_file = args.output
    
    # Parse input file
    if args.log_format:
        hex_data = parse_simulation_log(args.input_file)
    else:
        hex_data = parse_jpeg_output_file(args.input_file)
    
    if not hex_data:
        print("Error: Failed to extract valid hex data from input file")
        return
    
    # Create JPEG file
    create_jpeg_file(hex_data, args.width, args.height, output_file)
    
    print(f"\nConversion completed:")
    print(f"  Input file: {args.input_file}")
    print(f"  Output file: {output_file}")
    print(f"  Image size: {args.width}x{args.height}")
    print(f"  Data blocks: {len(hex_data)}")

if __name__ == "__main__":
    main()
