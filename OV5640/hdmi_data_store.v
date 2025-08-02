module hdmi_data_store (
    input wire        clk,
    input wire        rstn,

    //camera interface (no need iic)
    input  wire        hdmi_in_clk,
    input  wire        hdmi_in_rstn,
    input  wire        hdmi_in_href,
    input  wire        hdmi_in_vsync,
    input  wire[23:0]  hdmi_in_rgb,

    input  wire        trans_once_done,
    input  wire        capture_on,
    input  wire        rd_data_valid,
    output wire        rd_data_ready,
    output wire [31:0] rd_data
);
/*SiL接收到的HDMI信号会自动转换为1920x1080的格式
1080p负担太重，隔行搁列抽取像素点，做成960x540的格式
*/

wire fifo_wr_rst, fifo_wr_en;
wire fifo_rd_rst, fifo_rd_en;
wire almost_full;
wire rd_empty;
wire [13:0] rd_water_level; //读水位线

reg HDMI_VSYNC_d1, HDMI_VSYNC_d2;
reg HDMI_HREF_d1, HDMI_HREF_d2;
reg [23:0] HDMI_DATA_d1;
reg [15:0] camera_hcount, camera_vcount;
wire frame_notready = 0;
reg trans_state;
localparam TRANS_ST_WAIT = 1'b0,
           TRANS_ST_TRANS = 1'b1;
// wire frame_notready = (expect_height_cnt <= 4'd2) || (expect_width_cnt <= 4'd2);

wire HDMI_VSYNC_pos = (HDMI_VSYNC_d1 == 1'b1 && HDMI_VSYNC_d2 == 1'b0);
wire HDMI_VSYNC_neg = (HDMI_VSYNC_d1 == 1'b0 && HDMI_VSYNC_d2 == 1'b1);
wire HDMI_HREF_pos  = (HDMI_HREF_d1 == 1'b1 && HDMI_HREF_d2 == 1'b0);
wire HDMI_HREF_neg  = (HDMI_HREF_d1 == 1'b0 && HDMI_HREF_d2 == 1'b1);
always @(posedge hdmi_in_clk or negedge hdmi_in_rstn) begin
    if(~hdmi_in_rstn) begin
        HDMI_VSYNC_d1 <= 1'b0;
        HDMI_VSYNC_d2 <= 1'b0;
        HDMI_HREF_d1 <= 1'b0;
        HDMI_HREF_d2 <= 1'b0;
        HDMI_DATA_d1 <= 24'h00;
    end
    else begin
        HDMI_VSYNC_d1 <= hdmi_in_vsync;
        HDMI_VSYNC_d2 <= HDMI_VSYNC_d1;
        HDMI_HREF_d1  <= hdmi_in_href;
        HDMI_HREF_d2  <= HDMI_HREF_d1;
        HDMI_DATA_d1  <= hdmi_in_rgb;
        // if(HDMI_VSYNC_neg) HDMI_DATA_d1 <= 0;
        // else HDMI_DATA_d1 <= (~HDMI_VSYNC)&&(HDMI_HREF)?(HDMI_DATA_d1+1):(HDMI_DATA_d1);
    end
end

always @(posedge hdmi_in_clk or negedge hdmi_in_rstn) begin
    if(~hdmi_in_rstn) camera_hcount <= 0;
    else if(HDMI_VSYNC_neg || HDMI_HREF_neg) camera_hcount <= 0;
    else if(HDMI_HREF_d1) camera_hcount <= camera_hcount + 1;
    else camera_hcount <= camera_hcount;
end
always @(posedge hdmi_in_clk or negedge hdmi_in_rstn) begin
    if(~hdmi_in_rstn) camera_vcount <= 0;
    else if(HDMI_VSYNC_neg) camera_vcount <= 0;
    else if(HDMI_HREF_neg) camera_vcount <= camera_vcount + 1;
    else camera_vcount <= camera_vcount;
end

reg [1:0] cu_st_store, nt_st_store;
localparam ST_IDLE = 2'b00, 
           ST_STORE = 2'b01, 
           ST_PAUSE = 2'b10;
//如果FIFO数据有反压，则记录反压时的hcount和vcount并停止存储，等FIFO不再反压并且hcount和vcount与记录的相同后再继续存储。
reg [31:0] pause_camera_hcount, pause_camera_vcount;
always @(posedge hdmi_in_clk or negedge hdmi_in_rstn) begin
    if(~hdmi_in_rstn) begin
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
always @(posedge hdmi_in_clk or negedge hdmi_in_rstn) begin
    if(~hdmi_in_rstn) cu_st_store <= ST_IDLE;
    else cu_st_store <= nt_st_store;
end
always @(*) begin
    if((~capture_on) || (frame_notready)) nt_st_store = ST_IDLE;
    else case (cu_st_store)
        ST_IDLE : nt_st_store = (HDMI_VSYNC_neg)?(ST_STORE):(ST_IDLE);
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

assign fifo_wr_rst = (~hdmi_in_rstn) || ((~capture_on) || (frame_notready));
assign fifo_wr_en = (HDMI_HREF_d1) && (~HDMI_VSYNC_d1) && (camera_hcount[0] == 0) && (camera_vcount[0] == 0) && (nt_st_store == ST_STORE);
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
fifo_hdmi_data u_fifo_hdmi_data(
    .wr_clk  (hdmi_in_clk), 
    .wr_rst  (fifo_wr_rst), 
    .wr_en   (fifo_wr_en), 
    .wr_data ({HDMI_DATA_d1[23-:5],HDMI_DATA_d1[15-:6],HDMI_DATA_d1[7-:5]}), 
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