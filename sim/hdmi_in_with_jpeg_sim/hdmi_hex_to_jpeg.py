#!/usr/bin/env python3
"""
HDMI JPEG Simulation Output Converter
Convert HDMI-JPEG simulation hex output files to viewable JPEG images
适用于hdmi_in_with_jpeg_sim仿真输出的转换脚本
Enhanced with proper JPEG table management and zigzag ordering
Author: AI Assistant
"""

import argparse
import os
import struct
from typing import List, Tuple, Dict

class JPEGHeaderBuilder:
    """JPEG头部构建器 - 基于jpeg_tables_manager.py的逻辑"""
    
    # 标准JPEG zigzag扫描顺序
    ZIGZAG_ORDER = [
        0,  1,  8, 16,  9,  2,  3, 10,
       17, 24, 32, 25, 18, 11,  4,  5,
       12, 19, 26, 33, 40, 48, 41, 34,
       27, 20, 13,  6,  7, 14, 21, 28,
       35, 42, 49, 56, 57, 50, 43, 36,
       29, 22, 15, 23, 30, 37, 44, 51,
       58, 59, 52, 45, 38, 31, 39, 46,
       53, 60, 61, 54, 47, 55, 62, 63
    ]
    
    # 标准JPEG Y量化表 (亮度) - 8x8格式
    STANDARD_Y_QUANT_TABLE = [
        [16, 11, 10, 16, 24, 40, 51, 61],
        [12, 12, 14, 19, 26, 58, 60, 55],
        [14, 13, 16, 24, 40, 57, 69, 56],
        [14, 17, 22, 29, 51, 87, 80, 62],
        [18, 22, 37, 56, 68, 109, 103, 77],
        [24, 35, 55, 64, 81, 104, 113, 92],
        [49, 64, 78, 87, 103, 121, 120, 101],
        [72, 92, 95, 98, 112, 100, 103, 99]
    ]
    
    # 标准JPEG CbCr量化表 (色度) - 8x8格式
    STANDARD_CBCR_QUANT_TABLE = [
        [17, 18, 24, 47, 99, 99, 99, 99],
        [18, 21, 26, 66, 99, 99, 99, 99],
        [24, 26, 56, 99, 99, 99, 99, 99],
        [47, 66, 99, 99, 99, 99, 99, 99],
        [99, 99, 99, 99, 99, 99, 99, 99],
        [99, 99, 99, 99, 99, 99, 99, 99],
        [99, 99, 99, 99, 99, 99, 99, 99],
        [99, 99, 99, 99, 99, 99, 99, 99]
    ]
    
    # 标准DC哈夫曼表 (Y分量)
    STANDARD_DC_Y_HUFFMAN = {
        'bits': [0x00, 0x01, 0x05, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00],
        'values': [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B]
    }
    
    # 标准AC哈夫曼表 (Y分量)
    STANDARD_AC_Y_HUFFMAN = {
        'bits': [0x00, 0x02, 0x01, 0x03, 0x03, 0x02, 0x04, 0x03, 0x05, 0x05, 0x04, 0x04, 0x00, 0x00, 0x01, 0x7D],
        'values': [
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
            0xF9, 0xFA
        ]
    }
    
    # 标准DC哈夫曼表 (CbCr分量)
    STANDARD_DC_CBCR_HUFFMAN = {
        'bits': [0x00, 0x01, 0x05, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00],
        'values': [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B]
    }
    
    # 标准AC哈夫曼表 (CbCr分量, 与Y分量相同)
    STANDARD_AC_CBCR_HUFFMAN = STANDARD_AC_Y_HUFFMAN
    
    def __init__(self, quality_factor: int = 50):
        """
        初始化JPEG头部构建器
        Args:
            quality_factor: JPEG质量因子 (1-100), 50为标准质量
        """
        self.quality_factor = quality_factor
        self.y_quant_table = self.create_custom_table("y", quality_factor)
        self.cbcr_quant_table = self.create_custom_table("cbcr", quality_factor)
    
    def create_custom_table(self, base_table: str, quality_factor: int) -> List[List[int]]:
        """根据质量因子创建自定义量化表 - 与jpeg_tables_manager.py完全一致的算法"""
        if base_table == "y":
            base = self.STANDARD_Y_QUANT_TABLE
        elif base_table == "cbcr":
            base = self.STANDARD_CBCR_QUANT_TABLE
        else:
            base = self.STANDARD_Y_QUANT_TABLE
        
        # 根据质量因子调整表值 - 与jpeg_tables_manager.py完全一致
        if quality_factor < 1:
            quality_factor = 1
        elif quality_factor > 100:
            quality_factor = 100
        
        if quality_factor < 50:
            scale = 5000 / quality_factor
        else:
            scale = 200 - 2 * quality_factor
        
        custom_table = []
        for row in base:
            custom_row = []
            for val in row:
                scaled_val = int((val * scale + 50) / 100)
                if scaled_val < 1:
                    scaled_val = 1
                elif scaled_val > 255:
                    scaled_val = 255
                custom_row.append(scaled_val)
            custom_table.append(custom_row)
        
        return custom_table
    
    def flatten_table(self, table: List[List[int]]) -> List[int]:
        """将8x8表展平为64元素列表"""
        flattened = []
        for row in table:
            flattened.extend(row)
        return flattened
    
    def apply_zigzag_order(self, table: List[List[int]]) -> List[int]:
        """将8x8表按zigzag顺序重新排列"""
        flattened = self.flatten_table(table)
        return [flattened[i] for i in self.ZIGZAG_ORDER]
    
    def create_dqt_segment(self, table_id: int, table: List[List[int]]) -> List[int]:
        """创建DQT (Define Quantization Table) 段"""
        zigzag_table = self.apply_zigzag_order(table)
        
        dqt_segment = [
            0xFF, 0xDB,  # DQT marker
            0x00, 0x43,  # Length (67 bytes)
            table_id     # Table ID (0=Y, 1=CbCr)
        ]
        dqt_segment.extend(zigzag_table)
        
        return dqt_segment
    
    def create_dht_segment(self, table_class: int, table_id: int, huffman_table: Dict) -> List[int]:
        """创建DHT (Define Huffman Table) 段"""
        bits = huffman_table['bits']
        values = huffman_table['values']
        
        # 计算长度: 2 (marker) + 2 (length) + 1 (class/id) + 16 (bits) + len(values)
        length = 19 + len(values)
        
        dht_segment = [
            0xFF, 0xC4,  # DHT marker
            (length >> 8) & 0xFF, length & 0xFF,  # Length
            (table_class << 4) | table_id  # Table class (0=DC, 1=AC) and ID
        ]
        dht_segment.extend(bits)
        dht_segment.extend(values)
        
        return dht_segment
    
    def build_header(self, width: int, height: int) -> bytes:
        """构建完整的JPEG头部"""
        header = []
        
        # SOI (Start of Image)
        header.extend([0xFF, 0xD8])
        
        # APP0 段 (JFIF标识)
        header.extend([
            0xFF, 0xE0,  # APP0 marker
            0x00, 0x10,  # Length (16 bytes)
            0x4A, 0x46, 0x49, 0x46, 0x00,  # "JFIF\0"
            0x01, 0x01,  # Version 1.1
            0x00,        # Units: 0 = no units
            0x00, 0x01,  # X density (1)
            0x00, 0x01,  # Y density (1)
            0x00,        # Thumbnail width
            0x00         # Thumbnail height
        ])
        
        # DQT - Y量化表
        header.extend(self.create_dqt_segment(0, self.y_quant_table))
        
        # DQT - CbCr量化表
        header.extend(self.create_dqt_segment(1, self.cbcr_quant_table))
        
        # SOF0 (Start of Frame)
        header.extend([
            0xFF, 0xC0,  # SOF0 marker
            0x00, 0x11,  # Length (17 bytes)
            0x08,        # Precision (8 bits)
            (height >> 8) & 0xFF, height & 0xFF,  # Height
            (width >> 8) & 0xFF, width & 0xFF,    # Width
            0x03,        # Number of components
            0x01, 0x11, 0x00,  # Y component: ID=1, sampling=1:1, quant_table=0
            0x02, 0x11, 0x01,  # Cb component: ID=2, sampling=1:1, quant_table=1
            0x03, 0x11, 0x01   # Cr component: ID=3, sampling=1:1, quant_table=1
        ])
        
        # DHT - DC Y哈夫曼表
        header.extend(self.create_dht_segment(0, 0, self.STANDARD_DC_Y_HUFFMAN))
        
        # DHT - AC Y哈夫曼表
        header.extend(self.create_dht_segment(1, 0, self.STANDARD_AC_Y_HUFFMAN))
        
        # DHT - DC CbCr哈夫曼表
        header.extend(self.create_dht_segment(0, 1, self.STANDARD_DC_CBCR_HUFFMAN))
        
        # DHT - AC CbCr哈夫曼表
        header.extend(self.create_dht_segment(1, 1, self.STANDARD_AC_CBCR_HUFFMAN))
        
        # SOS (Start of Scan)
        header.extend([
            0xFF, 0xDA,  # SOS marker
            0x00, 0x0C,  # Length (12 bytes)
            0x03,        # Number of components
            0x01, 0x00,  # Y component, DC table 0, AC table 0
            0x02, 0x11,  # Cb component, DC table 1, AC table 1
            0x03, 0x11,  # Cr component, DC table 1, AC table 1
            0x00, 0x3F, 0x00  # Start of spectral, End of spectral, Ah/Al
        ])
        
        return bytes(header)

