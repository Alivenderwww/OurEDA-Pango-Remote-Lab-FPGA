module password_lock(
    input  wire clk,
    input  wire rstn,
    input  wire [15:0] key_trigger,
    output  reg [8*8-1:0] assic_seg,
    output wire [7:0] seg_point
);

/*
    K00   K01   K02   K03   |   1   2   3   A
                            |
    K04   K05   K06   K07   |   4   5   6   B   
                            |
    K08   K09   K10   K11   |   7   8   9   C
                            |
    K12   K13   K14   K15   |   *   0   #   D
*/

/*
密码锁状态机设定：
1. SETUP状态 ：设置密码，按*清空输入，按#确认输入进入LOCK状态，不足4位#键无效
2. LOCK状态  ：锁定状态，按*清空输入，按#确认输入，不足4位#键无效，密码正确解锁，错误则进入ERROR状态
3. ERROR状态 ：密码错误状态，按任意键返回LCOK状态
4. UNLOCK状态：解锁状态，按*重设密码，按#重新锁定，其余键无效

1-D键为输入
*为清空之前的输入
#为确认输入

*/

wire flag_setup_password;
wire flag_input_pass;
wire flag_input_confirm;
wire flag_error_return;
wire flag_relock;
wire flag_reset;

localparam [2:0] ST_SETUP  = 3'b001;
localparam [2:0] ST_LOCK   = 3'b010;
localparam [2:0] ST_ERROR  = 3'b100;
localparam [2:0] ST_UNLOCK = 3'b101;

reg [2:0] cu_st, nt_st;
reg [4*4-1:0] password, input_password;
reg [2:0] input_num;

