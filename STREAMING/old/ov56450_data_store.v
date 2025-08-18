module ov56450_data_store (
    input wire        clk,
    input wire        rstn,

    input wire [15:0] expect_width, //期望宽度
    input wire [15:0] expect_height, //期望高度

    //camera interface (no need iic)
    input  wire       CCD_PCLK,
    input  wire       CCD_RSTN,
    input  wire       CCD_VSYNC,
    input  wire       CCD_HSYNC, //原理图把HREF和HSYNC搞混了
    input  wire [7:0] CCD_DATA,

    input  wire        trans_once_done,
    input  wire        capture_on,
    input  wire        rd_data_valid,
    output wire        rd_data_ready,
    output wire [31:0] rd_data
);

wire fifo_wr_rst, fifo_wr_en;
wire fifo_rd_rst, fifo_rd_en;
wire almost_full;
wire rd_empty;
wire [13:0] rd_water_level; //读水位线

reg CCD_VSYNC_d1, CCD_VSYNC_d2;
reg CCD_HSYNC_d1, CCD_HSYNC_d2;
reg [7:0] CCD_DATA_d1;
reg [15:0] camera_hcount, camera_vcount;
reg [3:0] expect_width_cnt, expect_height_cnt; //帧计数
wire frame_notready = 0;
reg trans_state;
localparam TRANS_ST_WAIT = 1'b0,
           TRANS_ST_TRANS = 1'b1;
// wire frame_notready = (expect_height_cnt <= 4'd2) || (expect_width_cnt <= 4'd2);

wire CCD_VSYNC_pos = (CCD_VSYNC_d1 == 1'b1 && CCD_VSYNC_d2 == 1'b0);
wire CCD_VSYNC_neg = (CCD_VSYNC_d1 == 1'b0 && CCD_VSYNC_d2 == 1'b1);
wire CCD_HSYNC_pos = (CCD_HSYNC_d1 == 1'b1 && CCD_HSYNC_d2 == 1'b0);
wire CCD_HSYNC_neg = (CCD_HSYNC_d1 == 1'b0 && CCD_HSYNC_d2 == 1'b1);
always @(posedge CCD_PCLK or negedge CCD_RSTN) begin
    if(~CCD_RSTN) begin
        CCD_VSYNC_d1 <= 1'b0;
        CCD_VSYNC_d2 <= 1'b0;
        CCD_HSYNC_d1 <= 1'b0;
        CCD_HSYNC_d2 <= 1'b0;
        CCD_DATA_d1 <= 8'h00;
    end
    else begin
        CCD_VSYNC_d1 <= CCD_VSYNC;
        CCD_VSYNC_d2 <= CCD_VSYNC_d1;
        CCD_HSYNC_d1 <= CCD_HSYNC;
        CCD_HSYNC_d2 <= CCD_HSYNC_d1;
        CCD_DATA_d1 <= CCD_DATA;
        // if(CCD_VSYNC_neg) CCD_DATA_d1 <= 0;
        // else CCD_DATA_d1 <= (~CCD_VSYNC)&&(CCD_HSYNC)?(CCD_DATA_d1+1):(CCD_DATA_d1);
    end
end

always @(posedge CCD_PCLK or negedge CCD_RSTN) begin
    if(~CCD_RSTN) camera_hcount <= 0;
    else if(CCD_VSYNC_neg || CCD_HSYNC_neg) camera_hcount <= 0;
    else if(CCD_HSYNC_d1) camera_hcount <= camera_hcount + 1;
    else camera_hcount <= camera_hcount;
end
always @(posedge CCD_PCLK or negedge CCD_RSTN) begin
    if(~CCD_RSTN) camera_vcount <= 0;
    else if(CCD_VSYNC_neg) camera_vcount <= 0;
    else if(CCD_HSYNC_neg) camera_vcount <= camera_vcount + 1;
    else camera_vcount <= camera_vcount;
