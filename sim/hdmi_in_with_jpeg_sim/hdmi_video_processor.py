#!/usr/bin/env python3
"""
HDMI Media to Hex Converter for hdmi_in_with_jpeg_sim
Reads video file or image from input folder, converts to hex format for testbench simulation
Supports both video files and static images
"""

import os
import sys
import cv2
import numpy as np
from pathlib import Path
import re
import argparse
from PIL import Image

class HDMIMediaProcessor:
    def __init__(self, input_dir="input", output_dir="output"):
        self.input_dir = Path(input_dir)
        self.output_dir = Path(output_dir)
        self.testbench_file = Path("hdmi_in_with_jpeg_sim.sv")
        
        # 确保输出目录存在
        self.output_dir.mkdir(exist_ok=True)
        
    def find_media_file(self):
        """在input文件夹中查找视频或图片文件"""
        video_extensions = ['.mp4', '.avi', '.mov', '.mkv', '.flv', '.wmv']
        image_extensions = ['.jpg', '.jpeg', '.png', '.bmp', '.tiff', '.tga']
        
        # 优先查找图片文件
        for ext in image_extensions:
            for image_file in self.input_dir.glob(f'*{ext}'):
                print(f"Found image file: {image_file}")
                return image_file, 'image'
        
        # 然后查找视频文件
        for ext in video_extensions:
            for video_file in self.input_dir.glob(f'*{ext}'):
                print(f"Found video file: {video_file}")
                return video_file, 'video'
        
        raise FileNotFoundError("No video or image file found in input directory")
    
    def update_testbench_parameters(self, width, height, total_pixels):
        """更新testbench中的动态参数"""
        print(f"Updating testbench parameters: {width}x{height}, total_pixels={total_pixels}")
        
        if not self.testbench_file.exists():
            print(f"Warning: Testbench file {self.testbench_file} not found")
            return False
        
        try:
            # 读取testbench文件
            content = self.testbench_file.read_text(encoding='utf-8')
            
            # 更新VIDEO_WIDTH参数
            content = re.sub(
                r'parameter\s+VIDEO_WIDTH\s*=\s*\d+\s*;',
                f'parameter VIDEO_WIDTH = {width};',
                content
            )
            
            # 更新VIDEO_HEIGHT参数
            content = re.sub(
                r'parameter\s+VIDEO_HEIGHT\s*=\s*\d+\s*;',
                f'parameter VIDEO_HEIGHT = {height};',
                content
            )
            
            # 更新VIDEO_TOTAL_PIXELS参数
            content = re.sub(
                r'parameter\s+VIDEO_TOTAL_PIXELS\s*=\s*\d+\s*;',
                f'parameter VIDEO_TOTAL_PIXELS = {total_pixels};',
                content
            )
            
            # 写回文件
            self.testbench_file.write_text(content, encoding='utf-8')
            print(f"Successfully updated testbench parameters")
            return True
            
        except Exception as e:
            print(f"Error updating testbench parameters: {e}")
            return False
    
    def image_to_hex(self, image_path, repeat_frames=1):
        """将单张图片转换为hex格式"""
        print(f"Processing image: {image_path}")
        
        image = Image.open(image_path)
        # 转换为RGB模式（如果不是的话）
        if image.mode != 'RGB':
            image = image.convert('RGB')
            
        width, height = image.size
        print(f"Image info: {width}x{height}, will repeat {repeat_frames} times")
        
        # 转换为numpy数组
        frame_rgb = np.array(image)
        
        # 计算总像素数
        total_pixels_needed = width * height * repeat_frames
        print(f"Total pixels needed: {total_pixels_needed}")
        
        # 更新testbench参数
        self.update_testbench_parameters(width, height, total_pixels_needed)
        
        # 输出hex文件路径
        hex_file_path = self.output_dir / "video_data.hex"
        
        total_pixels = 0
        
        with open(hex_file_path, 'w') as hex_file:
            # 重复写入图片数据指定次数
            for frame_idx in range(repeat_frames):
                print(f"Writing frame {frame_idx + 1}/{repeat_frames}")
                
                # 逐像素转换为hex
                for y in range(height):
                    for x in range(width):
                        r, g, b = frame_rgb[y, x]
                        # 24位RGB格式：BBGGRR
                        rgb_hex = f"{b:02X}{g:02X}{r:02X}"
                        hex_file.write(f"{rgb_hex}\n")
                        total_pixels += 1
        
        print(f"Hex conversion complete: {total_pixels} pixels written to {hex_file_path}")
        return width, height, repeat_frames, total_pixels

    def video_to_hex(self, video_path, max_frames=None):
        """将视频转换为hex格式"""
        print(f"Processing video: {video_path}")
        
        # 打开视频文件
        cap = cv2.VideoCapture(str(video_path))
        
        if not cap.isOpened():
            raise ValueError(f"Cannot open video file: {video_path}")
        
        # 获取视频信息
        frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
        fps = cap.get(cv2.CAP_PROP_FPS)
        width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
        height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
        
        # 确定实际要处理的帧数
        if max_frames is not None:
            actual_frames = min(max_frames, frame_count)
            print(f"Video info: {width}x{height}, {frame_count} total frames, processing {actual_frames} frames, {fps} FPS")
        else:
            actual_frames = frame_count
            print(f"Video info: {width}x{height}, {frame_count} frames, {fps} FPS")
        
        # 计算总像素数
        total_pixels_needed = width * height * actual_frames
        print(f"Total pixels needed: {total_pixels_needed}")
        
        # 更新testbench参数
        self.update_testbench_parameters(width, height, total_pixels_needed)
        
        # 输出hex文件路径
        hex_file_path = self.output_dir / "video_data.hex"
        
        total_pixels = 0
        
        with open(hex_file_path, 'w') as hex_file:
            frame_idx = 0
            while frame_idx < actual_frames:
                ret, frame = cap.read()
                if not ret:
                    break
                
                # OpenCV默认是BGR格式，转换为RGB
                frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                
                print(f"Processing frame {frame_idx + 1}/{actual_frames}")
                
                # 逐像素转换为hex
                for y in range(height):
                    for x in range(width):
                        r, g, b = frame_rgb[y, x]
                        # 24位RGB格式：RRGGBB
                        rgb_hex = f"{r:02X}{g:02X}{b:02X}"
                        hex_file.write(f"{rgb_hex}\n")
                        total_pixels += 1
                
                frame_idx += 1
        
        cap.release()
        
        print(f"Hex conversion complete: {total_pixels} pixels written to {hex_file_path}")
        return width, height, frame_idx, total_pixels
    
    def process_media(self, max_frames=None, repeat_frames=1):
        """完整的媒体文件处理流程，支持视频和图片"""
        try:
            # 1. 查找媒体文件
            media_path, media_type = self.find_media_file()
            
            # 2. 根据文件类型进行处理
            if media_type == 'image':
                width, height, frame_count, total_pixels = self.image_to_hex(media_path, repeat_frames)
                print(f"\nImage Processing Complete:")
                print(f"Input: {media_path}")
                print(f"Output: {self.output_dir}/video_data.hex")
                print(f"Resolution: {width}x{height}")
                print(f"Repeated frames: {frame_count}")
                print(f"Total pixels: {total_pixels}")
            
            elif media_type == 'video':
                width, height, frame_count, total_pixels = self.video_to_hex(media_path, max_frames)
                print(f"\nVideo Processing Complete:")
                print(f"Input: {media_path}")
                print(f"Output: {self.output_dir}/video_data.hex")
                print(f"Resolution: {width}x{height}")
                print(f"Frames processed: {frame_count}")
                print(f"Total pixels: {total_pixels}")
            
        except Exception as e:
            print(f"Error during media processing: {e}")
            return False
        
        return True

def main():
    # 命令行参数解析
    parser = argparse.ArgumentParser(
        description='HDMI Media to Hex Converter - Supports both video and image files',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
使用示例:
  # 处理视频文件，限制前10帧
  python hdmi_video_processor.py --frames 10
  
  # 处理图片文件，重复100次
  python hdmi_video_processor.py --repeat 100
  
  # 自动检测并处理input目录中的媒体文件
  python hdmi_video_processor.py
        """)
    
    parser.add_argument('--frames', '-f', type=int, default=None, 
                        help='限制处理的视频帧数 (仅对视频文件有效)')
    parser.add_argument('--repeat', '-r', type=int, default=1,
                        help='图片重复次数 (仅对图片文件有效，默认1次)')
    
    args = parser.parse_args()
    
    processor = HDMIMediaProcessor()
    success = processor.process_media(max_frames=args.frames, repeat_frames=args.repeat)
    
    if success:
        print("Media processing completed successfully")
    else:
        print("Media processing failed")
        sys.exit(1)

if __name__ == "__main__":
    main()
