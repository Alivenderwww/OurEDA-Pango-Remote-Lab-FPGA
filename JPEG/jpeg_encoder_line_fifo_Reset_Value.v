//user set reset value
localparam c_RSTB_VAL_00 = {1'h0,8'h00,1'h0,8'h00,1'h0,8'h00,1'h0,8'h00};
localparam c_RSTA_VAL_00 = {1'h0,8'h00,1'h0,8'h00,1'h0,8'h00,1'h0,8'h00};
localparam c_RSTB_VAL_01 = {1'h0,8'h00,1'h0,8'h00,1'h0,8'h00,1'h0,8'h00};
localparam c_RSTA_VAL_01 = {1'h0,8'h00,1'h0,8'h00,1'h0,8'h00,1'h0,8'h00};
localparam c_RSTB_VAL_02 = {1'h0,8'h00,1'h0,8'h00,1'h0,8'h00,1'h0,8'h00};
localparam c_RSTA_VAL_02 = {1'h0,8'h00,1'h0,8'h00,1'h0,8'h00,1'h0,8'h00};
localparam c_RSTA_VAL = { c_RSTA_VAL_02, c_RSTA_VAL_01, c_RSTA_VAL_00}; 
localparam c_RSTB_VAL = { c_RSTB_VAL_02, c_RSTB_VAL_01, c_RSTB_VAL_00}; 
