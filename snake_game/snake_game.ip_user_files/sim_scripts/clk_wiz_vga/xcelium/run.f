-makelib xcelium_lib/xpm -sv \
  "C:/Xilinx/Vivado/2022.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
-endlib
-makelib xcelium_lib/xpm \
  "C:/Xilinx/Vivado/2022.2/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../../snake_game.gen/sources_1/ip/clk_wiz_vga/clk_wiz_vga_clk_wiz.v" \
  "../../../../snake_game.gen/sources_1/ip/clk_wiz_vga/clk_wiz_vga.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  glbl.v
-endlib

