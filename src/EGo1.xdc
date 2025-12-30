################################################################################
#                           CLOCK & RESET
################################################################################
set_property -dict { PACKAGE_PIN P17 IOSTANDARD LVCMOS33 } [get_ports sys_clk_in ]
set_property -dict { PACKAGE_PIN P15 IOSTANDARD LVCMOS33 } [get_ports sys_rst_n  ]

################################################################################
#                           XADC ANALOG INPUT
################################################################################
set_property -dict { PACKAGE_PIN B12 IOSTANDARD LVCMOS33 } [get_ports XADC_AUX_v_n   ]
set_property -dict { PACKAGE_PIN C12 IOSTANDARD LVCMOS33 } [get_ports XADC_AUX_v_p   ]
set_property -dict { PACKAGE_PIN K9  IOSTANDARD LVCMOS33 } [get_ports XADC_VP_VN_v_n ]
set_property -dict { PACKAGE_PIN J10 IOSTANDARD LVCMOS33 } [get_ports XADC_VP_VN_v_p ]

################################################################################
#                           PUSH BUTTONS (BTN0-BTN4)
################################################################################
set_property -dict { PACKAGE_PIN R11 IOSTANDARD LVCMOS33 } [get_ports {btn_pin[0]} ]
set_property -dict { PACKAGE_PIN R17 IOSTANDARD LVCMOS33 } [get_ports {btn_pin[1]} ]
set_property -dict { PACKAGE_PIN R15 IOSTANDARD LVCMOS33 } [get_ports {btn_pin[2]} ]
set_property -dict { PACKAGE_PIN V1  IOSTANDARD LVCMOS33 } [get_ports {btn_pin[3]} ]
set_property -dict { PACKAGE_PIN U4  IOSTANDARD LVCMOS33 } [get_ports {btn_pin[4]} ]

################################################################################
#                           7-SEGMENT DISPLAY
################################################################################
set_property -dict { PACKAGE_PIN G2 IOSTANDARD LVCMOS33 } [get_ports {seg_cs[0]} ]
set_property -dict { PACKAGE_PIN C2 IOSTANDARD LVCMOS33 } [get_ports {seg_cs[1]} ]
set_property -dict { PACKAGE_PIN C1 IOSTANDARD LVCMOS33 } [get_ports {seg_cs[2]} ]
set_property -dict { PACKAGE_PIN H1 IOSTANDARD LVCMOS33 } [get_ports {seg_cs[3]} ]
set_property -dict { PACKAGE_PIN G1 IOSTANDARD LVCMOS33 } [get_ports {seg_cs[4]} ]
set_property -dict { PACKAGE_PIN F1 IOSTANDARD LVCMOS33 } [get_ports {seg_cs[5]} ]
set_property -dict { PACKAGE_PIN E1 IOSTANDARD LVCMOS33 } [get_ports {seg_cs[6]} ]
set_property -dict { PACKAGE_PIN G6 IOSTANDARD LVCMOS33 } [get_ports {seg_cs[7]} ]

set_property -dict { PACKAGE_PIN B4 IOSTANDARD LVCMOS33 } [get_ports {seg_data_0[0]} ]
set_property -dict { PACKAGE_PIN A4 IOSTANDARD LVCMOS33 } [get_ports {seg_data_0[1]} ]
set_property -dict { PACKAGE_PIN A3 IOSTANDARD LVCMOS33 } [get_ports {seg_data_0[2]} ]
set_property -dict { PACKAGE_PIN B1 IOSTANDARD LVCMOS33 } [get_ports {seg_data_0[3]} ]
set_property -dict { PACKAGE_PIN A1 IOSTANDARD LVCMOS33 } [get_ports {seg_data_0[4]} ]
set_property -dict { PACKAGE_PIN B3 IOSTANDARD LVCMOS33 } [get_ports {seg_data_0[5]} ]
set_property -dict { PACKAGE_PIN B2 IOSTANDARD LVCMOS33 } [get_ports {seg_data_0[6]} ]
set_property -dict { PACKAGE_PIN D5 IOSTANDARD LVCMOS33 } [get_ports {seg_data_0[7]} ]

