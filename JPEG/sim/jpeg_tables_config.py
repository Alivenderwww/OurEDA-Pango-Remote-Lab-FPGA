#!/usr/bin/env python3
"""
JPEG Quantization Tables Configuration Tool
Standalone tool for managing JPEG quantization tables
Author: AI Assistant
"""

import argparse
import os
import sys
from pathlib import Path

# Import the tables manager
try:
    from jpeg_tables_manager import JPEGTablesManager
except ImportError:
    print("Error: Cannot import jpeg_tables_manager.py")
    print("Please ensure jpeg_tables_manager.py is in the same directory")
    sys.exit(1)

def main():
    parser = argparse.ArgumentParser(description='JPEG量化表配置工具')
    
    # 基本参数
    parser.add_argument('--workspace', '-w', default='.', 
                       help='工作空间路径 (默认: 当前目录)')
    parser.add_argument('--quality', '-q', type=int, default=50,
                       help='JPEG质量因子 (1-100, 默认50)')
    
    # 操作模式
    group = parser.add_mutually_exclusive_group()
    group.add_argument('--show', action='store_true', 
                      help='显示指定质量因子的量化表')
    group.add_argument('--apply', action='store_true',
                      help='应用指定质量因子的量化表到Verilog和Python文件')
    group.add_argument('--interactive', '-i', action='store_true',
                      help='交互式模式')
    
    # 其他选项
    parser.add_argument('--backup', action='store_true',
                       help='应用前备份原文件')
    parser.add_argument('--verbose', '-v', action='store_true',
                       help='详细输出')
    
    args = parser.parse_args()
    
    # 如果没有指定操作，默认显示表
    if not any([args.apply, args.show, args.interactive]):
        args.show = True
    
    # 检查工作空间
    workspace_path = Path(args.workspace).resolve()
    if not workspace_path.exists():
        print(f"错误: 工作空间路径不存在: {workspace_path}")
        return 1
    
    # 初始化管理器
    manager = JPEGTablesManager()
    manager.set_workspace_path(str(workspace_path))
    
    print(f"JPEG量化表配置工具")
    print(f"=" * 50)
    print(f"工作空间: {workspace_path}")
    print(f"质量因子: {args.quality}")
    
    # 执行操作
    if args.interactive:
        return interactive_mode(manager, args)
    elif args.show:
        return show_tables(manager, args)
    elif args.apply:
        return apply_tables(manager, args)
    
    return 0

def interactive_mode(manager, args):
    """交互式模式"""
    print(f"\n=== 交互式模式 ===")
    
    while True:
        print(f"\n选择操作:")
        print(f"1. 显示标准量化表")
        print(f"2. 显示简单量化表 (全1)")
        print(f"3. 显示自定义质量量化表")
        print(f"4. 应用标准量化表")
        print(f"5. 应用简单量化表")
        print(f"6. 应用自定义质量量化表")
        print(f"7. 显示哈夫曼表信息")
        print(f"0. 退出")
        
        try:
            choice = input("\n请输入选择 (0-7): ").strip()
            
            if choice == '0':
                print("退出程序")
                break
            elif choice == '1':
                manager.print_table(manager.STANDARD_Y_QUANT_TABLE, "标准Y量化表")
                manager.print_table(manager.STANDARD_CBCR_QUANT_TABLE, "标准CbCr量化表")
            elif choice == '2':
                manager.print_table(manager.SIMPLE_QUANT_TABLE, "简单量化表 (全1)")
            elif choice == '3':
                quality = input("输入质量因子 (1-100): ").strip()
                try:
                    quality = int(quality)
                    if 1 <= quality <= 100:
                        custom_y = manager.create_custom_table("y", quality)
                        custom_cbcr = manager.create_custom_table("cbcr", quality)
                        manager.print_table(custom_y, f"自定义Y量化表 (质量{quality})")
                        manager.print_table(custom_cbcr, f"自定义CbCr量化表 (质量{quality})")
                    else:
                        print("质量因子必须在1-100之间")
                except ValueError:
                    print("请输入有效的数字")
            elif choice == '4':
                if manager.apply_quantization_tables("standard"):
                    print("✓ 标准量化表应用成功")
                else:
                    print("✗ 标准量化表应用失败")
            elif choice == '5':
                if manager.apply_quantization_tables("simple"):
                    print("✓ 简单量化表应用成功")
                else:
                    print("✗ 简单量化表应用失败")
            elif choice == '6':
                quality = input("输入质量因子 (1-100): ").strip()
                try:
                    quality = int(quality)
                    if 1 <= quality <= 100:
                        # TODO: 实现自定义质量应用功能
                        print("自定义质量应用功能尚未实现")
                    else:
                        print("质量因子必须在1-100之间")
                except ValueError:
                    print("请输入有效的数字")
            elif choice == '7':
                huffman_data = manager.get_huffman_header_data()
                print(f"\n哈夫曼表信息:")
                print(f"  DC Y表: {len(huffman_data['dc_y']['values'])} 个值")
                print(f"  AC Y表: {len(huffman_data['ac_y']['values'])} 个值")
                print(f"  DC CbCr表: {len(huffman_data['dc_cbcr']['values'])} 个值")
                print(f"  AC CbCr表: {len(huffman_data['ac_cbcr']['values'])} 个值")
            else:
                print("无效选择，请重新输入")
                
        except KeyboardInterrupt:
            print("\n\n程序被用户中断")
            break
        except Exception as e:
            print(f"错误: {e}")
    
    return 0

