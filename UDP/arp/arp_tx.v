module arp_tx (
    
    input   wire          rstn,
    input   wire          gmii_tx_clk,
    output  reg           gmii_tx_en,
    output  reg  [7:0]    gmii_txd,
    input   wire [31:0]   board_ip,
    input   wire [47:0]   board_mac,
    input   wire [47:0]   dec_mac,
    input   wire [31:0]   dec_ip,
    input   wire          arp_valid/* synthesis PAP_MARK_DEBUG=”true” */,

    input        [31:0]  crc_data   , //CRC校验数据
    input         [7:0]  crc_next   , //CRC下次校验完成数据
    output  reg          crc_en     , //CRC开始校验使能
    output  reg          crc_clr    , //CRC数据复位信号
    input                arp_tx_sel /* synthesis PAP_MARK_DEBUG=”true” */,
    output  reg          arp_tx_done/* synthesis PAP_MARK_DEBUG=”true” */,
    output  reg          arp_tx_req /* synthesis PAP_MARK_DEBUG=”true” */,
    output  reg          arp_working
);
reg  [7:0]   preamble[7:0]  ; //前导码
reg  [7:0]   eth_head[13:0] ; //以太网首部
reg  [7:0]   arp_head[7:0]  ; //arp报头
reg  [7:0]   arp_data[19:0] ; //arp数据
localparam  ETH_TYPE      = 16'h0806   ; //arp帧类型编号
localparam  HARD_TYPE     = 16'h0001   ; //硬件类型，0001以太网地址传输
localparam  PROTOCOL_TYPE = 16'h0800   ; //ARP映射IP地址时为0800
localparam  MAC_LENGTH    = 8'h06      ;
localparam  IP_LENGTH     = 8'h04      ;
localparam  OP_REQ        = 16'h0001   ; //ARP请求
localparam  OP_REP        = 16'h0002   ; //ARP应答
localparam  st_idle       = 7'b000_0001; //初始状态，等待开始发送信号
localparam  st_preamble   = 7'b000_0010; //发送前导码+帧起始界定符
localparam  st_eth_head   = 7'b000_0100; //发送以太网帧头
localparam  st_arp_head   = 7'b000_1000; //发送IP首部+UDP首部
localparam  st_tx_data    = 7'b001_0000; //发送数据
localparam  st_tx_00      = 7'b010_0000; //发送补充数据
localparam  st_crc        = 7'b100_0000; //发送CRC校验值
localparam  st_wait       = 7'b000_0000; //等待仲裁器回应
always @(*) begin
    //初始化数组
    //前导码 7个8'h55 + 1个8'hd5
    preamble[0] <= 8'h55;
    preamble[1] <= 8'h55;
    preamble[2] <= 8'h55;
    preamble[3] <= 8'h55;
    preamble[4] <= 8'h55;
    preamble[5] <= 8'h55;
    preamble[6] <= 8'h55;
    preamble[7] <= 8'hd5;
    arp_data[ 0] <= board_mac[47:40];
    arp_data[ 1] <= board_mac[39:32];
    arp_data[ 2] <= board_mac[31:24];
    arp_data[ 3] <= board_mac[23:16];
    arp_data[ 4] <= board_mac[15: 8];
    arp_data[ 5] <= board_mac[ 7: 0];
    arp_data[ 6] <= board_ip[31:24];
    arp_data[ 7] <= board_ip[23:16];
    arp_data[ 8] <= board_ip[15: 8];
    arp_data[ 9] <= board_ip[ 7: 0];
    arp_data[10] <= dec_mac[47:40];
    arp_data[11] <= dec_mac[39:32];
    arp_data[12] <= dec_mac[31:24];
    arp_data[13] <= dec_mac[23:16];
    arp_data[14] <= dec_mac[15: 8];
    arp_data[15] <= dec_mac[ 7: 0];
    arp_data[16] <= dec_ip[31:24];
    arp_data[17] <= dec_ip[23:16];
    arp_data[18] <= dec_ip[15: 8];
    arp_data[19] <= dec_ip[ 7: 0];
    //目的MAC地址
    eth_head[0] <= 8'hFF;//广播
    eth_head[1] <= 8'hFF;//广播
    eth_head[2] <= 8'hFF;//广播
    eth_head[3] <= 8'hFF;//广播
    eth_head[4] <= 8'hFF;//广播
    eth_head[5] <= 8'hFF;//广播
    eth_head[6]  <= board_mac[47:40];
    eth_head[7]  <= board_mac[39:32];
    eth_head[8]  <= board_mac[31:24];
    eth_head[9]  <= board_mac[23:16];
    eth_head[10] <= board_mac[15:8] ;
    eth_head[11] <= board_mac[7:0]  ;
    //以太网类型
    eth_head[12] <= ETH_TYPE[15:8];
    eth_head[13] <= ETH_TYPE[7:0];
    //arp报头
    arp_head[0]  <= HARD_TYPE[15:8];
    arp_head[1]  <= HARD_TYPE[ 7:0];
    arp_head[2]  <= PROTOCOL_TYPE[15:8];
    arp_head[3]  <= PROTOCOL_TYPE[ 7:0];
    arp_head[4]  <= MAC_LENGTH;
    arp_head[5]  <= IP_LENGTH;
    arp_head[6]  <= OP_REP[15:8];
    arp_head[7]  <= OP_REP[ 7:0];
