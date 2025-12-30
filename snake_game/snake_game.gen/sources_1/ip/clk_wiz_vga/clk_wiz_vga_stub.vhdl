-- Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2022.2 (win64) Build 3671981 Fri Oct 14 05:00:03 MDT 2022
-- Date        : Tue Dec  9 17:42:37 2025
-- Host        : Acer-Predator running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               d:/University/Junior/FPGA/Snake_Game_V3/snake_game/snake_game.gen/sources_1/ip/clk_wiz_vga/clk_wiz_vga_stub.vhdl
-- Design      : clk_wiz_vga
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7a35tcsg324-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity clk_wiz_vga is
  Port ( 
    clk_out1 : out STD_LOGIC;
    reset : in STD_LOGIC;
    locked : out STD_LOGIC;
    clk_in1 : in STD_LOGIC
  );

end clk_wiz_vga;

architecture stub of clk_wiz_vga is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk_out1,reset,locked,clk_in1";
begin
end;
