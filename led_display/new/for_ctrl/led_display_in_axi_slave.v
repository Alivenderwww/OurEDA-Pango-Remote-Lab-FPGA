module led_display_in_axi_slave (
    input  wire         clk,
    input  wire         rstn,
    //LED
    input  wire         sck                ,
    input  wire         ser                ,
    input  wire         rck                ,
    //SW
    inout  wire [ 4:0]  sw                 ,
    //encoder
    inout  wire [ 2:0]  A                  ,
    inout  wire [ 2:0]  B                  ,
    inout  wire [ 1:0]  key                , 

    output wire         SLAVE_CLK          ,
    output wire         SLAVE_RSTN         ,

    input  wire [4-1:0] SLAVE_WR_ADDR_ID   ,
    input  wire [31:0]  SLAVE_WR_ADDR      ,
    input  wire [ 7:0]  SLAVE_WR_ADDR_LEN  ,
    input  wire [ 1:0]  SLAVE_WR_ADDR_BURST,
    input  wire         SLAVE_WR_ADDR_VALID,
    output wire         SLAVE_WR_ADDR_READY,

    input  wire [31:0]  SLAVE_WR_DATA      ,
    input  wire [ 3:0]  SLAVE_WR_STRB      ,
    input  wire         SLAVE_WR_DATA_LAST ,
    input  wire         SLAVE_WR_DATA_VALID,
    output wire         SLAVE_WR_DATA_READY,

    output wire [4-1:0] SLAVE_WR_BACK_ID   ,
    output wire [ 1:0]  SLAVE_WR_BACK_RESP ,
    output reg          SLAVE_WR_BACK_VALID,
    input  wire         SLAVE_WR_BACK_READY,

    input  wire [4-1:0] SLAVE_RD_ADDR_ID   ,
    input  wire [31:0]  SLAVE_RD_ADDR      ,
    input  wire [ 7:0]  SLAVE_RD_ADDR_LEN  ,
    input  wire [ 1:0]  SLAVE_RD_ADDR_BURST,
    input  wire         SLAVE_RD_ADDR_VALID,
    output wire         SLAVE_RD_ADDR_READY,
    output wire [4-1:0] SLAVE_RD_BACK_ID   ,

    output wire [31:0]  SLAVE_RD_DATA      ,
    output wire [ 1:0]  SLAVE_RD_DATA_RESP ,
    output wire         SLAVE_RD_DATA_LAST ,
    output wire         SLAVE_RD_DATA_VALID,
    input  wire         SLAVE_RD_DATA_READY
);
//encoder
reg encoder_ctrl;
reg [2:0] A_out;
reg [2:0] B_out;
reg       key_ctrl;
reg [1:0] key_out;
reg [2:0] right_start;
reg [2:0] left_start;
reg [2:0] right_done;
reg [2:0] left_done;
assign A[0]   = encoder_ctrl   ? A_out[0]   : 1'bz;
assign A[1]   = encoder_ctrl   ? A_out[1]   : 1'bz;
assign A[2]   = encoder_ctrl   ? A_out[2]   : 1'bz;
assign B[0]   = encoder_ctrl   ? B_out[0]   : 1'bz;
assign B[1]   = encoder_ctrl   ? B_out[1]   : 1'bz;
assign B[2]   = encoder_ctrl   ? B_out[2]   : 1'bz;
assign key[0] = key_ctrl       ? key_out[0] : 1'bz;
assign key[1] = key_ctrl       ? key_out[1] : 1'bz;
reg [31:0] encoder_cnt[2:0];
//sw
reg sw_ctrl;
reg [4:0] sw_out;
//只能读
rstn_sync led_display_rstn_sync(clk,rstn,SLAVE_RSTN);
assign SLAVE_CLK = clk;
// assign SLAVE_WR_ADDR_READY = 0;
// assign SLAVE_WR_DATA_READY = 0;
// assign SLAVE_WR_BACK_ID    = 0;
// assign SLAVE_WR_BACK_RESP  = 0;
// assign SLAVE_WR_BACK_VALID = 0;
//****************************************************//
wire QS;
wire [7:0] led_display_in_seg;
wire [31:0] led_display_in_sel;
wire [4:0] decoder_in;//5bit
SIM_74HC595  SIM_74HC595_inst_seg (
    .sck(sck),
    .rstn(SLAVE_RSTN),
    .rck(rck),
    .ser(ser),
    .QS(QS),
    .out(led_display_in_seg)
  );
