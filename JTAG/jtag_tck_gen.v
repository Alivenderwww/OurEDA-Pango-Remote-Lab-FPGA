module jtag_tck_gen (
    input wire ref_clk,
    input wire rstn,
    output reg tck,
    input wire [15:0] tck_high_period,
    input wire [15:0] tck_low_period,
    output reg jtag_rd_en, //ref_clk时钟域，高电平表示JTAG发送数据，在TCK上升沿前拉高一时钟周期
    output reg jtag_wr_en  //ref_clk时钟域，高电平表示JTAG锁存数据，在TCK下降沿前拉高一时钟周期
);
    reg [15:0] tck_high_period_dly, tck_low_period_dly;
    always @(posedge ref_clk or negedge rstn) begin
        if (!rstn) begin
            tck_high_period_dly <= 5;
            tck_low_period_dly <= 5;
        end else begin
            tck_high_period_dly <= (tck_high_period == 0)?(1):(tck_high_period);
            tck_low_period_dly <= (tck_low_period == 0)?(1):(tck_low_period);
        end
    end


    //JTAG发送与接收数据的逻辑是：TCK上升沿时刻读取数据，TCK下降沿时刻锁存数据
    reg [31:0] counter; // Counter for TCK period
    always @(posedge ref_clk or negedge rstn) begin
        if (!rstn) begin
            counter <= 0;
        end else if (counter < tck_low_period_dly + tck_high_period_dly - 1) begin
            counter <= counter + 1;
        end else begin
            counter <= 0; // Reset counter after reaching TCK_PERIOD
        end
    end

    always @(posedge ref_clk or negedge rstn) begin
        if (!rstn) begin
            jtag_rd_en <= 0;
        end else if (counter == tck_low_period_dly - 1) begin
            jtag_rd_en <= 1;
        end else begin
            jtag_rd_en <= 0; // Reset counter after reaching TCK_PERIOD
        end
    end

    always @(posedge ref_clk or negedge rstn) begin
        if (!rstn) begin
            jtag_wr_en <= 0;
        end else if (counter == tck_low_period_dly + tck_high_period_dly - 1) begin
            jtag_wr_en <= 1;
        end else begin
            jtag_wr_en <= 0; // Reset counter after reaching TCK_PERIOD
        end
    end

    always @(posedge ref_clk or negedge rstn) begin
        if (!rstn) begin
            tck <= 0;
        end else if (jtag_rd_en) begin
            tck <= 1; // Set TCK low during the high period
        end else if (jtag_wr_en)begin
            tck <= 0; // Set TCK high during the low period
        end else tck <= tck;
    end
    
endmodule //jtag_tck_gen
