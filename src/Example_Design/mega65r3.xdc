# Signal mapping for MEGA65 platform revision 3
#
# Created by Michael Jørgensen in 2022 (mjoergen.github.io/HyperRAM).


#############################################################################################################
# Pin locations and I/O standards
#############################################################################################################

## External clock signal (connected to 100 MHz oscillator)
set_property -dict {PACKAGE_PIN V13  IOSTANDARD LVCMOS33}                                    [get_ports {sys_clk_i}]

## Reset signal (Active low. From MAX10)
set_property -dict {PACKAGE_PIN M13  IOSTANDARD LVCMOS33}                                    [get_ports {sys_rstn_i}]

## HyperRAM (connected to IS66WVH8M8BLL-100B1LI, 64 Mbit, 100 MHz, 3.0 V, single-ended clock).
## SLEW and DRIVE set to maximum performance to reduce rise and fall times, and therefore
## give better timing margins.
set_property -dict {PACKAGE_PIN B22  IOSTANDARD LVCMOS33  PULLTYPE {}                          } [get_ports {hr_resetn_o}]
set_property -dict {PACKAGE_PIN C22  IOSTANDARD LVCMOS33  PULLTYPE {}                          } [get_ports {hr_csn_o}]
set_property -dict {PACKAGE_PIN D22  IOSTANDARD LVCMOS33  PULLTYPE {}       SLEW FAST  DRIVE 16} [get_ports {hr_ck_o}]
set_property -dict {PACKAGE_PIN B21  IOSTANDARD LVCMOS33  PULLTYPE PULLDOWN SLEW FAST  DRIVE 16} [get_ports {hr_rwds_io}]
set_property -dict {PACKAGE_PIN A21  IOSTANDARD LVCMOS33  PULLTYPE {}       SLEW FAST  DRIVE 16} [get_ports {hr_dq_io[0]}]
set_property -dict {PACKAGE_PIN D21  IOSTANDARD LVCMOS33  PULLTYPE {}       SLEW FAST  DRIVE 16} [get_ports {hr_dq_io[1]}]
set_property -dict {PACKAGE_PIN C20  IOSTANDARD LVCMOS33  PULLTYPE {}       SLEW FAST  DRIVE 16} [get_ports {hr_dq_io[2]}]
set_property -dict {PACKAGE_PIN A20  IOSTANDARD LVCMOS33  PULLTYPE {}       SLEW FAST  DRIVE 16} [get_ports {hr_dq_io[3]}]
set_property -dict {PACKAGE_PIN B20  IOSTANDARD LVCMOS33  PULLTYPE {}       SLEW FAST  DRIVE 16} [get_ports {hr_dq_io[4]}]
set_property -dict {PACKAGE_PIN A19  IOSTANDARD LVCMOS33  PULLTYPE {}       SLEW FAST  DRIVE 16} [get_ports {hr_dq_io[5]}]
set_property -dict {PACKAGE_PIN E21  IOSTANDARD LVCMOS33  PULLTYPE {}       SLEW FAST  DRIVE 16} [get_ports {hr_dq_io[6]}]
set_property -dict {PACKAGE_PIN E22  IOSTANDARD LVCMOS33  PULLTYPE {}       SLEW FAST  DRIVE 16} [get_ports {hr_dq_io[7]}]

# USB-RS232 Interface
set_property -dict {PACKAGE_PIN L14  IOSTANDARD LVCMOS33} [get_ports {uart_rx_i}];              # DBG_UART_RX
set_property -dict {PACKAGE_PIN L13  IOSTANDARD LVCMOS33} [get_ports {uart_tx_o}];              # DBG_UART_TX

