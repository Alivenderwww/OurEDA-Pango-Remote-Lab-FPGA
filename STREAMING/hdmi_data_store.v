module hdmi_data_store (
    //camera interface (no need iic)
    input  wire        hdmi_in_clk,
    input  wire        hdmi_in_rstn,
    input  wire        hdmi_in_vsync,   // ____|▔▔▔|___________________________________________________________________|▔▔▔|_______
    input  wire        hdmi_in_hsync,   // ________________|▔▔|_______________________|▔▔|__..._____|▔▔|___________
    input  wire        hdmi_in_de,      // _________________________|▔▔|_|▔▔...|____________...__________
    input  wire [23:0] hdmi_in_rgb,

    input  wire        capture_on,
    output wire        frame_notready,
    output wire [31:0] frame_height_width,

    input  wire        rd_clk,
    input  wire        rd_rstn,
    output wire        rd_data_burst_valid,
    input  wire        rd_data_burst_ready,
    output wire        rd_addr_reset,
    output  reg [ 7:0] rd_data_burst,
    output wire        rd_data_valid,
    input  wire        rd_data_ready,
    output wire [31:0] rd_data,
    output wire        rd_data_last
);

wire fifo_wr_rst;
reg fifo_wr_en;
reg [31:0] fifo_wr_data;
wire almost_full;

wire fifo_rd_rst, fifo_rd_en;
wire rd_empty;
wire [12:0] rd_water_level;

reg HDMI_VSYNC_d1, HDMI_VSYNC_d2;
reg HDMI_HSYNC_d1, HDMI_HSYNC_d2;
reg HDMI_DE_d1;
reg [23:0] HDMI_DATA_d1, HDMI_DATA_d2;
reg [11:0] camera_hcount, camera_vcount;
reg [11:0] camera_v, camera_h;
reg [3:0] stage_width_cnt, stage_height_cnt; //帧计数
assign frame_notready = (stage_height_cnt <= 4'd1) || (stage_width_cnt <= 4'd1);

//如果FIFO数据有反压，则记录反压时的hcount和vcount并停止存储，等FIFO不再反压并且hcount和vcount与记录的相同后再继续存储。
reg [11:0] pause_camera_hcount, pause_camera_vcount;

reg [3:0] cu_st_store, nt_st_store;
localparam ST_IDLE  = 4'b0000,
           ST_TRANS = 4'b0001,
           ST_PULSE = 4'b1000;

assign frame_height_width = {4'b0, camera_v, 4'b0, camera_h};

wire HDMI_VSYNC_pos = (HDMI_VSYNC_d1 == 1'b1 && HDMI_VSYNC_d2 == 1'b0);
wire HDMI_VSYNC_neg = (HDMI_VSYNC_d1 == 1'b0 && HDMI_VSYNC_d2 == 1'b1);
wire HDMI_HSYNC_pos = (HDMI_HSYNC_d1 == 1'b1 && HDMI_HSYNC_d2 == 1'b0);
wire HDMI_HSYNC_neg = (HDMI_HSYNC_d1 == 1'b0 && HDMI_HSYNC_d2 == 1'b1);
always @(posedge hdmi_in_clk or negedge hdmi_in_rstn) begin
    if(~hdmi_in_rstn) begin
        HDMI_VSYNC_d1 <= 1'b0;
        HDMI_VSYNC_d2 <= 1'b0;
        HDMI_HSYNC_d1 <= 1'b0;
        HDMI_HSYNC_d2 <= 1'b0;
        HDMI_DE_d1    <= 1'b0;
        HDMI_DATA_d1  <= 24'h00;
        HDMI_DATA_d2  <= 24'h00;
    end
    else begin
        HDMI_VSYNC_d1 <= hdmi_in_vsync;
        HDMI_VSYNC_d2 <= HDMI_VSYNC_d1;
        HDMI_HSYNC_d1 <= hdmi_in_hsync;
        HDMI_HSYNC_d2 <= HDMI_HSYNC_d1;
        HDMI_DE_d1    <= hdmi_in_de;
        HDMI_DATA_d1  <= hdmi_in_rgb;
        HDMI_DATA_d2  <= (HDMI_DE_d1)?(HDMI_DATA_d1):(HDMI_DATA_d2);
    end
end