# JPEG文件头模板 (标准JPEG文件格式)
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
    
    # DQT (Define Quantization Table) - Y table (来自y_quantizer.v)
    0xFF, 0xDB,  # DQT marker
    0x00, 0x43,  # Length (67 bytes)
    0x00,        # Table ID (0 = Y table)
    # Y量化表 (与y_quantizer.v完全一致)
    2, 1, 1, 2, 2, 4, 5, 6,
    1, 1, 1, 2, 3, 6, 6, 6,
    1, 1, 2, 2, 4, 6, 7, 6,
    1, 2, 2, 3, 5, 9, 8, 6,
    2, 2, 4, 6, 7, 11, 10, 8,
    2, 4, 6, 6, 8, 10, 11, 9,
    5, 6, 8, 9, 10, 12, 12, 10,
    7, 9, 10, 10, 11, 10, 10, 10,
    
    # DQT (Define Quantization Table) - CbCr table (来自cb_quantizer.v和cr_quantizer.v)
    0xFF, 0xDB,  # DQT marker
    0x00, 0x43,  # Length (67 bytes)
    0x01,        # Table ID (1 = CbCr table)
    # CbCr量化表 (与cb_quantizer.v和cr_quantizer.v完全一致)
    2, 2, 2, 5, 10, 10, 10, 10,
    2, 2, 3, 7, 10, 10, 10, 10,
    2, 3, 6, 10, 10, 10, 10, 10,
    5, 7, 10, 10, 10, 10, 10, 10,
    10, 10, 10, 10, 10, 10, 10, 10,
    10, 10, 10, 10, 10, 10, 10, 10,
    10, 10, 10, 10, 10, 10, 10, 10,
    10, 10, 10, 10, 10, 10, 10, 10,
    
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
    # DC Y Huffman table (standard)
    0x00, 0x01, 0x05, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B,
    
    # DHT (Define Huffman Table) - AC Y table
    0xFF, 0xC4,  # DHT marker
    0x00, 0xB5,  # Length
    0x10,        # Table class and ID (AC table 0)
    # AC Y Huffman table (standard)
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
    0x00, 0x01, 0x05, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B,
    
    # DHT (Define Huffman Table) - AC CbCr table
    0xFF, 0xC4,  # DHT marker
    0x00, 0xB5,  # Length
    0x11,        # Table class and ID (AC table 1)
    # AC CbCr Huffman table
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

