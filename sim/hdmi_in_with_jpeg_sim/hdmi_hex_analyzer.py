#!/usr/bin/env python3
"""
HDMI Hex Data Analyzer
分析HDMI仿真输出的hex数据，提供数据统计和格式检查
"""

import os
import argparse
from collections import Counter

def analyze_hex_file(filename: str):
    """分析hex文件内容"""
    if not os.path.exists(filename):
        print(f"错误: 文件 {filename} 不存在")
        return
    
    print(f"分析文件: {filename}")
    print("=" * 50)
    
    try:
        with open(filename, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        total_lines = len(lines)
        valid_hex_lines = 0
        hex_values = []
        line_lengths = Counter()
        
        print(f"总行数: {total_lines}")
        
        for i, line in enumerate(lines):
            line = line.strip()
            line_lengths[len(line)] += 1
            
            # 检查是否为有效的8位十六进制
            if len(line) == 8 and all(c in '0123456789abcdefABCDEF' for c in line):
                valid_hex_lines += 1
                try:
                    value = int(line, 16)
                    hex_values.append(value)
                except ValueError:
                    pass
        
        print(f"有效的32位hex行数: {valid_hex_lines}")
        print(f"解析成功的hex值数量: {len(hex_values)}")
        
        if hex_values:
            total_bytes = len(hex_values) * 4
            print(f"总数据量: {total_bytes} 字节 ({total_bytes/1024:.2f} KB)")
            
            # 显示前几个和后几个值
            print(f"\\n前10个hex值:")
            for i in range(min(10, len(hex_values))):
                print(f"  [{i:3d}] 0x{hex_values[i]:08X}")
            
            if len(hex_values) > 10:
                print(f"\\n后5个hex值:")
                for i in range(max(10, len(hex_values)-5), len(hex_values)):
                    print(f"  [{i:3d}] 0x{hex_values[i]:08X}")
            
            # 统计分析
            print(f"\\n数据统计:")
            print(f"  最小值: 0x{min(hex_values):08X}")
            print(f"  最大值: 0x{max(hex_values):08X}")
            print(f"  平均值: 0x{sum(hex_values)//len(hex_values):08X}")
            
            # 检查是否有JPEG标记
            jpeg_markers = []
            for i, value in enumerate(hex_values):
                # JPEG标记通常以0xFF开头
                if (value >> 24) == 0xFF or (value >> 16) & 0xFF == 0xFF or (value >> 8) & 0xFF == 0xFF or value & 0xFF == 0xFF:
                    jpeg_markers.append((i, value))
            
            if jpeg_markers:
                print(f"\\n检测到可能的JPEG标记 ({len(jpeg_markers)}个):")
                for i, (pos, value) in enumerate(jpeg_markers[:10]):  # 显示前10个
                    print(f"  位置[{pos:3d}]: 0x{value:08X}")
                if len(jpeg_markers) > 10:
                    print(f"  ... 还有 {len(jpeg_markers)-10} 个标记")
        
        print(f"\\n行长度统计:")
        for length, count in sorted(line_lengths.items()):
            if length > 0:  # 跳过空行
                print(f"  {length}字符行: {count}行")
    
    except Exception as e:
        print(f"分析文件时出错: {e}")

def main():
    parser = argparse.ArgumentParser(description='分析HDMI仿真输出的hex数据文件')
    parser.add_argument('file', nargs='?', help='hex文件路径')
    parser.add_argument('-a', '--all', action='store_true', help='分析output目录中的所有hex文件')
    
    args = parser.parse_args()
    
    if args.all:
        output_dir = "output"
        if os.path.exists(output_dir):
            hex_files = [f for f in os.listdir(output_dir) if f.endswith('.hex')]
            if hex_files:
                for hex_file in sorted(hex_files):
                    analyze_hex_file(os.path.join(output_dir, hex_file))
                    print("\\n" + "="*70 + "\\n")
            else:
                print(f"在 {output_dir} 目录中未找到.hex文件")
        else:
            print(f"输出目录 {output_dir} 不存在")
    
    elif args.file:
        analyze_hex_file(args.file)
    
    else:
        # 默认分析output目录中的JPEG相关hex文件
        output_dir = "output"
        if os.path.exists(output_dir):
            hex_files = [f for f in os.listdir(output_dir) if f.endswith('.hex') and 'jpeg' in f.lower()]
            if hex_files:
                # 选择最新的文件
                latest_file = max(hex_files, key=lambda x: os.path.getmtime(os.path.join(output_dir, x)))
                analyze_hex_file(os.path.join(output_dir, latest_file))
            else:
                print("在output目录中未找到JPEG相关的hex文件")
                print("可用的hex文件:")
                all_hex = [f for f in os.listdir(output_dir) if f.endswith('.hex')]
                for f in all_hex:
                    print(f"  {f}")
        else:
            print("请指定hex文件路径或确保output目录存在")

if __name__ == "__main__":
    main()
