module mydebugger #(
    parameter PORT_WIDTH   = 32,
    parameter SAMPLE_DEPTH = 1024
) (
    input wire                      clk          ,//数据参考时钟
    input wire                      rxclk        ,//hsst接收时钟
    input wire                      txclk        ,//hsst传输时钟
    input wire                      rstn         ,
    input wire [PORT_WIDTH - 1 : 0] testport     ,//clk
    //trigger
    input wire                      trigger      ,//clk
    output reg                      trigdone     /* synthesis PAP_MARK_DEBUG="1" */,//clk
    input wire                      refresh      /* synthesis PAP_MARK_DEBUG="1" */,//rxclk,无所谓 
    //read
    input wire                      porten       ,//rxclk 读数据使能
    input wire [15:0]               addr         ,//rxclk
    input wire [ 9:0]               rdnum        ,//rxclk 1023+1
    //txdata
    input wire                      tx_sel       ,//txclk
    output reg                      tx_datavalid ,//txclk
    output reg                      tx_datalast  ,//txclk
    output wire [31:0]              tx_portdata   //txclk 传输的数据
);
    //问题
    //有关数据位宽的问题，hsst传输是32位，如果检测的数据位宽大于32位怎么办 //采用异步fifo且端口位宽不相同，输出端口永远是32位
reg trigdone_reg/* synthesis PAP_MARK_DEBUG="1" */;           //clk
reg tx_en;                  //rxclk
reg tx_en_reg;              //txclk
reg [15:0] rxaddr/* synthesis PAP_MARK_DEBUG="1" */;          //clk
reg [15:0] rdaddr/* synthesis PAP_MARK_DEBUG="1" */;          //txclk
reg [15:0] rdaddr_reg;      //rxclk
reg [ 9:0] rdnum_reg;       //rxclk
reg [ 9:0] txcnt/* synthesis PAP_MARK_DEBUG="1" */;           //txclk
//trigdone_reg 和 trigdone跨时钟,相互钳制


//---------------------------------------------//
//rdaddrreg rdnum_reg rdaddr_reg tx_en跨时钟域
always @(posedge rxclk or negedge rstn) begin
    if(~rstn) begin
        rdnum_reg <= 0;
        rdaddr_reg <= 0;
        tx_en <= 0;
    end
    else if(porten) begin
        rdnum_reg <= rdnum;
        if(rxaddr + addr + 1> SAMPLE_DEPTH - 1)
            rdaddr_reg <= rxaddr + addr - 31'd1024 + 1;
        else
            rdaddr_reg <= rxaddr + addr + 1;
        tx_en <= 1;
    end
    else if(tx_en_reg)begin
        tx_en <= 0;
    end
end
//*********************************************************//
//tx_en 和 tx_en_reg跨时钟域
always @(posedge txclk or negedge rstn) begin
    if(~rstn) tx_en_reg <= 0;
    else if(tx_en) tx_en_reg <= 1;
    else if(txcnt == rdnum_reg) tx_en_reg <= 0;
    else tx_en_reg <= tx_en_reg;
end
//
reg txvalid_delay;
always @(posedge txclk or negedge rstn) begin
    if(~rstn) rdaddr <= 0;
    else if(rdaddr == SAMPLE_DEPTH -1) rdaddr <= 0;
    else if(tx_en_reg && (tx_datavalid || txvalid_delay)) rdaddr <= rdaddr + 1;
    else if(tx_en_reg) rdaddr <= rdaddr_reg;//先将数据准备好
    else rdaddr <= rdaddr;
end

always @(posedge txclk or negedge rstn) begin
    if(~rstn) tx_datavalid <= 0;
    else if(tx_en_reg && txcnt == rdnum_reg) tx_datavalid <= 0;
    else if(tx_en_reg && txvalid_delay) tx_datavalid <= 1;

    if(~rstn) txvalid_delay <= 0;
    else if(tx_datavalid) txvalid_delay <= 0;
    else if(tx_en_reg) txvalid_delay <= 1;

    if(~rstn) tx_datalast <= 0;
    else if(tx_en_reg && txcnt == rdnum_reg - 1) tx_datalast <= 1;
    else tx_datalast <= 0;
