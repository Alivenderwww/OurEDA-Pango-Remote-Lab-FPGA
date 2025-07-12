module eth_Arbiter (
    input       clk,
    input       rstn,
    input       port0_req/* synthesis PAP_MARK_DEBUG=¡±true¡± */,
    input       port0_done/* synthesis PAP_MARK_DEBUG=¡±true¡± */,
    output reg  port0_sel/* synthesis PAP_MARK_DEBUG=¡±true¡± */,
    input       port1_req/* synthesis PAP_MARK_DEBUG=¡±true¡± */,
    input       port1_done/* synthesis PAP_MARK_DEBUG=¡±true¡± */,
    output reg  port1_sel/* synthesis PAP_MARK_DEBUG=¡±true¡± */
);
localparam st_idle  = 8'b00000000;
localparam st_port0 = 8'b00000001;
localparam st_port1 = 8'b00000010;
reg [7:0] state/* synthesis PAP_MARK_DEBUG=¡±true¡± */;
reg [7:0] next_state/* synthesis PAP_MARK_DEBUG=¡±true¡± */;
reg port0_en,port1_en;
always @(posedge clk or negedge rstn) begin
    if(~rstn)
        state <= st_idle;
    else 
        state <= next_state;
end
always@(*)begin
    if(~rstn) 
        next_state <= st_idle;
    else begin
        case (state)
            st_idle : begin
                case({port1_en,port0_en})
                    2'b01   : next_state <= st_port0;
                    2'b10   : next_state <= st_port1;
                    default : next_state <= st_idle;
                endcase
            end
            st_port0 : begin
                if(port0_done)
                    next_state <= st_idle;
                else 
                    next_state <= st_port0; 
            end
            st_port1 : begin
                if(port1_done)
                    next_state <= st_idle;
                else 
                    next_state <= st_port1; 
            end
            default : next_state <= st_idle;
        endcase
    end 
end
always @(posedge clk or negedge rstn) begin
    if(~rstn)begin
        port0_sel <= 0;
        port1_sel <= 0;
    end
    else begin
        case(next_state)
            st_idle : begin
                if(port0_req)begin
                    port0_en <= 1;
                    port0_sel <= 1;
                end
                else if(port1_req)begin
                    port1_en <= 1;
                    port1_sel <= 1;
                end
                else begin
                    port0_en <= 0;
                    port1_en <= 0;
                    port0_sel <= 0;
                    port1_sel <= 0;
                end
            end
            st_port0 : begin
                if(port0_done)
                    port0_sel <= 0;
                else 
                    port0_sel <= 1;
                port0_en <= 0;
                port1_en <= 0;
            end
            st_port1 : begin
                if(port1_done)
                    port1_sel <= 0;
                else 
                    port1_sel <= 1;
                port0_en <= 0;
                port1_en <= 0;
            end
        endcase
    end
end
endmodule