module Word_Alignment_32bit (
    input wire          clk             ,
    input wire          rstn            ,
    input wire [31:0]   data_bf_align   /* synthesis PAP_MARK_DEBUG="1" */,
    input wire [ 3:0]   rxk             /* synthesis PAP_MARK_DEBUG="1" */,
    output reg          data_valid      /* synthesis PAP_MARK_DEBUG="1" */,
    output reg [31:0]   data_af_align   /* synthesis PAP_MARK_DEBUG="1" */,
    output reg          data_done/* synthesis PAP_MARK_DEBUG="1" */
);
//************************ 8b10b    K_Code ********************************************
//K28.0     1C
//K28.1     3C
//K28.2     5C
//K28.3     7C
//K28.4     9C
//K28.5     BC
//K28.6     DC
//K28.7     FC
//K23.7     F7
//K27.7     FB
//K29.7     FD
//K30.7     FE
//********************** Pattern Controller ********************************************
// txdata format
// data_x = {data_x_1,data_x_2,data_x_3,data_x_4}
// 假如发送数据是data_1，data_2，data_3
// 接收数据很可能会出现
// {data_1}
//
//
//
//
//
//
// data Format:
// 
// __ ________ ________ ________ ________          ________ ________ ________ ________ ________
// __X_ idle__X__idle__X__idle__X__data__x ……………… x__data__X__idle__X__idle__X__idle__X___idle_
// 
// idle   <=  K28.5
// 空闲时发送K28.5，有数据时发送数据，
// 本模块根据以上格式实现32位数据对齐，使得接收数据与发送数据一致，不会出现错位。
// 
// 
//**************************************************************************************

//parameter
localparam IDLE   = 0;
localparam ALIGN1 = 1;
localparam ALIGN2 = 2;
localparam ALIGN3 = 3;
localparam ALIGN4 = 4;
reg [4:0] state;
reg [4:0] nextstate;
reg skip;
reg rxcnt;
reg [ 7:0] datareg8;
reg [15:0] datareg16;
reg [23:0] datareg24;
reg [31:0] datareg32;
reg error;
// always @(negedge clk or negedge rstn)begin
//     if(~rstn)begin
//         datareg8       <= 0;
//         datareg16      <= 0;
//         datareg24      <= 0;
//         datareg32      <= 0;
//     end
//     else begin
//         datareg8  <= data_bf_align[31:24];
//         datareg16 <= data_bf_align[31:16];
//         datareg24 <= data_bf_align[31:8];
//         datareg32 <= data_bf_align;
//     end
// end
always @(posedge clk or negedge rstn)begin
    if(~rstn)begin
        state <= IDLE;
    end
    else begin
        state <= nextstate;
    end