always @(posedge hdmi_in_clk or negedge hdmi_in_rstn) begin
    if(~hdmi_in_rstn) camera_hcount <= 0;
    else if(HDMI_HSYNC_pos || HDMI_HSYNC_neg) camera_hcount <= 0;
    else if(HDMI_DE_d1) begin
             camera_hcount <= camera_hcount + 1;
    end else camera_hcount <= camera_hcount;
end
always @(posedge hdmi_in_clk or negedge hdmi_in_rstn) begin
    if(~hdmi_in_rstn) camera_h <= 0;
    else if(HDMI_HSYNC_pos && camera_hcount != 0) begin
             camera_h <= camera_hcount;
    end else camera_h <= camera_h;
end
always @(posedge hdmi_in_clk or negedge hdmi_in_rstn) begin
    if(~hdmi_in_rstn) camera_vcount <= 0;
    else if(HDMI_VSYNC_pos) camera_vcount <= 0;
    else if(HDMI_HSYNC_pos && camera_hcount != 0) begin
             camera_vcount <= camera_vcount + 1;
    end else camera_vcount <= camera_vcount;
end
always @(posedge hdmi_in_clk or negedge hdmi_in_rstn) begin
    if(~hdmi_in_rstn) camera_v <= 0;
    else if(HDMI_VSYNC_pos && camera_vcount != 0) begin
             camera_v <= camera_vcount;
    end else camera_v <= camera_v;
end
always @(posedge hdmi_in_clk or negedge hdmi_in_rstn) begin
    if(~hdmi_in_rstn) begin
        pause_camera_hcount <= 0;
        pause_camera_vcount <= 0;
    end else begin
        if((cu_st_store == ST_TRANS) && (almost_full)) begin
            pause_camera_hcount <= camera_hcount;
            pause_camera_vcount <= camera_vcount;
        end else begin
            pause_camera_hcount <= pause_camera_hcount;
            pause_camera_vcount <= pause_camera_vcount;
        end
    end
end

always @(posedge hdmi_in_clk or negedge hdmi_in_rstn) begin
    if(~hdmi_in_rstn) cu_st_store <= ST_IDLE;
    else cu_st_store <= nt_st_store;
end
always @(*) begin
    if(~capture_on) nt_st_store = ST_IDLE;
    else case (cu_st_store)
        ST_IDLE  : nt_st_store = (capture_on && HDMI_VSYNC_neg && (~frame_notready))?(ST_TRANS):(ST_IDLE);
        ST_TRANS : nt_st_store = (HDMI_VSYNC_pos)?(ST_IDLE):((almost_full)?(ST_PULSE):(ST_TRANS));
        ST_PULSE : nt_st_store = ((~almost_full) && (pause_camera_hcount == camera_hcount) && (pause_camera_vcount == camera_vcount))?(ST_TRANS):(ST_PULSE);
        default  : nt_st_store = ST_IDLE;
    endcase
