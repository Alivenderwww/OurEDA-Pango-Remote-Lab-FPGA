module streaming_axi_slave(
    input wire        clk,
    input wire        rstn,

    output logic [15:0]  rd_capture_rstn,
    output logic [15:0]  wr_capture_rstn,

    output logic [31:0]  start_write_addr0,
    output logic [31:0]  end_write_addr0,
    output logic [31:0]  start_write_addr1,
    output logic [31:0]  end_write_addr1,

    output logic [31:0]  start_read_addr0,
    output logic [31:0]  end_read_addr0,

    //hdmi
    input  logic         hdmi_notready,
    input  logic [31:0]  hdmi_height_width,

    //jpeg
    output logic [31:0]  jpeg_height_width,
    output logic         jpeg_add_need_frame_pos,
    output logic [31:0]  jpeg_add_need_frame_num,
    input  logic [31:0]  jpeg_total_need_frame_num,

    input  logic [31:0]  jpeg_save_num,
    output logic         jpeg_rd_info_valid,
    input  logic [31:0]  jpeg_rd_info,
    input  logic         jpeg_rd_info_ready,

    input  logic [13*8*8 - 1:0] Y_Quantizer,
    input  logic [13*8*8 - 1:0] CB_Quantizer,
    input  logic [13*8*8 - 1:0] CR_Quantizer,

    
    //AXI SLAVE interface
    output logic         SLAVE_CLK          ,
    output logic         SLAVE_RSTN         ,
    input  logic [4-1:0] SLAVE_WR_ADDR_ID   ,
    input  logic [31:0]  SLAVE_WR_ADDR      ,
    input  logic [ 7:0]  SLAVE_WR_ADDR_LEN  ,
    input  logic [ 1:0]  SLAVE_WR_ADDR_BURST,
    input  logic         SLAVE_WR_ADDR_VALID,
    output logic         SLAVE_WR_ADDR_READY,
    input  logic [31:0]  SLAVE_WR_DATA      ,
    input  logic [ 3:0]  SLAVE_WR_STRB      ,
    input  logic         SLAVE_WR_DATA_LAST ,
    input  logic         SLAVE_WR_DATA_VALID,
    output logic         SLAVE_WR_DATA_READY,
    output logic [4-1:0] SLAVE_WR_BACK_ID   ,
    output logic [ 1:0]  SLAVE_WR_BACK_RESP ,
    output logic         SLAVE_WR_BACK_VALID,
    input  logic         SLAVE_WR_BACK_READY,
    input  logic [4-1:0] SLAVE_RD_ADDR_ID   ,
    input  logic [31:0]  SLAVE_RD_ADDR      ,
    input  logic [ 7:0]  SLAVE_RD_ADDR_LEN  ,
    input  logic [ 1:0]  SLAVE_RD_ADDR_BURST,
    input  logic         SLAVE_RD_ADDR_VALID,
    output logic         SLAVE_RD_ADDR_READY,
    output logic [4-1:0] SLAVE_RD_BACK_ID   ,
    output logic [31:0]  SLAVE_RD_DATA      ,
    output logic [ 1:0]  SLAVE_RD_DATA_RESP ,
    output logic         SLAVE_RD_DATA_LAST ,
    output logic         SLAVE_RD_DATA_VALID,
    input  logic         SLAVE_RD_DATA_READY);

assign SLAVE_CLK  = clk;
assign SLAVE_RSTN = rstn;

logic [8*8*3-1:0] [12:0] Quantizer;
assign Quantizer = {CR_Quantizer, CB_Quantizer, Y_Quantizer};

localparam [31:0]
    ADDR_CAPTURE_RD_CTRL        = 32'h0000_0000,
    ADDR_CAPTURE_WR_CTRL        = 32'h0000_0001,

    ADDR_START_WRITE_ADDR0      = 32'h0000_0002,
    ADDR_END_WRITE_ADDR0        = 32'h0000_0003,
    ADDR_START_WRITE_ADDR1      = 32'h0000_0004,
    ADDR_END_WRITE_ADDR1        = 32'h0000_0005,
    ADDR_START_READ_ADDR0       = 32'h0000_0006,
    ADDR_END_READ_ADDR0         = 32'h0000_0007,

    ADDR_HDMI_NOTREADY          = 32'h0000_0008,
    ADDR_HDMI_HEIGHT_WIDTH      = 32'h0000_0009,

    ADDR_JPEG_HEIGHT_WIDTH      = 32'h0000_000A,
    ADDR_JPEG_ADD_NEED_FRAME_NUM= 32'h0000_000B,
    ADDR_JPEG_FRAME_SAVE_NUM    = 32'h0000_000C,
    ADDR_FIFO_FRAME_INFO        = 32'h0000_000D,

    ADDR_Y_QUANTIZER_START      = 32'h0000_0100,
    ADDR_Y_QUANTIZER_END        = 32'h0000_013F,
    ADDR_CB_QUANTIZER_START     = 32'h0000_0140,
    ADDR_CB_QUANTIZER_END       = 32'h0000_017F,
    ADDR_CR_QUANTIZER_START     = 32'h0000_0180,
    ADDR_CR_QUANTIZER_END       = 32'h0000_01BF;

