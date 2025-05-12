`timescale 1ns/1ps
module dso_test();

reg         clk;
reg         rstn;       
reg         ad_clk;     
reg  [7:0]  ad_data;    
reg         wave_run;
reg  [7:0]  trig_level; 
reg         trig_edge;  
reg  [9:0]  h_shift;    
reg  [9:0]  deci_rate;  
reg         ram_rd_clk;
wire        ram_rd_over;
reg         ram_rd_en;
wire [9:0]  wave_rd_addr;

// outports wire
wire [7:0]  	wave_rd_data;
wire        	outrange;
wire        	ad_pulse;
wire [19:0] 	ad_freq;
wire [7:0]  	ad_vpp;
wire [7:0]  	ad_max;
wire [7:0]  	ad_min;

real freq = 500;    // 500 Hz
real amp = 127.0;   // Full scale
real phase = 0.0;   // 0 degree phase

always #10 clk = ~clk; // 50MHz
always #20 ad_clk = ~ad_clk; // 25MHz
always #10 ram_rd_clk = ~ram_rd_clk; // 50MHz
initial begin
    clk = 1'b0;
	ad_clk = 1'b0;
	ram_rd_clk = 1'b0;
    rstn = 1'b0;
    #100 rstn = 1'b1; // 复位信号
end

initial begin
    // Generate continuous waveform
    forever begin
        gen_sine_wave(ad_data, freq, amp, phase);
        #10ns; // 100MHz sampling rate
    end
end

initial begin
	wave_run = 1'b1;
	trig_level = 8'd128;
	trig_edge = 1'b0;
	h_shift = 10'd0;
	deci_rate = 10'd250;
	ram_rd_en = 1'b0;
end

dso_top u_dso_top(
	.clk          	( clk           ),
	.rstn         	( rstn          ),

	.ad_clk       	( ad_clk        ),
	.ad_data      	( ad_data       ),

	.wave_run     	( wave_run      ),
	.trig_level   	( trig_level    ),
	.trig_edge    	( trig_edge     ),
	.h_shift      	( h_shift       ),
	.deci_rate    	( deci_rate     ),

	.ram_rd_clk   	( ram_rd_clk    ),
	.ram_rd_over  	( ram_rd_over   ),
	.ram_rd_en    	( ram_rd_en     ),
	.wave_rd_addr 	( wave_rd_addr  ),
	.wave_rd_data 	( wave_rd_data  ),

	.outrange     	( outrange      ),
	.ad_pulse     	( ad_pulse      ),
	.ad_freq      	( ad_freq       ),
	.ad_vpp       	( ad_vpp        ),
	.ad_max       	( ad_max        ),
	.ad_min       	( ad_min        )
);

always @(posedge ram_rd_clk) begin
	if(~rstn) ram_rd_en <= 0;
	else ram_rd_en <= 1;
end

reg [31:0] cnt;
always @(posedge ram_rd_clk) begin
	if(~rstn) cnt <= 0;
	else if(cnt >= 640-1) cnt <= 0;
	else if(ram_rd_en) cnt <= cnt + 1;
	else cnt <= cnt;
end
assign ram_rd_over = (cnt == 640-1) ? 1'b1 : 1'b0; // 300个时钟周期后ram_rd_over信号拉高
assign wave_rd_addr = cnt[9:0]; // 10位地址线


reg grs_n;
GTP_GRS GRS_INST(.GRS_N (grs_n));
initial begin
grs_n = 1'b0;
#5 grs_n = 1'b1;
end

task automatic gen_sine_wave(
    output reg [7:0]    wave_out,  // 8-bit waveform output
    input real          freq,      // Frequency in Hz
    input real          amplitude, // Amplitude (0-127)
    input real          phase_deg  // Phase in degrees
);
    // Internal variables
    real phase_rad;                // Phase in radians
    real abs_amplitude;            // Constrained amplitude
    real current_time;             // Current simulation time
    real time_offset;              // Elapsed time since first call
    real phase_total;              // Total accumulated phase
    real sin_val;                  // Sine calculation result
    integer offset_val;            // Scaled sine value
    
    // Static variables maintain state between calls
    static real start_time = 0;    // First call timestamp
    static real prev_phase = 0;    // Previous phase accumulation
    
    // Initialize start time on first call
    if (start_time == 0) start_time = $realtime;
    
    // Calculate elapsed time (in seconds)
    current_time = $realtime;
    time_offset = (current_time - start_time) * 1e-9; // Convert ns to seconds
    
    // Constrain amplitude to prevent overflow
    abs_amplitude = (amplitude > 127.0) ? 127.0 : amplitude;
    
    // Convert phase to radians
    phase_rad = phase_deg * (3.1415926535 / 180.0);
    
    // Calculate total phase (continuous accumulation)
    phase_total = 2 * 3.1415926535 * freq * time_offset + phase_rad;
    
    // Calculate sine value
    sin_val = $sin(phase_total);
    
    // Scale to 8-bit range (128 ± amplitude)
    offset_val = $rtoi(abs_amplitude * sin_val);
    wave_out = 8'($signed(128 + offset_val));
    
    // Overflow protection (shouldn't trigger with proper amplitude)
    if (wave_out > 255) wave_out = 255;
    else if (wave_out < 0) wave_out = 0;
endtask

endmodule //dso_test
