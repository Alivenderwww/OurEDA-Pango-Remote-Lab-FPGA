module Send #(
    parameter DEPTH = 24, //RGB888
    parameter CLKHZ = 32'd50_000_000,
    parameter WS_NUM = 7
) (
    input wire [DEPTH - 1:0] wscolor [WS_NUM],
    input wire clk,
    input wire rst,
    output reg data_stream
);

//R5

wire [DEPTH - 1:0] colortemp_GRB;
reg [DEPTH - 1:0] colortemp_RGB;

localparam ST_T0L = 'd0,
           ST_T0H = 'd1,
           ST_T1L = 'd2,
           ST_T1H = 'd3,
           ST_RES = 'd4;

localparam TIME_T0L = (32'd750    )/((32'd1000_000_000) / (CLKHZ)),  //750ns
           TIME_T0H = (32'd300    )/((32'd1000_000_000) / (CLKHZ)),  //300ns
           TIME_T1L = (32'd750    )/((32'd1000_000_000) / (CLKHZ)),  //750ns
           TIME_T1H = (32'd750    )/((32'd1000_000_000) / (CLKHZ)),  //750ns
           TIME_RES = (32'd500_000)/((32'd1000_000_000) / (CLKHZ));  //500us=500_000ns

reg [2:0] st_current,st_next;
reg [31:0] cnt_trans,cnt_depth,cnt_num;
wire flag_bitend, flag_oneend, flag_allend;
reg flag_transend, flag_gettemp;

//flag_transend
always @(*) begin
    case (st_current)
        ST_T0L:  flag_transend <= (cnt_trans >= TIME_T0L - 1);
        ST_T0H:  flag_transend <= (cnt_trans >= TIME_T0H - 1);
        ST_T1L:  flag_transend <= (cnt_trans >= TIME_T1L - 1);
        ST_T1H:  flag_transend <= (cnt_trans >= TIME_T1H - 1);
        ST_RES:  flag_transend <= (cnt_trans >= TIME_RES - 1);
        default: flag_transend <= (cnt_trans >= TIME_RES - 1);
    endcase
end

//flag_gettemp
always @(*) begin
    case (st_current)
        ST_T0L:  flag_gettemp <= (cnt_trans >= TIME_T0L - 3 && cnt_depth == 0);
        ST_T1L:  flag_gettemp <= (cnt_trans >= TIME_T1L - 3 && cnt_depth == 0);
        ST_RES:  flag_gettemp <= (cnt_trans >= TIME_RES - 3);
        default: flag_gettemp <= 0;
    endcase
end

//flag_bitend, flag_oneend, flag_allend
assign flag_bitend = (flag_transend) && (st_current == ST_T0L || st_current == ST_T1L);
assign flag_oneend = (flag_bitend) && (cnt_depth == 0);
assign flag_allend = (flag_oneend) && (cnt_num >= WS_NUM - 1);

//st_current
always @(posedge clk) begin
    if(rst) st_current <= ST_RES;
    else st_current <= st_next;
end

//st_next
always @(*) begin
    if(rst) st_next <= ST_RES;
    else case (st_current)
        ST_T0L,ST_T1L: begin
            if(flag_allend) st_next <= ST_RES;
            else if(flag_bitend) begin
                if((cnt_depth == 0 && colortemp_GRB[DEPTH - 1] == 1'b0) || (cnt_depth != 0 && colortemp_GRB[cnt_depth - 1] == 1'b0))
                     st_next <= ST_T0H;
                else st_next <= ST_T1H;
            end else st_next <= st_current;
        end
        ST_RES: begin
            if(flag_transend) begin
                if(colortemp_GRB[DEPTH - 1] == 1'b0) 
                     st_next <= ST_T0H;
                else st_next <= ST_T1H;
            end else st_next <= ST_RES;
        end
        ST_T0H: st_next <= (flag_transend)?(ST_T0L):(ST_T0H);
        ST_T1H: st_next <= (flag_transend)?(ST_T1L):(ST_T1H);
        default: st_next <= ST_RES;
    endcase
end

//cnt_trans
always @(posedge clk) begin
    if(rst) cnt_trans <= 0;
    else if(flag_transend) cnt_trans <= 0;
    else cnt_trans <= cnt_trans + 1;
end

//cnt_num
always @(posedge clk) begin
    if(rst) cnt_num <= 0;
    else if(flag_allend) cnt_num <= 0;
    else if(flag_oneend)
         cnt_num <= cnt_num + 1;
    else cnt_num <= cnt_num;
end

//cnt_depth
always @(posedge clk) begin
    if(rst) cnt_depth <= DEPTH - 1;
    else if(flag_oneend) cnt_depth <= DEPTH - 1;
    else if(flag_bitend) cnt_depth <= cnt_depth - 1;
    else cnt_depth <= cnt_depth;
end

//RGB -> GRB
//colortemp_RGB, colortemp_GRB
integer i;
always @(posedge clk) begin
    if(rst) for(i=0;i<DEPTH;i=i+1) colortemp_RGB[i] <= 0;
    else if(flag_gettemp) begin
        if(st_current == ST_RES) 
             colortemp_RGB <= {wscolor[0]};
        else if(cnt_num >= WS_NUM - 1) for(i=0;i<DEPTH;i=i+1) colortemp_RGB[i] <= 0;
        else colortemp_RGB <= wscolor[cnt_num + 1];
    end
end
assign colortemp_GRB = {colortemp_RGB[15:8],colortemp_RGB[23:16],colortemp_RGB[7:0]};

//data_stream
always @(posedge clk) begin
    if(rst) data_stream <= 0;
    else case (st_current)
        ST_T0L, ST_T1L, ST_RES: data_stream <= 1'b0;
        ST_T0H, ST_T1H: data_stream <= 1'b1;
        default: data_stream <= 1'b0;
    endcase
end

endmodule