//_________________写___通___道_________________//
reg [ 3:0] wr_addr_id;
reg [31:0] wr_addr;
reg [ 3:0] wr_addr_burst;
reg        wr_transcript_error, wr_transcript_error_reg;
//ANALYZER作为SLAVE不接收WR_ADDR_LEN，其DATA线的结束以WR_DATA_LAST为参考。
reg [ 1:0] cu_wrchannel_st, nt_wrchannel_st;
localparam ST_WR_IDLE = 2'b00, //写通道空闲
           ST_WR_DATA = 2'b01, //地址线握手成功，数据线通道开启
           ST_WR_RESP = 2'b10; //写响应
//_________________读___通___道_________________//
reg [ 3:0] rd_addr_id;
reg [31:0] rd_addr;
reg [ 7:0] rd_addr_len;
reg [ 3:0] rd_addr_burst;
reg [ 7:0] rd_data_trans_num;
reg        rd_transcript_error, rd_transcript_error_reg;
reg [ 1:0] cu_rdchannel_st, nt_rdchannel_st;
localparam ST_RD_IDLE = 2'b00, //发送完LAST和RESP，读通道空闲
           ST_RD_DATA = 2'b01; //地址线握手成功，数据线通道开启

//_______________________________________________________________________________//
always @(*) begin
    case (cu_wrchannel_st)
        ST_WR_IDLE: nt_wrchannel_st = (SLAVE_WR_ADDR_VALID && SLAVE_WR_ADDR_READY)?(ST_WR_DATA):(ST_WR_IDLE);
        ST_WR_DATA: nt_wrchannel_st = (SLAVE_WR_DATA_VALID && SLAVE_WR_DATA_READY && SLAVE_WR_DATA_LAST)?(ST_WR_RESP):(ST_WR_DATA);
        ST_WR_RESP: nt_wrchannel_st = (SLAVE_WR_BACK_VALID && SLAVE_WR_BACK_READY)?(ST_WR_IDLE):(ST_WR_RESP);
        default   : nt_wrchannel_st = ST_WR_IDLE;
    endcase
end
always @(posedge clk or negedge rstn) begin
    if(~rstn) cu_wrchannel_st <= ST_WR_IDLE;
    else cu_wrchannel_st <= nt_wrchannel_st;
end
assign SLAVE_WR_ADDR_READY = (rstn) && (cu_wrchannel_st == ST_WR_IDLE);
assign SLAVE_WR_BACK_VALID = (rstn) && (cu_wrchannel_st == ST_WR_RESP);
assign SLAVE_WR_BACK_RESP  = ((rstn) && ((~wr_transcript_error) && (~wr_transcript_error_reg)))?(2'b00):(2'b10);
assign SLAVE_WR_BACK_ID    = wr_addr_id;
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        wr_addr_id    <= 0;
        wr_addr_burst <= 0;
    end else if(SLAVE_WR_ADDR_VALID && SLAVE_WR_ADDR_READY) begin
        wr_addr_id    <= SLAVE_WR_ADDR_ID;
        wr_addr_burst <= SLAVE_WR_ADDR_BURST;
    end else begin
        wr_addr_id    <= wr_addr_id;
        wr_addr_burst <= wr_addr_burst;
    end