SIM_74HC595  SIM_74HC595_inst_sel (
    .sck(sck),
    .rstn(SLAVE_RSTN),
    .rck(rck),
    .ser(QS),
    .QS(),
    .out(decoder_in)
  );
decoder_5_32  decoder_5_32_inst (
    .in(decoder_in),
    .sel(led_display_in_sel)
  );
reg [7:0] led [31:0];
integer i;
always @(posedge clk or negedge SLAVE_RSTN) begin
    if (~SLAVE_RSTN) begin
        for (i = 0; i < 32; i = i + 1) 
            led[i] <= 8'd0;
    end else begin
        for (i = 0; i < 32; i = i + 1) begin
            if (led_display_in_sel[i]) 
                led[i] <= ~led_display_in_seg;
        end
    end
end
//****************************************************//
reg rd_en;
reg rd_data_valid_reg;
reg [ 7:0] txcnt    ;
reg [ 3:0] rdaddrid ;
reg [31:0] rdaddr   ;
reg [ 7:0] rdaddrlen;
reg [31:0] rddata   ;
assign SLAVE_RD_BACK_ID = rdaddrid;
assign SLAVE_RD_ADDR_READY = ~rd_en;
always @(posedge clk or negedge SLAVE_RSTN) begin
    if(~SLAVE_RSTN)begin
        rdaddrid  <= 'd0;
        rdaddrlen <= 'd0;
    end
    else if(SLAVE_RD_ADDR_VALID && SLAVE_RD_ADDR_READY)begin
        rdaddrid  <= SLAVE_RD_ADDR_ID;
        rdaddrlen <= SLAVE_RD_ADDR_LEN;
    end
    else begin
        rdaddrid  <= rdaddrid ;
        rdaddrlen <= rdaddrlen;
    end
end
always @(posedge clk or negedge SLAVE_RSTN) begin
    if(~SLAVE_RSTN) rdaddr <= 'd0;
    else if(SLAVE_RD_ADDR_VALID && SLAVE_RD_ADDR_READY) rdaddr <= SLAVE_RD_ADDR;
    else if(SLAVE_RD_DATA_VALID && SLAVE_RD_DATA_READY && ~SLAVE_RD_DATA_LAST) rdaddr <= rdaddr + 1;
    else rdaddr <= rdaddr;
end
always @(posedge clk or negedge SLAVE_RSTN) begin
    if(~SLAVE_RSTN) rd_en <= 0;
    else if(SLAVE_RD_ADDR_VALID && SLAVE_RD_ADDR_READY) rd_en <= 1;
    else if(SLAVE_RD_DATA_VALID && SLAVE_RD_DATA_READY && SLAVE_RD_DATA_LAST) rd_en <= 0;
    else rd_en <= rd_en;
end
always @(posedge clk or negedge SLAVE_RSTN) begin
    if(~SLAVE_RSTN) txcnt <= 0;
    else if(SLAVE_RD_ADDR_VALID && SLAVE_RD_ADDR_READY) txcnt <= 0;
    else if(SLAVE_RD_DATA_VALID && SLAVE_RD_DATA_READY) begin
        if(~SLAVE_RD_DATA_LAST)
            txcnt <= txcnt + 1;
        else 
            txcnt <= 0;
    end
    else txcnt <= txcnt;
end
assign SLAVE_RD_DATA_VALID = rd_data_valid_reg;
assign SLAVE_RD_DATA       = rddata;
assign SLAVE_RD_DATA_RESP  =  2'b00;
assign SLAVE_RD_DATA_LAST  = txcnt == rdaddrlen ? 1'b1 : 1'b0;
always @(posedge clk or negedge SLAVE_RSTN) begin
    if(~SLAVE_RSTN) rd_data_valid_reg <= 0;
    else if(SLAVE_RD_DATA_VALID && SLAVE_RD_DATA_READY && SLAVE_RD_DATA_LAST) rd_data_valid_reg <= 0;
    else if(rd_en) rd_data_valid_reg <= 1;
    else rd_data_valid_reg <= rd_data_valid_reg;
