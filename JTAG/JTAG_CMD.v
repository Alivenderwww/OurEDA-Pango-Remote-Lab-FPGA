`define JTAG_DR_BYPASS   10'b1111111111 //旁路指令        
`define JTAG_DR_SAMPLE   10'b1010000000 //采样指令        
`define JTAG_DR_PRELOAD  10'b1010000000 //预装指令        
`define JTAG_DR_EXTEST   10'b1010000001 //外测试指令      
`define JTAG_DR_INTEST   10'b1010000010 //内测试指令      
`define JTAG_DR_IDCODE   10'b1010000011 //标识指令        
`define JTAG_DR_HIGHZ    10'b1010000101 //高阻指令        
`define JTAG_DR_JRST     10'b1010001010 //复位指令        
`define JTAG_DR_CFGI     10'b1010001011 //配置指令        
`define JTAG_DR_CFGO     10'b1010001100 //回读指令        
`define JTAG_DR_JWAKEUP  10'b1010001101 //唤醒指令        
`define JTAG_DR_READ_UID 10'b0101001100 //读UID指令       
`define JTAG_DR_RDSR     10'b0101011001 //读状态寄存器指令

`define BITSTREAM        10'b0001110101


`define CMD_JTAG_CLOSE_TEST    4'b0000 //进入TEST_LOGIC_RESET态
`define CMD_JTAG_RUN_TEST      4'b0001 //进入RUN_TEST_IDLE态
`define CMD_JTAG_LOAD_IR       4'b0010 //RESET -> RTI -> SDR -> SIR -> CIR -> SHIFTIR(循环) -> EX1IR -> UIR -> RTI
`define CMD_JTAG_LOAD_DR       4'b0011 //RESET -> RTI -> SDR -> CDR -> SHIFTDR(循环) -> EX1DR -> UDR -> RTI
`define CMD_JTAG_IDLE_DELAY    4'b0100 //RTI(循环)

`define TAP_UNKNOWN           16'b0000_0000_0000_0000
`define TAP_TEST_LOGIC_RESET  16'b0000_0000_0000_0001
`define TAP_RUN_TEST_IDLE     16'b0000_0000_0000_0010
`define TAP_SELECT_DR_SCAN    16'b0000_0000_0000_0100
`define TAP_CAPTURE_DR        16'b0000_0000_0000_1000
`define TAP_SHIFT_DR          16'b0000_0000_0001_0000
`define TAP_EXIT1_DR          16'b0000_0000_0010_0000
`define TAP_PAUSE_DR          16'b0000_0000_0100_0000
`define TAP_EXIT2_DR          16'b0000_0000_1000_0000
`define TAP_UPDATE_DR         16'b0000_0001_0000_0000
`define TAP_SELECT_IR_SCAN    16'b0000_0010_0000_0000
`define TAP_CAPTURE_IR        16'b0000_0100_0000_0000
`define TAP_SHIFT_IR          16'b0000_1000_0000_0000
`define TAP_EXIT1_IR          16'b0001_0000_0000_0000
`define TAP_PAUSE_IR          16'b0010_0000_0000_0000
`define TAP_EXIT2_IR          16'b0100_0000_0000_0000
`define TAP_UPDATE_IR         16'b1000_0000_0000_0000