def parse_hdmi_hex_file(filename: str, handle_invalid: str = 'skip') -> List[int]:
    """
    解析HDMI仿真输出的hex文件
    Args:
        filename: hex文件路径
        handle_invalid: 处理无效数据的方式 ('skip', 'zero', 'stop')
    Returns:
        hex_data: 32位整数列表
    """
    hex_data = []
    invalid_count = 0
    
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            
        print(f"读取到 {len(lines)} 行数据")
            
        for i, line in enumerate(lines):
            line = line.strip()
            
            # 跳过空行和注释
            if not line or line.startswith('//') or line.startswith('#'):
                continue
                
            # 检查是否为8位十六进制数
            if len(line) == 8:
                if all(c in '0123456789abcdefABCDEF' for c in line):
                    try:
                        value = int(line, 16)
                        hex_data.append(value)
                        if i < 10:  # 显示前10个数据用于调试
                            print(f"Line {i+1}: {line} -> 0x{value:08x}")
                    except ValueError as e:
                        print(f"Warning: Invalid hex value at line {i+1}: {line}")
                        invalid_count += 1
                        continue
                elif line.lower() == 'xxxxxxxx':
                    # 处理 'xxxxxxxx' 这种无效数据
                    invalid_count += 1
                    if handle_invalid == 'skip':
                        if invalid_count == 1:
                            print(f"发现无效数据 'xxxxxxxx' 从第 {i+1} 行开始，跳过...")
                        continue
                    elif handle_invalid == 'zero':
                        hex_data.append(0)
                        if invalid_count == 1:
                            print(f"发现无效数据 'xxxxxxxx' 从第 {i+1} 行开始，替换为 0x00000000...")
                    elif handle_invalid == 'stop':
                        print(f"在第 {i+1} 行遇到无效数据 'xxxxxxxx'，停止解析")
                        break
                else:
                    print(f"Warning: Invalid format at line {i+1}: {line}")
                    invalid_count += 1
                    continue
            else:
                print(f"Warning: Wrong length at line {i+1}: {line} (length={len(line)})")
                invalid_count += 1
                continue
        
        print(f"成功解析 {len(hex_data)} 个32位十六进制值")
        if invalid_count > 0:
            print(f"跳过了 {invalid_count} 个无效数据行")
        return hex_data
        
    except FileNotFoundError:
        print(f"错误: 无法找到文件 {filename}")
        return []
    except Exception as e:
        print(f"解析文件时出错: {e}")
        return []

