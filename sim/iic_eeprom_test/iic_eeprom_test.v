`timescale 1ns/1ps
module iic_eeprom_test ();

// outports wire
wire        	scl_out;
wire        	sda_out;
wire        	scl_in;
wire        	sda_in;
wire        	scl_enable;
wire        	sda_enable;
wire        	cmd_ready;
wire        	cmd_done;
wire        	cmd_error;
wire        	wr_data_ready;
wire        	rd_data_valid;
wire [7:0]  	rd_data;

reg clk;
reg rstn;
always #20 clk = ~clk;
initial begin
    clk = 1'b0;
    rstn = 1'b0;
    #5000 rstn = 1'b1;
end

reg         cmd_valid;
reg [6:0]   i2c_slave_addr;
reg         i2c_read_write;
reg         i2c_addr_length;
reg [15:0]  i2c_start_addr;
reg [15:0]  i2c_data_length;
reg [7:0]   wr_data;

initial begin
    cmd_valid = 0;
    i2c_slave_addr = 0;
    i2c_read_write = 0;
    i2c_addr_length = 0;
    i2c_start_addr = 0;
    i2c_data_length = 0;
    wr_data = 0;
end

i2c_master u_i2c_master(
	.clk             	( clk              ),
	.rstn            	( rstn             ),
    .scl_in             (scl_in    ),
    .scl_out            (scl_out   ),
    .scl_enable         (scl_enable),
    .sda_in             (sda_in    ),
    .sda_out            (sda_out   ),
    .sda_enable         (sda_enable),
	.cmd_valid       	( cmd_valid        ),
	.cmd_ready       	( cmd_ready        ),
	.cmd_done        	( cmd_done         ),
	.cmd_error       	( cmd_error        ),
	.i2c_slave_addr  	( i2c_slave_addr   ),
	.i2c_read_write  	( i2c_read_write   ),
	.i2c_addr_length 	( i2c_addr_length  ),
	.i2c_start_addr  	( i2c_start_addr   ),
	.i2c_data_length 	( i2c_data_length  ),
	.wr_data_ready   	( wr_data_ready    ),
	.wr_data         	( wr_data          ),
	.rd_data_valid   	( rd_data_valid    ),
	.rd_data         	( rd_data          )
);

wire sda_memory_ctrl, sda_slave_out;
assign scl = (scl_enable)?(scl_out):(1'b1);
assign sda = (sda_enable)?(sda_out):((sda_memory_ctrl)?(sda_slave_out):(1'b1));
assign scl_in = scl;
assign sda_in = sda;

M24AA04 M24AA04_inst(1'b0, 1'b0, 1'b0, 1'b0, sda, sda_slave_out, sda_memory_ctrl, scl, ~rstn);
    reg grs_n;
    GTP_GRS GRS_INST(.GRS_N (grs_n));
    initial begin
    grs_n = 1'b0;
    #5 grs_n = 1'b1;
    end

initial begin
    #10000 iic_write_byte(7'b1010_000, 8'h00, 8'b00110011);
    #10000 iic_read_byte(7'b1010_000, 8'h00);

    #10000 iic_write_multibyte(7'b1010_000, 8'h08, 8'h07);
    $display("iic_write_multibyte: i2c_slave_addr=%h, i2c_start_addr=%h, wr_data_length=%h", i2c_slave_addr, i2c_start_addr, i2c_data_length);
    #10000 iic_read_multibyte(7'b1010_000, 8'h08, 8'h07);
end


task automatic iic_write_byte;
    input [6:0] i2c_slave_addr_in;
    input [7:0] i2c_start_addr_in;
    input [7:0] wr_data_in;
    begin
        @(posedge clk) begin
            cmd_valid <= 1'b1;
            i2c_read_write <= 1'b0; // write
            i2c_slave_addr <= i2c_slave_addr_in;
            i2c_addr_length <= 2'b00; // 7-bit address
            i2c_start_addr <= {8'b0,i2c_start_addr_in};
            i2c_data_length <= 8'h00; // 1 byte data
            wr_data <= wr_data_in;
        end
        while(~(cmd_ready && cmd_valid)) begin
            @(posedge clk);
        end
        @(negedge clk) cmd_valid <= 1'b0;
    end
endtask

task automatic iic_write_multibyte;
    input [6:0] i2c_slave_addr_in;
    input [7:0] i2c_start_addr_in;
    input [7:0] wr_data_length_in;
    begin
        @(posedge clk) begin
            cmd_valid <= 1'b1;
            i2c_read_write <= 1'b0; // write
            i2c_slave_addr <= i2c_slave_addr_in;
            i2c_addr_length <= 2'b00; // 7-bit address
            i2c_start_addr <= {8'b0,i2c_start_addr_in};
            i2c_data_length <= wr_data_length_in; // length+1 byte data
            wr_data <= 0; //start from 0, add 1 in the loop
        end
        while(~(cmd_ready && cmd_valid)) @(posedge clk);
        @(negedge clk) cmd_valid <= 1'b0;
        repeat (wr_data_length_in + 1) begin
            while(~(wr_data_ready)) @(posedge clk);
            @(negedge clk) wr_data <= wr_data + 1;
            $display("end of iic_write_multibyte: wr_data=%h", wr_data);
        end
    end
endtask

task automatic iic_read_byte;
    input [6:0] i2c_slave_addr_in;
    input [7:0] i2c_start_addr_in;
    begin
        @(posedge clk) begin
            cmd_valid <= 1'b1;
            i2c_read_write <= 1'b1; // read
            i2c_slave_addr <= i2c_slave_addr_in;
            i2c_addr_length <= 2'b00; // 7-bit address
            i2c_start_addr <= {8'b0,i2c_start_addr_in};
            i2c_data_length <= 8'h00; // 1 byte data
        end
        while(~(cmd_ready && cmd_valid)) begin
            @(posedge clk);
        end
        @(negedge clk) cmd_valid <= 1'b0;
        while(~(rd_data_valid)) begin
            @(posedge clk);
        end
    end
endtask

task automatic iic_read_multibyte;
    input [6:0] i2c_slave_addr_in;
    input [7:0] i2c_start_addr_in;
    input [7:0] rd_data_length_in;
    begin
        @(posedge clk) begin
            cmd_valid <= 1'b1;
            i2c_read_write <= 1'b1; // read
            i2c_slave_addr <= i2c_slave_addr_in;
            i2c_addr_length <= 2'b00; // 7-bit address
            i2c_start_addr <= {8'b0,i2c_start_addr_in};
            i2c_data_length <= rd_data_length_in; // length+1 byte data
            $display("iic_read_multibyte: i2c_slave_addr=%h, i2c_start_addr=%h, rd_data_length=%h", i2c_slave_addr, i2c_start_addr, rd_data_length_in);
        end
        while(~(cmd_ready && cmd_valid)) @(posedge clk);
        @(negedge clk) cmd_valid <= 1'b0;
        repeat (rd_data_length_in + 1) begin
            while(~(rd_data_valid)) @(posedge clk);
        end
    end
endtask

endmodule