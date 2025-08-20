module Datacreate #(
    parameter CLKHZ = 32'd100_000_000,
    parameter BANK_NUM = 1,
    parameter BANK_X = 8,
    parameter BANK_Y = 8
) (
    input wire clk,
    input wire rst,
    output reg [23:0] wscolor [BANK_NUM*BANK_X*BANK_Y]
);
wire tick;
reg [31:0] pixelx, pixely, pixelxy, pixelbank, pixelxyb;
reg [64-1:0] tempnum[10];
wire [64-1:0] tempnumnow;
reg [31:0] numcnt;
reg [7:0] pixel_h, pixel_s, pixel_v, pixel_R, pixel_G, pixel_B;
assign tempnumnow = tempnum[numcnt];
always @(posedge clk) pixelxy = (pixelx) + (BANK_X * (pixely));
always @(posedge clk) pixelxyb = (pixelx) + (BANK_X * (pixely)) + pixelbank*BANK_X*BANK_Y;

always @(posedge clk) begin
    if(rst) numcnt <= 0;
    else if(tick)begin
        if(numcnt >= 9) numcnt <= 0;
        else numcnt <= numcnt + 1;
    end else numcnt <= numcnt;
end

integer i;
always @(posedge clk) begin
    if(rst) for(i=0;i<BANK_NUM*BANK_X*BANK_Y;i=i+1) wscolor[i] <= 0;
    else if(tick)begin
        wscolor[pixelxyb] <= {pixel_R,pixel_G,pixel_B};
        // case (pixelbank)
        //     0: wscolor[pixelxyb] <= (tempnumnow[pixelxy] == 1'b1)?(24'h990000):(24'h070707);
        //     1: wscolor[pixelxyb] <= (tempnumnow[pixelxy] == 1'b1)?(24'h009900):(24'h100010);
        //     2: wscolor[pixelxyb] <= (tempnumnow[pixelxy] == 1'b1)?(24'h000099):(24'h101000);
        //     3: wscolor[pixelxyb] <= (tempnumnow[pixelxy] == 1'b1)?(24'h999900):(24'h000010);
        //     default: wscolor[pixelxyb] <= (tempnumnow[pixelxy] == 1'b1)?(24'h330000):(24'h050505);
        // endcase
    end
end

// integer i;
always @(posedge clk) begin
    if(rst) begin
        {pixel_h, pixel_s, pixel_v} <= 0;
    end
    else if(tick)begin
        pixel_h <= pixel_h + 1;
        // pixel_v <= (pixel_h == 255)?(pixel_v+1):(pixel_v);
        // pixel_s <= (pixel_v == 255)?(pixel_s+1):(pixel_s);
        pixel_v <= 100;
        pixel_s <= 200;
    end
end

always @(posedge clk) begin
    if(rst) begin
        pixelx <= 0;
        pixely <= 0;
        pixelbank <= 0;
    end else if(tick)begin
        pixelx <= (pixelx >= BANK_X - 1)?(0):(pixelx + 1);
        pixely <= (pixelx >= BANK_X - 1)?((pixely >= BANK_Y - 1)?(0):(pixely + 1)):(pixely);
        pixelbank <= (pixelx >= BANK_X - 1 && pixely >= BANK_Y - 1)?((pixelbank >= BANK_NUM - 1)?(0):(pixelbank + 1)):(pixelbank);
    end
end

timingDivider #(
    .INPUTCLKHZ (CLKHZ),
    .OUTPUTCLKus(0),
    .OUTPUTCLKms(10),
    .SIMULATION (0)
) timingDivider_inst(
    .inclk(clk),
    .reset(rst),
    .tick(tick)
);

initial begin
    tempnum[0] = {8'h00,8'h38,8'h44,8'h4C,8'h54,8'h64,8'h44,8'h38}; //0
    tempnum[1] = {8'h00,8'h38,8'h10,8'h10,8'h10,8'h10,8'h18,8'h10}; //1
    tempnum[2] = {8'h00,8'h7C,8'h04,8'h08,8'h30,8'h40,8'h44,8'h38}; //2
    tempnum[3] = {8'h00,8'h38,8'h44,8'h40,8'h30,8'h20,8'h40,8'h7C}; //3
    tempnum[4] = {8'h00,8'h20,8'h20,8'h7C,8'h24,8'h28,8'h30,8'h20}; //4
    tempnum[5] = {8'h00,8'h38,8'h44,8'h40,8'h40,8'h3C,8'h04,8'h7C}; //5
    tempnum[6] = {8'h00,8'h38,8'h44,8'h44,8'h3C,8'h04,8'h08,8'h70}; //6
    tempnum[7] = {8'h00,8'h08,8'h08,8'h08,8'h10,8'h20,8'h40,8'h7C}; //7
    tempnum[8] = {8'h00,8'h38,8'h44,8'h44,8'h38,8'h44,8'h44,8'h38}; //8
    tempnum[9] = {8'h00,8'h1C,8'h20,8'h40,8'h78,8'h44,8'h44,8'h38}; //9
end

HSV2RGB #(          //HSV: hue, saturation, value. (same as HSB(Brightness))
    .HSV_DEPTH(8),
    .RGB_DEPTH(8)
) HSV2RGB_inst(   
    .clk(clk),               
    .hue(pixel_h),
    .sat(pixel_s),
    .val(pixel_v),
    .R  (pixel_R),
    .G  (pixel_G),
    .B  (pixel_B)
);

endmodule