def create_jpeg_header(width: int, height: int, quality_factor: int = 50) -> bytes:
    """
    创建JPEG文件头 - 使用增强的JPEG头部构建器
    Args:
        width: 图像宽度
        height: 图像高度
        quality_factor: JPEG质量因子 (1-100), 50为标准质量
    Returns:
        header_bytes: JPEG头部字节数组
    """
    # 使用新的JPEG头部构建器
    builder = JPEGHeaderBuilder(quality_factor=quality_factor)
    header = builder.build_header(width, height)
    
    print(f"设置JPEG尺寸: {width}x{height}")
    print(f"质量因子: {quality_factor}")
    print(f"量化表按zigzag顺序排列")
    
    return header

def convert_32bit_to_bytes(hex_values: List[int]) -> bytes:
    """
    将32位十六进制值转换为字节数组
    Args:
        hex_values: 32位整数列表
    Returns:
        byte_data: 字节数组
    """
    byte_data = bytearray()
    
    for value in hex_values:
        # 将32位值转换为4个字节 (大端序)
        byte_data.extend(struct.pack('>I', value))
    
    return bytes(byte_data)

def create_jpeg_file(hex_data: List[int], width: int, height: int, output_file: str, quality_factor: int = 50):
    """
    创建完整的JPEG文件
    Args:
        hex_data: 来自HDMI JPEG仿真的32位数据
        width: 图像宽度
        height: 图像高度
        output_file: 输出JPEG文件路径
        quality_factor: JPEG质量因子 (1-100), 50为标准质量
    """
    try:
        # 创建JPEG头部
        header = create_jpeg_header(width, height, quality_factor)
        
        # 转换核心数据为字节
        jpeg_data = convert_32bit_to_bytes(hex_data)
        
        # 添加结束标记
        end_marker = bytes([0xFF, 0xD9])
        
        # 写入完整的JPEG文件
        with open(output_file, 'wb') as f:
            f.write(header)
            f.write(jpeg_data)
            f.write(end_marker)
        
        print(f"成功创建JPEG文件: {output_file}")
        print(f"文件大小: {len(header) + len(jpeg_data) + len(end_marker)} 字节")
        print(f"  头部: {len(header)} 字节")
        print(f"  数据: {len(jpeg_data)} 字节 ({len(hex_data)} 个32位字)")
        print(f"  结束标记: {len(end_marker)} 字节")
        
    except Exception as e:
        print(f"创建JPEG文件时出错: {e}")

def detect_image_dimensions(data_size: int) -> Tuple[int, int]:
    """
    根据数据大小推测图像尺寸
    Args:
        data_size: 数据字节数
    Returns:
        (width, height): 推测的图像尺寸
    """
    # 常见的图像尺寸
    common_sizes = [
        (320, 240),   # QVGA
        (640, 480),   # VGA
        (800, 600),   # SVGA
        (1024, 768),  # XGA
        (1280, 720),  # HD
        (1920, 1080), # Full HD
    ]
    
    # 估算每像素字节数（JPEG压缩后通常为0.1-2字节/像素）
    for width, height in common_sizes:
        pixels = width * height
        expected_size_min = pixels * 0.05  # 高压缩比
        expected_size_max = pixels * 3.0   # 低压缩比
        
        if expected_size_min <= data_size <= expected_size_max:
            print(f"推测图像尺寸: {width}x{height} (基于数据大小 {data_size} 字节)")
            return width, height
    
    # 如果没有匹配的标准尺寸，返回默认值
    print(f"无法推测图像尺寸，使用默认: 640x480 (数据大小: {data_size} 字节)")
    return 640, 480