end


reg  [6:0]   cur_state      /* synthesis PAP_MARK_DEBUG=”true” */;
reg  [6:0]   next_state     ;
reg          skip_en        /* synthesis PAP_MARK_DEBUG=”true” */; //控制状态跳转使能信号
reg  [5:0]   cnt;
reg  [1:0]   tx_bit_sel     ;
//reg          arp_tx_done;
reg          tx_done_t;
//assign arp_tx_working = (next_state[0] == 1) ? 0 : 1;
always @(posedge gmii_tx_clk or negedge rstn) begin
    if(!rstn)
        cur_state <= st_idle;
    else
        cur_state <= next_state;
end

always @(*) begin
    case(cur_state)
        st_idle     : begin                               //等待发送数据
            if(skip_en)
                next_state = st_wait;
            else
                next_state = st_idle;
        end
        st_wait : begin                                   //等待仲裁器回应
            if(skip_en)
                next_state = st_preamble;
            else
                next_state = st_wait;
        end
        st_preamble : begin                               //发送前导码+帧起始界定符
            if(skip_en)
                next_state = st_eth_head;
            else
                next_state = st_preamble;
        end
        st_eth_head : begin                               //发送以太网首部
            if(skip_en)
                next_state = st_arp_head;
            else
                next_state = st_eth_head;
        end
        st_arp_head : begin                                //发送arp报头
            if(skip_en)
                next_state = st_tx_data;
            else
                next_state = st_arp_head;
        end
        st_tx_data : begin                                //发送数据
            if(skip_en)
                next_state = st_tx_00;
            else
                next_state = st_tx_data;
        end
        st_tx_00 : begin
            if(skip_en)
                next_state = st_crc;
            else
                next_state = st_tx_00;
        end
        st_crc: begin                                     //发送CRC校验值
            if(skip_en)
                next_state = st_idle;
            else
                next_state = st_crc;
        end
        default : next_state = st_idle;
    endcase
