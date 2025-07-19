module btn_led_boot_ctrl(
    input  wire clk,
    input  wire rstn,

    input  wire       btn,
    output wire       booting,
    output wire       admin_mode,
    output  reg [3:0] led
);

wire btn_ggle;
btn_ggle btn_ggle0(clk, rstn, btn, btn_ggle);

reg btn_d0, btn_d1;
wire btn_neg = (~btn_d0) & (btn_d1);
always @(posedge clk) begin
    btn_d0 <= btn_ggle;
    btn_d1 <= btn_d0;
end

reg [1:0] system_state;
localparam [1:0] 
    STATE_BOOTING    = 2'b00,
    STATE_ADMIN_MODE = 2'b01,
    STATE_USER_MODE  = 2'b10;

reg [31:0] timecnt;
wire timeout = (timecnt >= 32'd50_000_000 * 6); // 6秒钟的计数
assign booting = (system_state == STATE_BOOTING);
assign admin_mode = (system_state == STATE_ADMIN_MODE);
always @(posedge clk or negedge rstn) begin
    if(~rstn) timecnt <= 0;
    else if(system_state == STATE_BOOTING || system_state == STATE_ADMIN_MODE)
         timecnt <= timecnt + 1;
    else timecnt <= 0;
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) system_state <= STATE_BOOTING;
    else case(system_state)
        STATE_BOOTING: begin
            if(btn_neg) system_state <= STATE_ADMIN_MODE;
            else if(timeout) system_state <= STATE_USER_MODE;
            else system_state <= STATE_BOOTING;
        end
        STATE_ADMIN_MODE: begin
            system_state <= STATE_ADMIN_MODE;
        end
        STATE_USER_MODE: begin
            system_state <= STATE_USER_MODE;
        end
        default: system_state <= STATE_BOOTING;
    endcase
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) led <= 4'b0000;
    else begin
        case(system_state)
            STATE_BOOTING   : led <= {timecnt[25],~timecnt[25],timecnt[25],~timecnt[25]}; // Booting状态，LED缓慢闪烁
            STATE_ADMIN_MODE: led <= {timecnt[23],~timecnt[23],timecnt[23],~timecnt[23]}; // Admin模式，LED快速闪烁
            STATE_USER_MODE : led <= 4'b1111; // User模式，LED常亮
            default         : led <= 4'b0000; // 尚未初始化完毕，LED熄灭
        endcase
    end
end

endmodule