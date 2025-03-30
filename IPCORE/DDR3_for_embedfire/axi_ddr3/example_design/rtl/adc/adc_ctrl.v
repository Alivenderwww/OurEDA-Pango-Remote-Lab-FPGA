module adc_ctrl #(
    parameter DEVICE_ID  = 0  //8'h00: OTHERS; 
                              //8'h01: PG2L100H; 
                              //8'h02: PG2K400;
                              //8'h03: PG2T70H;
                              //8'h04: PG2T390HX;
)(
input				clk,
input				rst_n,
input				dbg_temp_rd,
input				dbg_volt_rd,
output reg [15:0]   pdata
);

parameter  CREG_00H =16'b0011_0000_0011_1111;       //PD=10 PCLK(NOT OSC_CLK) SEQ=1 RDATA=1 ALARM[4:0]='hF OT=1
parameter  CREG_01H =16'b1101_0000_0001_1110;       //CAL=11(offset&gain) AVG=10(average=64) DIV=32
parameter  CREG_02H =16'b0000_0000_0000_1001;       //VREF=1(external reference) E_B_VPN=0 E_OSC_1
parameter  CREG_03H =16'b0000_0000_0111_1100;       //ADC_A  temp/voltage enable(0=disable)
parameter  CREG_04H =16'b0000_0000_0000_0000;       //ADC_A  auxiliary channel enable(0=disable)
parameter  CREG_0AH =16'b0000_0000_0000_0000;       //ADC_B  auxiliary channel enable(0=disable)
parameter  CREG_05H =16'b0000_0000_0000_0000;       //Internal and VPN channle mode select(0=UNIPOLAR)
parameter  CREG_06H =16'b0000_0000_0000_0000;       //ADC_A auxiliary channle mode select(0=UNIPOLAR)
parameter  CREG_0CH =16'b0000_0000_0000_0000;       //ADC_B auxiliary channle mode select(0=UNIPOLAR)
parameter  CREG_07H =16'b0000_0000_0111_1100;       //Internal channle average enable(0=disable)
//parameter  CREG_07H =16'b0000_0000_0000_0000;       //Internal channle average enable(0=disable)
parameter  CREG_08H =16'b0000_0000_0000_0000;       //ADC_A auxiliary channle average enable(0=disable)
parameter  CREG_0EH =16'b0000_0000_0000_0000;       //ADC_B auxiliary channle average enable(0=disable)
parameter  CREG_16H =16'b0000_0000_0000_0000;       //
parameter  CREG_17H =16'b0000_0000_0000_0000;       //
parameter  CREG_18H =16'b0000_0000_0000_0000;       //
parameter  CREG_19H =16'b0000_0000_0000_0000;       //
parameter  CREG_1AH =16'b0000_0000_0000_0000;       //
parameter  CREG_1BH =16'b0000_0000_0000_0000;       //
parameter  CREG_20H =12'b1100_1100_0010;            //TEMP_SENSOR_HIGH'hCC2;125C
parameter  CREG_21H =12'b0111_0111_1001;            //TEMP_SENSOR_LOW 'h779;-40C
parameter  CREG_22H =12'b0101_1001_1010;            //VCC_HIGH        'h59A;1.05V
parameter  CREG_23H =12'b0101_0001_0001;            //VCC_LOW         'h511;0.95V
parameter  CREG_24H =12'b1010_0001_0100;            //VCCA_HIGH       'hA14;1.89V
parameter  CREG_25H =12'b1001_0001_1111;            //VCCA_LOW        'h91F;1.71V
parameter  CREG_26H =12'b0110_1110_1111;            //VCC_CRAM_HIGH   'h6EF;1.3V
parameter  CREG_27H =12'b0110_0110_0110;            //VCC_CRAM_LOW    'h666;1.2V
parameter  CREG_28H =12'b0101_1001_1010;            //VCC_DRM_HIGH    'h59A;1.05V
parameter  CREG_29H =12'b0101_0001_0001;            //VCC_DRM_LOW     'h511;0.95V
parameter  CREG_2AH =12'b1100_1100_0010;            //OVER_TEMP_LIMIT 'hCC2;125C
parameter  CREG_2BH =12'b1010_0101_1011;            //OVER_TEMP_RESET 'hA5B;50C

wire [15:0]     adc_di;
wire [15:0]     adc_do;
wire            OVER_TEMP;
wire            LOGIC_DONE_A;
wire            LOGIC_DONE_B;
wire            ADC_CLK_OUT;
wire            DMODIFIED;
wire [5:0]      ALARM;
wire [7:0]      DADDR=8'h40;
wire            data_rdy;

wire			sel;
wire			penable;

wire      ready;
reg  [7:0] paddr;

reg  [3:0] dbg_temp_rd_d;
reg  [3:0] dbg_volt_rd_d;
wire       dbg_temp_rd_pos;
wire       dbg_volt_rd_pos;
reg  [1:0] dbg_temp_rd_pos_d;
reg  [1:0] dbg_volt_rd_pos_d;
reg  [5:0] adc_cnt;
reg  [4:0] adc_sel;
reg        adc_enable;
reg        ck_1m;

