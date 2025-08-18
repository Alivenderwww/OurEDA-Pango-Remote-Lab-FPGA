# HDMI JPEG Simulation 输出转换工具

本目录包含用于处理HDMI JPEG仿真输出的Python工具脚本。

## 文件说明

### 1. `hdmi_hex_to_jpeg.py` - 主转换工具
将HDMI JPEG仿真输出的hex文件转换为可查看的JPEG图片文件。

**功能特点:**
- 支持标准的32位hex格式 (每行8个十六进制字符)
- 自动添加标准JPEG文件头和结束标记
- 支持手动指定或自动推测图像尺寸
- 提供详细的转换过程信息

**使用方法:**

```bash
# 基本用法：转换指定文件，手动指定尺寸
python hdmi_hex_to_jpeg.py output/jpeg_data_new.hex -w 640 --height 480

# 自动模式：处理output目录中的最新JPEG hex文件
python hdmi_hex_to_jpeg.py -a

# 指定输出文件名
python hdmi_hex_to_jpeg.py output/jpeg_data_new.hex -w 640 --height 480 -o result.jpg

# 让工具自动推测图像尺寸（基于数据大小）
python hdmi_hex_to_jpeg.py output/jpeg_data_new.hex
```

**参数说明:**
- `input_file`: 输入的hex文件路径
- `-w, --width`: 图像宽度
- `--height`: 图像高度  
- `-o, --output`: 输出JPEG文件路径
- `-a, --auto`: 自动处理output目录中的hex文件

### 2. `hdmi_hex_analyzer.py` - 数据分析工具
分析hex文件内容，提供数据统计和格式检查。

**功能特点:**
- 统计hex数据的行数和格式
- 检测可能的JPEG标记
- 显示数据范围和分布
- 验证文件格式正确性

**使用方法:**

```bash
# 分析指定文件
python hdmi_hex_analyzer.py output/jpeg_data_new.hex

# 分析output目录中的所有hex文件
python hdmi_hex_analyzer.py -a

# 默认分析最新的JPEG相关hex文件
python hdmi_hex_analyzer.py
```

## 输出文件说明

仿真通常会生成以下hex文件：

- `jpeg_data.hex`: 旧版输出格式
- `jpeg_data_new.hex`: 新版输出格式（推荐使用）
- `video_data.hex`: 视频数据（原始像素数据）

## 常见问题

### Q: 转换后的JPEG文件无法打开或显示异常
**A:** 
1. 检查图像尺寸是否正确，使用 `-w` 和 `--height` 参数指定正确尺寸
2. 使用 `hdmi_hex_analyzer.py` 分析数据格式是否正确
3. 确认仿真是否正确生成了JPEG数据

### Q: 如何确定正确的图像尺寸？
**A:**
1. 查看仿真参数中的VIDEO_WIDTH和VIDEO_HEIGHT设置
2. 使用数据分析工具查看数据量，估算合理尺寸
3. 尝试常见尺寸：320x240, 640x480, 800x600等

### Q: hex文件格式要求
**A:**
- 每行必须是8个十六进制字符（代表32位数据）
- 支持大小写字母
- 忽略空行和以//或#开头的注释行

## 工作流程示例

1. **运行HDMI JPEG仿真**
   ```bash
   cd c:\_Project\Pangu\sim\hdmi_in_with_jpeg_sim
   # 运行仿真脚本...
   ```

2. **分析输出数据**
   ```bash
   python hdmi_hex_analyzer.py
   ```

3. **转换为JPEG图片**
   ```bash
   python hdmi_hex_to_jpeg.py -a -w 640 --height 480
   ```

4. **查看结果**
   使用图片查看器打开生成的JPEG文件

## 技术说明

### JPEG文件结构
工具生成的JPEG文件包含：
- SOI (Start of Image) 标记
- APP0段 (JFIF信息)
- DQT (量化表) - Y和CbCr分量
- SOF0 (帧头) - 包含图像尺寸信息
- DHT (哈夫曼表) - DC和AC表
- SOS (扫描开始) 标记
- 图像数据 (来自仿真输出)
- EOI (End of Image) 标记

### 数据格式
- 输入：32位十六进制值 (大端序)
- 输出：标准JPEG格式文件
- 颜色空间：YCbCr (JPEG标准)

## 故障排除

如果遇到问题，请：

1. 首先运行数据分析工具检查文件格式
2. 确认仿真输出的数据是有效的JPEG编码数据
3. 检查图像尺寸设置是否与仿真参数一致
4. 查看工具输出的详细信息和错误提示

## 更新历史

- v1.0: 初始版本，支持基本的hex到JPEG转换
- 基于 `c:\_Project\Pangu\JPEG\sim\jpeg_core_to_jpg.py` 开发
- 针对HDMI仿真输出格式进行了优化