end
//计数
always @(posedge txclk or negedge rstn) begin
    if(~rstn) txcnt <= 0;
    else if(txcnt == rdnum_reg) txcnt <= 0;
    else if(tx_datavalid) txcnt <= txcnt + 1;
    else txcnt <= txcnt;
end
//*********************************************************//
localparam IDLE = 2'b00;
localparam TRIG = 2'b01;
localparam READ = 2'b10;
reg [1:0] state/* synthesis PAP_MARK_DEBUG="1" */;
reg [1:0] nextstate/* synthesis PAP_MARK_DEBUG="1" */;
reg rx_en;                  //clk
reg [31:0] rxaddr_temp/* synthesis PAP_MARK_DEBUG="1" */;
reg [31:0] rxcnt/* synthesis PAP_MARK_DEBUG="1" */;
always @(posedge clk or negedge rstn) begin
    if(~rstn) 
        state <= IDLE;
    else 
        state <= nextstate;
end

always @(*) begin
    case(state)
        IDLE:begin
            if(trigger)
                nextstate = TRIG;
            else 
                nextstate = IDLE;
        end
        TRIG:begin
            if(trigdone)
                nextstate = READ;
            else 
                nextstate = TRIG;
        end
        READ:begin
            if(refresh)
                nextstate = IDLE;
            else 
                nextstate = READ;
        end
        default : nextstate = IDLE;
    endcase
end
always @(posedge clk or negedge rstn) begin
    if(~rstn)begin
        rx_en <= 1;
        rxaddr <= 0;
        rxaddr_temp <= 0;
        trigdone_reg <= 0;
        rxcnt <= 0;
    end
    else begin
        case(nextstate)
            IDLE:begin
                rx_en <= 1;
                rxcnt <= 0;
                if(rxaddr == SAMPLE_DEPTH - 1)begin
                    rxaddr_temp <= 0;
                    rxaddr <= 0;
                end
                else begin
                    rxaddr <= rxaddr + 1;
                    rxaddr_temp <= rxaddr_temp + 1;
                end
            end
            TRIG:begin
                if(rxcnt == SAMPLE_DEPTH/2)begin
                    rxcnt <= rxcnt;
                    trigdone_reg <= 1;
                    rx_en <= 0;
                end
                else begin
                    rxcnt <= rxcnt + 1;
                    trigdone_reg <= 0 ;
                    rx_en <= rx_en;
                end
                    
                if(rxcnt == SAMPLE_DEPTH/2)
                    rxaddr <= rxaddr;
                else if(rxaddr == SAMPLE_DEPTH - 1)
                    rxaddr <= 0;
                else 
                    rxaddr <= rxaddr + 1;
                    
            end
            READ:begin
                trigdone_reg <= 0;
                rx_en <= 0;
            end
            default : rxcnt <= 0;
        endcase
    end
end
always @(posedge clk or negedge rstn) begin
    if(~rstn) trigdone <= 0;
    else if(trigdone_reg) trigdone <= 1;
    else trigdone <= 0;
end
//*********************************************************//
reg [31:0] tx_portdata_reg;
//BRAM--DRM36K  //如果不能编译成DRM再用原语
reg [PORT_WIDTH - 1:0] ram [0:SAMPLE_DEPTH-1];
always @(posedge clk) begin
    if(rx_en)
        ram[rxaddr] <= testport;
end
always @(posedge txclk) begin
    // if(tx_sel)
        tx_portdata_reg <= ram[rdaddr];
end
assign tx_portdata = tx_sel ? tx_portdata_reg : 32'b0;

endmodule