set_property -dict { PACKAGE_PIN D4 IOSTANDARD LVCMOS33 } [get_ports {seg_data_1[0]} ]
set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 } [get_ports {seg_data_1[1]} ]
set_property -dict { PACKAGE_PIN D3 IOSTANDARD LVCMOS33 } [get_ports {seg_data_1[2]} ]
set_property -dict { PACKAGE_PIN F4 IOSTANDARD LVCMOS33 } [get_ports {seg_data_1[3]} ]
set_property -dict { PACKAGE_PIN F3 IOSTANDARD LVCMOS33 } [get_ports {seg_data_1[4]} ]
set_property -dict { PACKAGE_PIN E2 IOSTANDARD LVCMOS33 } [get_ports {seg_data_1[5]} ]
set_property -dict { PACKAGE_PIN D2 IOSTANDARD LVCMOS33 } [get_ports {seg_data_1[6]} ]
set_property -dict { PACKAGE_PIN H2 IOSTANDARD LVCMOS33 } [get_ports {seg_data_1[7]} ]

################################################################################
#                           VGA INTERFACE
################################################################################
set_property -dict { PACKAGE_PIN D7 IOSTANDARD LVCMOS33 } [get_ports vga_hs_pin ]
set_property -dict { PACKAGE_PIN C4 IOSTANDARD LVCMOS33 } [get_ports vga_vs_pin ]

set_property -dict { PACKAGE_PIN F5 IOSTANDARD LVCMOS33 } [get_ports {vga_R_Data_pin[0]} ]
set_property -dict { PACKAGE_PIN C6 IOSTANDARD LVCMOS33 } [get_ports {vga_R_Data_pin[1]} ]
set_property -dict { PACKAGE_PIN C5 IOSTANDARD LVCMOS33 } [get_ports {vga_R_Data_pin[2]} ]
set_property -dict { PACKAGE_PIN B7 IOSTANDARD LVCMOS33 } [get_ports {vga_R_Data_pin[3]} ]

set_property -dict { PACKAGE_PIN B6 IOSTANDARD LVCMOS33 } [get_ports {vga_G_Data_pin[0]} ]
set_property -dict { PACKAGE_PIN A6 IOSTANDARD LVCMOS33 } [get_ports {vga_G_Data_pin[1]} ]
set_property -dict { PACKAGE_PIN A5 IOSTANDARD LVCMOS33 } [get_ports {vga_G_Data_pin[2]} ]
set_property -dict { PACKAGE_PIN D8 IOSTANDARD LVCMOS33 } [get_ports {vga_G_Data_pin[3]} ]

set_property -dict { PACKAGE_PIN C7 IOSTANDARD LVCMOS33 } [get_ports {vga_B_Data_pin[0]} ]
set_property -dict { PACKAGE_PIN E6 IOSTANDARD LVCMOS33 } [get_ports {vga_B_Data_pin[1]} ]
set_property -dict { PACKAGE_PIN E5 IOSTANDARD LVCMOS33 } [get_ports {vga_B_Data_pin[2]} ]
set_property -dict { PACKAGE_PIN E7 IOSTANDARD LVCMOS33 } [get_ports {vga_B_Data_pin[3]} ]

################################################################################
#                           KEYPAD & SOUND
################################################################################
set_property -dict { PACKAGE_PIN B16 IOSTANDARD LVCMOS33 } [get_ports {row[0]} ]
set_property -dict { PACKAGE_PIN A15 IOSTANDARD LVCMOS33 } [get_ports {row[1]} ]
set_property -dict { PACKAGE_PIN A13 IOSTANDARD LVCMOS33 } [get_ports {row[2]} ]
set_property -dict { PACKAGE_PIN B18 IOSTANDARD LVCMOS33 } [get_ports {row[3]} ]

set_property -dict { PACKAGE_PIN B17 IOSTANDARD LVCMOS33 } [get_ports {column[0]} ]
set_property -dict { PACKAGE_PIN A16 IOSTANDARD LVCMOS33 } [get_ports {column[1]} ]
set_property -dict { PACKAGE_PIN A14 IOSTANDARD LVCMOS33 } [get_ports {column[2]} ]
set_property -dict { PACKAGE_PIN A18 IOSTANDARD LVCMOS33 } [get_ports {column[3]} ]

set_property -dict { PACKAGE_PIN H17 IOSTANDARD LVCMOS33 } [get_ports sound ]