end
always @(posedge clk or negedge rstn) begin
    if(~rstn) wr_addr <= 0;
    else if(SLAVE_WR_ADDR_VALID && SLAVE_WR_ADDR_READY) wr_addr <= SLAVE_WR_ADDR;
    else if((wr_addr_burst == 2'b01) && SLAVE_WR_DATA_VALID && SLAVE_WR_DATA_READY) wr_addr <= wr_addr + 1;
    else wr_addr <= wr_addr;
end
always @(*) begin
    if((~rstn) || (cu_wrchannel_st == ST_WR_IDLE) || (cu_wrchannel_st == ST_WR_RESP)) wr_transcript_error = 0;
    else if((wr_addr_burst == 2'b10) || (wr_addr_burst == 2'b11)) wr_transcript_error = 1;
    else wr_transcript_error = 0;
end
always @(posedge clk or negedge rstn) begin
    if((~rstn) || (cu_wrchannel_st == ST_WR_IDLE)) wr_transcript_error_reg <= 0;
    else wr_transcript_error_reg <= (wr_transcript_error)?(1):(wr_transcript_error_reg);
end

//_______________________________________________________________________________//
always @(*) begin
    case (cu_rdchannel_st)
        ST_RD_IDLE: nt_rdchannel_st = (SLAVE_RD_ADDR_VALID && SLAVE_RD_ADDR_READY)?(ST_RD_DATA):(ST_RD_IDLE);
        ST_RD_DATA: nt_rdchannel_st = (SLAVE_RD_DATA_VALID && SLAVE_RD_DATA_READY && SLAVE_RD_DATA_LAST)?(ST_RD_IDLE):(ST_RD_DATA);
        default   : nt_rdchannel_st = ST_RD_IDLE;
    endcase
end
always @(posedge clk or negedge rstn)begin
    if(~rstn) cu_rdchannel_st <= ST_RD_IDLE;
    else cu_rdchannel_st <= nt_rdchannel_st;
end
assign SLAVE_RD_ADDR_READY = (rstn) && (cu_rdchannel_st == ST_RD_IDLE);
always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        rd_addr_id    <= 0;
        rd_addr_burst <= 0;
        rd_addr_len   <= 0;
    end else if(SLAVE_RD_ADDR_VALID && SLAVE_RD_ADDR_READY) begin
        rd_addr_id    <= SLAVE_RD_ADDR_ID;
        rd_addr_burst <= SLAVE_RD_ADDR_BURST;
        rd_addr_len   <= SLAVE_RD_ADDR_LEN;
    end else begin
        rd_addr_id    <= rd_addr_id;
        rd_addr_burst <= rd_addr_burst;
        rd_addr_len   <= rd_addr_len;
    end
end
always @(posedge clk or negedge rstn) begin
    if(~rstn) rd_addr <= 0;
    else if(SLAVE_RD_ADDR_VALID && SLAVE_RD_ADDR_READY) rd_addr <= SLAVE_RD_ADDR;
    else if((rd_addr_burst == 2'b01) && SLAVE_RD_DATA_VALID && SLAVE_RD_DATA_READY) rd_addr <= rd_addr + 1;
    else rd_addr <= rd_addr;
end
always @(posedge clk or negedge rstn) begin
    if(~rstn || (cu_rdchannel_st == ST_RD_IDLE)) rd_data_trans_num <= 0;
    else if(SLAVE_RD_DATA_VALID && SLAVE_RD_DATA_READY) rd_data_trans_num <= rd_data_trans_num + 1;
    else rd_data_trans_num <= rd_data_trans_num;
end
assign SLAVE_RD_DATA_LAST = (rstn) && (cu_rdchannel_st == ST_RD_DATA) && (SLAVE_RD_DATA_VALID) && (rd_data_trans_num == rd_addr_len);
assign SLAVE_RD_BACK_ID = rd_addr_id;
assign SLAVE_RD_DATA_RESP  = ((rstn) && (cu_rdchannel_st == ST_RD_DATA) && ((~rd_transcript_error) && (~rd_transcript_error_reg)))?(2'b00):(2'b10);

integer i;
always @(*) begin
    //写数据READY选通
    if(cu_wrchannel_st == ST_WR_DATA) begin
             SLAVE_WR_DATA_READY = 1;
    end else SLAVE_WR_DATA_READY = 0;
    //读数据VALID选通
    if(cu_rdchannel_st == ST_RD_DATA) case (rd_addr)
        ADDR_FIFO_FRAME_INFO: SLAVE_RD_DATA_VALID = jpeg_rd_info_ready;
        default             : SLAVE_RD_DATA_VALID = 1;
    endcase
    else SLAVE_RD_DATA_VALID = 0;
    //读数据DATA选通
    if(cu_rdchannel_st == ST_RD_DATA) begin
        if(rd_addr >= ADDR_Y_QUANTIZER_START && rd_addr <= ADDR_CR_QUANTIZER_END) begin
            for(i = 0; i < 8*8*3; i++) if(rd_addr[7:0] == i)
                SLAVE_RD_DATA = {19'b0, Quantizer[i]};
                else SLAVE_RD_DATA = 32'hFFFFFFFF; //ERROR，直接跳过默认为全1
        end else case(rd_addr)
            ADDR_CAPTURE_RD_CTRL        : SLAVE_RD_DATA = {16'b0, rd_capture_rstn};
            ADDR_CAPTURE_WR_CTRL        : SLAVE_RD_DATA = {16'b0, wr_capture_rstn};
            ADDR_START_WRITE_ADDR0      : SLAVE_RD_DATA = start_write_addr0;
            ADDR_END_WRITE_ADDR0        : SLAVE_RD_DATA = end_write_addr0;
            ADDR_START_WRITE_ADDR1      : SLAVE_RD_DATA = start_write_addr1;
            ADDR_END_WRITE_ADDR1        : SLAVE_RD_DATA = end_write_addr1;
            ADDR_START_READ_ADDR0       : SLAVE_RD_DATA = start_read_addr0;
            ADDR_END_READ_ADDR0         : SLAVE_RD_DATA = end_read_addr0;
            ADDR_HDMI_NOTREADY          : SLAVE_RD_DATA = {31'b0, hdmi_notready};
            ADDR_HDMI_HEIGHT_WIDTH      : SLAVE_RD_DATA = hdmi_height_width;
            ADDR_JPEG_HEIGHT_WIDTH      : SLAVE_RD_DATA = jpeg_height_width;
            ADDR_JPEG_ADD_NEED_FRAME_NUM: SLAVE_RD_DATA = jpeg_total_need_frame_num;
            ADDR_JPEG_FRAME_SAVE_NUM    : SLAVE_RD_DATA = jpeg_save_num;
            ADDR_FIFO_FRAME_INFO        : SLAVE_RD_DATA = jpeg_rd_info;
            default                     : SLAVE_RD_DATA = 32'hFFFFFFFF; //ERROR，直接跳过默认为全1
        endcase
    end else SLAVE_RD_DATA = 0;
end

always @(*) begin
    if((~rstn) || (cu_rdchannel_st == ST_RD_IDLE)) rd_transcript_error = 0;
    else if((rd_addr_burst == 2'b10) || (rd_addr_burst == 2'b11)) rd_transcript_error = 1;
    else rd_transcript_error = 0;
end
always @(posedge clk or negedge rstn) begin
    if((~rstn) || (cu_rdchannel_st == ST_RD_IDLE)) rd_transcript_error_reg = 0;
    else rd_transcript_error_reg = (rd_transcript_error)?(1):(rd_transcript_error_reg);
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        rd_capture_rstn <= 0;
        wr_capture_rstn <= 0;
        start_write_addr0 <= 0;
        end_write_addr0   <= 0;
        start_write_addr1 <= 0;
        end_write_addr1   <= 0;
        start_read_addr0  <= 0;
        end_read_addr0    <= 0;
        jpeg_height_width       <= 0;
        jpeg_add_need_frame_num <= 0;
        jpeg_add_need_frame_pos <= 0;
    end else if(SLAVE_WR_DATA_VALID && SLAVE_WR_DATA_READY)begin
        case(wr_addr)
            ADDR_CAPTURE_RD_CTRL        : rd_capture_rstn   <= SLAVE_WR_DATA[15:0];
            ADDR_CAPTURE_WR_CTRL        : wr_capture_rstn   <= SLAVE_WR_DATA[15:0];
            ADDR_START_WRITE_ADDR0      : start_write_addr0 <= SLAVE_WR_DATA;
            ADDR_END_WRITE_ADDR0        : end_write_addr0   <= SLAVE_WR_DATA;
            ADDR_START_WRITE_ADDR1      : start_write_addr1 <= SLAVE_WR_DATA;
            ADDR_END_WRITE_ADDR1        : end_write_addr1   <= SLAVE_WR_DATA;
            ADDR_START_READ_ADDR0       : start_read_addr0  <= SLAVE_WR_DATA;
            ADDR_END_READ_ADDR0         : end_read_addr0    <= SLAVE_WR_DATA;
            // ADDR_HDMI_NOTREADY          : read only;
            // ADDR_HDMI_HEIGHT_WIDTH      : read only;
            ADDR_JPEG_HEIGHT_WIDTH      : jpeg_height_width       <= SLAVE_WR_DATA;
            ADDR_JPEG_ADD_NEED_FRAME_NUM: begin
                jpeg_add_need_frame_num <= SLAVE_WR_DATA;
                jpeg_add_need_frame_pos <= 1;
            end
            // ADDR_JPEG_FRAME_SAVE_NUM    : read only;
            // ADDR_FIFO_FRAME_INFO        : read only;
            default: begin
                jpeg_add_need_frame_pos <= 0;
            end
        endcase
    end else begin
        jpeg_add_need_frame_pos <= 0;
    end
end

assign jpeg_rd_info_valid = (cu_rdchannel_st == ST_RD_DATA) && (rd_addr == ADDR_FIFO_FRAME_INFO) && (SLAVE_RD_DATA_VALID);


endmodule