def show_tables(manager, args):
    """显示量化表"""
    print(f"\n=== 质量因子 {args.quality} 的量化表 ===")
    
    # 生成指定质量因子的量化表
    y_table = manager.create_custom_table("y", args.quality)
    cbcr_table = manager.create_custom_table("cbcr", args.quality)
    
    manager.print_table(y_table, f"Y量化表 (质量因子{args.quality})")
    manager.print_table(cbcr_table, f"CbCr量化表 (质量因子{args.quality})")
    
    if args.verbose:
        huffman_data = manager.get_huffman_header_data()
        print(f"\n哈夫曼表信息:")
        print(f"  DC Y表: {len(huffman_data['dc_y']['values'])} 个值")
        print(f"  AC Y表: {len(huffman_data['ac_y']['values'])} 个值")
        print(f"  DC CbCr表: {len(huffman_data['dc_cbcr']['values'])} 个值")
        print(f"  AC CbCr表: {len(huffman_data['ac_cbcr']['values'])} 个值")
    
    return 0

def show_custom_tables(manager, args):
    """显示自定义质量量化表"""
    print(f"\n=== 自定义质量量化表 ===")
    print(f"质量因子: {args.quality}")
    
    custom_y = manager.create_custom_table("y", args.quality)
    custom_cbcr = manager.create_custom_table("cbcr", args.quality)
    
    manager.print_table(custom_y, f"自定义Y量化表 (质量{args.quality})")
    manager.print_table(custom_cbcr, f"自定义CbCr量化表 (质量{args.quality})")
    
    return 0

def apply_tables(manager, args):
    """应用量化表"""
    print(f"\n=== 应用质量因子 {args.quality} 的量化表 ===")
    
    # 备份文件 (如果需要)
    if args.backup:
        backup_files(manager, args)
    
    # 应用量化表
    print(f"正在应用质量因子 {args.quality} 的量化表...")
    
    if manager.apply_quantization_tables(args.quality):
        print("✓ 量化表应用成功")
        
        # 验证应用结果
        workspace = Path(args.workspace)
        files_to_check = [
            workspace / "y_quantizer.v",
            workspace / "cb_quantizer.v", 
            workspace / "cr_quantizer.v",
            workspace / "jpeg_core_to_jpg.py"
        ]
        
        print(f"\n验证更新的文件:")
        for file_path in files_to_check:
            if file_path.exists():
                print(f"  ✓ {file_path.name}")
            else:
                print(f"  ⚠ {file_path.name} (文件不存在)")
        
        return 0
    else:
        print("✗ 量化表应用失败")
        return 1

def backup_files(manager, args):
    """备份原文件"""
    print(f"正在备份原文件...")
    
    workspace = Path(args.workspace)
    files_to_backup = [
        "y_quantizer.v",
        "cb_quantizer.v", 
        "cr_quantizer.v",
        "jpeg_core_to_jpg.py"
    ]
    
    backup_dir = workspace / "backup_quantization_tables"
    backup_dir.mkdir(exist_ok=True)
    
    for filename in files_to_backup:
        src_file = workspace / filename
        if src_file.exists():
            import shutil
            backup_file = backup_dir / f"{filename}.backup"
            shutil.copy2(src_file, backup_file)
            print(f"  ✓ 备份 {filename} -> {backup_file}")
        else:
            print(f"  ⚠ 跳过 {filename} (文件不存在)")
    
    print(f"备份完成，备份目录: {backup_dir}")

if __name__ == "__main__":
    try:
        exit_code = main()
        sys.exit(exit_code)
    except KeyboardInterrupt:
        print("\n程序被用户中断")
        sys.exit(1)
    except Exception as e:
        print(f"程序错误: {e}")
        sys.exit(1)
