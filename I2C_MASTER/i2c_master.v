module i2c_master(
    input wire clk,
    input wire rstn,

    input  wire scl_in,
    output wire scl_out,
    output  reg scl_enable,

    input wire sda_in,
    output reg sda_out,
    output reg sda_enable,

    //cmd interface
    input  wire        cmd_valid,
    output wire        cmd_ready,
    output wire        cmd_done,
    output wire        cmd_error,
    output wire        cmd_rollback,

    input  wire [ 6:0] i2c_slave_addr,
    input  wire        i2c_read_write,
    input  wire        i2c_read_ifstop, //读操作时，是否在DUMMY数据发完后先STOP再START，还是直接START
    input  wire        i2c_addr_length,
    input  wire [15:0] i2c_start_addr,
    input  wire [15:0] i2c_data_length,

    output  reg        wr_data_ready,
    input  wire [ 7:0] wr_data,
    output wire        rd_data_valid,
    output  reg [ 7:0] rd_data
);

//I2C主机的一次传输需要知道的参数有：
// 1. 7位从机地址
// 2. 读写标志位
// 3. 起始地址（地址可能是7位或10位或12位的）
// 4. 数据长度

reg [ 6:0] i2c_slave_addr_reg;
reg        i2c_read_write_reg;
reg        i2c_read_ifstop_reg;
reg        i2c_addr_length_reg;
reg [15:0] i2c_start_addr_reg;
reg [15:0] i2c_data_length_reg;

wire i2c_data_update;
wire i2c_data_capture;
wire i2c_start_flag;
wire i2c_stop_flag;

reg [4:0] st_iic_cu, st_iic_nt; //内层状态机，一个循环完成一个字节的读写
localparam ST_IIC_IDLE          = 5'b00000;
localparam ST_IIC_GET_SUBCMD    = 5'b00001;
localparam ST_IIC_BYTE7_UPDATE  = 5'b00010;
localparam ST_IIC_BYTE7_CAPTURE = 5'b00011;
localparam ST_IIC_BYTE6_UPDATE  = 5'b00100;
localparam ST_IIC_BYTE6_CAPTURE = 5'b00101;
localparam ST_IIC_BYTE5_UPDATE  = 5'b00110;
localparam ST_IIC_BYTE5_CAPTURE = 5'b00111;
localparam ST_IIC_BYTE4_UPDATE  = 5'b01000;
localparam ST_IIC_BYTE4_CAPTURE = 5'b01001;
localparam ST_IIC_BYTE3_UPDATE  = 5'b01010;
localparam ST_IIC_BYTE3_CAPTURE = 5'b01011;
localparam ST_IIC_BYTE2_UPDATE  = 5'b01100;
localparam ST_IIC_BYTE2_CAPTURE = 5'b01101;
localparam ST_IIC_BYTE1_UPDATE  = 5'b01110;
localparam ST_IIC_BYTE1_CAPTURE = 5'b01111;
localparam ST_IIC_BYTE0_UPDATE  = 5'b10000;
localparam ST_IIC_BYTE0_CAPTURE = 5'b10001;
localparam ST_IIC_ACK_UPDATE    = 5'b10010;
localparam ST_IIC_ACK_CAPTURE   = 5'b10011;
localparam ST_IIC_BYTE_DONE     = 5'b10100;
localparam ST_IIC_BYTE_DONE_D   = 5'b10101;

reg [3:0] st_module_cu, st_module_nt; //外层状态机，一个循环完成外部命令的读写
localparam ST_MODULE_IDLE                          = 4'b0000;
localparam ST_MODULE_ERROR_START                   = 4'b0001;
localparam ST_MODULE_START                         = 4'b0010;
localparam ST_MODULE_TRANS_WR_IIC_ADDR             = 4'b0011;
localparam ST_MODULE_TRANS_WR_START_ADDR_D10       = 4'b0100;
localparam ST_MODULE_TRANS_WR_START_ADDR_D7        = 4'b0101;
localparam ST_MODULE_TRANS_WR_DATA                 = 4'b0110;
localparam ST_MODULE_TRANS_RD_IIC_ADDR_DUMMY       = 4'b0111;
localparam ST_MODULE_TRANS_RD_START_ADDR_D10_DUMMY = 4'b1000;
localparam ST_MODULE_TRANS_RD_START_ADDR_D7_DUMMY  = 4'b1001;
localparam ST_MODULE_RESTOP                        = 4'b1010;
localparam ST_MODULE_RESTART                       = 4'b1011;
localparam ST_MODULE_TRANS_RD_IIC_ADDR             = 4'b1100;
localparam ST_MODULE_TRANS_RD_DATA                 = 4'b1101;
localparam ST_MODULE_STOP                          = 4'b1110;