end
always @(*)begin
    case(state)
        IDLE : begin
            if     (rxk == 4'b0111) nextstate <= ALIGN1;
            else if(rxk == 4'b0011) nextstate <= ALIGN2;
            else if(rxk == 4'b0001) nextstate <= ALIGN3;
            else if(rxk == 4'b0000) nextstate <= ALIGN4;
            else                    nextstate <= IDLE; 
        end
        ALIGN1 : begin
            if(skip || error) begin
                if     (rxk == 4'b0111) nextstate <= ALIGN1;
                else if(rxk == 4'b0011) nextstate <= ALIGN2;
                else if(rxk == 4'b0001) nextstate <= ALIGN3;
                else if(rxk == 4'b0000) nextstate <= ALIGN4;
                else                    nextstate <= IDLE; 
            end
            else 
                nextstate <= ALIGN1; 
        end
        ALIGN2 : begin
            if(skip || error) begin
                if     (rxk == 4'b0111) nextstate <= ALIGN1;
                else if(rxk == 4'b0011) nextstate <= ALIGN2;
                else if(rxk == 4'b0001) nextstate <= ALIGN3;
                else if(rxk == 4'b0000) nextstate <= ALIGN4;
                else                    nextstate <= IDLE; 
            end
            else 
                nextstate <= ALIGN2; 
        end
        ALIGN3 : begin
            if(skip || error) begin
                if     (rxk == 4'b0111) nextstate <= ALIGN1;
                else if(rxk == 4'b0011) nextstate <= ALIGN2;
                else if(rxk == 4'b0001) nextstate <= ALIGN3;
                else if(rxk == 4'b0000) nextstate <= ALIGN4;
                else                    nextstate <= IDLE; 
            end
            else 
                nextstate <= ALIGN3; 
        end
        ALIGN4 : begin
            if(skip || error) begin
                if     (rxk == 4'b0111) nextstate <= ALIGN1;
                else if(rxk == 4'b0011) nextstate <= ALIGN2;
                else if(rxk == 4'b0001) nextstate <= ALIGN3;
                else if(rxk == 4'b0000) nextstate <= ALIGN4;
                else                    nextstate <= IDLE; 
            end
            // if(skip)
            //     nextstate <= IDLE;
            // else if(error)
            //     nextstate <= IDLE;
            else 
                nextstate <= ALIGN4; 
        end
    endcase
end
always @(posedge clk or negedge rstn) begin
    if(~rstn)begin
        data_valid     <= 0;
        data_af_align  <= 0;
        data_done      <= 0; 
        rxcnt          <= 0;
        skip           <= 0;
        datareg8       <= 0;
        datareg16      <= 0;
        datareg24      <= 0;
        datareg32      <= 0;
        error          <= 0;
    end
    else begin
        // data_valid <= 0;
        // data_done <= 0;
        case(state)
            IDLE : begin
                rxcnt <= 0; 
                skip <= 0;
                data_valid <= 0;
                data_done <= 0;
                if(rxk == 4'b1111)begin
                    data_af_align <= data_bf_align;
                    error <= 0;
                end
                else begin
                    if(rxk == 4'b0111)begin
                        datareg8  <= data_bf_align[31:24];
                        error <= 0;
                    end
                    else if(rxk == 4'b0011)begin
                        datareg16 <= data_bf_align[31:16];
                        error <= 0;
                    end
                    else if(rxk == 4'b0001)begin
                       datareg24 <= data_bf_align[31: 8];
                       error <= 0;
                    end
                    else if(rxk == 4'b0000)begin
                       datareg32 <= data_bf_align;
                       error <= 0;
                    end
                    else begin
                        error <= 1;
                    end
                end
            end 
            ALIGN1 : begin
                data_af_align <= {data_bf_align[23:0],datareg8};
                datareg8 <= data_bf_align[31:24];
                if(skip) skip <= 0;
                else if(rxk == 4'b1000) skip <= 1;
                else if(rxk == 4'b0000) skip <= 0;
                else error <= 1;
                
                if(skip)                data_done <= 0;
                else if(rxk == 4'b1000) data_done <= 1;
                else                    data_done <= 0;

                if(skip)  data_valid <= 0;
                else      data_valid <= 1;
            end
            ALIGN2 : begin
                data_af_align <= {data_bf_align[15:0],datareg16};
                datareg16 <= data_bf_align[31:16];
                if(skip) skip <= 0;
                else if(rxk == 4'b1100) skip <= 1;
                else if(rxk == 4'b0000) skip <= 0;
                else error <= 1;
                
                if(skip)                data_done <= 0;
                else if(rxk == 4'b1100) data_done <= 1;
                else                    data_done <= 0;

                if(skip)  data_valid <= 0;
                else      data_valid <= 1;
            end
            ALIGN3 : begin
                data_af_align <= {data_bf_align[7:0],datareg24};
                datareg24 <= data_bf_align[31:8];
                if(skip) skip <= 0;
                else if(rxk == 4'b1110) skip <= 1;
                else if(rxk == 4'b0000) skip <= 0;
                else error <= 1;
                
                if(skip)                data_done <= 0;
                else if(rxk == 4'b1110) data_done <= 1;
                else                    data_done <= 0;

                if(skip)  data_valid <= 0;
                else      data_valid <= 1;
            end
            ALIGN4 : begin
                data_af_align[31:0] <= datareg32;
                datareg32 <= data_bf_align;

                if(skip) skip <= 0;
                else if(rxk == 4'b1111) skip <= 1;
                else if(rxk == 4'b0000) skip <= 0;
                else error <= 1;
                
                if(skip)                data_done <= 0;
                else if(rxk == 4'b1111) data_done <= 1;
                else                    data_done <= 0;

                if(skip)  data_valid <= 0;
                else      data_valid <= 1;
            end
        endcase
    end
end

endmodule