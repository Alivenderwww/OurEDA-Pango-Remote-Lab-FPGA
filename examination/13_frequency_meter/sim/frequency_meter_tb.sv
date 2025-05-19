`timescale 1ns /1ns
module frequency_meter_tb;

  // Parameters

  //Ports
  reg clk;
  reg rstn;
  wire ad_clk;
  reg [7:0] ad_data;
  wire [7:0] led_display_seg;
  wire [7:0] led_display_sel;

  frequency_meter  frequency_meter_inst (
    .clk(clk),
    .rstn(rstn),
    .ad_clk(ad_clk),
    .ad_data(ad_data),
    .led_display_seg(led_display_seg),
    .led_display_sel(led_display_sel)
  );
  initial begin
    clk = 0;
    rstn = 1;
    #10
    rstn = 0;
    #50
    rstn = 1;
  end


//正弦波生成器
real freq = 1e6;    // 1x10^6 所以是1Mhz
real amp = 127.0;   // 8bit满振幅值+-127
real phase = 0.0;   // 初始相位0°
initial begin
    // Generate continuous waveform
    forever begin
        gen_sine_wave(ad_data, freq, amp, phase);
        #10ns; // 每隔10ns生成一个波形数据，所以是100MHz采样率    100MHz sampling rate
    end
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
/////////联合仿真要加
reg grs_n;
GTP_GRS GRS_INST(.GRS_N (grs_n));
initial begin
grs_n = 1'b0;
#5 grs_n = 1'b1;
end
endmodule