# VGA via VDAC. U3 = ADV7125BCPZ170
set_property -dict {PACKAGE_PIN W11  IOSTANDARD LVCMOS33} [get_ports {vdac_blank_n_o}];         # VDAC_BLANK_N
set_property -dict {PACKAGE_PIN AA9  IOSTANDARD LVCMOS33} [get_ports {vdac_clk_o}];             # VDAC_CLK
set_property -dict {PACKAGE_PIN W16  IOSTANDARD LVCMOS33} [get_ports {vdac_psave_n_o}];         # VDAC_PSAVE_N
set_property -dict {PACKAGE_PIN V10  IOSTANDARD LVCMOS33} [get_ports {vdac_sync_n_o}];          # VDAC_SYNC_N
set_property -dict {PACKAGE_PIN W10  IOSTANDARD LVCMOS33} [get_ports {vga_blue_o[0]}];          # B0
set_property -dict {PACKAGE_PIN Y12  IOSTANDARD LVCMOS33} [get_ports {vga_blue_o[1]}];          # B1
set_property -dict {PACKAGE_PIN AB12 IOSTANDARD LVCMOS33} [get_ports {vga_blue_o[2]}];          # B2
set_property -dict {PACKAGE_PIN AA11 IOSTANDARD LVCMOS33} [get_ports {vga_blue_o[3]}];          # B3
set_property -dict {PACKAGE_PIN AB11 IOSTANDARD LVCMOS33} [get_ports {vga_blue_o[4]}];          # B4
set_property -dict {PACKAGE_PIN Y11  IOSTANDARD LVCMOS33} [get_ports {vga_blue_o[5]}];          # B5
set_property -dict {PACKAGE_PIN AB10 IOSTANDARD LVCMOS33} [get_ports {vga_blue_o[6]}];          # B6
set_property -dict {PACKAGE_PIN AA10 IOSTANDARD LVCMOS33} [get_ports {vga_blue_o[7]}];          # B7
set_property -dict {PACKAGE_PIN Y14  IOSTANDARD LVCMOS33} [get_ports {vga_green_o[0]}];         # G0
set_property -dict {PACKAGE_PIN W14  IOSTANDARD LVCMOS33} [get_ports {vga_green_o[1]}];         # G1
set_property -dict {PACKAGE_PIN AA15 IOSTANDARD LVCMOS33} [get_ports {vga_green_o[2]}];         # G2
set_property -dict {PACKAGE_PIN AB15 IOSTANDARD LVCMOS33} [get_ports {vga_green_o[3]}];         # G3
set_property -dict {PACKAGE_PIN Y13  IOSTANDARD LVCMOS33} [get_ports {vga_green_o[4]}];         # G4
set_property -dict {PACKAGE_PIN AA14 IOSTANDARD LVCMOS33} [get_ports {vga_green_o[5]}];         # G5
set_property -dict {PACKAGE_PIN AA13 IOSTANDARD LVCMOS33} [get_ports {vga_green_o[6]}];         # G6
set_property -dict {PACKAGE_PIN AB13 IOSTANDARD LVCMOS33} [get_ports {vga_green_o[7]}];         # G7
set_property -dict {PACKAGE_PIN W12  IOSTANDARD LVCMOS33} [get_ports {vga_hs_o}];               # HSYNC
set_property -dict {PACKAGE_PIN U15  IOSTANDARD LVCMOS33} [get_ports {vga_red_o[0]}];           # R0
set_property -dict {PACKAGE_PIN V15  IOSTANDARD LVCMOS33} [get_ports {vga_red_o[1]}];           # R1
set_property -dict {PACKAGE_PIN T14  IOSTANDARD LVCMOS33} [get_ports {vga_red_o[2]}];           # R2
set_property -dict {PACKAGE_PIN Y17  IOSTANDARD LVCMOS33} [get_ports {vga_red_o[3]}];           # R3
set_property -dict {PACKAGE_PIN Y16  IOSTANDARD LVCMOS33} [get_ports {vga_red_o[4]}];           # R4
set_property -dict {PACKAGE_PIN AB17 IOSTANDARD LVCMOS33} [get_ports {vga_red_o[5]}];           # R5
set_property -dict {PACKAGE_PIN AA16 IOSTANDARD LVCMOS33} [get_ports {vga_red_o[6]}];           # R6
set_property -dict {PACKAGE_PIN AB16 IOSTANDARD LVCMOS33} [get_ports {vga_red_o[7]}];           # R7
set_property -dict {PACKAGE_PIN V14  IOSTANDARD LVCMOS33} [get_ports {vga_vs_o}];               # VSYNC

