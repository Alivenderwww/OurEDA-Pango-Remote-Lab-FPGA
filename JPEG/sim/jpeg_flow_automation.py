#!/usr/bin/env python3
"""
JPEG Encoder Complete Flow Automation Script
Complete flow from image file to JPEG encoding
Author: AI Assistant
"""

import os
import sys
import subprocess
import argparse
import re
from pathlib import Path
from PIL import Image

# Import JPEG tables manager
try:
    from jpeg_tables_manager import JPEGTablesManager
    TABLES_MANAGER_AVAILABLE = True
except ImportError:
    TABLES_MANAGER_AVAILABLE = False
    print("Warning: JPEG Tables Manager not available")

# Import JPEG core to JPG converter
try:
    from jpeg_core_to_jpg import create_jpeg_file, parse_jpeg_output_file
    JPEG_CORE_CONVERTER_AVAILABLE = True
except ImportError:
    JPEG_CORE_CONVERTER_AVAILABLE = False
    print("Warning: JPEG Core to JPG converter not available")

def run_command(cmd, description, timeout=300):
    """Run command and show results"""
    print(f"\n{description}...")
    print(f"Command: {cmd}")
    
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout, encoding='utf-8', errors='ignore')
        if result.returncode == 0:
            print(f"✓ {description} successful")
            if result.stdout:
                print("Output:", result.stdout.strip())
        else:
            print(f"✗ {description} failed")
            print("Error:", result.stderr.strip())
            return False
    except subprocess.TimeoutExpired:
        if timeout is not None:
            print(f"⚠ {description} timeout ({timeout}s)")
            print("   Possible causes:")
            print("   1. Simulation stuck in infinite loop")
            print("   2. Waiting for user input")
            print("   3. ModelSim GUI unexpectedly launched")
        else:
            print(f"⚠ {description} was interrupted")
        return False
    except Exception as e:
        print(f"✗ Error executing {description}: {e}")
        return False
    
    return True