end
always @(posedge clk or negedge SLAVE_RSTN) begin
    if(~SLAVE_RSTN) rddata <= 0;
    else
        case(rdaddr)
            32'h00000000 : rddata <= {16'd0 , 8'd0  , led[0 ]};
            32'h00000001 : rddata <= {16'd0 , 8'd1  , led[1 ]};
            32'h00000002 : rddata <= {16'd0 , 8'd2  , led[2 ]};
            32'h00000003 : rddata <= {16'd0 , 8'd3  , led[3 ]};
            32'h00000004 : rddata <= {16'd0 , 8'd4  , led[4 ]};
            32'h00000005 : rddata <= {16'd0 , 8'd5  , led[5 ]};
            32'h00000006 : rddata <= {16'd0 , 8'd6  , led[6 ]};
            32'h00000007 : rddata <= {16'd0 , 8'd7  , led[7 ]};
            32'h00000008 : rddata <= {16'd0 , 8'd8  , led[8 ]};
            32'h00000009 : rddata <= {16'd0 , 8'd9  , led[9 ]};
            32'h0000000a : rddata <= {16'd0 , 8'd10 , led[10]};
            32'h0000000b : rddata <= {16'd0 , 8'd11 , led[11]};
            32'h0000000c : rddata <= {16'd0 , 8'd12 , led[12]};
            32'h0000000d : rddata <= {16'd0 , 8'd13 , led[13]};
            32'h0000000e : rddata <= {16'd0 , 8'd14 , led[14]};
            32'h0000000f : rddata <= {16'd0 , 8'd15 , led[15]};
            32'h00000010 : rddata <= {16'd0 , 8'd16 , led[16]};
            32'h00000011 : rddata <= {16'd0 , 8'd17 , led[17]};
            32'h00000012 : rddata <= {16'd0 , 8'd18 , led[18]};
            32'h00000013 : rddata <= {16'd0 , 8'd19 , led[19]};
            32'h00000014 : rddata <= {16'd0 , 8'd20 , led[20]};
            32'h00000015 : rddata <= {16'd0 , 8'd21 , led[21]};
            32'h00000016 : rddata <= {16'd0 , 8'd22 , led[22]};
            32'h00000017 : rddata <= {16'd0 , 8'd23 , led[23]};
            32'h00000018 : rddata <= {16'd0 , 8'd24 , led[24]};
            32'h00000019 : rddata <= {16'd0 , 8'd25 , led[25]};
            32'h0000001a : rddata <= {16'd0 , 8'd26 , led[26]};
            32'h0000001b : rddata <= {16'd0 , 8'd27 , led[27]};
            32'h0000001c : rddata <= {16'd0 , 8'd28 , led[28]};
            32'h0000001d : rddata <= {16'd0 , 8'd29 , led[29]};
            32'h0000001e : rddata <= {16'd0 , 8'd30 , led[30]};
            32'h0000001f : rddata <= {16'd0 , 8'd31 , led[31]};
            32'h00000020 : rddata <= {31'd0  , sw_ctrl  };
            32'h00000021 : rddata <= {31'd0  , sw_out[4]};
            32'h00000022 : rddata <= {31'd0  , sw_out[3]};
            32'h00000023 : rddata <= {31'd0  , sw_out[2]};
            32'h00000024 : rddata <= {31'd0  , sw_out[1]};
            32'h00000025 : rddata <= {31'd0  , sw_out[0]};
            32'h00000030 : rddata <= {31'd0  , encoder_ctrl};
            default : rddata <= 32'hFFFFFFFF;
        endcase
end
//sw

assign sw = sw_ctrl ? sw_out : 5'bzzzzz;

reg [ 3:0] wraddrid;
reg [31:0] wraddr;
reg [ 7:0] wraddrlen;
reg wr_en;
assign SLAVE_WR_ADDR_READY = ~wr_en;
always @(posedge clk or negedge SLAVE_RSTN) begin
    if(~SLAVE_RSTN)begin
        wraddrid  <= 'd0;
        wraddrlen <= 'd0;
    end
    else if(SLAVE_WR_ADDR_VALID && SLAVE_WR_ADDR_READY)begin
        wraddrid  <= SLAVE_WR_ADDR_ID;
        wraddrlen <= SLAVE_WR_ADDR_LEN;
    end
    else begin
        wraddrid  <= wraddrid ;
        wraddrlen <= wraddrlen;
    end
end
always @(posedge clk or negedge SLAVE_RSTN) begin
    if(~SLAVE_RSTN) wraddr <= 'd0;
    else if(SLAVE_WR_ADDR_VALID && SLAVE_WR_ADDR_READY) wraddr <= SLAVE_WR_ADDR;
    else if(SLAVE_WR_DATA_VALID && SLAVE_WR_DATA_READY && ~SLAVE_WR_DATA_LAST) wraddr <= wraddr + 1;
    else wraddr <= wraddr;
