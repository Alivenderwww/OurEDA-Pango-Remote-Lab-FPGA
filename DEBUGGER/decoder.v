module decoder #(
    parameter PORT_NUM = 3,
    parameter MAX_SAMPLE_DEPTH = 2048
) (
    input wire                      rxclk,//hsst rxclk
    input wire                      rstn,
    input wire                      sfp_rxdatalast,
    input wire                      sfp_rxdatavalid,//从hsst来的
    input wire [31:0]               sfp_rxdata,//从hsst来的数据
    output reg                      trigger,//触发信号
    output reg [PORT_NUM - 1:0]     porten,
    output reg [15:0]               addr,
    output reg [ 9:0]               num     
);
//decoder主要是解析命令
//控制指令32'hFF_000000读;32'h00_000000写;32'h0F_000000触发
//64位命令，前32位控制，后32位地址等
//addr <= sfp_rxdata[15:0]
//num  <= sfp_rxdata[25:16]
localparam IDLE  = 0;
localparam READ  = 1;
localparam WRITE = 2;
reg [3:0] state;
reg [3:0] nextstate;
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
                    nextstate <= READ;
                else if(sfp_rxdata[31:24] == 8'h00)
                    nextstate <= WRITE; 
                // else if(sfp_rxdata[31:24] == 8'h0F)
                //     nextstate <= TRIG;
            end
            else begin
                nextstate <= IDLE;
            end
        end
        READ : begin
            if(sfp_rxdatalast)
                nextstate <= IDLE;
            else 
                nextstate <= READ;
        end
        WRITE : begin
            if(sfp_rxdatalast)
                nextstate <= IDLE;
            else 
                nextstate <= WRITE; 
        end
    endcase
end
always @(posedge rxclk or negedge rstn) begin
    if(~rstn)begin
        trigger <= 0;
    end
    else begin
        // trigger <= 0;
        case(state)
            IDLE : begin
                trigger <= 0;
            end
            WRITE : begin
                if(sfp_rxdata == 32'h0000FFFF)
                    trigger <= 1;
            end
        endcase
    end
end

//读
genvar i;
generate
    for (i = 0;i < PORT_NUM ;i = i + 1 ) begin
        always @(posedge rxclk or negedge rstn) begin
            if(~rstn)begin
                porten[i] <= 0;
                addr <= 0;
                num <= 0;
            end
            else if(state == READ && sfp_rxdata[15:0] <= MAX_SAMPLE_DEPTH * (i+1) - 1 && sfp_rxdata[15:0] >= MAX_SAMPLE_DEPTH * i)begin
                porten[i] <= 1;
                addr <= sfp_rxdata[15:0] - MAX_SAMPLE_DEPTH * i;
                num <= sfp_rxdata[25:16];
            end
            else begin
                porten[i] <= 0;
                // addr <= 0;//注释掉是因为另一个会触发else,,,,,,,,,,,,
                // num <= 0;
            end
        end
    end
endgenerate
endmodule