def convert_images_to_batch_hex(input_path, hex_output_path, padding=False, specific_files=None):
    """Step 1: Convert image(s) to batch hex file
    Args:
        input_path: 图片文件路径或包含图片的目录路径
        hex_output_path: 输出hex文件路径
        padding: 是否填充到8的倍数
        specific_files: 指定要处理的文件名列表（仅在input_path为目录时使用）
    Returns:
        (success, image_info): 成功标志和图片信息列表
    """
    try:
        print(f"\n--- Step 1: 图像转Hex转换 ---")
        print(f"输入路径: {input_path}")
        print(f"输出hex文件: {hex_output_path}")
        
        input_path_obj = Path(input_path)
        image_extensions = ['.jpg', '.jpeg', '.png', '.bmp', '.gif', '.tiff', '.tif']
        
        # 判断是单个文件还是目录
        if input_path_obj.is_file():
            # 单个文件模式
            if input_path_obj.suffix.lower() not in image_extensions:
                print(f"✗ 不支持的图片格式: {input_path_obj.suffix}")
                return False, []
            image_files = [input_path_obj]
            print(f"单图片模式: {input_path_obj.name}")
        elif input_path_obj.is_dir():
            # 目录模式
            image_files = []
            if specific_files:
                # 处理指定的文件
                for filename in specific_files:
                    file_path = input_path_obj / filename
                    if file_path.exists() and file_path.suffix.lower() in image_extensions:
                        image_files.append(file_path)
            else:
                # 处理目录中所有图片
                image_files_set = set()  # 使用set避免重复
                for ext in image_extensions:
                    # 使用不区分大小写的匹配
                    for file_path in input_path_obj.iterdir():
                        if file_path.is_file() and file_path.suffix.lower() == ext:
                            image_files_set.add(file_path)
                
                image_files = sorted(list(image_files_set))
            
            if not image_files:
                print(f"✗ 未在 {input_path} 中找到图像文件")
                return False, []
            
            print(f"批量模式: 找到 {len(image_files)} 张图片:")
            for i, img_file in enumerate(image_files):
                print(f"  {i+1}. {img_file.name}")
        else:
            print(f"✗ 输入路径不存在: {input_path}")
            return False, []
        
        # Create output directory if needed
        os.makedirs(os.path.dirname(hex_output_path), exist_ok=True)
        
        image_info = []  # 存储每张图片的信息
        
        # 处理每张图片
        with open(hex_output_path, 'w') as f:
            for i, image_path in enumerate(image_files):
                print(f"\n处理图片 {i+1}/{len(image_files)}: {image_path.name}")
                
                # Open and get original dimensions
                img = Image.open(image_path)
                orig_width, orig_height = img.size
                
                # 计算填充后的尺寸
                if padding:
                    convert_width = ((orig_width + 7) // 8) * 8
                    convert_height = ((orig_height + 7) // 8) * 8
                    print(f"  原始尺寸: {orig_width}x{orig_height}")
                    print(f"  填充尺寸: {convert_width}x{convert_height}")
                else:
                    convert_width = orig_width
                    convert_height = orig_height
                    print(f"  处理尺寸: {convert_width}x{convert_height}")
                
                # Resize and convert
                img = img.resize((convert_width, convert_height))
                img = img.convert('RGB')
                
                # 记录图片信息
                final_width = ((convert_width + 7) // 8) * 8
                final_height = ((convert_height + 7) // 8) * 8
                image_info.append({
                    'filename': image_path.stem,
                    'orig_width': orig_width,
                    'orig_height': orig_height,
                    'convert_width': convert_width,
                    'convert_height': convert_height,
                    'final_width': final_width,
                    'final_height': final_height
                })
                
                # Write image data to hex file
                for y in range(convert_height):
                    for x in range(convert_width):
                        r, g, b = img.getpixel((x, y))
                        # 按位序排列: [23:16]=蓝色, [15:8]=绿色, [7:0]=红色
                        hex_value = f"{b:02x}{g:02x}{r:02x}"
                        f.write(hex_value + '\n')
                
                print(f"  ✓ 完成: {convert_width}x{convert_height}, {convert_width * convert_height} 像素")
        
        if len(image_files) == 1:
            print(f"\n✓ 单图像转换完成")
        else:
            print(f"\n✓ 批量图像转换完成，总共处理: {len(image_files)} 张图片")
        print(f"格式: 逐行逐列 (TB将处理8x8块排序)")
        
        return True, image_info
        
    except Exception as e:
        print(f"✗ 图像转换失败: {e}")
        return False, []

def run_modelsim_simulation(work_dir="work", enable_wave=False):
    """Step 2: Run ModelSim simulation"""
    # 将work目录创建在脚本所在目录
    script_dir = os.path.dirname(os.path.abspath(__file__))
    work_path = os.path.join(script_dir, work_dir)
    
    # 首先尝试清理旧的工作目录
    import shutil
    if os.path.exists(work_path):
        try:
            shutil.rmtree(work_path)
            print(f"✓ 清理旧工作目录: {work_path}")
        except Exception as e:
            print(f"⚠ 清理工作目录失败: {e}")
    
    print(f"逐步执行ModelSim命令...")
    commands = [
        f"vlib \"{work_path}\"",
        f"vmap work \"{work_path}\"",
    ]
    
    # 添加Pango仿真库映射 - 参考TCL文件
    # 计算仿真库的路径: script_dir = JPEG/sim, 需要到达 Pangu/sim/pangu_sim_libraries
    # JPEG/sim -> JPEG -> Pangu -> sim -> pangu_sim_libraries
    pangu_sim_lib_path = os.path.join(os.path.dirname(os.path.dirname(script_dir)), "sim", "pangu_sim_libraries")
    print(f"调试: script_dir = {script_dir}")
    print(f"调试: 计算的仿真库路径 = {pangu_sim_lib_path}")
    
    if os.path.exists(pangu_sim_lib_path):
        print(f"✓ 找到Pango仿真库目录: {pangu_sim_lib_path}")
        # 映射各个仿真库
        sim_libraries = [
            "usim", "adc_e2", "ddc_e2", "dll_e2", 
            "hsstlp_lane", "hsstlp_pll", "iolhr_dft", 
            "ipal_e1", "ipal_e2", "iserdes_e2", "oserdes_e2", "pciegen2"
        ]
        
        for lib in sim_libraries:
            lib_path = os.path.join(pangu_sim_lib_path, lib)
            if os.path.exists(lib_path):
                commands.append(f"vmap {lib} \"{lib_path}\"")
                print(f"✓ 映射仿真库: {lib}")
            else:
                print(f"⚠ 警告: 仿真库不存在 {lib_path}")
    else:
        print(f"⚠ 警告: 未找到Pango仿真库目录: {pangu_sim_lib_path}")
        print(f"  请确保pangu_sim_libraries目录存在，否则IP核可能无法正常仿真")
    
    # 按顺序编译文件 - 使用绝对路径指向 jpeg_encoder 目录，并包含新的顶层文件
    verilog_base_path = os.path.join(os.path.dirname(script_dir), "jpeg_encoder")
    jpeg_top_path = os.path.dirname(script_dir)  # 到达JPEG目录
    
    verilog_files = [
        # 基础组件
        "y_dct.v", "cb_dct.v", "cr_dct.v",
        "y_quantizer.v", "cb_quantizer.v", "cr_quantizer.v", 
        "y_huff.v", "cb_huff.v", "cr_huff.v",
        "yd_q_h.v", "cbd_q_h.v", "crd_q_h.v",
        "rgb2ycbcr.v", "sync_fifo_32.v", "pre_fifo.v",
        "fifo_out.v", "sync_fifo_ff.v", "ff_checker.v",
        "jpeg_top.v"
    ]
    
    # 编译基础文件
    for vfile in verilog_files:
        vfile_path = os.path.join(verilog_base_path, vfile)
        if os.path.exists(vfile_path):
            commands.append(f"vlog -sv -mfcu -incr -suppress 2902 \"{vfile_path}\"")  # 添加SystemVerilog支持和抑制警告
        else:
            print(f"⚠ 警告: 文件不存在 {vfile_path}")
    
    # 编译IP核文件 - JPEG专用的FIFO IP核
    ip_files = [
        "jpeg_encoder_line_fifo.v",
        "ipm2l_fifo_v1_10_jpeg_encoder_line_fifo.v", 
        "ipm2l_sdpram_v1_10_jpeg_encoder_line_fifo.v",
        "ipm2l_fifo_ctrl_v1_1_jpeg_encoder_line_fifo.v",
        "jpeg_encoder_line_fifo_Reset_Value.v"
    ]
    
    for ip_file in ip_files:
        ip_file_path = os.path.join(jpeg_top_path, ip_file)
        if os.path.exists(ip_file_path):
            commands.append(f"vlog -sv -mfcu -incr -suppress 2902 \"{ip_file_path}\"")
            print(f"✓ 添加IP核文件: {ip_file}")
        else:
            print(f"⚠ 警告: IP核文件不存在 {ip_file_path}")
    
    # 编译顶层模块文件
    jpeg_encoder_top_path = os.path.join(jpeg_top_path, "jpeg_encoder_top.sv")
    if os.path.exists(jpeg_encoder_top_path):
        commands.append(f"vlog -sv -mfcu -incr -suppress 2902 \"{jpeg_encoder_top_path}\"")
        print(f"✓ 添加顶层模块: {jpeg_encoder_top_path}")
    else:
        print(f"⚠ 警告: 顶层模块文件不存在 {jpeg_encoder_top_path}")
    
    # 编译测试台文件
    tb_file_path = os.path.join(script_dir, "jpeg_encoder_top_tb.sv")
    if os.path.exists(tb_file_path):
        commands.append(f"vlog -sv -mfcu -incr -suppress 2902 \"{tb_file_path}\"")
        print(f"✓ 添加测试台文件: {tb_file_path}")
    else:
        print(f"⚠ 警告: 测试台文件不存在 {tb_file_path}")
    
    # 运行仿真命令
    if enable_wave:
        # 图形化界面模式，带波形查看，参考TCL文件添加仿真参数和库链接
        vsim_cmd = ("vsim -suppress 3486,3680,3781 -voptargs=\"+acc\" +nowarn1 -sva "
                   "-L work -L usim -L adc_e2 -L ddc_e2 -L dll_e2 -L hsstlp_lane -L hsstlp_pll "
                   "-L iolhr_dft -L ipal_e1 -L ipal_e2 -L iserdes_e2 -L oserdes_e2 -L pciegen2 "
                   "work.jpeg_encoder_top_tb -do \"add wave -radix hex /jpeg_encoder_top_tb/*; run -all\"")
        commands.append(vsim_cmd)
        print("📊 启用波形查看模式 - ModelSim将打开图形界面")
    else:
        # 命令行模式，添加抑制警告参数和库链接
        vsim_cmd = ("vsim -suppress 3486,3680,3781 -voptargs=\"+acc\" +nowarn1 -c "
                   "-L work -L usim -L adc_e2 -L ddc_e2 -L dll_e2 -L hsstlp_lane -L hsstlp_pll "
                   "-L iolhr_dft -L ipal_e1 -L ipal_e2 -L iserdes_e2 -L oserdes_e2 -L pciegen2 "
                   "work.jpeg_encoder_top_tb -do \"run -all; quit -f\"")
        commands.append(vsim_cmd)
        print("⚡ 使用命令行模式进行仿真")
    
    # 保存当前目录，切换到脚本目录执行ModelSim命令
    original_dir = os.getcwd()
    os.chdir(script_dir)
    
    success_count = 0
    try:
        for cmd in commands:
            if run_command(cmd, f"ModelSim: {cmd}", timeout=None):  # 无超时限制
                success_count += 1
            else:
                print(f"⚠ 命令失败: {cmd}")
    finally:
        # 恢复原始目录
        os.chdir(original_dir)
    
    # 如果大部分命令成功，认为仿真可能成功
    return success_count >= len(commands) - 2

def convert_batch_jpeg_output_to_jpg(hex_output_file, image_info, output_dir):
    """步骤3: 将批量JPEG核心输出转换为JPG文件"""
    try:
        print(f"\n--- Step 3: JPEG核心输出转JPG转换 ---")
        
        if not JPEG_CORE_CONVERTER_AVAILABLE:
            print("✗ JPEG核心转换器不可用，请确保 jpeg_core_to_jpg.py 文件存在")
            return False
        
        # 读取整个输出hex文件并按图片分割
        with open(hex_output_file, 'r') as f:
            all_lines = f.readlines()
        
        # 找到所有图片分界标记
        image_boundaries = []
        for i, line in enumerate(all_lines):
            if "// End of Image" in line:
                # 提取图片编号
                import re
                match = re.search(r'End of Image\s+(\d+)', line)
                if match:
                    img_num = int(match.group(1))
                    image_boundaries.append((i, img_num))
        
        print(f"发现 {len(image_boundaries)} 个图片分界标记")
        for boundary in image_boundaries:
            print(f"  图片 {boundary[1]} 结束于第 {boundary[0]+1} 行")
        
        successful_conversions = 0
        start_line = 0
        
        for i, img_info in enumerate(image_info):
            print(f"\n转换图片 {i+1}/{len(image_info)}: {img_info['filename']}")
            
            # 找到当前图片的结束位置
            end_line = len(all_lines)  # 默认到文件末尾
            for boundary in image_boundaries:
                if boundary[1] == i + 1:  # 图片编号从1开始
                    end_line = boundary[0] - 2  # 跳过Valid bits和End of Image注释行，取前面一行的数据
                    break
            
            # 为每张图片创建临时hex文件
            temp_hex_file = os.path.join(output_dir, f"temp_{img_info['filename']}.hex")
            final_jpg_path = os.path.join(output_dir, f"{img_info['filename']}_encoded.jpg")
            
            print(f"  提取数据: 第 {start_line+1} 行到第 {end_line+1} 行")
            
            # 提取这张图片的hex数据
            with open(temp_hex_file, 'w') as temp_f:
                for j in range(start_line, min(end_line + 1, len(all_lines))):
                    line = all_lines[j].strip()
                    # 跳过注释行
                    if not line.startswith('//') and line:
                        temp_f.write(line + '\n')
            
            # 直接调用转换函数
            hex_data = parse_jpeg_output_file(temp_hex_file)
            
            if hex_data:
                create_jpeg_file(hex_data, img_info['final_width'], img_info['final_height'], final_jpg_path)
                successful_conversions += 1
                print(f"  ✓ 生成: {final_jpg_path}")
            else:
                print(f"  ✗ 转换失败: {img_info['filename']} - 无法解析hex数据")
            
            # 清理临时文件
            try:
                os.remove(temp_hex_file)
            except:
                pass
            
            # 更新下一张图片的起始行
            if i < len(image_boundaries):
                # 下一张图片从当前图片结束标记后开始
                for boundary in image_boundaries:
                    if boundary[1] == i + 1:
                        start_line = boundary[0] + 1  # 跳过End of Image行
                        break
        
        print(f"\n✓ 转换完成: {successful_conversions}/{len(image_info)} 张图片成功")
        return successful_conversions == len(image_info)
        
    except Exception as e:
        print(f"✗ JPEG输出转换失败: {e}")
        return False

def update_testbench_parameters(testbench_file, width, height):
    """更新测试台文件中的图像尺寸参数"""
    # 获取脚本所在目录，测试台文件现在在sim目录中
    script_dir = os.path.dirname(os.path.abspath(__file__))
    tb_path = os.path.join(script_dir, testbench_file)
    
    try:
        with open(tb_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 使用正则表达式替换参数，支持任意初始值
        content = re.sub(r'parameter IMAGE_WIDTH = \d+;', f'parameter IMAGE_WIDTH = {width};', content)
        content = re.sub(r'parameter IMAGE_HEIGHT = \d+;', f'parameter IMAGE_HEIGHT = {height};', content)
        
        with open(tb_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"✓ 更新测试台参数: {width}x{height} 在 {tb_path}")
        return True
        
    except Exception as e:
        print(f"✗ 更新测试台参数失败: {e}")
        print(f"  尝试的路径: {tb_path}")
        return False

def get_image_dimensions(image_path):
    """获取图像尺寸并调整为8的倍数"""
    try:
        from PIL import Image
        
        with Image.open(image_path) as img:
            width, height = img.size
        
        # 调整为8的倍数
        padded_width = ((width + 7) // 8) * 8
        padded_height = ((height + 7) // 8) * 8
        
        return padded_width, padded_height, width, height
        
    except Exception as e:
        print(f"✗ 获取图像尺寸失败: {e}")
        return None, None, None, None

def manage_quantization_tables(quality_factor=50, workspace_path="."):
    """管理量化表配置"""
    if not TABLES_MANAGER_AVAILABLE:
        print("⚠ 量化表管理器不可用")
        return False
    
    try:
        manager = JPEGTablesManager()
        manager.set_workspace_path(workspace_path)
        
        print(f"\n=== 量化表管理 ===")
        print(f"工作路径: {workspace_path}")
        print(f"质量因子: {quality_factor}")
        
        # 生成并显示当前质量因子的表
        y_table = manager.create_custom_table("y", quality_factor)
        cbcr_table = manager.create_custom_table("cbcr", quality_factor)
        manager.print_table(y_table, f"Y量化表 (质量因子{quality_factor})")
        manager.print_table(cbcr_table, f"CbCr量化表 (质量因子{quality_factor})")
        
        # 应用量化表
        if manager.apply_quantization_tables(quality_factor):
            print("✓ 量化表应用成功")
            
            # 显示哈夫曼表信息
            huffman_data = manager.get_huffman_header_data()
            print(f"\n哈夫曼表信息:")
            print(f"  DC Y表: {len(huffman_data['dc_y']['values'])} 个值")
            print(f"  AC Y表: {len(huffman_data['ac_y']['values'])} 个值")
            print(f"  DC CbCr表: {len(huffman_data['dc_cbcr']['values'])} 个值")
            print(f"  AC CbCr表: {len(huffman_data['ac_cbcr']['values'])} 个值")
            
            return True
        else:
            print("✗ 量化表应用失败")
            return False
            
    except Exception as e:
        print(f"✗ 量化表管理错误: {e}")
        return False

def generate_testbench_params(image_info, params_file_path="output/testbench_params.v"):
    """Generate testbench parameter file for batch image processing"""
    try:
        # Create output directory
        os.makedirs(os.path.dirname(params_file_path), exist_ok=True)
        
        num_images = len(image_info)
        print(f"\n--- 生成Testbench参数文件 ---")
        print(f"图片数量: {num_images}")
        print(f"参数文件: {params_file_path}")
        
        # Calculate total pixels needed
        total_pixels = sum(info['convert_width'] * info['convert_height'] for info in image_info)
        max_width = max(info['convert_width'] for info in image_info)
        max_height = max(info['convert_height'] for info in image_info)
        
        with open(params_file_path, 'w') as f:
            f.write("// Auto-generated testbench parameters for batch image processing\n")
            f.write(f"// Generated by jpeg_flow_automation.py\n\n")
            
            # Basic parameters
            f.write(f"parameter NUM_IMAGES = {num_images};\n")
            f.write(f"parameter TOTAL_PIXELS = {total_pixels};\n")
            f.write(f"parameter MAX_WIDTH = {max_width};\n")
            f.write(f"parameter MAX_HEIGHT = {max_height};\n\n")
            
            # Generate image dimensions as parameter arrays (SystemVerilog style)
            f.write("// Image width array\n")
            f.write("parameter integer IMAGE_WIDTHS[0:{}] = '{{".format(num_images-1))
            width_values = [str(info['convert_width']) for info in image_info]
            f.write(", ".join(width_values))
            f.write("};\n\n")
            
            f.write("// Image height array\n") 
            f.write("parameter integer IMAGE_HEIGHTS[0:{}] = '{{".format(num_images-1))
            height_values = [str(info['convert_height']) for info in image_info]
            f.write(", ".join(height_values))
            f.write("};\n\n")
            
            f.write("// Image information summary\n")
            for i, info in enumerate(image_info):
                f.write(f"// Image {i}: {info['filename']} - {info['convert_width']}x{info['convert_height']} pixels\n")
        
        print(f"✓ Testbench参数文件生成完成")
        print(f"总像素数: {total_pixels}")
        print(f"最大尺寸: {max_width}x{max_height}")
        
        # Display summary
        print("\n图片处理信息:")
        for i, info in enumerate(image_info):
            pixels = info['convert_width'] * info['convert_height']
            print(f"  {i+1}. {info['filename']}: {info['convert_width']}x{info['convert_height']} ({pixels} pixels)")
        
        return True
        
    except Exception as e:
        print(f"✗ 生成testbench参数失败: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description='JPEG编码器完整流程自动化')
    parser.add_argument('input_image', nargs='?', default='input', 
                       help='输入图像文件路径或目录 (默认: input文件夹)')
    parser.add_argument('-o', '--output-dir', default='output', help='输出目录')
    parser.add_argument('--skip-simulation', action='store_true', help='跳过ModelSim仿真')
    parser.add_argument('--modelsim-path', default='', help='ModelSim安装路径')
    parser.add_argument('-q', '--quality-factor', type=int, default=50, 
                       help='JPEG质量因子 (1-100, 默认50)')
    parser.add_argument('--update-tables', action='store_true', 
                       help='强制更新量化表到Verilog和Python文件')
    parser.add_argument('--wave', action='store_true', 
                       help='启用ModelSim波形查看 (图形界面模式)')
    parser.add_argument('--padding', action='store_true', 
                       help='在Python端填充图像行列至8的倍数 (默认：不填充，由Verilog模块处理)')
    
    args = parser.parse_args()
    
    # 处理输入路径 - 如果是相对路径，转换为相对于脚本所在目录的路径
    if not os.path.isabs(args.input_image):
        script_dir = os.path.dirname(os.path.abspath(__file__))
        args.input_image = os.path.join(script_dir, args.input_image)
    
    # 检查输入路径
    if not os.path.exists(args.input_image):
        if os.path.basename(args.input_image) == 'input':
            # 默认input文件夹不存在，创建它并提示用户
            os.makedirs(args.input_image, exist_ok=True)
            print(f"✓ 创建了默认输入文件夹: {args.input_image}")
            print(f"请将图片文件放入 {args.input_image} 文件夹中，然后重新运行脚本")
            print(f"或者直接指定图片文件路径，例如:")
            print(f"  python {sys.argv[0]} path/to/image.jpg")
            print(f"  python {sys.argv[0]} path/to/folder")
            return 1
        else:
            print(f"✗ 输入图像文件或目录不存在: {args.input_image}")
            return 1
    
    # 量化表配置
    if TABLES_MANAGER_AVAILABLE:
        print(f"\n--- 量化表配置 ---")
        print(f"质量因子: {args.quality_factor}")
        
        tables_manager = JPEGTablesManager()
        tables_manager.set_workspace_path(os.getcwd())
        
        if args.update_tables or args.quality_factor != 50:
            print(f"正在应用质量因子 {args.quality_factor} 的量化表...")
            if tables_manager.apply_quantization_tables(args.quality_factor):
                print("✓ 量化表更新成功")
            else:
                print("⚠ 量化表更新失败，继续使用现有配置")
        else:
            print("使用现有量化表配置（质量因子50）")
    else:
        print("⚠ 量化表管理器不可用，使用默认配置")
    
    # 创建输出目录 - 相对于脚本所在目录
    script_dir = os.path.dirname(os.path.abspath(__file__))
    output_dir = Path(script_dir) / args.output_dir
    output_dir.mkdir(exist_ok=True)
    
    print(f"\n=== JPEG编码器完整流程 ===")
    print(f"输入路径: {args.input_image}")
    print(f"输出目录: {output_dir}")
    
    # 步骤1: 图像转hex
    print(f"\n--- 步骤1: 图像转hex ---")
    hex_file = output_dir / "ja_pixels.txt"
    success, image_info = convert_images_to_batch_hex(args.input_image, str(hex_file), args.padding)
    
    if not success or not image_info:
        print("✗ 图像转换失败")
        return 1
    
    # 检查生成的hex文件
    if not hex_file.exists():
        print(f"✗ hex文件未生成: {hex_file}")
        return 1
    
    # 生成testbench参数文件
    print(f"\n--- 步骤1.5: 生成testbench参数 ---")
    params_file = output_dir / "testbench_params.v" 
    if not generate_testbench_params(image_info, str(params_file)):
        print("✗ testbench参数生成失败")
        return 1
    
    # 更新测试台中的hex文件路径和输出路径
    simulation_output = output_dir / "jpeg_output_hex.txt"
    tb_path = os.path.join(script_dir, "jpeg_encoder_top_tb.sv")
    
    try:
        with open(tb_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # 获取hex文件相对于测试台文件的路径（现在都在sim目录中）
        hex_file_relative = os.path.relpath(str(hex_file), script_dir)
        output_file_relative = os.path.relpath(str(simulation_output), script_dir)
        # 将Windows路径分隔符转换为正斜杠（Verilog中使用）
        hex_file_relative = hex_file_relative.replace('\\', '/')
        output_file_relative = output_file_relative.replace('\\', '/')
        
        # 更新输入文件路径
        content = content.replace('load_hex_file("../sim/output/ja_pixels.txt");', 
                                f'load_hex_file("{hex_file_relative}");')
        
        # 更新输出文件路径
        content = content.replace('$fopen("../sim/output/jpeg_output_hex.txt", "w")', 
                                f'$fopen("{output_file_relative}", "w")')
        
        with open(tb_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"✓ 更新hex文件路径: {hex_file_relative}")
        print(f"✓ 更新输出文件路径: {output_file_relative}")
        
    except Exception as e:
        print(f"✗ 更新测试台文件路径失败: {e}")
        print(f"  尝试的路径: {tb_path}")
        return 1
    
    # 步骤2: 运行仿真 (可选)
    if not args.skip_simulation:
        print(f"\n--- 步骤2: ModelSim仿真 ---")
        if args.modelsim_path:
            os.environ['PATH'] = args.modelsim_path + os.pathsep + os.environ['PATH']
        
        if args.wave:
            print("🌊 使用波形查看模式 - 请在ModelSim GUI中手动控制仿真")
            print("   注意: 仿真可能需要较长时间，请耐心等待")
        
        simulation_success = run_modelsim_simulation(enable_wave=args.wave)
        
        # 检查仿真输出
        if os.path.exists(simulation_output):
            print(f"✓ 发现仿真输出文件: {simulation_output}")
        else:
            print(f"⚠ 仿真输出文件未生成: {simulation_output}")
            print("   这可能是由于以下原因:")
            print("   1. ModelSim版本兼容性问题")
            print("   2. 工作目录权限问题") 
            print("   3. Verilog文件编译错误")
            print("   4. 新顶层模块时序问题")
            print("\n   建议手动运行仿真:")
            print("   1. 打开ModelSim")
            print("   2. 执行以下命令:")
            print("      vlib work")
            print("      vmap work work")
            print("      vlog jpeg_encoder_top.sv jpeg_encoder_top_tb.sv (以及其他依赖文件)")
            print("      vsim work.jpeg_encoder_top_tb")
            print("      run -all")
            print("   3. 确保生成了 jpeg_output_hex.txt 文件")
            
            # 询问用户是否已手动生成输出文件
            response = input("\n   是否已手动生成仿真输出文件? (y/N): ").strip().lower()
            if response != 'y':
                print("   请先完成仿真步骤，然后重新运行此脚本并使用 --skip-simulation 参数")
                return 1
            
            # 再次检查文件是否存在
            if not os.path.exists(simulation_output):
                print(f"✗ 仍未找到仿真输出文件: {simulation_output}")
                return 1
    else:
        print(f"\n--- 跳过仿真步骤 ---")
        print(f"请确保存在仿真输出文件: {simulation_output}")
        if not os.path.exists(simulation_output):
            print(f"✗ 仿真输出文件不存在: {simulation_output}")
            print("   请先运行仿真或移除 --skip-simulation 参数")
            return 1
    
    # 步骤3: JPEG核心输出转JPG
    print(f"\n--- 步骤3: JPEG核心输出转JPG ---")
    if not convert_batch_jpeg_output_to_jpg(str(simulation_output), image_info, str(output_dir)):
        print("✗ JPEG输出转换失败")
        return 1
    
    # 步骤4: 生成测试台参数文件
    print(f"\n--- 步骤4: 生成测试台参数文件 ---")
    params_file = output_dir / "testbench_params.v"
    if not generate_testbench_params(image_info, str(params_file)):
        print("✗ 测试台参数文件生成失败")
        return 1
    
    print(f"\n=== 流程完成 ===")
    if len(image_info) == 1:
        print(f"✓ 成功生成JPEG文件: {output_dir}/{image_info[0]['filename']}_encoded.jpg")
    else:
        print(f"✓ 成功生成 {len(image_info)} 个JPEG文件")
        for img in image_info:
            print(f"   - {img['filename']}_encoded.jpg")
    
    print(f"✓ 中间文件:")
    print(f"    Hex数据: {hex_file}")
    print(f"    仿真输出: {simulation_output}")
    
    # 清理选项
    response = input("\n是否删除中间文件? (y/N): ").strip().lower()
    if response == 'y':
        try:
            if hex_file.exists():
                hex_file.unlink()
            if os.path.exists(simulation_output):
                os.remove(simulation_output)
            print("✓ 中间文件已删除")
        except Exception as e:
            print(f"⚠ 删除中间文件时出错: {e}")
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