reg [7:0] subcmd_byte_data;
reg       subcmd_sda_ctrl ;
reg       subcmd_ack_set  ;

reg [31:0] cooling_cnt;

reg [3:0] error_cnt;
wire i2c_error_flag = (st_iic_cu == ST_IIC_ACK_CAPTURE) && (i2c_data_capture) && (sda_in != subcmd_ack_set);
wire i2c_error_timeout = (i2c_error_flag) && (error_cnt == 4'b0111);

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        i2c_slave_addr_reg  <= 0;
        i2c_read_write_reg  <= 0;
        i2c_addr_length_reg <= 0;
        i2c_start_addr_reg  <= 0;
    end else if(cmd_valid && cmd_ready) begin
        i2c_slave_addr_reg  <= i2c_slave_addr;
        i2c_read_write_reg  <= i2c_read_write;
        i2c_read_ifstop_reg <= i2c_read_ifstop;
        i2c_addr_length_reg <= i2c_addr_length;
        i2c_start_addr_reg  <= i2c_start_addr;
    end else begin
        i2c_slave_addr_reg  <= i2c_slave_addr_reg;
        i2c_read_write_reg  <= i2c_read_write_reg;
        i2c_addr_length_reg <= i2c_addr_length_reg;
        i2c_start_addr_reg  <= i2c_start_addr_reg;
    end
end

reg [7:0] i2c_data_length_error_use_reg;
always @(posedge clk or negedge rstn) begin
    if(~rstn) i2c_data_length_error_use_reg <= 0;
    else if((cmd_valid && cmd_ready)) i2c_data_length_error_use_reg <= i2c_data_length;
    else i2c_data_length_error_use_reg <= i2c_data_length_error_use_reg;
end
always @(posedge clk or negedge rstn) begin
    if(~rstn) i2c_data_length_reg <= 0;
    else if((cmd_valid && cmd_ready)) i2c_data_length_reg <= i2c_data_length;
    else if(st_module_cu == ST_MODULE_ERROR_START) i2c_data_length_reg <= i2c_data_length_error_use_reg;
    else if((st_module_cu == ST_MODULE_TRANS_WR_DATA || st_module_cu == ST_MODULE_TRANS_RD_DATA) && (st_iic_cu == ST_IIC_BYTE_DONE) && (i2c_data_length_reg != 0)) i2c_data_length_reg <= i2c_data_length_reg - 1;
    else i2c_data_length_reg <= i2c_data_length_reg;
end


//wr_data_ready, subcmd_byte_data, wr_data, addr
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin subcmd_byte_data <= 0;
    end else if(st_iic_cu == ST_IIC_GET_SUBCMD) case(st_module_cu)
            ST_MODULE_TRANS_WR_IIC_ADDR            : begin subcmd_byte_data <= {i2c_slave_addr_reg, 1'b0}; wr_data_ready <= 1'b0; end
            ST_MODULE_TRANS_WR_START_ADDR_D10      : begin subcmd_byte_data <= i2c_start_addr_reg[15:8]  ; wr_data_ready <= 1'b0; end
            ST_MODULE_TRANS_WR_START_ADDR_D7       : begin subcmd_byte_data <= i2c_start_addr_reg[7:0]   ; wr_data_ready <= 1'b0; end
            ST_MODULE_TRANS_WR_DATA                : begin subcmd_byte_data <= wr_data                   ; wr_data_ready <= 1'b1; end
            ST_MODULE_TRANS_RD_IIC_ADDR_DUMMY      : begin subcmd_byte_data <= {i2c_slave_addr_reg, 1'b0}; wr_data_ready <= 1'b0; end
            ST_MODULE_TRANS_RD_START_ADDR_D10_DUMMY: begin subcmd_byte_data <= i2c_start_addr_reg[15:8]  ; wr_data_ready <= 1'b0; end
            ST_MODULE_TRANS_RD_START_ADDR_D7_DUMMY : begin subcmd_byte_data <= i2c_start_addr_reg[7:0]   ; wr_data_ready <= 1'b0; end
            ST_MODULE_TRANS_RD_IIC_ADDR            : begin subcmd_byte_data <= {i2c_slave_addr_reg, 1'b1}; wr_data_ready <= 1'b0; end
            ST_MODULE_TRANS_RD_DATA                : begin subcmd_byte_data <= 8'h00                     ; wr_data_ready <= 1'b0; end
            default                                : begin subcmd_byte_data <= subcmd_byte_data          ; wr_data_ready <= 1'b0; end
    endcase else begin
        subcmd_byte_data <= subcmd_byte_data;
        wr_data_ready <= 1'b0;
    end
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) subcmd_sda_ctrl <= 1'b0;
    else if(st_iic_cu == ST_IIC_GET_SUBCMD)
        if(st_module_cu == ST_MODULE_TRANS_RD_DATA) subcmd_sda_ctrl <= 1'b0;
        else subcmd_sda_ctrl <= 1'b1;
    else subcmd_sda_ctrl <= subcmd_sda_ctrl;
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) subcmd_ack_set <= 1'b0;
    else if(st_iic_cu == ST_IIC_GET_SUBCMD)
        if(st_module_cu == ST_MODULE_TRANS_RD_DATA && (i2c_data_length_reg == 0)) subcmd_ack_set <= 1'b1;
        else subcmd_ack_set <= 1'b0;
    else subcmd_ack_set <= subcmd_ack_set;
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        st_iic_cu <= ST_IIC_IDLE;
    end else begin
        st_iic_cu <= st_iic_nt;
    end
end

always @(*) begin
    if(i2c_error_flag) st_iic_nt <= ST_IIC_IDLE;
    else if(i2c_start_flag) st_iic_nt <= ST_IIC_IDLE;
    else case(st_iic_cu)
        ST_IIC_IDLE         : st_iic_nt <= ((st_module_cu != ST_MODULE_IDLE) && (st_module_cu != ST_MODULE_START) && (st_module_cu != ST_MODULE_STOP) && (st_module_cu != ST_MODULE_RESTOP) && (st_module_cu != ST_MODULE_RESTART)) ? (ST_IIC_GET_SUBCMD) : (ST_IIC_IDLE);
        ST_IIC_GET_SUBCMD   : st_iic_nt <= ST_IIC_BYTE7_UPDATE;
        ST_IIC_BYTE7_UPDATE : st_iic_nt <= (i2c_data_update ) ? (ST_IIC_BYTE7_CAPTURE) : (ST_IIC_BYTE7_UPDATE );
        ST_IIC_BYTE7_CAPTURE: st_iic_nt <= (i2c_data_capture) ? (ST_IIC_BYTE6_UPDATE ) : (ST_IIC_BYTE7_CAPTURE);
        ST_IIC_BYTE6_UPDATE : st_iic_nt <= (i2c_data_update ) ? (ST_IIC_BYTE6_CAPTURE) : (ST_IIC_BYTE6_UPDATE );
        ST_IIC_BYTE6_CAPTURE: st_iic_nt <= (i2c_data_capture) ? (ST_IIC_BYTE5_UPDATE ) : (ST_IIC_BYTE6_CAPTURE);
        ST_IIC_BYTE5_UPDATE : st_iic_nt <= (i2c_data_update ) ? (ST_IIC_BYTE5_CAPTURE) : (ST_IIC_BYTE5_UPDATE );
        ST_IIC_BYTE5_CAPTURE: st_iic_nt <= (i2c_data_capture) ? (ST_IIC_BYTE4_UPDATE ) : (ST_IIC_BYTE5_CAPTURE);
        ST_IIC_BYTE4_UPDATE : st_iic_nt <= (i2c_data_update ) ? (ST_IIC_BYTE4_CAPTURE) : (ST_IIC_BYTE4_UPDATE );
        ST_IIC_BYTE4_CAPTURE: st_iic_nt <= (i2c_data_capture) ? (ST_IIC_BYTE3_UPDATE ) : (ST_IIC_BYTE4_CAPTURE);
        ST_IIC_BYTE3_UPDATE : st_iic_nt <= (i2c_data_update ) ? (ST_IIC_BYTE3_CAPTURE) : (ST_IIC_BYTE3_UPDATE );
        ST_IIC_BYTE3_CAPTURE: st_iic_nt <= (i2c_data_capture) ? (ST_IIC_BYTE2_UPDATE ) : (ST_IIC_BYTE3_CAPTURE);
        ST_IIC_BYTE2_UPDATE : st_iic_nt <= (i2c_data_update ) ? (ST_IIC_BYTE2_CAPTURE) : (ST_IIC_BYTE2_UPDATE );
        ST_IIC_BYTE2_CAPTURE: st_iic_nt <= (i2c_data_capture) ? (ST_IIC_BYTE1_UPDATE ) : (ST_IIC_BYTE2_CAPTURE);
        ST_IIC_BYTE1_UPDATE : st_iic_nt <= (i2c_data_update ) ? (ST_IIC_BYTE1_CAPTURE) : (ST_IIC_BYTE1_UPDATE );
        ST_IIC_BYTE1_CAPTURE: st_iic_nt <= (i2c_data_capture) ? (ST_IIC_BYTE0_UPDATE ) : (ST_IIC_BYTE1_CAPTURE);
        ST_IIC_BYTE0_UPDATE : st_iic_nt <= (i2c_data_update ) ? (ST_IIC_BYTE0_CAPTURE) : (ST_IIC_BYTE0_UPDATE );
        ST_IIC_BYTE0_CAPTURE: st_iic_nt <= (i2c_data_capture) ? (ST_IIC_ACK_UPDATE   ) : (ST_IIC_BYTE0_CAPTURE);
        ST_IIC_ACK_UPDATE   : st_iic_nt <= (i2c_data_update ) ? (ST_IIC_ACK_CAPTURE  ) : (ST_IIC_ACK_UPDATE   );
        ST_IIC_ACK_CAPTURE  : st_iic_nt <= (i2c_data_capture) ? (ST_IIC_BYTE_DONE    ) : (ST_IIC_ACK_CAPTURE  );
        ST_IIC_BYTE_DONE    : st_iic_nt <= ST_IIC_BYTE_DONE_D;
        ST_IIC_BYTE_DONE_D  : st_iic_nt <= ((st_module_cu != ST_MODULE_IDLE) && (st_module_cu != ST_MODULE_START) && (st_module_cu != ST_MODULE_STOP) && (st_module_cu != ST_MODULE_RESTOP) && (st_module_cu != ST_MODULE_RESTART)) ? (ST_IIC_GET_SUBCMD) : (ST_IIC_IDLE);
        default             : st_iic_nt <= ST_IIC_IDLE;
    endcase
end

//sda_out
always @(posedge clk or negedge rstn) begin
    if(~rstn) sda_out <= 1'b1;
    else if(st_module_cu == ST_MODULE_START && (~scl_in) && scl_enable) sda_out <= 1'b1;
    else if(st_module_cu == ST_MODULE_START && (scl_in) && scl_enable) sda_out <= 1'b0;
    else if(st_module_cu == ST_MODULE_RESTOP && (~scl_in) && scl_enable) sda_out <= 1'b0;
    else if(st_module_cu == ST_MODULE_RESTOP && i2c_data_capture) sda_out <= 1'b1;
    else if(st_module_cu == ST_MODULE_RESTART && (~scl_in) && scl_enable) sda_out <= 1'b1;
    else if(st_module_cu == ST_MODULE_RESTART && i2c_data_capture) sda_out <= 1'b0;
    else if(st_module_cu == ST_MODULE_STOP && (~scl_in) && scl_enable) sda_out <= 1'b0;
    else if(st_module_cu == ST_MODULE_STOP && i2c_data_capture) sda_out <= 1'b1;
    else if(i2c_data_update) case(st_iic_cu)
        ST_IIC_BYTE7_UPDATE : sda_out <= subcmd_byte_data[7];
        ST_IIC_BYTE6_UPDATE : sda_out <= subcmd_byte_data[6];
        ST_IIC_BYTE5_UPDATE : sda_out <= subcmd_byte_data[5];
        ST_IIC_BYTE4_UPDATE : sda_out <= subcmd_byte_data[4];
        ST_IIC_BYTE3_UPDATE : sda_out <= subcmd_byte_data[3];
        ST_IIC_BYTE2_UPDATE : sda_out <= subcmd_byte_data[2];
        ST_IIC_BYTE1_UPDATE : sda_out <= subcmd_byte_data[1];
        ST_IIC_BYTE0_UPDATE : sda_out <= subcmd_byte_data[0];
        ST_IIC_ACK_UPDATE   : sda_out <= subcmd_ack_set;
        default             : sda_out <= 1'b1;
    endcase
    else sda_out <= sda_out;
end

//sda_enable
always @(posedge clk or negedge rstn) begin
    if(~rstn) sda_enable <= 1'b0;
    else if(st_module_cu == ST_MODULE_IDLE) sda_enable <= 1'b0;
    else if(st_module_cu == ST_MODULE_START) sda_enable <= 1'b1;
    else if(i2c_data_update) begin
        if(st_iic_cu == ST_IIC_BYTE7_UPDATE) sda_enable <= subcmd_sda_ctrl;
        else if(st_iic_cu == ST_IIC_ACK_UPDATE) sda_enable <= ~subcmd_sda_ctrl;
        else if(st_module_cu == ST_MODULE_STOP || st_module_cu == ST_MODULE_RESTOP || st_module_cu == ST_MODULE_RESTART) sda_enable <= 1'b1;
        else sda_enable <= sda_enable;
    end else sda_enable <= sda_enable;
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        st_module_cu <= ST_MODULE_IDLE;
    end else begin
        st_module_cu <= st_module_nt;
    end
end

always @(*) begin
    if(i2c_error_timeout) st_module_nt <= ST_MODULE_STOP;
    else if(i2c_error_flag) st_module_nt <= ST_MODULE_ERROR_START;
    else case(st_module_cu)
        ST_MODULE_IDLE                         : st_module_nt <= (cmd_valid && cmd_ready) ? (ST_MODULE_START) : (ST_MODULE_IDLE);
        ST_MODULE_ERROR_START                  : st_module_nt <= ST_MODULE_START;
        ST_MODULE_START                        : st_module_nt <= (i2c_start_flag) ? ((i2c_read_write_reg == 0)?(ST_MODULE_TRANS_WR_IIC_ADDR):(ST_MODULE_TRANS_RD_IIC_ADDR_DUMMY)) : (ST_MODULE_START);
        ST_MODULE_TRANS_WR_IIC_ADDR            : st_module_nt <= ((st_iic_cu == ST_IIC_BYTE_DONE)) ? ((i2c_addr_length_reg)?(ST_MODULE_TRANS_WR_START_ADDR_D10):(ST_MODULE_TRANS_WR_START_ADDR_D7)) : (ST_MODULE_TRANS_WR_IIC_ADDR);
        ST_MODULE_TRANS_WR_START_ADDR_D10      : st_module_nt <= ((st_iic_cu == ST_IIC_BYTE_DONE)) ? (ST_MODULE_TRANS_WR_START_ADDR_D7) : (ST_MODULE_TRANS_WR_START_ADDR_D10);
        ST_MODULE_TRANS_WR_START_ADDR_D7       : st_module_nt <= ((st_iic_cu == ST_IIC_BYTE_DONE)) ? (ST_MODULE_TRANS_WR_DATA) : (ST_MODULE_TRANS_WR_START_ADDR_D7);
        ST_MODULE_TRANS_WR_DATA                : st_module_nt <= ((st_iic_cu == ST_IIC_BYTE_DONE) && (i2c_data_length_reg == 0)) ? (ST_MODULE_STOP) : (ST_MODULE_TRANS_WR_DATA);
        ST_MODULE_TRANS_RD_IIC_ADDR_DUMMY      : st_module_nt <= ((st_iic_cu == ST_IIC_BYTE_DONE)) ? ((i2c_addr_length_reg)?(ST_MODULE_TRANS_RD_START_ADDR_D10_DUMMY):(ST_MODULE_TRANS_RD_START_ADDR_D7_DUMMY)) : (ST_MODULE_TRANS_RD_IIC_ADDR_DUMMY);
        ST_MODULE_TRANS_RD_START_ADDR_D10_DUMMY: st_module_nt <= ((st_iic_cu == ST_IIC_BYTE_DONE)) ? (ST_MODULE_TRANS_RD_START_ADDR_D7_DUMMY) : (ST_MODULE_TRANS_RD_START_ADDR_D10_DUMMY);
        ST_MODULE_TRANS_RD_START_ADDR_D7_DUMMY : st_module_nt <= ((st_iic_cu == ST_IIC_BYTE_DONE)) ? ((i2c_read_ifstop_reg)?(ST_MODULE_RESTOP):(ST_MODULE_RESTART)) : (ST_MODULE_TRANS_RD_START_ADDR_D7_DUMMY);
        ST_MODULE_RESTOP                       : st_module_nt <= (i2c_stop_flag) ? (ST_MODULE_RESTART) : (ST_MODULE_RESTOP);
        ST_MODULE_RESTART                      : st_module_nt <= (i2c_start_flag) ? (ST_MODULE_TRANS_RD_IIC_ADDR) : (ST_MODULE_RESTART);
        ST_MODULE_TRANS_RD_IIC_ADDR            : st_module_nt <= ((st_iic_cu == ST_IIC_BYTE_DONE)) ? (ST_MODULE_TRANS_RD_DATA) : (ST_MODULE_TRANS_RD_IIC_ADDR);
        ST_MODULE_TRANS_RD_DATA                : st_module_nt <= ((st_iic_cu == ST_IIC_BYTE_DONE) && (i2c_data_length_reg == 0)) ? (ST_MODULE_STOP) : (ST_MODULE_TRANS_RD_DATA);
        ST_MODULE_STOP                         : st_module_nt <= (i2c_stop_flag) ? (ST_MODULE_IDLE) : (ST_MODULE_STOP);
        default                                : st_module_nt <= ST_MODULE_IDLE;
    endcase
end

//rd_data, rd_data_valid
assign rd_data_valid = (st_iic_cu == ST_IIC_BYTE_DONE) && (st_module_cu == ST_MODULE_TRANS_RD_DATA);
always @(posedge clk or negedge rstn) begin
    if(~rstn) rd_data <= 8'h00;
    else if(i2c_data_capture) case(st_iic_cu)
        ST_IIC_BYTE7_CAPTURE : rd_data[7] <= sda_in;
        ST_IIC_BYTE6_CAPTURE : rd_data[6] <= sda_in;
        ST_IIC_BYTE5_CAPTURE : rd_data[5] <= sda_in;
        ST_IIC_BYTE4_CAPTURE : rd_data[4] <= sda_in;
        ST_IIC_BYTE3_CAPTURE : rd_data[3] <= sda_in;
        ST_IIC_BYTE2_CAPTURE : rd_data[2] <= sda_in;
        ST_IIC_BYTE1_CAPTURE : rd_data[1] <= sda_in;
        ST_IIC_BYTE0_CAPTURE : rd_data[0] <= sda_in;
        default              : rd_data    <= rd_data;
    endcase
end

//scl_enable
always @(posedge clk or negedge rstn) begin
    if(~rstn) scl_enable <= 1'b0;
    else if(cmd_valid && cmd_ready) scl_enable <= 1'b1;
    else if(st_module_cu == ST_MODULE_IDLE && (cooling_cnt == 0)) scl_enable <= 1'b0;
    else scl_enable <= scl_enable;
end

//cmd_ready, cmd_done, cmd_error
assign cmd_ready = (st_module_cu == ST_MODULE_IDLE && (cooling_cnt == 0)) ? 1'b1 : 1'b0;
assign cmd_done  = (st_module_cu == ST_MODULE_IDLE) ? 1'b1 : 1'b0;
assign cmd_error = i2c_error_timeout;
assign cmd_rollback = i2c_error_flag;

i2c_scl_gen #(
    .SCL_RISE_CYCLE (200),
    .SCL_HIGH_CYCLE (200),
    .SCL_FALL_CYCLE (200),
    .SCL_LOW_CYCLE  (200)
)i2c_scl_gen_inst(
    .clk             (clk),
    .rstn            (rstn),
    .sda_in          (sda_in),
    .scl_in          (scl_in),
    .scl_out         (scl_out),
    .scl_enable      (scl_enable),
    .i2c_data_update (i2c_data_update),
    .i2c_data_capture(i2c_data_capture),
    .i2c_start_flag  (i2c_start_flag),
    .i2c_stop_flag   (i2c_stop_flag)
);

//每一次读写都需要50ms的冷却时间，50MHz时钟下，50M/100K=500次时钟周期
//怎么不好使
always @(posedge clk or negedge rstn) begin
    if(~rstn) cooling_cnt <= 0;
    else if(st_module_cu == ST_MODULE_STOP && st_module_nt == ST_MODULE_IDLE) cooling_cnt <= cooling_cnt + 1'b1;
    else if(cooling_cnt <= 500 && cooling_cnt > 0) cooling_cnt <= cooling_cnt + i2c_data_capture;
    else cooling_cnt <= 0;
end

//如果传回的ACK=1，则error_cnt+1，状态机跳转至ST_MODULE_START状态，重新开始。若error_cnt=7，则跳转至ST_MODULE_STOP状态，等待下一个命令。
always @(posedge clk or negedge rstn) begin
    if(~rstn) error_cnt <= 0;
    else if(st_module_cu == ST_MODULE_IDLE) error_cnt <= 0;
    else if(i2c_error_flag) error_cnt <= error_cnt + 1;
    else error_cnt <= error_cnt;
end

endmodule //i2c_master