# HDMI output
set_property -dict {PACKAGE_PIN Y1   IOSTANDARD TMDS_33}  [get_ports {hdmi_clk_n_o}]
set_property -dict {PACKAGE_PIN W1   IOSTANDARD TMDS_33}  [get_ports {hdmi_clk_p_o}]
set_property -dict {PACKAGE_PIN AB1  IOSTANDARD TMDS_33}  [get_ports {hdmi_data_n_o[0]}]
set_property -dict {PACKAGE_PIN AA1  IOSTANDARD TMDS_33}  [get_ports {hdmi_data_p_o[0]}]
set_property -dict {PACKAGE_PIN AB2  IOSTANDARD TMDS_33}  [get_ports {hdmi_data_n_o[1]}]
set_property -dict {PACKAGE_PIN AB3  IOSTANDARD TMDS_33}  [get_ports {hdmi_data_p_o[1]}]
set_property -dict {PACKAGE_PIN AB5  IOSTANDARD TMDS_33}  [get_ports {hdmi_data_n_o[2]}]
set_property -dict {PACKAGE_PIN AA5  IOSTANDARD TMDS_33}  [get_ports {hdmi_data_p_o[2]}]

## Keyboard interface (connected to MAX10)
set_property -dict {PACKAGE_PIN A14  IOSTANDARD LVCMOS33} [get_ports {kb_io0_o}];               # KB_IO1
set_property -dict {PACKAGE_PIN A13  IOSTANDARD LVCMOS33} [get_ports {kb_io1_o}];               # KB_IO2
set_property -dict {PACKAGE_PIN C13  IOSTANDARD LVCMOS33} [get_ports {kb_io2_i}];               # KB_IO3


############################################################################################################
# Clocks
############################################################################################################

## System board clock (100 MHz)
create_clock -period 10.000 -name sys_clk [get_ports {sys_clk_i}]

## Name Autogenerated Clocks
create_generated_clock -name ctrl_clk  [get_pins mega65_wrapper_inst/clk_inst/plle2_base_inst/CLKOUT0];      # 100.00 MHz
create_generated_clock -name video_clk [get_pins mega65_wrapper_inst/clk_inst/mmcme2_base_inst/CLKOUT0];     #  74.25 MHz
create_generated_clock -name hdmi_clk  [get_pins mega65_wrapper_inst/clk_inst/mmcme2_base_inst/CLKOUT1];     # 371.25 MHz

########### HyperRAM timing #################
# Rename autogenerated clocks
create_generated_clock -name delay_refclk [get_pins clk_controller_inst/i_clk_hyperram/CLKOUT1]
create_generated_clock -name hr_clk_del   [get_pins clk_controller_inst/i_clk_hyperram/CLKOUT2]
create_generated_clock -name hr_clk       [get_pins clk_controller_inst/i_clk_hyperram/CLKOUT3]

# HyperRAM output clock relative to delayed clock
create_generated_clock -name hr_ck         [get_ports hr_ck_o] \
   -source [get_pins clk_controller_inst/i_clk_hyperram/CLKOUT2] -multiply_by 1

# HyperRAM RWDS as a clock for the read path (hr_dq -> IDDR -> CDC)
create_clock -period 10.000 -name hr_rwds -waveform {2.5 7.5} [get_ports hr_rwds_io]

# Asynchronous clocks
set_false_path -from [get_ports hr_rwds_io] -to [get_clocks hr_ck]

# Clock Domain Crossing
set_max_delay 2 -datapath_only -from [get_cells core_wrapper_inst/hyperram_inst/hyperram_ctrl_inst/hb_read_o_reg]
set_max_delay 2 -datapath_only -from [get_cells core_wrapper_inst/hyperram_inst/hyperram_rx_inst/iddr_dq_gen[*].iddr_dq_inst]

