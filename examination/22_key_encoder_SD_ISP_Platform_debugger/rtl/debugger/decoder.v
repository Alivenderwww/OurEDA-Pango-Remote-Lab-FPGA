module decoder #(
    parameter PORT_NUM = 3,
    parameter PORT_WIDTH = 32,
    parameter MAX_SAMPLE_DEPTH = 2048
) (
    input wire                       rxclk,//hsst rxclk
    input wire                       rstn,
    input wire                       sfp_rxdatalast,
    input wire                       sfp_rxdatavalid,//从hsst来的
    input wire [31:0]                sfp_rxdata,//从hsst来的数据
    output reg                       trigger/* synthesis PAP_MARK_DEBUG="1" */,//触发信号
    output reg                       refresh/* synthesis PAP_MARK_DEBUG="1" */,
    output reg [PORT_NUM*32 - 1 : 0] trigger_sel/* synthesis PAP_MARK_DEBUG="1" */,
    output reg [2:0]                 mode/* synthesis PAP_MARK_DEBUG="1" */, 
    output reg [PORT_NUM - 1:0]      porten/* synthesis PAP_MARK_DEBUG="1" */,
    output reg [15:0]                addr/* synthesis PAP_MARK_DEBUG="1" */,
    output reg [ 9:0]                num/* synthesis PAP_MARK_DEBUG="1" */     
);

//decoder主要是解析命???
//控制指令32'hFF_000000???;32'h00_000000???;32'h0F_000000触发
//读：      FF_000000  {6'bxx,10'bnum,16'baddr}
//触发???    00_000000   0000FFFF
//刷新???    00_000000   FFFF0000
//写mode???  55_000000  {13'bxx,3'bmode,16'baddr}
//64位命令，???32位控制，???32位地??????
//addr <= sfp_rxdata[15:0]
//num  <= sfp_rxdata[25:16]
localparam IDLE     = 4'd0;
localparam READ     = 4'd1;
localparam SPECIAL  = 4'd2;
localparam MODE     = 4'd3;
reg [3:0] state/* synthesis PAP_MARK_DEBUG="1" */;
reg [3:0] nextstate/* synthesis PAP_MARK_DEBUG="1" */;
always @(posedge rxclk or negedge rstn) begin
    if(~rstn)
        state <= IDLE;
    else
        state <= nextstate;
end
always @(*)begin
    case(state)
        IDLE : begin
            if(sfp_rxdatavalid)begin
                if(sfp_rxdata[31:24] == 8'hFF)
                    nextstate = READ;
                else if(sfp_rxdata[31:24] == 8'h00)
                    nextstate = SPECIAL; 
                else if(sfp_rxdata[31:24] == 8'h55)
                    nextstate = MODE;
            end
            else begin
                nextstate = IDLE;
            end
        end
        READ : begin
            if(sfp_rxdatalast)
                nextstate = IDLE;
            else 
                nextstate = READ;
        end
        SPECIAL : begin
            if(sfp_rxdatalast)
                nextstate = IDLE;
            else 
                nextstate = SPECIAL; 
        end
        MODE : begin
            if(sfp_rxdatalast)
                nextstate = IDLE;
            else 
                nextstate = MODE; 
        end
        default : nextstate = IDLE;
    endcase
end
always @(posedge rxclk or negedge rstn) begin
    if(~rstn)begin
        trigger <= 0;
        trigger_sel <= 'b0;
        mode <= 0;
        refresh <= 0;
    end
    else begin
        // trigger <= 0;
        case(state)
            IDLE : begin
                mode <= 0;
                trigger_sel <= 'b0;
                trigger <= 0;
                refresh <= 0;
            end
            SPECIAL : begin
                if(sfp_rxdata == 32'h0000FFFF)
                    trigger <= 1;
                if(sfp_rxdata == 32'hFFFF0000)
                    refresh <= 1;
            end
            MODE : begin
                if(sfp_rxdata[15:0] < PORT_NUM * PORT_WIDTH)begin
                    mode <= sfp_rxdata[2:0];
                    trigger_sel <= {{(PORT_NUM*32){1'b0}}} | ({1'b1} << sfp_rxdata[31:16]);
                end
            end
        endcase
    end
end

//???
//???
integer i;
always @(posedge rxclk or negedge rstn) begin
    if (~rstn) begin
        porten <= 0;
        addr <= 0;
        num <= 0;
    end else begin
        porten <= 0;
        for (i = 0; i < PORT_NUM; i = i + 1) begin
            if (state == READ && sfp_rxdata[15:0] <= MAX_SAMPLE_DEPTH * (i+1) - 1 && sfp_rxdata[15:0] >= MAX_SAMPLE_DEPTH * i) begin
                porten[i] <= 1;
                addr <= sfp_rxdata[15:0] - MAX_SAMPLE_DEPTH * i;
                num  <= sfp_rxdata[25:16];
            end
        end
    end
end  
endmodule