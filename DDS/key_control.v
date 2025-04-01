module  key_control(
    input  wire       clk        ,
    input  wire       rst        ,
    input  wire [3:0] key        ,
    output wire [3:0] wave_select
);

parameter   sin_wave    =   4'b0001,    //正弦波
            squ_wave    =   4'b0010,    //方波
            tri_wave    =   4'b0100,    //三角波
            saw_wave    =   4'b1000;    //锯齿波


parameter   CNT_MAX =   20'd999_999;    //计数器计数最大值          



wire            key3    ;   //按键3
wire            key2    ;   //按键2
wire            key1    ;   //按键1
wire            key0    ;   //按键0

reg     [3:0]   wave    ;   //按键状态对应波形
reg     [3:0]   key_state;  //按键状态

//key_state:按键状态
always@(posedge clk)
    if(rst == 1) key_state <= 4'b0001;
    else if(key0 == 1'b1) key_state <= 4'b0001;
    else if(key1 == 1'b1) key_state <= 4'b0010;
    else if(key2 == 1'b1) key_state <= 4'b0100;
    else if(key3 == 1'b1) key_state <= 4'b1000;
    else key_state <= key_state;

//wave:按键状态对应波形
always@(posedge clk)
    if(rst == 1)
        wave <= 4'd0;
    else
        case(key_state) //按键扫描
            4'b0001:wave <= sin_wave;
            4'b0010:wave <= squ_wave;
            4'b0100:wave <= tri_wave;
            4'b1000:wave <= saw_wave;
            default:wave <= sin_wave;
        endcase

//wave_select:波形选择
assign wave_select = wave;

key_filter #(
    .CNT_MAX      (CNT_MAX  )
)key_filter_inst3(
    .clk          (clk      ),
    .rst          (rst      ),
    .key_in       (key[3]   ),
    .key_flag     (key3     )
);

key_filter #(
    .CNT_MAX      (CNT_MAX  )
)key_filter_inst2(
    .clk          (clk      ),
    .rst          (rst      ),
    .key_in       (key[2]   ),
    .key_flag     (key2     )
);

key_filter #(
    .CNT_MAX      (CNT_MAX  )
)key_filter_inst1(
    .clk          (clk      ),
    .rst          (rst      ),
    .key_in       (key[1]   ),
    .key_flag     (key1     )
);

key_filter #(
    .CNT_MAX      (CNT_MAX  )
)key_filter_inst0(
    .clk          (clk      ),
    .rst          (rst      ),
    .key_in       (key[0]   ),
    .key_flag     (key0     )
);

endmodule
