# 基于 Pango 的远程实验平台设计——FPGA端工程

第九届（2025）集创赛紫光同创国二作品，FPGA端的工程

除此以外还有服务器端的工程，暂时没有上传。

![总览图](asstes\image1.png)

[初赛视频](bilibili.com/video/BV125JezzELP/)（该视频是很早期的设计，部分功能和界面有很大改动。欢迎来b站一键三连+关注）

有时间可能会录赛后总结，但是紫光已经把借的板子收回了。这byd紫光连板子都不肯送，岂可修（

- 整体架构采用双FPGA架构，参考了[清华数字电路试验箱](bilibili.com/video/BV125JezzELP/)的设计方案；
- Ctrl_FPAG使用的是**野火的PG2L100H开发板**；Lab_FPGA使用的是**小眼睛的PG2L100H开发板**。本工程绝大部分代码在Ctrl_FPGA上运行，只有`/examination`文件夹内实验工程是运行在Lab_FPGA上的。
- Ctrl_FPGA端使用AXI-4互联，接了**3个Master，12个Slave**，支持跨时钟域、超前传输、乱序等特性；
- 通过**以太网UDP自定义协议 - AXI_MASTER**实现与服务器的通信。
- 关于IP地址处理，系统在启动后3s内按任意按键可以进入admin_mode，该模式下板卡允许通过ARP与未知IP地址的服务端进行暂时性连接，服务端可以更改存储于EEPROM中的板卡IP地址、MAC地址和服务端的IP、MAC。修改完毕后再重新启动，等待3s进入user_mode，该模式下板卡不回应任何ARP请求，只根据EEPROM存储的IP和MAC响应服务端。
- 视频采集支持两种方案，一种是通过FPGA接OV5640采集，服务器控制FPGA的I2C模块配置摄像头；一种是服务器直接连USB摄像头采集。
- 模块设计有：逻辑分析仪、AXI总线、DDR3从机、DDS信号发生器、DEBUGGER模块、DSO示波器、HDMI采集、I2C从机（支持I2C和SCCB）、JTAG时序模拟从机、Flash固化从机、DMA数据搬运、UDP主机、系统状态控制从机、矩阵键盘、数码管、WS2812等外设模拟从机。

有几个点需要注意一下：

`/IPCORE` 文件夹内是Pango的相关IP核文件，内部已经用文件夹标注出各个IP被什么模块使用。

`/sim`文件夹内是Modelsim仿真相关文件，包括各个版本的顶层模块仿真、子模块仿真。可以直接点击`do.bat`运行。

`/Top/top_project`文件夹内的顶层文件是最终版本的顶层工程。我没有把紫光的Pango Design Suite工程传上去，因此需要自己创建工程添加模块。
