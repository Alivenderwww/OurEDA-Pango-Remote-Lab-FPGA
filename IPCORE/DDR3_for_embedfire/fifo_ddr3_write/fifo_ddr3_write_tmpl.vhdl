-- Created by IP Generator (Version 2022.2-SP6.4 build 146967)
-- Instantiation Template
--
-- Insert the following codes into your VHDL file.
--   * Change the_instance_name to your own instance name.
--   * Change the net names in the port map.


COMPONENT fifo_ddr3_write
  PORT (
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;
    wr_en : IN STD_LOGIC;
    wr_data : IN STD_LOGIC_VECTOR(35 DOWNTO 0);
    wr_full : OUT STD_LOGIC;
    wr_water_level : OUT STD_LOGIC_VECTOR(9 DOWNTO 0);
    almost_full : OUT STD_LOGIC;
    rd_en : IN STD_LOGIC;
    rd_data : OUT STD_LOGIC_VECTOR(287 DOWNTO 0);
    rd_empty : OUT STD_LOGIC;
    almost_empty : OUT STD_LOGIC
  );
END COMPONENT;


the_instance_name : fifo_ddr3_write
  PORT MAP (
    clk => clk,
    rst => rst,
    wr_en => wr_en,
    wr_data => wr_data,
    wr_full => wr_full,
    wr_water_level => wr_water_level,
    almost_full => almost_full,
    rd_en => rd_en,
    rd_data => rd_data,
    rd_empty => rd_empty,
    almost_empty => almost_empty
  );