def main():
    parser = argparse.ArgumentParser(
        description='将HDMI JPEG仿真输出的hex文件转换为JPEG图片 - 增强版',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
使用示例:
  # 转换jpeg_data_new.hex到JPEG图片，指定尺寸
  python hdmi_hex_to_jpeg.py output/jpeg_data_new.hex -w 640 --height 480
  
  # 自动检测输出目录中的最新hex文件
  python hdmi_hex_to_jpeg.py -a
  
  # 指定输出文件名
  python hdmi_hex_to_jpeg.py output/jpeg_data_new.hex -w 640 --height 480 -o result.jpg
  
  # 处理包含无效数据(xxxxxxxx)的文件
  python hdmi_hex_to_jpeg.py file.hex -w 640 --height 480 --invalid skip
  
  # 指定JPEG质量因子 (1-100)
  python hdmi_hex_to_jpeg.py file.hex -w 640 --height 480 -q 80
        """)
    
    parser.add_argument('input_file', nargs='?', help='输入的hex文件路径')
    parser.add_argument('-w', '--width', type=int, help='图像宽度')
    parser.add_argument('--height', type=int, help='图像高度')
    parser.add_argument('-o', '--output', help='输出JPEG文件路径')
    parser.add_argument('-a', '--auto', action='store_true', 
                       help='自动处理output目录中的hex文件')
    parser.add_argument('--invalid', choices=['skip', 'zero', 'stop'], default='skip',
                       help='处理无效数据(xxxxxxxx)的方式: skip=跳过, zero=替换为0, stop=停止解析')
    parser.add_argument('-q', '--quality', type=int, default=50, 
                       help='JPEG质量因子 (1-100), 默认50')
    
    args = parser.parse_args()
    
    # 自动模式：处理output目录中的文件
    if args.auto:
        output_dir = "output"
        if not os.path.exists(output_dir):
            print(f"错误: 输出目录 {output_dir} 不存在")
            return
        
        # 查找hex文件
        hex_files = [f for f in os.listdir(output_dir) if f.endswith('.hex') and 'jpeg' in f.lower()]
        
        if not hex_files:
            print(f"错误: 在 {output_dir} 目录中未找到JPEG hex文件")
            return
        
        # 使用最新修改的文件
        hex_files.sort(key=lambda x: os.path.getmtime(os.path.join(output_dir, x)), reverse=True)
        input_file = os.path.join(output_dir, hex_files[0])
        print(f"自动选择文件: {input_file}")
        
    elif args.input_file:
        input_file = args.input_file
    else:
        parser.print_help()
        return
    
    # 解析hex文件
    print(f"正在解析文件: {input_file}")
    print(f"无效数据处理方式: {args.invalid}")
    hex_data = parse_hdmi_hex_file(input_file, handle_invalid=args.invalid)
    
    if not hex_data:
        print("错误: 无法从输入文件中提取有效的hex数据")
        return
    
    # 验证质量因子范围
    if args.quality < 1 or args.quality > 100:
        print(f"错误: 质量因子必须在1-100范围内，当前值: {args.quality}")
        return
    
    # 确定图像尺寸
    if args.width and args.height:
        width, height = args.width, args.height
    else:
        data_size = len(hex_data) * 4  # 每个32位值4字节
        width, height = detect_image_dimensions(data_size)
        print(f"注意: 图像尺寸是推测值，如果输出图片不正确，请使用 -w 和 --height 参数指定正确的尺寸")
    
    # 确定输出文件名
    if args.output:
        output_file = args.output
    else:
        base_name = os.path.splitext(os.path.basename(input_file))[0]
        output_file = f"{base_name}_{width}x{height}_q{args.quality}.jpg"
    
    # 创建JPEG文件
    print(f"正在创建JPEG文件...")
    create_jpeg_file(hex_data, width, height, output_file, args.quality)
    
    print(f"\\n转换完成:")
    print(f"  输入文件: {input_file}")
    print(f"  输出文件: {output_file}")
    print(f"  图像尺寸: {width}x{height}")
    print(f"  质量因子: {args.quality}")
    print(f"  数据块数: {len(hex_data)}")
    print(f"\\n请使用图片查看器打开 {output_file} 查看结果")

if __name__ == "__main__":
    main()