assign flag_setup_password = (cu_st == ST_SETUP) && (key_trigger[14]) && (input_num == 3'b100);
assign flag_input_confirm  = (cu_st == ST_LOCK) && (key_trigger[14]) && (input_num == 3'b100);
assign flag_input_pass     = (cu_st == ST_LOCK) && (password == input_password) && (input_num == 3'b100);
assign flag_error_return   = (cu_st == ST_ERROR) && (|key_trigger);
assign flag_relock         = (cu_st == ST_UNLOCK) && (key_trigger[14]);
assign flag_reset          = (cu_st == ST_UNLOCK) && (key_trigger[12]);

always @(posedge clk or negedge rstn) begin
    if(~rstn) cu_st <= ST_SETUP;
    else cu_st <= nt_st;
end

always @(*) begin
    case(cu_st)
        ST_SETUP : nt_st <= (flag_setup_password)?(ST_LOCK):(ST_SETUP);
        ST_LOCK  : nt_st <= (flag_input_confirm)?((flag_input_pass)?(ST_UNLOCK):(ST_ERROR)):(ST_LOCK);
        ST_ERROR : nt_st <= (flag_error_return)?(ST_LOCK):(ST_ERROR);
        ST_UNLOCK: nt_st <= (flag_relock)?(ST_LOCK):((flag_reset)?(ST_SETUP):(ST_UNLOCK));
        default  : nt_st <= ST_SETUP;
    endcase
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) password <= 0;
    else if((cu_st == ST_SETUP) && (input_num != 3'b100)) begin
             if(key_trigger[00]) password <= {password[0+:3*4], 4'h1};
        else if(key_trigger[01]) password <= {password[0+:3*4], 4'h2};
        else if(key_trigger[02]) password <= {password[0+:3*4], 4'h3};
        else if(key_trigger[03]) password <= {password[0+:3*4], 4'hA};
        else if(key_trigger[04]) password <= {password[0+:3*4], 4'h4};
        else if(key_trigger[05]) password <= {password[0+:3*4], 4'h5};
        else if(key_trigger[06]) password <= {password[0+:3*4], 4'h6};
        else if(key_trigger[07]) password <= {password[0+:3*4], 4'hB};
        else if(key_trigger[08]) password <= {password[0+:3*4], 4'h7};
        else if(key_trigger[09]) password <= {password[0+:3*4], 4'h8};
        else if(key_trigger[10]) password <= {password[0+:3*4], 4'h9};
        else if(key_trigger[11]) password <= {password[0+:3*4], 4'hC};
        else if(key_trigger[12]) password <= 0;
        else if(key_trigger[13]) password <= {password[0+:3*4], 4'h0};
        else if(key_trigger[14]) password <= password;
        else if(key_trigger[15]) password <= {password[0+:3*4], 4'hD};
        else password <= password;
    end else password <= password;
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) input_password <= 0;
    else if(cu_st == ST_LOCK) begin
        if(input_num == 3'b100) input_password <= input_password;
        else if(key_trigger[00]) input_password <= {input_password[0+:3*4], 4'h1};
        else if(key_trigger[01]) input_password <= {input_password[0+:3*4], 4'h2};
        else if(key_trigger[02]) input_password <= {input_password[0+:3*4], 4'h3};
        else if(key_trigger[03]) input_password <= {input_password[0+:3*4], 4'hA};
        else if(key_trigger[04]) input_password <= {input_password[0+:3*4], 4'h4};
        else if(key_trigger[05]) input_password <= {input_password[0+:3*4], 4'h5};
        else if(key_trigger[06]) input_password <= {input_password[0+:3*4], 4'h6};
        else if(key_trigger[07]) input_password <= {input_password[0+:3*4], 4'hB};
        else if(key_trigger[08]) input_password <= {input_password[0+:3*4], 4'h7};
        else if(key_trigger[09]) input_password <= {input_password[0+:3*4], 4'h8};
        else if(key_trigger[10]) input_password <= {input_password[0+:3*4], 4'h9};
        else if(key_trigger[11]) input_password <= {input_password[0+:3*4], 4'hC};
        else if(key_trigger[12]) input_password <= 0;
        else if(key_trigger[13]) input_password <= {input_password[0+:3*4], 4'h0};
        else if(key_trigger[14]) input_password <= input_password;
        else if(key_trigger[15]) input_password <= {input_password[0+:3*4], 4'hD};
        else input_password <= input_password;
    end else input_password <= 0;
end

always @(posedge clk or negedge rstn) begin
    if(~rstn) input_num <= 0;
    else if(cu_st == ST_SETUP || cu_st == ST_LOCK) begin
        if(flag_setup_password || flag_input_confirm) input_num <= 0;
        else if(key_trigger[00] || key_trigger[01] || key_trigger[02] || key_trigger[03] ||
           key_trigger[04] || key_trigger[05] || key_trigger[06] || key_trigger[07] ||
           key_trigger[08] || key_trigger[09] || key_trigger[10] || key_trigger[11] ||
                              key_trigger[13]                    || key_trigger[15])
            input_num <= (input_num < 3'b100)?(input_num + 1):(input_num);
        else if(key_trigger[12]) input_num <= 0;
        else input_num <= input_num;
    end else input_num <= 0;
end

assign seg_point = 8'b0;
always @(posedge clk or negedge rstn) begin
    if(~rstn) assic_seg <= "12345678";
    else case(cu_st)
        ST_SETUP :begin
            assic_seg[0+:8] <= "-";
            assic_seg[8+:8] <= "-";
            assic_seg[16+:8] <= (input_num > 0)?(hex2assic(password[0+:4])):("_");
            assic_seg[24+:8] <= (input_num > 1)?(hex2assic(password[4+:4])):("_");
            assic_seg[32+:8] <= (input_num > 2)?(hex2assic(password[8+:4])):("_");
            assic_seg[40+:8] <= (input_num > 3)?(hex2assic(password[12+:4])):("_");
            assic_seg[48+:8] <= "-";
            assic_seg[56+:8] <= "-";
        end
        ST_LOCK  :begin
            assic_seg[0+:8] <= "=";
            assic_seg[8+:8] <= "=";
            assic_seg[16+:8] <= (input_num > 0)?(hex2assic(input_password[0+:4])):("-");
            assic_seg[24+:8] <= (input_num > 1)?(hex2assic(input_password[4+:4])):("-");
            assic_seg[32+:8] <= (input_num > 2)?(hex2assic(input_password[8+:4])):("-");
            assic_seg[40+:8] <= (input_num > 3)?(hex2assic(input_password[12+:4])):("-");
            assic_seg[48+:8] <= "=";
            assic_seg[56+:8] <= "=";
        end
        ST_ERROR : assic_seg <= "  ERROR ";
        ST_UNLOCK: assic_seg <= " unlock ";
        default  : assic_seg <= "12345678";
    endcase
end


function [7:0] hex2assic;
    input [3:0] hex;
    case(hex)
        4'h0: hex2assic = "0"; // 0
        4'h1: hex2assic = "1"; // 1
        4'h2: hex2assic = "2"; // 2
        4'h3: hex2assic = "3"; // 3
        4'h4: hex2assic = "4"; // 4
        4'h5: hex2assic = "5"; // 5
        4'h6: hex2assic = "6"; // 6
        4'h7: hex2assic = "7"; // 7
        4'h8: hex2assic = "8"; // 8
        4'h9: hex2assic = "9"; // 9
        4'hA: hex2assic = "A"; // A
        4'hB: hex2assic = "B"; // B
        4'hC: hex2assic = "C"; // C
        4'hD: hex2assic = "D"; // D
        4'hE: hex2assic = "E"; // E
        4'hF: hex2assic = "F"; // F
        default: hex2assic = " ";
    endcase
endfunction

endmodule //password_lock