end
always @(posedge hdmi_in_clk or negedge hdmi_in_rstn) begin
    if(~hdmi_in_rstn) stage_width_cnt <= 0;
    else if(HDMI_VSYNC_pos && camera_vcount != 0) begin
        if((camera_vcount + 0) == camera_v) begin
            if(stage_width_cnt < 4'd15)
                 stage_width_cnt <= stage_width_cnt + 1;
            else stage_width_cnt <= 4'd15;
        end else stage_width_cnt <= 0;
    end else     stage_width_cnt <= stage_width_cnt;
end
always @(posedge hdmi_in_clk or negedge hdmi_in_rstn) begin
    if(~hdmi_in_rstn) stage_height_cnt <= 0;
    else if(HDMI_HSYNC_pos && camera_hcount != 0) begin
        if((camera_hcount + 0) == camera_h) begin
            if(stage_height_cnt < 4'd15)
                 stage_height_cnt <= stage_height_cnt + 1;
            else stage_height_cnt <= 4'd15;
        end else stage_height_cnt <= 0;
    end else     stage_height_cnt <= stage_height_cnt;
end

reg fifo_rd_data_valid;
always @(posedge rd_clk or negedge rd_rstn) begin
    if(~rd_rstn) fifo_rd_data_valid <= 1'b0;
    else if((~capture_on) || (frame_notready)) fifo_rd_data_valid <= 1'b0;
    else if(rd_data_valid && rd_data_ready && rd_empty && fifo_rd_data_valid) fifo_rd_data_valid <= 1'b0;
    else if(fifo_rd_en && (~rd_empty) && (~fifo_rd_data_valid)) fifo_rd_data_valid <= 1'b1;
    else fifo_rd_data_valid <= fifo_rd_data_valid;
end
//fifo_wr_en, fifo_wr_data
always @(*) begin
    if(HDMI_DE_d1 && (nt_st_store == ST_TRANS)) begin
        fifo_wr_en = 1;
        fifo_wr_data = {8'hff, HDMI_DATA_d1};
    end else begin
        fifo_wr_en = 0;
        fifo_wr_data = 32'hffffffff; // no data
    end
end

assign fifo_wr_rst = (~hdmi_in_rstn) || ((~capture_on) || (frame_notready));
assign fifo_rd_rst = (~rd_rstn) || ((~capture_on) || (frame_notready));
assign fifo_rd_en = (~rd_empty) && ((rd_data_valid && rd_data_ready) || (~fifo_rd_data_valid));
assign rd_data_valid = fifo_rd_data_valid;

hdmi_data_store_fifo u_hdmi_data_store_fifo(
    .wr_clk         ( hdmi_in_clk     ),
    .wr_rst         ( fifo_wr_rst     ),
    .wr_en          ( fifo_wr_en      ),
    .wr_data        ( fifo_wr_data    ),
    .almost_full    ( almost_full     ),

    .rd_clk         ( rd_clk          ),
    .rd_rst         ( fifo_rd_rst     ),
    .rd_en          ( fifo_rd_en      ),
    .rd_data        ( rd_data         ),
    .rd_empty       ( rd_empty        ),
    .rd_water_level ( rd_water_level  )
);

reg [1:0] cu_fifo_rd_st, nt_fifo_rd_st;
localparam
    FIFO_RD_ST_IDLE        = 2'b00,
    FIFO_RD_ST_TRANS_BURST = 2'b01,
    FIFO_RD_ST_TRANS_DATA  = 2'b10;

always @(posedge rd_clk or negedge rd_rstn) begin
    if(~rd_rstn) begin
             rd_data_burst <= 0;
    end else if(cu_fifo_rd_st == FIFO_RD_ST_IDLE) begin
        if(rd_water_level >= 255 - fifo_rd_data_valid)
             rd_data_burst <= 8'hff; // burst size is 255
        else rd_data_burst <= rd_data_burst;
    end else if(cu_fifo_rd_st == FIFO_RD_ST_TRANS_DATA && rd_data_valid && rd_data_ready) begin
             rd_data_burst <= (rd_data_last) ? (rd_data_burst) : (rd_data_burst - 1);
    end else rd_data_burst <= rd_data_burst;
end

always @(posedge rd_clk or negedge rd_rstn) begin
    if(~rd_rstn) cu_fifo_rd_st <= FIFO_RD_ST_IDLE;
    else cu_fifo_rd_st <= nt_fifo_rd_st;
end
always @(*) begin
    case (cu_fifo_rd_st)
        FIFO_RD_ST_IDLE        : nt_fifo_rd_st = (rd_water_level >= 255 - fifo_rd_data_valid)?(FIFO_RD_ST_TRANS_BURST):(FIFO_RD_ST_IDLE);
        FIFO_RD_ST_TRANS_BURST : nt_fifo_rd_st = (rd_data_burst_valid && rd_data_burst_ready)?(FIFO_RD_ST_TRANS_DATA):(FIFO_RD_ST_TRANS_BURST);
        FIFO_RD_ST_TRANS_DATA  : nt_fifo_rd_st = (rd_data_valid && rd_data_ready && rd_data_last)?(FIFO_RD_ST_IDLE):(FIFO_RD_ST_TRANS_DATA);
        default                : nt_fifo_rd_st = FIFO_RD_ST_IDLE;
    endcase
end
assign rd_data_burst_valid = (cu_fifo_rd_st == FIFO_RD_ST_TRANS_BURST);
assign rd_data_last = (cu_fifo_rd_st == FIFO_RD_ST_TRANS_DATA) && (rd_data_burst == 0);
// assign rd_addr_reset = HDMI_VSYNC_pos;
assign rd_addr_reset = 0;

endmodule