end
always @(posedge clk or negedge SLAVE_RSTN) begin
    if(~SLAVE_RSTN) wr_en <= 'd0;
    else if(SLAVE_WR_DATA_VALID && SLAVE_WR_DATA_READY && SLAVE_WR_DATA_LAST) wr_en <= 0;
    else if(SLAVE_WR_ADDR_VALID && SLAVE_WR_ADDR_READY) wr_en <= 1;
    else wr_en <= wr_en;
end
//把axi的信号做暂存或许比直接大量使用axi的信号时序更稳定吗？
assign SLAVE_WR_DATA_READY = wr_en;
always @(posedge clk or negedge SLAVE_RSTN) begin
    if(~SLAVE_RSTN) begin
        sw_ctrl <= 0;
        sw_out  <= 0;
    end
    else if(SLAVE_WR_DATA_VALID && SLAVE_WR_DATA_READY)begin
        case(wraddr)
            32'h00000020 : sw_ctrl   <= SLAVE_WR_DATA[0];
            32'h00000021 : sw_out[4] <= SLAVE_WR_DATA[0];
            32'h00000022 : sw_out[3] <= SLAVE_WR_DATA[0];
            32'h00000023 : sw_out[2] <= SLAVE_WR_DATA[0];
            32'h00000024 : sw_out[1] <= SLAVE_WR_DATA[0];
            32'h00000025 : sw_out[0] <= SLAVE_WR_DATA[0];
            default : ;
        endcase
    end
end
assign SLAVE_WR_BACK_ID = wraddrid;
// assign SLAVE_WR_BACK_RESP = (wraddr >= 31'h00000020 && wraddr <= 31'h00000025) ? 2'b00 : 2'b10;
always @(posedge clk or negedge SLAVE_RSTN) begin
    if(~SLAVE_RSTN) SLAVE_WR_BACK_VALID <= 0;
    else if(SLAVE_WR_BACK_VALID && SLAVE_WR_BACK_READY) SLAVE_WR_BACK_VALID <= 0;
    else if(SLAVE_WR_DATA_LAST && SLAVE_WR_DATA_VALID && SLAVE_WR_DATA_READY) SLAVE_WR_BACK_VALID <= 1;
    else SLAVE_WR_BACK_VALID <= SLAVE_WR_BACK_VALID;
end

