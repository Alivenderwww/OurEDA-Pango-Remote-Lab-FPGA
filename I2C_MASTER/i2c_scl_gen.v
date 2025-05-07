module i2c_scl_gen #(
    parameter SCL_RISE_CYCLE = 20, 
    parameter SCL_HIGH_CYCLE = 100,
    parameter SCL_FALL_CYCLE = 20,
    parameter SCL_LOW_CYCLE  = 100 
)(
    input  wire clk,
    input  wire rstn,
    
    input  wire sda_in,

    input  wire scl_in,
    output  reg scl_out,
    input   reg scl_enable,

    output  reg i2c_data_update,
    output  reg i2c_data_capture,
    output wire i2c_start_flag,
    output wire i2c_stop_flag
);

reg sda_d0;
always @(posedge clk or negedge rstn) begin
    if(~rstn) sda_d0 <= 1'b1;
    else sda_d0 <= sda_in;
end
wire sda_pos = sda_in & ~sda_d0;
wire sda_neg = ~sda_in & sda_d0;

assign i2c_start_flag = sda_neg & (scl_in == 1'b1);
assign i2c_stop_flag  = sda_pos & (scl_in == 1'b1);

reg [31:0] scl_cnt;
always @(posedge clk or negedge rstn) begin
    if(~rstn) scl_cnt <= 0;
    else if(scl_cnt >= SCL_RISE_CYCLE + SCL_HIGH_CYCLE + SCL_FALL_CYCLE + SCL_LOW_CYCLE)
        scl_cnt <= 0;
    else if(scl_enable) scl_cnt <= scl_cnt + 1'b1;
    else scl_cnt <= scl_cnt;    
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) scl_out <= 1;
    else if(scl_enable) begin
        if(scl_cnt < SCL_RISE_CYCLE + SCL_HIGH_CYCLE) scl_out <= 1;
        else scl_out <= 0;
    end else scl_out <= 1;
end

// assign scl_in = scl_enable ? scl_out : 1'bz;

always @(posedge clk or negedge rstn) begin
    if(~rstn) i2c_data_capture <= 0;
    else if(scl_enable && (scl_cnt == SCL_RISE_CYCLE) && (scl_in == 1)) i2c_data_capture <= 1;
    else i2c_data_capture <= 0;
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) i2c_data_update <= 0;
    else if(scl_enable && (scl_cnt == SCL_RISE_CYCLE + SCL_HIGH_CYCLE + SCL_FALL_CYCLE) && (scl_in == 0)) i2c_data_update <= 1;
    else i2c_data_update <= 0;
end

endmodule //i2c_scl_gen