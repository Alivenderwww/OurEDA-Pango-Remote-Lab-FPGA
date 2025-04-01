module top(
      input wire clk,
      input wire rst_n,

      input wire [3:0] key,

      // output wire ADC_clk,
      // input wire [7:0] ADC_data,
      output wire [3:0] led,
      output wire DAC_clk,
      output wire [7:0] DAC_data
);

wire [3:0] wave_select;   //波形选择
assign DAC_clk = ~clk;
assign led = wave_select;

reg [31:0] freq_ctrl;
reg [11:0] phase_ctrl;
reg [31:0] cnt;

always @(posedge clk or negedge rst_n) begin
   if(~rst_n) begin
      freq_ctrl <= 0;
      phase_ctrl <= 0;
   end
   else begin
       freq_ctrl <= 32'd42949;
       phase_ctrl <= 0;
   end 
   
end
// always @(posedge clk) begin
//    if(rst_n == 0) begin
//       freq_ctrl <= 0;
//       phase_ctrl <= 0;
//       cnt <= 0;
//    end else if(cnt >= 99999)begin
//       freq_ctrl <= freq_ctrl + 200;
//       phase_ctrl <= 0;
//       cnt <= 0;
//    end else begin
//       freq_ctrl <= freq_ctrl;
//       phase_ctrl <= phase_ctrl;
//       cnt <= cnt + 1;
//    end
// end

dds dds_inst(
   .clk          (clk        ),
   .rst_n        (rst_n       ),
   .wave_select  (wave_select),
   .freq_ctrl    (freq_ctrl  ),
   .phase_ctrl   (phase_ctrl ),
   .data_out     (DAC_data   )
);

key_control key_control_inst(
   .clk          (clk        ),
   .rst          (~rst_n     ),
   .key          (~key       ),
   .wave_select  (wave_select)
);

endmodule