module arp_rx #(
    parameter BOARD_MAC = 48'h12_34_56_78_9a_bc,
    parameter BOARD_IP  = {8'd0,8'd0,8'd0,8'd0},
    parameter DES_MAC  = 48'h2c_f0_5d_32_f1_07,
    parameter DES_IP   = {8'd0,8'd0,8'd0,8'd0}
) (
    
    input  wire          rstn,
    input  wire          gmii_rx_clk,
    input  wire          gmii_rx_dv,
    input  wire [7:0]    gmii_rxd,
    output wire [47:0]   dec_mac,
    output wire [31:0]   dec_ip,
    output reg           refresh
);
reg  [15:0]  eth_type                  ; //以太网协议类型
reg  [47:0]  eth_des_mac               ; //以太网帧目的MAC地址
reg  [15:0]  arp_hard_type             ; //ARP报头硬件类型
reg  [15:0]  arp_protocol_type         ; //ARP上层协议类型
reg  [15:0]  arp_op_type               ; //ARP操作类型
reg  [47:0]  arp_rx_des_mac            ; //arp请求帧目的MAC地址
reg  [47:0]  arp_rx_src_mac            ; //arp请求帧原MAC地址
reg  [31:0]  arp_rx_des_ip             ; //arp请求帧目的ip地址
reg  [31:0]  arp_rx_src_ip             ; //arp请求帧原ip地址
localparam  ETH_TYPE      = 16'h0806   ; //arp帧类型编号
localparam  HARD_TYPE     = 16'h0001   ; //硬件类型，0001以太网地址传输
localparam  PROTOCOL_TYPE = 16'h0800   ; //ARP映射IP地址时为0800
localparam  OP_REQ        = 16'h0001   ; //ARP请求
localparam  OP_REP        = 16'h0002   ; //ARP应答
localparam  st_idle       = 7'b000_0001; //初始状态，等待接收前导码
localparam  st_preamble   = 7'b000_0010; //接收前导码状态
localparam  st_eth_head   = 7'b000_0100; //接收以太网帧头
localparam  st_arp_head   = 7'b000_1000; //接收IP首部
localparam  st_arp_data   = 7'b001_0000; //接收UDP首部
assign dec_mac = arp_rx_src_mac;
assign dec_ip  = arp_rx_src_ip;

reg [7:0] state;
reg [7:0] next_state;
reg [4:0] cnt;
reg skip_en;
reg error_en;
always @(posedge gmii_rx_clk or negedge rstn) begin
    if(~rstn)
        state <= st_idle;
    else 
        state <= next_state;
end
always @(*) begin
    case(state)
        st_idle : begin                                     //等待接收前导码
            if(skip_en)
                next_state = st_preamble;
            else
                next_state = st_idle;
        end
        st_preamble : begin                                 //接收前导码
            if(skip_en)
                next_state = st_eth_head;
            else if(error_en)
                next_state = st_idle;
            else
                next_state = st_preamble;
        end
        st_eth_head : begin                                 //接收以太网帧头
            if(skip_en)
                next_state = st_arp_head;
            else if(error_en)
                next_state = st_idle;
            else
                next_state = st_eth_head;
        end
        st_arp_head : begin                                  //接收arp报头
            if(skip_en)
                next_state = st_arp_data;
            else if(error_en)
                next_state = st_idle;
            else
                next_state = st_arp_head;
        end
        st_arp_data : begin                                 //接收UDP首部
            if(skip_en)
                next_state = st_idle;
            else if(error_en)
                next_state = st_idle;
            else 
                next_state = st_arp_data;
        end
    endcase
end

always @(posedge gmii_rx_clk or negedge rstn ) begin
    if(~rstn)begin
        skip_en <= 0;
        error_en <= 0;
        cnt <= 0;
        refresh <= 0;
        arp_rx_des_mac <= 0;
        arp_rx_src_mac <= DES_MAC;
        arp_rx_des_ip  <= 0;
        arp_rx_src_ip  <= DES_IP;
    end
    else begin
        skip_en <= 0;
        error_en <= 0;
        refresh <= 0;
        case(next_state)
            st_idle : begin
                cnt <= 0;
                if((gmii_rx_dv == 1'b1) && (gmii_rxd == 8'h55))
                    skip_en <= 1'b1;
                else 
                    skip_en <= 0;
            end
            st_preamble : begin
                if(gmii_rx_dv) begin                         //解析前导码
                    cnt <= cnt + 5'd1;
                    if((cnt < 5'd6) && (gmii_rxd != 8'h55))  //7个8'h55
                        error_en <= 1'b1;
                    else if(cnt==5'd6) begin
                        cnt <= 5'd0;
                        if(gmii_rxd==8'hd5)                  //1个8'hd5
                            skip_en <= 1'b1;
                        else
                            error_en <= 1'b1;
                    end
                end
            end
            st_eth_head : begin
                if(gmii_rx_dv) begin
                    cnt <= cnt + 5'b1;
                    if(cnt < 5'd6)
                        eth_des_mac <= {eth_des_mac[39:0],gmii_rxd}; //目的MAC地址
                    else if(cnt == 5'd12)
                        eth_type[15:8] <= gmii_rxd;          //以太网协议类型
                    else if(cnt == 5'd13) begin
                        eth_type[7:0] <= gmii_rxd;
                        cnt <= 5'd0;
                        //判断MAC地址是否公共地址，是否为arp帧
                        if(eth_des_mac == 48'hff_ff_ff_ff_ff_ff && eth_type[15:8] == ETH_TYPE[15:8] && gmii_rxd == ETH_TYPE[7:0])
                            skip_en <= 1'b1;
                        else
                            error_en <= 1'b1;
                    end
                end
            end
            st_arp_head  : begin
                if(gmii_rx_dv)begin
                    cnt <= cnt + 5'b1;
                    if(cnt < 2)
                        arp_hard_type <= {arp_hard_type[7:0],gmii_rxd};//硬件类型
                    else if(cnt < 4)
                        arp_protocol_type <= {arp_protocol_type[7:0],gmii_rxd};//上层协议类型
                    else if(cnt == 6)
                        arp_op_type <= {arp_op_type[7:0],gmii_rxd};
                    else if(cnt == 7)begin
                        cnt <= 0;
                        arp_op_type <= {arp_op_type[7:0],gmii_rxd};
                        if(arp_hard_type == HARD_TYPE && arp_protocol_type == PROTOCOL_TYPE && gmii_rxd == OP_REQ[7:0])
                            skip_en <= 1;
                        else 
                            error_en <= 1;
                    end
                end
            end
            st_arp_data : begin
                if(gmii_rx_dv)begin
                    cnt <= cnt + 5'b1;
                    if(cnt < 6)
                        arp_rx_src_mac <= {arp_rx_src_mac[39:0],gmii_rxd};
                    else if(cnt < 10)
                        arp_rx_src_ip <= {arp_rx_src_ip[23:0],gmii_rxd};
                    else if(cnt < 16)
                        arp_rx_des_mac <= {arp_rx_des_mac[39:0],gmii_rxd};//全是0
                    else if(cnt < 20)
                        arp_rx_des_ip <= {arp_rx_des_ip[23:0],gmii_rxd};//接收完一次arp报文
                    else if(cnt == 20)begin
                        cnt <= 0;
                        if(arp_rx_des_ip == BOARD_IP)begin//是自己的ip地址
                            skip_en <= 1;
                            refresh <= 1;
                        end
                        else begin
                            error_en <= 1;
                        end
                    end
                end
            end
        endcase
    end
end
endmodule