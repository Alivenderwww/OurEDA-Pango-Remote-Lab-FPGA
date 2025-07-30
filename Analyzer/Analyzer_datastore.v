module Analyzer_datastore (
    input  wire          clk,
    input  wire          rstn,
    input  wire [8-1:0]  digital_in,
    input  wire          trig, 
    output wire          busy, 
    input  wire          start,
    output wire          done, 

    input  wire [31:0]   load_num     ,
    input  wire [31:0]   pre_load_num ,

    input  wire          rd_clk       ,
    output wire          rd_data_ready,
    input  wire          rd_data_valid,
    output wire [31:0]   rd_data      
);

reg [31:0] load_cnt, unload_cnt;

reg [2:0] state, next_state;
localparam ST_IDLE       = 3'b000;
localparam ST_PRELOAD    = 3'b001;
localparam ST_WAIT       = 3'b010;
localparam ST_CAPTURE    = 3'b011;
localparam ST_READ       = 3'b100;
localparam ST_DONE       = 3'b101;

reg [31:0] digital_in_combine;
reg [2:0] combine_cnt;
wire empty;
wire fifo_wr_en;
reg fifo_rd_en;

always @(posedge clk or negedge rstn) begin
    if(~rstn) state <= ST_IDLE;
    else state <= next_state;
end

always @(*) begin
    case (state)
        ST_IDLE   : next_state = (start                                                   )?(ST_PRELOAD):(ST_IDLE   );
        ST_PRELOAD: next_state = ((combine_cnt >= 4) && (load_cnt >= pre_load_num)        )?(ST_WAIT   ):(ST_PRELOAD);
        ST_WAIT   : next_state = (trig                                                    )?(ST_CAPTURE):(ST_WAIT   );
        ST_CAPTURE: next_state = ((combine_cnt >= 4) && (load_cnt >= load_num)            )?(ST_READ   ):(ST_CAPTURE);
        ST_READ   : next_state = ((rd_data_ready)&&(rd_data_valid)&&(unload_cnt>=load_num))?(ST_DONE   ):(ST_READ   );
        ST_DONE   : next_state = (start                                                   )?(ST_PRELOAD):(ST_DONE   );
        default   : next_state = ST_IDLE;
    endcase
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) unload_cnt <= 0;
    else if((state == ST_READ) || (state == ST_CAPTURE)) begin
        if(rd_data_valid && rd_data_ready) unload_cnt <= unload_cnt + 1;
        else unload_cnt <= unload_cnt;
    end else unload_cnt <= 0;
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) load_cnt <= 0;
    else if(combine_cnt >= 4) case (state)
        ST_PRELOAD: load_cnt <= load_cnt + 1;
        ST_WAIT   : load_cnt <= load_cnt;
        ST_CAPTURE: load_cnt <= load_cnt + 1;
        default   : load_cnt <= 0;
    endcase
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) begin
        combine_cnt <= 0;
        digital_in_combine <= 0;
    end else if(state == ST_PRELOAD || state == ST_WAIT || state == ST_CAPTURE) begin
        combine_cnt <= (combine_cnt >= 4)?(1):(combine_cnt + 1);
        digital_in_combine <= {digital_in_combine[23:0], digital_in};
    end else begin
        combine_cnt <= 0;
        digital_in_combine <= 0;
    end
end


reg fifo_rd_data_valid;
always @(posedge clk or negedge rstn) begin
    if(~rstn) fifo_rd_data_valid <= 1'b0;
    else if((rd_data_ready & rd_data_valid) && empty && fifo_rd_data_valid) fifo_rd_data_valid <= 1'b0;
    else if(fifo_rd_en && (~empty) && (~fifo_rd_data_valid)) fifo_rd_data_valid <= 1'b1;
    else fifo_rd_data_valid <= fifo_rd_data_valid;
end
assign fifo_wr_en = (combine_cnt >= 4) && ((state == ST_PRELOAD) || (state == ST_WAIT) || (state == ST_CAPTURE));
always @(*) begin
    if(empty) fifo_rd_en = 0;
    else if(~fifo_rd_data_valid) fifo_rd_en = 1;
    else case (state)
        ST_PRELOAD         : fifo_rd_en = 0;
        ST_WAIT            : fifo_rd_en = (combine_cnt >= 4);
        ST_CAPTURE, ST_READ: fifo_rd_en = (rd_data_ready) & (rd_data_valid);
        default            : fifo_rd_en = 0;
    endcase
end
assign rd_data_ready = (fifo_rd_data_valid) && ((state == ST_READ) || (state == ST_CAPTURE));
assign busy = (state == ST_CAPTURE) || (state == ST_READ);
assign done = (state == ST_DONE);
analyzer_fifo u_analyzer_fifo (
    .wr_clk       (clk          ),
    .wr_rst       (~rstn         ),
    .wr_en        (fifo_wr_en),
    .wr_data      (digital_in_combine),
    .wr_full      (),
    .almost_full  (),

    .rd_clk       (rd_clk       ),
    .rd_rst       (~rstn        ),
    .rd_en        (fifo_rd_en   ),
    .rd_data      (rd_data      ),
    .rd_empty     (empty        ),
    .almost_empty ()
);

endmodule //Analyzer