generate
if (DEVICE_ID == 8'h03) begin: adc_control
    // monitor

    always@ (posedge clk or negedge rst_n)
    begin
    	if(rst_n == 1'b0)
        begin
    		dbg_temp_rd_d <= 4'b0;
    		dbg_volt_rd_d <= 4'b0;
        end
    	else 
        begin
    		dbg_temp_rd_d <= {dbg_temp_rd_d[2:0],dbg_temp_rd};
    		dbg_volt_rd_d <= {dbg_volt_rd_d[2:0],dbg_volt_rd};
        end
    end
    
    always@ (posedge clk or negedge rst_n)
    begin
    	if(rst_n == 1'b0)
        begin
    		adc_cnt <= 5'b0;
    		ck_1m <= 1'b0;
        end
    	else if(adc_cnt == 5'd25)
        begin
    		adc_cnt <= 5'b0;
    		ck_1m <= ~ck_1m;
        end
        else 
        begin
            adc_cnt <= adc_cnt +5'b1;
    		ck_1m <= ck_1m;
        end
    end

     
    always@ (posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            adc_sel <= 5'b00000;
        else if(dbg_volt_rd_d[2])// VCC volt
            adc_sel <= 5'b00001;
        else if(dbg_temp_rd_d[2])// temperature
            adc_sel <= 5'b00000;
        else 
             adc_sel <= adc_sel;
    end 
 
    always@ (posedge clk or negedge rst_n)
    begin
        if(~rst_n)
            pdata   <= 16'b0;
        else if(data_rdy == 1'b1)
            pdata   <= adc_do;
        else
            pdata   <= pdata;
    end 

    always@ (posedge clk or negedge rst_n)
    begin
        if (~rst_n)
            adc_enable <= 1'b0;
        else
            adc_enable <= 1'b1;
    end
end
else begin: adc_control
    always@ (posedge clk or negedge rst_n)
    begin
    	if(rst_n == 1'b0)
        begin
    		dbg_temp_rd_d <= 4'b0;
    		dbg_volt_rd_d <= 4'b0;
        end
    	else
        begin
    		dbg_temp_rd_d <= {dbg_temp_rd_d[2:0],dbg_temp_rd};
    		dbg_volt_rd_d <= {dbg_volt_rd_d[2:0],dbg_volt_rd};
        end
    end
    
    assign dbg_temp_rd_pos = ~dbg_temp_rd_d[1] & dbg_temp_rd_d[0];
    assign dbg_volt_rd_pos = ~dbg_volt_rd_d[1] & dbg_volt_rd_d[0];
    
    always@ (posedge clk or negedge rst_n)
    begin
    	if(rst_n == 1'b0)
        begin
    		dbg_temp_rd_pos_d <= 2'b0;
    		dbg_volt_rd_pos_d <= 2'b0;
        end
    	else
        begin
    		dbg_temp_rd_pos_d <= {dbg_temp_rd_pos_d[0],dbg_temp_rd_pos};
    		dbg_volt_rd_pos_d <= {dbg_volt_rd_pos_d[0],dbg_volt_rd_pos};
        end
    end
    
    always@ (posedge clk or negedge rst_n)
    begin
    	if(rst_n == 1'b0)
    		paddr <= 8'h40;
    	else if(dbg_temp_rd_pos)
    		paddr <= 8'h40;
    	else if(dbg_volt_rd_pos)
    		paddr <= 8'h41;
        else;
    end
    
    assign sel     = dbg_temp_rd_pos_d[1] | dbg_volt_rd_pos_d[1];
    //assign sel     = (dbg_temp_rd_pos_d[0] | dbg_temp_rd_pos_d[1]) | (dbg_volt_rd_pos_d[0] | dbg_volt_rd_pos_d[1]);
    //assign penable = dbg_temp_rd_pos_d[1] | dbg_volt_rd_pos_d[1];
    
    always@ (posedge clk)
    begin
        if (data_rdy)
            pdata   <= adc_do;
        else;
    end
end
endgenerate

//
generate
if (DEVICE_ID == 8'h00 || DEVICE_ID == 8'h01 || DEVICE_ID == 8'h04) begin: adc_select
GTP_ADC_E2  #( 
                    .CREG_00H (CREG_00H), 
                    .CREG_01H (CREG_01H),
                    .CREG_02H (CREG_02H),
                    .CREG_03H (CREG_03H),
                    .CREG_04H (CREG_04H),
                    .CREG_0AH (CREG_0AH),
                    .CREG_05H (CREG_05H),
                    .CREG_06H (CREG_06H),
                    .CREG_0CH (CREG_0CH),
                    .CREG_07H (CREG_07H),
                    .CREG_08H (CREG_08H),
                    .CREG_0EH (CREG_0EH),
                    .CREG_20H (CREG_20H),
                    .CREG_21H (CREG_21H),
                    .CREG_22H (CREG_22H),
                    .CREG_23H (CREG_23H),
                    .CREG_24H (CREG_24H),
                    .CREG_25H (CREG_25H),
                    .CREG_26H (CREG_26H),
                    .CREG_27H (CREG_27H),
                    .CREG_28H (CREG_28H),
                    .CREG_29H (CREG_29H),
                    .CREG_2AH (CREG_2AH),
                    .CREG_2BH (CREG_2BH)
                  ) 
u_adc     
(
 	    //--------------input---------------// 
            .VA           (                ),
            .VAUX         (                ),
            .RST_N        (  rst_n         ),
            .CONVST       (  1'b0         ),
            .LOADSC_N     (  1'b1      ), 
            .DCLK         (  clk           ), 
            .DADDR        (  paddr         ), 
            .DEN          (  1'b1          ),	 
            .SECEN        (  sel           ),	 
            .DWE          (  1'b0          ),	 
            .DI           (  adc_di            ),	 
        //-------------output---------------//     
            .DO           (  adc_do            ),     
            .DRDY         (  data_rdy          ),
            .OVER_TEMP    (  OVER_TEMP     ),
            .LOGIC_DONE_A (  LOGIC_DONE_A  ),
            .LOGIC_DONE_B (  LOGIC_DONE_B  ),
            .ADC_CLK_OUT  (  ADC_CLK_OUT   ),
            .DMODIFIED    (  DMODIFIED     ), 
            .ALARM        (  ALARM         )
) /* synthesis syn_noprune = 1 */; 
end
else if(DEVICE_ID == 8'h03) begin
    wire [9:0] adc_do_pre ;
    assign adc_do = {6'b0,adc_do_pre} ;
    begin: adc_select
        GTP_MONITOR_E1 #(
            .MODE          ("DEFAULT"      ),
            .CALIB         ("TRUE"         ),
            .DYN_CALIB     ("TRUE"         ),
            .AVG_NUM       (16             ),
            .SAMPLE_AL     ('b00           ) 
        ) u_adc (
            .DATA_VALID    (data_rdy       ), // OUTPUT  
            .READY         (               ), // OUTPUT  
            .CLK           (ck_1m            ), // INPUT  
            .EN            (adc_enable     ), // INPUT  
            .RST_N         (rst_n          ), // INPUT  
            .SAMPLE        (               ), // INPUT  
            .DATA          (adc_do_pre     ), // OUTPUT[9:0]  
            .SEL           (adc_sel        )  // INPUT[4:0]  
        );
    end
end
else if(DEVICE_ID == 8'h02) begin: adc_select
GTP_ADC_E4  #( 
                    .CREG_00H (CREG_00H), 
                    .CREG_01H (CREG_01H),
                    .CREG_02H (CREG_02H),
                    .CREG_03H (CREG_03H),
                    .CREG_04H (CREG_04H),
                    .CREG_0AH (CREG_0AH),
                    .CREG_05H (CREG_05H),
                    .CREG_06H (CREG_06H),
                    .CREG_0CH (CREG_0CH),
                    .CREG_07H (CREG_07H),
                    .CREG_08H (CREG_08H),
                    .CREG_0EH (CREG_0EH),
                    .CREG_16H (CREG_16H),
                    .CREG_17H (CREG_17H),
                    .CREG_18H (CREG_18H),
                    .CREG_19H (CREG_19H),
                    .CREG_1AH (CREG_1AH),
                    .CREG_1BH (CREG_1BH),
                    .CREG_20H (CREG_20H),
                    .CREG_21H (CREG_21H),
                    .CREG_22H (CREG_22H),
                    .CREG_23H (CREG_23H),
                    .CREG_24H (CREG_24H),
                    .CREG_25H (CREG_25H),
                    .CREG_26H (CREG_26H),
                    .CREG_27H (CREG_27H),
                    .CREG_28H (CREG_28H),
                    .CREG_29H (CREG_29H),
                    .CREG_2AH (CREG_2AH),
                    .CREG_2BH (CREG_2BH)
                  ) 
u_adc     
(
 	    //--------------input---------------// 
            .VA           (                ),
            .VAUX         (                ),
            .RST_N        (  rst_n         ),
            .CONVST       (  1'b0         ),
            .LOADSC_N     (  1'b1      ), 
            .DCLK         (  clk           ), 
            .DADDR        (  paddr         ), 
            .DEN          (  1'b1          ),	 
            .SECEN        (  sel           ),	 
            .DWE          (  1'b0          ),	 
            .DI           (  adc_di            ),	 
        //-------------output---------------//     
            .DO           (  adc_do            ),     
            .DRDY         (  data_rdy          ),
            .OVER_TEMP    (  OVER_TEMP     ),
            .LOGIC_DONE_A (  LOGIC_DONE_A  ),
            .LOGIC_DONE_B (  LOGIC_DONE_B  ),
            .ADC_CLK_OUT  (  ADC_CLK_OUT   ),
            .DMODIFIED    (  DMODIFIED     ), 
            .ALARM        (  ALARM         )
) /* synthesis syn_noprune = 1 */; 
end
endgenerate

endmodule