end
always @(posedge gmii_tx_clk or negedge rstn) begin
    if(~rstn)begin
        skip_en <= 1'b0;
        cnt <= 5'd0;
        crc_en <= 1'b0;
        tx_done_t <= 0;
        arp_working <= 0;
        arp_tx_req <= 0;
    end else begin
        skip_en <= 0;
        crc_en <= 1'b0;
        gmii_tx_en <= 1'b0;
        tx_done_t <= 0;
        tx_bit_sel <= 0;
        case(next_state)
            st_idle : begin
                tx_bit_sel <= 0;
                arp_working <= 0;
                if(arp_valid)
                    skip_en <= 1;
                else 
                    skip_en <= 0;
            end
            st_wait : begin
                if(arp_tx_sel)begin
                    arp_working <= 1;
                    arp_tx_req <= 0;
                    skip_en <= 1;
                end
                else begin
                    arp_tx_req <= 1;
                    skip_en <= 0;
                    arp_working <= 0;
                end
            end
            st_preamble : begin                           //发送前导码+帧起始界定符
                gmii_tx_en <= 1'b1;
                gmii_txd <= preamble[cnt];
                if(cnt == 5'd7) begin
                    skip_en <= 1'b1;
                    cnt <= 5'd0;
                end
                else
                    cnt <= cnt + 5'd1;
            end
            st_eth_head : begin                           //发送以太网帧头
                gmii_tx_en <= 1'b1;
                crc_en <= 1'b1;
                gmii_txd <= eth_head[cnt];
                if (cnt == 5'd13) begin
                    skip_en <= 1'b1;
                    cnt <= 5'd0;
                end
                else
                    cnt <= cnt + 5'd1;
            end
            st_arp_head : begin                           //发送arp报头
                gmii_tx_en <= 1'b1;
                crc_en <= 1'b1;
                gmii_txd <= arp_head[cnt];
                if (cnt == 5'd7) begin
                    skip_en <= 1'b1;
                    cnt <= 5'd0;
                end
                else
                    cnt <= cnt + 5'd1;
            end
            st_tx_data : begin                            //发送arp数据
                gmii_tx_en <= 1'b1;
                crc_en <= 1'b1;
                gmii_txd <= arp_data[cnt];
                if (cnt == 5'd19) begin
                    skip_en <= 1'b1;
                    cnt <= 5'd0;
                end
                else
                    cnt <= cnt + 5'd1;
            end
            st_tx_00 : begin                             //填充数据
                gmii_tx_en <= 1'b1;
                crc_en <= 1'b1;
                gmii_txd <= 8'h00;
                if (cnt == 5'd17) begin
                    skip_en <= 1'b1;
                    cnt <= 5'd0;
                end
                else
                    cnt <= cnt + 5'd1;
            end
            st_crc : begin
                gmii_tx_en <= 1'b1;
                crc_en <= 1'b0;
                tx_bit_sel <= tx_bit_sel + 3'd1;
                if(tx_bit_sel == 3'd0)
                    gmii_txd <= {~crc_next[0], ~crc_next[1], ~crc_next[2],~crc_next[3],
                                 ~crc_next[4], ~crc_next[5], ~crc_next[6],~crc_next[7]};
                else if(tx_bit_sel == 3'd1)
                    gmii_txd <= {~crc_data[16], ~crc_data[17], ~crc_data[18],~crc_data[19],
                                 ~crc_data[20], ~crc_data[21], ~crc_data[22],~crc_data[23]};
                else if(tx_bit_sel == 3'd2) begin
                    gmii_txd <= {~crc_data[8], ~crc_data[9], ~crc_data[10],~crc_data[11],
                                 ~crc_data[12], ~crc_data[13], ~crc_data[14],~crc_data[15]};
                end
                else if(tx_bit_sel == 3'd3) begin
                    gmii_txd <= {~crc_data[0], ~crc_data[1], ~crc_data[2],~crc_data[3],
                                 ~crc_data[4], ~crc_data[5], ~crc_data[6],~crc_data[7]};
                    tx_done_t <= 1'b1;
                    skip_en <= 1'b1;
                end
            end
        endcase
    end
end


//发送完成信号及crc值复位信号
always @(posedge gmii_tx_clk or negedge rstn) begin
    if(!rstn) begin
        arp_tx_done <= 1'b0;
        crc_clr <= 1'b0;
    end
    else begin
        arp_tx_done <= tx_done_t;
        crc_clr <= tx_done_t;
    end
end
endmodule