# Prevent insertion of extra BUFG
set_property CLOCK_BUFFER_TYPE NONE [get_nets -of [get_pins core_wrapper_inst/hyperram_inst/hyperram_rx_inst/delay_rwds_inst/DATAOUT]]

# Receive FIFO: There is a CDC in the LUTRAM.
# There is approx 1.1 ns Clock->Data delay for the LUTRAM itself, plus 0.5 ns routing delay to the capture flip-flop.
set_max_delay 2 -datapath_only -from [get_clocks hr_rwds] -to [get_clocks hr_clk]

################################################################################
# HyperRAM timing (correct for IS66WVH8M8DBLL-100B1LI)

set tCKHP    5.0 ; # Clock Half Period
set HR_tIS   1.0 ; # input setup time
set HR_tIH   1.0 ; # input hold time
set tDSSmax  0.8 ; # RWDS to data valid, max
set tDSHmin -0.8 ; # RWDS to data invalid, min

################################################################################
# FPGA to HyperRAM (address and write data)

set_property IOB TRUE [get_cells core_wrapper_inst/hyperram_inst/hyperram_tx_inst/hr_rwds_oe_n_reg ]
set_property IOB TRUE [get_cells core_wrapper_inst/hyperram_inst/hyperram_tx_inst/hr_dq_oe_n_reg[*] ]
set_property IOB TRUE [get_cells core_wrapper_inst/hyperram_inst/hyperram_ctrl_inst/hb_csn_o_reg ]
set_property IOB TRUE [get_cells core_wrapper_inst/hyperram_inst/hyperram_ctrl_inst/hb_rstn_o_reg ]

# setup
set_output_delay -max  $HR_tIS -clock hr_ck [get_ports {hr_resetn_o hr_csn_o hr_rwds_io hr_dq_io[*]}]
set_output_delay -max  $HR_tIS -clock hr_ck [get_ports {hr_resetn_o hr_csn_o hr_rwds_io hr_dq_io[*]}] -clock_fall -add_delay

# hold
set_output_delay -min -$HR_tIH -clock hr_ck [get_ports {hr_resetn_o hr_csn_o hr_rwds_io hr_dq_io[*]}]
set_output_delay -min -$HR_tIH -clock hr_ck [get_ports {hr_resetn_o hr_csn_o hr_rwds_io hr_dq_io[*]}] -clock_fall -add_delay

################################################################################
# HyperRAM to FPGA (read data, clocked in by RWDS)
# edge aligned, so pretend that data is launched by previous edge

# setup
set_input_delay -max [expr $tCKHP + $tDSSmax] -clock hr_rwds [get_ports hr_dq_io[*]]
set_input_delay -max [expr $tCKHP + $tDSSmax] -clock hr_rwds [get_ports hr_dq_io[*]] -clock_fall -add_delay

# hold
set_input_delay -min [expr $tCKHP + $tDSHmin] -clock hr_rwds [get_ports hr_dq_io[*]]
set_input_delay -min [expr $tCKHP + $tDSHmin] -clock hr_rwds [get_ports hr_dq_io[*]] -clock_fall -add_delay


########### MEGA65 timing ################
# MEGA65 I/O timing is ignored (considered asynchronous)
set_false_path   -to [get_ports hdmi_data_p_o[*]]
set_false_path   -to [get_ports hdmi_clk_p_o]
set_false_path   -to [get_ports kb_io0_o]
set_false_path   -to [get_ports kb_io1_o]
set_false_path -from [get_ports kb_io2_i]


#############################################################################################################
# Configuration and Bitstream properties
#############################################################################################################

set_property CONFIG_VOLTAGE                  3.3   [current_design]
set_property CFGBVS                          VCCO  [current_design]
set_property BITSTREAM.GENERAL.COMPRESS      TRUE  [current_design]
set_property BITSTREAM.CONFIG.CONFIGRATE     66    [current_design]
set_property CONFIG_MODE                     SPIx4 [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR YES   [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH   4     [current_design]

