-- Created by IP Generator (Version 2022.2-SP6.4 build 146967)
-- Instantiation Template
--
-- Insert the following codes into your VHDL file.
--   * Change the_instance_name to your own instance name.
--   * Change the net names in the port map.


COMPONENT hsst
  PORT (
    i_free_clk : IN STD_LOGIC;
    i_pll_rst_0 : IN STD_LOGIC;
    i_wtchdg_clr_0 : IN STD_LOGIC;
    o_wtchdg_st_0 : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    o_pll_done_0 : OUT STD_LOGIC;
    o_txlane_done_3 : OUT STD_LOGIC;
    o_rxlane_done_3 : OUT STD_LOGIC;
    i_p_refckn_0 : IN STD_LOGIC;
    i_p_refckp_0 : IN STD_LOGIC;
    o_p_clk2core_tx_3 : OUT STD_LOGIC;
    i_p_tx3_clk_fr_core : IN STD_LOGIC;
    o_p_clk2core_rx_3 : OUT STD_LOGIC;
    i_p_rx3_clk_fr_core : IN STD_LOGIC;
    o_p_pll_lock_0 : OUT STD_LOGIC;
    o_p_rx_sigdet_sta_3 : OUT STD_LOGIC;
    o_p_lx_cdr_align_3 : OUT STD_LOGIC;
    i_p_pcs_word_align_en_3 : IN STD_LOGIC;
    i_p_l3rxn : IN STD_LOGIC;
    i_p_l3rxp : IN STD_LOGIC;
    o_p_l3txn : OUT STD_LOGIC;
    o_p_l3txp : OUT STD_LOGIC;
    i_txd_3 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    i_tdispsel_3 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    i_tdispctrl_3 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    i_txk_3 : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    o_rxstatus_3 : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    o_rxd_3 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    o_rdisper_3 : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    o_rdecer_3 : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    o_rxk_3 : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
  );
END COMPONENT;


the_instance_name : hsst
  PORT MAP (
    i_free_clk => i_free_clk,
    i_pll_rst_0 => i_pll_rst_0,
    i_wtchdg_clr_0 => i_wtchdg_clr_0,
    o_wtchdg_st_0 => o_wtchdg_st_0,
    o_pll_done_0 => o_pll_done_0,
    o_txlane_done_3 => o_txlane_done_3,
    o_rxlane_done_3 => o_rxlane_done_3,
    i_p_refckn_0 => i_p_refckn_0,
    i_p_refckp_0 => i_p_refckp_0,
    o_p_clk2core_tx_3 => o_p_clk2core_tx_3,
    i_p_tx3_clk_fr_core => i_p_tx3_clk_fr_core,
    o_p_clk2core_rx_3 => o_p_clk2core_rx_3,
    i_p_rx3_clk_fr_core => i_p_rx3_clk_fr_core,
    o_p_pll_lock_0 => o_p_pll_lock_0,
    o_p_rx_sigdet_sta_3 => o_p_rx_sigdet_sta_3,
    o_p_lx_cdr_align_3 => o_p_lx_cdr_align_3,
    i_p_pcs_word_align_en_3 => i_p_pcs_word_align_en_3,
    i_p_l3rxn => i_p_l3rxn,
    i_p_l3rxp => i_p_l3rxp,
    o_p_l3txn => o_p_l3txn,
    o_p_l3txp => o_p_l3txp,
    i_txd_3 => i_txd_3,
    i_tdispsel_3 => i_tdispsel_3,
    i_tdispctrl_3 => i_tdispctrl_3,
    i_txk_3 => i_txk_3,
    o_rxstatus_3 => o_rxstatus_3,
    o_rxd_3 => o_rxd_3,
    o_rdisper_3 => o_rdisper_3,
    o_rdecer_3 => o_rdecer_3,
    o_rxk_3 => o_rxk_3
  );