//encoder
reg  [2:0] fifo_wr_en;
reg  [2:0] fifo_rd_en;
reg  [2:0] fifo_wr_data;
wire [2:0] fifo_rd_data;
wire [2:0] fifo_rd_empty;
always @(posedge clk or negedge SLAVE_RSTN) begin
    if(~SLAVE_RSTN) begin
        fifo_wr_en <= 0;
        encoder_ctrl <= 0;
        fifo_wr_data <= 0;
    end
    else if(SLAVE_WR_DATA_VALID && SLAVE_WR_DATA_READY)begin
        case(wraddr)
            32'h00000030 : encoder_ctrl   <= SLAVE_WR_DATA[0];
            32'h00000031 : begin
                if(SLAVE_WR_DATA[0] == 1'b1)begin
                    fifo_wr_en[0] <= 1'b1;
                    fifo_wr_data[0] <= 1'b1;
                end
                else begin
                    fifo_wr_en[0] <= 1'b1;
                    fifo_wr_data[0] <= 1'b0;
                end
                    
            end
            32'h00000032 : begin
                if(SLAVE_WR_DATA[0] == 1'b1)begin
                    fifo_wr_en[1] <= 1'b1;
                    fifo_wr_data[1] <= 1'b1;
                end
                else begin
                    fifo_wr_en[1]  <= 1'b1;
                    fifo_wr_data[1] <= 1'b0;
                end
                    
            end
            32'h00000033 : begin
                if(SLAVE_WR_DATA[0] == 1'b1)begin
                    fifo_wr_en[2] <= 1'b1;
                    fifo_wr_data[2] <= 1'b1;
                end
                else begin
                    fifo_wr_en[2]  <= 1'b1;
                    fifo_wr_data[2] <= 1'b0;
                end
                    
            end
            default : begin
                fifo_wr_en <= 0;
                encoder_ctrl <= 0;
                fifo_wr_data <= fifo_wr_data;
            end
        endcase
    end
    else begin 
        fifo_wr_en <= 0;
        encoder_ctrl <= encoder_ctrl;
        fifo_wr_data <= fifo_wr_data;
    end
end
reg [2:0] state [2:0];
reg [2:0] nextstate [2:0];
localparam IDLE = 0;
localparam WAIT = 1;
localparam READ = 2;
localparam WORK = 3;
parameter  CNTTIME = 30000;
genvar j;
generate
    for(j = 0;j < 3; j = j + 1)begin
        FIFO_encoder FIFO_encoder_0 (
            .clk(clk),                      // input
            .rst(~SLAVE_RSTN),                      // input
            .wr_en(fifo_wr_en[j]),                  // input
            .wr_data(fifo_wr_data[j]),              // input
            .wr_full(),              // output
            .almost_full(),      // output
            .rd_en(fifo_rd_en[j]),                  // input
            .rd_data(fifo_rd_data[j]),              // output
            .rd_empty(fifo_rd_empty[j]),            // output
            .almost_empty()     // output
        );
        always @(posedge clk or negedge SLAVE_RSTN) begin
            if(~SLAVE_RSTN) state[j] <= IDLE;
            else state[j] <= nextstate[j];
        end
        always @(*) begin
            nextstate[j] = state[j];
            case(state[j])
                IDLE : begin
                    if(~fifo_rd_empty[j])
                        nextstate[j] = WAIT;
                    else 
                        nextstate[j] = IDLE;
                end
                WAIT : begin
                    if(fifo_rd_en[j])
                        nextstate[j] = READ;
                    else 
                        nextstate[j] = nextstate[j];
                end
                READ : begin
                    // if(right_start[j] | left_start[j])
                        nextstate[j] = WORK;
                    // else 
                    //     nextstate[j] = READ;
                end
                WORK : begin
                    if(right_done[j] | left_done[j])
                        nextstate[j] = IDLE;
                    else 
                        nextstate[j] = WORK;
                end
            endcase
        end
        always @(posedge clk or negedge SLAVE_RSTN) begin
            if(~SLAVE_RSTN) begin
                fifo_rd_en[j] <= 0;
                right_start[j] <= 0;

                A_out[j] <= 0;
                B_out[j] <= 0;
                right_done[j] <= 0;
                left_done[j] <= 0;
            end
            else begin
                fifo_rd_en[j] <= 0;
                right_done[j] <= 0;
                left_done[j] <= 0;
                case(state[j])
                    IDLE : begin
                        right_start[j] <= 0;
                        left_start[j]  <= 0;
                        
                        A_out[j] <= A_out[j];
                        B_out[j] <= B_out[j];
                        if(~fifo_rd_empty[j])
                            fifo_rd_en[j] <= 1;
                        else 
                            fifo_rd_en[j] <= 0;
                    end
                    WAIT : begin
                        fifo_rd_en[j] <= 0;
                        A_out[j] <= A_out[j];
                        B_out[j] <= B_out[j];
                    end
                    READ : begin
                        if(fifo_rd_data[j]) begin
                            right_start[j] <= 1;
                            A_out[j] <= ~A_out[j];
                        end
                        else begin
                            left_start[j] <= 1;
                            B_out[j] <= ~B_out[j];
                        end
                            
                    end
                    WORK : begin
                        if(encoder_cnt[j] == CNTTIME) begin
                            if(right_start[j])begin
                                B_out[j] <= ~B_out[j];
                                right_done[j] <= 1;
                            end
                                
                            else begin
                                A_out[j] <= ~A_out[j];
                                left_done[j] <= 1;
                            end
                                
                        end
                            
                    end
                endcase
            end
        end
        always @(posedge clk or negedge SLAVE_RSTN) begin
            if(~SLAVE_RSTN) encoder_cnt[j] <= 0;
            else if(right_done[j] | left_done[j]) encoder_cnt[j] <= 0;
            else if(right_start[j] | left_start[j]) encoder_cnt[j] <= encoder_cnt[j] + 1;
            else encoder_cnt[j] <= encoder_cnt[j];
        end
    end
endgenerate
//key
always @(posedge clk or negedge SLAVE_RSTN) begin
    if(~SLAVE_RSTN) begin
        key_ctrl <= 0;
        key_out  <= 0;
    end
    else if(SLAVE_WR_DATA_VALID && SLAVE_WR_DATA_READY)begin
        case(wraddr)
            32'h00000040 : key_ctrl   <= SLAVE_WR_DATA[0];
            32'h00000041 : key_out[0] <= SLAVE_WR_DATA[0];
            32'h00000042 : key_out[1] <= SLAVE_WR_DATA[0];
        endcase
    end
    else begin
        key_ctrl <= key_ctrl;
        key_out <= key_out;
    end
end
assign SLAVE_WR_BACK_RESP = 2'b00;
endmodule