#!/usr/bin/env python3
"""
JPEG Tables Manager
Manages quantization tables and Huffman tables for JPEG encoder
Supports updating Verilog quantizer modules and Python JPEG header templates
Author: AI Assistant
"""

import os
import re
from typing import Dict, List, Tuple

class JPEGTablesManager:
    """管理JPEG量化表和哈夫曼表"""
    
    # 标准JPEG Y量化表 (亮度)
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
    
    # 标准JPEG CbCr量化表 (色度)
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
    
    # 简化的全1量化表 (用于测试)
    SIMPLE_QUANT_TABLE = [
        [1, 1, 1, 1, 1, 1, 1, 1],
        [1, 1, 1, 1, 1, 1, 1, 1],
        [1, 1, 1, 1, 1, 1, 1, 1],
        [1, 1, 1, 1, 1, 1, 1, 1],
        [1, 1, 1, 1, 1, 1, 1, 1],
        [1, 1, 1, 1, 1, 1, 1, 1],
        [1, 1, 1, 1, 1, 1, 1, 1],
        [1, 1, 1, 1, 1, 1, 1, 1]
    ]
    
    # 标准JPEG DC哈夫曼表 (Y分量)
    STANDARD_DC_Y_HUFFMAN = {
        'bits': [0x00, 0x03, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00],
        'values': [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B]
    }
    
    # 标准JPEG AC哈夫曼表 (Y分量)
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
    
    # 标准JPEG DC哈夫曼表 (CbCr分量)
    STANDARD_DC_CBCR_HUFFMAN = {
        'bits': [0x00, 0x03, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00],
        'values': [0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0A, 0x0B]
    }
    
    # 标准JPEG AC哈夫曼表 (CbCr分量, 与Y分量相同)
    STANDARD_AC_CBCR_HUFFMAN = STANDARD_AC_Y_HUFFMAN
    
    def __init__(self):
        """初始化表管理器"""
        self.current_y_table = self.STANDARD_Y_QUANT_TABLE
        self.current_cbcr_table = self.STANDARD_CBCR_QUANT_TABLE
        self.workspace_path = ""
    
    def set_workspace_path(self, path: str):
        """设置工作空间路径"""
        self.workspace_path = path
    
    def flatten_table(self, table: List[List[int]]) -> List[int]:
        """将8x8表展平为64元素列表"""
        flattened = []
        for row in table:
            flattened.extend(row)
        return flattened
    
    def format_table_for_verilog(self, table: List[List[int]]) -> Dict[str, int]:
        """将8x8表格式化为Verilog参数字典"""
        params = {}
        for i in range(8):
            for j in range(8):
                param_name = f"Q{i+1}_{j+1}"
                params[param_name] = table[i][j]
        return params
    
    def format_table_for_jpeg_header(self, table: List[List[int]]) -> List[int]:
        """将8x8表格式化为JPEG头部格式 (zigzag order)"""
        # 标准JPEG zigzag扫描顺序
        zigzag_order = [
            0,  1,  8, 16,  9,  2,  3, 10,
           17, 24, 32, 25, 18, 11,  4,  5,
           12, 19, 26, 33, 40, 48, 41, 34,
           27, 20, 13,  6,  7, 14, 21, 28,
           35, 42, 49, 56, 57, 50, 43, 36,
           29, 22, 15, 23, 30, 37, 44, 51,
           58, 59, 52, 45, 38, 31, 39, 46,
           53, 60, 61, 54, 47, 55, 62, 63
        ]
        
        flattened = self.flatten_table(table)
        zigzag_table = [flattened[i] for i in zigzag_order]
        return zigzag_table
    
    def update_verilog_quantizer(self, verilog_file: str, table: List[List[int]]) -> bool:
        """更新Verilog量化器文件中的参数"""
        try:
            if not os.path.exists(verilog_file):
                print(f"Error: Verilog file not found: {verilog_file}")
                return False
            
            # 读取文件
            with open(verilog_file, 'r') as f:
                content = f.read()
            
            # 格式化参数
            params = self.format_table_for_verilog(table)
            
            # 更新每个参数
            for param_name, value in params.items():
                pattern = rf'parameter\s+{param_name}\s*=\s*\d+\s*;'
                replacement = f'parameter {param_name}\t= {value};'
                content = re.sub(pattern, replacement, content)
            
            # 写回文件
            with open(verilog_file, 'w') as f:
                f.write(content)
            
            print(f"Successfully updated {verilog_file}")
            return True
            
        except Exception as e:
            print(f"Error updating Verilog file {verilog_file}: {e}")
            return False
    
    def update_python_jpeg_header(self, python_file: str, y_table: List[List[int]], cbcr_table: List[List[int]]) -> bool:
        """更新Python文件中的JPEG头部量化表"""
        try:
            if not os.path.exists(python_file):
                print(f"Error: Python file not found: {python_file}")
                return False
            
            # 读取文件
            with open(python_file, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            
            # 格式化Y量化表 (zigzag order)
            y_zigzag = self.format_table_for_jpeg_header(y_table)
            y_table_lines = []
            for i in range(0, 64, 8):
                row = ", ".join(str(x) for x in y_zigzag[i:i+8])
                if i < 56:  # 不是最后一行
                    y_table_lines.append(f"    {row},\n")
                else:  # 最后一行不加逗号
                    y_table_lines.append(f"    {row},\n")
            
            # 格式化CbCr量化表 (zigzag order)
            cbcr_zigzag = self.format_table_for_jpeg_header(cbcr_table)
            cbcr_table_lines = []
            for i in range(0, 64, 8):
                row = ", ".join(str(x) for x in cbcr_zigzag[i:i+8])
                if i < 56:  # 不是最后一行
                    cbcr_table_lines.append(f"    {row},\n")
                else:  # 最后一行不加逗号
                    cbcr_table_lines.append(f"    {row},\n")
            
            # 找到并替换Y量化表
            in_y_table = False
            y_start_idx = -1
            y_end_idx = -1
            
            for i, line in enumerate(lines):
                if "# Standard JPEG Y quantization table" in line:
                    in_y_table = True
                    y_start_idx = i + 1
                elif in_y_table and ("# DQT (Define Quantization Table) - CbCr table" in line or "# Standard JPEG CbCr quantization table" in line):
                    y_end_idx = i - 1
                    break
            
            if y_start_idx >= 0 and y_end_idx >= 0:
                # 删除旧的Y量化表数据
                del lines[y_start_idx:y_end_idx]
                # 插入新的Y量化表数据
                for j, new_line in enumerate(y_table_lines):
                    lines.insert(y_start_idx + j, new_line)
            
            # 重新读取更新后的行（因为索引已变化）
            # 找到并替换CbCr量化表
            in_cbcr_table = False
            cbcr_start_idx = -1
            cbcr_end_idx = -1
            
            for i, line in enumerate(lines):
                if "# Standard JPEG CbCr quantization table" in line:
                    in_cbcr_table = True
                    cbcr_start_idx = i + 1
                elif in_cbcr_table and "# SOF0 (Start of Frame)" in line:
                    cbcr_end_idx = i - 1
                    break
            
            if cbcr_start_idx >= 0 and cbcr_end_idx >= 0:
                # 删除旧的CbCr量化表数据
                del lines[cbcr_start_idx:cbcr_end_idx]
                # 插入新的CbCr量化表数据
                for j, new_line in enumerate(cbcr_table_lines):
                    lines.insert(cbcr_start_idx + j, new_line)
            
            # 写回文件
            with open(python_file, 'w', encoding='utf-8') as f:
                f.writelines(lines)
            
            print(f"Successfully updated {python_file}")
            return True
            
        except Exception as e:
            print(f"Error updating Python file {python_file}: {e}")
            return False
    
    def apply_quantization_tables(self, quality_factor: int = 50) -> bool:
        """应用基于质量因子的量化表到所有相关文件"""
        success = True
        
        if quality_factor < 1:
            quality_factor = 1
        elif quality_factor > 100:
            quality_factor = 100
        
        print(f"Applying quantization tables with quality factor {quality_factor}...")
        
        # 生成基于质量因子的量化表
        y_table = self.create_custom_table("y", quality_factor)
        cbcr_table = self.create_custom_table("cbcr", quality_factor)
        
        # 更新当前表
        self.current_y_table = y_table
        self.current_cbcr_table = cbcr_table
        
        # 定义文件路径 - 量化器文件在 jpeg_encoder 目录中
        if self.workspace_path:
            # 如果设置了工作路径，通常是从外部调用，使用绝对路径
            if os.path.isabs(self.workspace_path):
                # 工作路径是绝对路径，假设结构是 .../Pangu/...
                pangu_root = self.workspace_path
                while pangu_root and os.path.basename(pangu_root).lower() != 'pangu':
                    pangu_root = os.path.dirname(pangu_root)
                if pangu_root:
                    jpeg_encoder_path = os.path.join(pangu_root, "JPEG", "jpeg_encoder")
                    sim_path = os.path.join(pangu_root, "JPEG", "sim")
                else:
                    # 备用：假设当前目录在 Pangu 下
                    jpeg_encoder_path = os.path.join(self.workspace_path, "JPEG", "jpeg_encoder")
                    sim_path = os.path.join(self.workspace_path, "JPEG", "sim")
            else:
                # 相对路径，假设它是相对于 sim 目录
                jpeg_encoder_path = os.path.join(os.path.dirname(self.workspace_path), "jpeg_encoder")
                sim_path = self.workspace_path
        else:
            # 获取当前脚本目录，假设它在 sim 目录中
            script_dir = os.path.dirname(os.path.abspath(__file__))
            jpeg_encoder_path = os.path.join(os.path.dirname(script_dir), "jpeg_encoder")
            sim_path = script_dir
            
        y_quantizer_file = os.path.join(jpeg_encoder_path, "y_quantizer.v")
        cb_quantizer_file = os.path.join(jpeg_encoder_path, "cb_quantizer.v")
        cr_quantizer_file = os.path.join(jpeg_encoder_path, "cr_quantizer.v")
        jpeg_core_file = os.path.join(sim_path, "jpeg_core_to_jpg.py")
        
        # 更新Verilog文件
        if not self.update_verilog_quantizer(y_quantizer_file, y_table):
            success = False
        if not self.update_verilog_quantizer(cb_quantizer_file, cbcr_table):
            success = False
        if not self.update_verilog_quantizer(cr_quantizer_file, cbcr_table):
            success = False
        
        # 更新Python JPEG头部文件
        if not self.update_python_jpeg_header(jpeg_core_file, y_table, cbcr_table):
            success = False
        
        return success
    
    def create_custom_table(self, base_table: str, quality_factor: int) -> List[List[int]]:
        """根据质量因子创建自定义量化表"""
        if base_table == "y":
            base = self.STANDARD_Y_QUANT_TABLE
        elif base_table == "cbcr":
            base = self.STANDARD_CBCR_QUANT_TABLE
        else:
            base = self.SIMPLE_QUANT_TABLE
        
        # 根据质量因子调整表值
        # 质量因子: 1-100, 50为标准质量
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
    
    def print_table(self, table: List[List[int]], title: str = "Table"):
        """打印量化表"""
        print(f"\n{title}:")
        for row in table:
            print("  " + " ".join(f"{val:3d}" for val in row))
        print()
    
    def get_huffman_header_data(self) -> Dict:
        """获取哈夫曼表的头部数据"""
        return {
            'dc_y': self.STANDARD_DC_Y_HUFFMAN,
            'ac_y': self.STANDARD_AC_Y_HUFFMAN,
            'dc_cbcr': self.STANDARD_DC_CBCR_HUFFMAN,
            'ac_cbcr': self.STANDARD_AC_CBCR_HUFFMAN
        }


def main():
    """测试函数"""
    manager = JPEGTablesManager()
    manager.set_workspace_path(r"c:\_Project\Pi_FPGA\jpeg_encoder")
    
    print("JPEG Tables Manager Test")
    print("=" * 40)
    
    # 打印当前表
    manager.print_table(manager.STANDARD_Y_QUANT_TABLE, "Standard Y Quantization Table")
    manager.print_table(manager.STANDARD_CBCR_QUANT_TABLE, "Standard CbCr Quantization Table")
    
    # 应用标准量化表
    print("Applying standard quantization tables...")
    if manager.apply_quantization_tables("standard"):
        print("✅ Successfully applied standard tables")
    else:
        print("❌ Failed to apply standard tables")
    
    # 创建自定义表 (质量因子75)
    custom_y = manager.create_custom_table("y", 75)
    custom_cbcr = manager.create_custom_table("cbcr", 75)
    manager.print_table(custom_y, "Custom Y Table (Quality 75)")
    manager.print_table(custom_cbcr, "Custom CbCr Table (Quality 75)")


if __name__ == "__main__":
    main()