end
always @(posedge CCD_PCLK or negedge CCD_RSTN) begin
    if(~CCD_RSTN) expect_width_cnt <= 0;
    else if(CCD_VSYNC_neg) begin
        if((camera_vcount + 0) == expect_height) begin
            if(expect_width_cnt < 4'd15)
                 expect_width_cnt <= expect_width_cnt + 1;
            else expect_width_cnt <= 4'd15;
        end else expect_width_cnt <= 0;
    end else     expect_width_cnt <= expect_width_cnt;
end
always @(posedge CCD_PCLK or negedge CCD_RSTN) begin
    if(~CCD_RSTN) expect_height_cnt <= 0;
    else if(CCD_HSYNC_neg) begin
        if((camera_hcount + 0) == expect_width) begin
            if(expect_height_cnt < 4'd15)
                 expect_height_cnt <= expect_height_cnt + 1;
            else expect_height_cnt <= 4'd15;
        end else expect_height_cnt <= 0;
    end else     expect_height_cnt <= expect_height_cnt;
end

reg [1:0] cu_st_store, nt_st_store;
localparam ST_IDLE = 2'b00, 
           ST_STORE = 2'b01, 
           ST_PAUSE = 2'b10;
//如果FIFO数据有反压，则记录反压时的hcount和vcount并停止存储，等FIFO不再反压并且hcount和vcount与记录的相同后再继续存储。
reg [31:0] pause_camera_hcount, pause_camera_vcount;
always @(posedge CCD_PCLK or negedge CCD_RSTN) begin
    if(~CCD_RSTN) begin
        pause_camera_hcount <= 0;
        pause_camera_vcount <= 0;
    end else begin
        if((cu_st_store == ST_STORE) && (almost_full)) begin
            pause_camera_hcount <= camera_hcount;
            pause_camera_vcount <= camera_vcount;
        end else begin
            pause_camera_hcount <= pause_camera_hcount;
            pause_camera_vcount <= pause_camera_vcount;
        end
    end
end
always @(posedge CCD_PCLK or negedge CCD_RSTN) begin
    if(~CCD_RSTN) cu_st_store <= ST_IDLE;
    else cu_st_store <= nt_st_store;
end
always @(*) begin
    if((~capture_on) || (frame_notready)) nt_st_store = ST_IDLE;
    else case (cu_st_store)
        ST_IDLE : nt_st_store = (CCD_VSYNC_neg)?(ST_STORE):(ST_IDLE);
        ST_STORE: nt_st_store = (almost_full)?(ST_PAUSE):(ST_STORE);
        ST_PAUSE: nt_st_store = ((~almost_full) && (pause_camera_hcount == camera_hcount) && (pause_camera_vcount == camera_vcount))?(ST_STORE):(ST_PAUSE);
    endcase
end

reg fifo_rd_data_valid;
always @(posedge clk or negedge rstn) begin
    if(~rstn) fifo_rd_data_valid <= 1'b0;
    else if((~capture_on) || (frame_notready)) fifo_rd_data_valid <= 1'b0;
    else if(rd_data_valid && rd_empty && fifo_rd_data_valid) fifo_rd_data_valid <= 1'b0;
    else if(fifo_rd_en && (~rd_empty) && (~fifo_rd_data_valid)) fifo_rd_data_valid <= 1'b1;
    else fifo_rd_data_valid <= fifo_rd_data_valid;
end

assign fifo_wr_rst = (~CCD_RSTN) || ((~capture_on) || (frame_notready));
assign fifo_wr_en = (CCD_HSYNC_d1) && (~CCD_VSYNC_d1) && (nt_st_store == ST_STORE);
assign fifo_rd_rst = (~rstn) || ((~capture_on) || (frame_notready));
assign fifo_rd_en = (~rd_empty) && ((rd_data_valid) || (~fifo_rd_data_valid));

always @(posedge clk or negedge rstn) begin
    if(~rstn) trans_state <= TRANS_ST_WAIT;
    else if((trans_state == TRANS_ST_WAIT) && (rd_water_level >= 14'd512))
        trans_state <= TRANS_ST_TRANS;
    else if((trans_state == TRANS_ST_TRANS) && (trans_once_done))
        trans_state <= TRANS_ST_WAIT;
    else trans_state <= trans_state;
end
assign rd_data_ready = (trans_state == TRANS_ST_TRANS);

//8bit存入，32bit读出，直接怼到AXI上，发给DDR。
//每次都攒满32bit x 256再发出去，效率最高。
fifo_camera_data u_fifo_camera_data(
    .wr_clk  (CCD_PCLK), 
    .wr_rst  (fifo_wr_rst), 
    .wr_en   (fifo_wr_en), 
    .wr_data (CCD_DATA_d1), 
    .wr_full (),
    .almost_full(almost_full), //反压
    
    .rd_clk  (clk),
    .rd_rst  (fifo_rd_rst),
    .rd_en   (fifo_rd_en),
    .rd_data (rd_data),
    .rd_empty(rd_empty),
    .rd_water_level(rd_water_level),
    .almost_empty()
);

endmodule