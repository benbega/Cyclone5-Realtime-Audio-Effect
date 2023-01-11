
#**************************************************************
# Create Clock
#**************************************************************
# FPGA system clocks
create_clock -period "50.0 MHz"  [get_ports fpga_clk1_50]
create_clock -period "50.0 MHz"  [get_ports fpga_clk2_50]
create_clock -period "50.0 MHz"  [get_ports fpga_clk3_50]
create_clock -period "400.0 kHz" [get_ports hps_i2c1_sclk]

# HPS Clocks
create_clock -period "125.0 MHz" [get_ports hps_enet_rx_clk]
create_clock -period "125.0 MHz" [get_ports hps_enet_gtx_clk]
create_clock -period "50.0 MHz"  [get_ports hps_sd_clk]


# AD1939 Clocks
# Note the period of a 12.288 MHz clock is 81.380208333333329
create_clock -period "12.288 MHz" -waveform { 20.345 61.035 } [get_ports ad1939_mclk]
create_clock -period "12.288 MHz" -waveform { 20.345 61.035 } [get_ports ad1939_adc_abclk] 
create_clock -period  "0.192 MHz" [get_ports ad1939_adc_alrclk]
#----------------------------------------------------------------------------------------
# Create a virtual clock for the AD1939 serial data input
# See example 36 in AN 433: Constraining and Analyzing Source-Synchronous Interfaces
# https://www.altera.com/content/dam/altera-www/global/en_US/pdfs/literature/an/an433.pdf
#----------------------------------------------------------------------------------------
create_clock -name virtual_sdata_input_clock  -period "12.288 MHz" 
create_clock -name virtual_sdata_output_clock -period "12.288 MHz" 

# Clocks for enhancing USB BlasterII to be reliable, 25MHz (from Terasic)
create_clock -name {altera_reserved_tck} -period 40 {altera_reserved_tck}
set_input_delay  -clock altera_reserved_tck -clock_fall 3 [get_ports altera_reserved_tdi]
set_input_delay  -clock altera_reserved_tck -clock_fall 3 [get_ports altera_reserved_tms]
set_output_delay -clock altera_reserved_tck 3 [get_ports altera_reserved_tdo]

#**************************************************************
# Derive clocks coming from PLLs 
#**************************************************************
derive_pll_clocks

#**************************************************************
# Rename PLL derived clocks
# To find these clocks names
#       1. Open Timing Analyzer
#       2. Select Task: "Read SDC file"  (Under netlist setup)
#       3. Select Task: "Report Clocks"  (Under \Reports\Diagnostic)
#**************************************************************

set data_plane_clock "u0|ad1939_subsystem|sys_clk_from_ad1939_mclk_pll|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk"

set PLL_internal_clock "u0|ad1939_subsystem|sys_clk_from_ad1939_mclk_pll|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0]"

#**************************************************************
# Set Clock Latency
#**************************************************************

#**************************************************************
# Set Clock Uncertainty
#**************************************************************
derive_clock_uncertainty

#**************************************************************
# Set Clock Groups
# Note: in the Tcl script below, make sure there are no spaces
# after the Tcl escape character "\", otherwise Tcl will escape
# the whitespace and not the end-of-line character and generate
# an error.
#**************************************************************
set_clock_groups -asynchronous \
	-group { 	ad1939_mclk \
				ad1939_adc_abclk \
				ad1939_adc_alrclk \
				u0|ad1939_subsystem|sys_clk_from_ad1939_mclk_pll|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk \
				u0|ad1939_subsystem|sys_clk_from_ad1939_mclk_pll|altera_pll_i|general[0].gpll~FRACTIONAL_PLL|vcoph[0] \
				virtual_sdata_input_clock \
				virtual_sdata_output_clock \
						       } \
						-group { fpga_clk1_50 \
						         fpga_clk2_50 \
									fpga_clk3_50 \
						       } \
						-group { altera_reserved_tck } \
						-group { hps_i2c1_sclk } 

#**************************************************************
# Set Input Delay
#**************************************************************

#**************************************************************
# Input Delay Process:
#   1. Set initial input delay minimum and maximum to 0
#   2. Run timing analysis
#   3. Modify minimum and maximums based on analysis  
#**************************************************************
set maxtime_lrclk_in  0.200
set maxtime_bclk_in   0.200
set maxtime_mclk_in   0.200
set maxtime_sysclk_in 0.300
set maxtime_spiclk_in 0.200
set maxtime_i2cclk_in 0.200
set maxtime_sdclk_in  0.200
set maxtime_eclk_in   0.200

set mintime_lrclk_in  0.200
set mintime_bclk_in   0.900
set mintime_mclk_in   0.200
set mintime_sysclk_in 0.300
set mintime_spiclk_in 0.200
set mintime_i2cclk_in 0.200
set mintime_sdclk_in  0.200
set mintime_eclk_in   0.200

set_input_delay -clock { ad1939_adc_abclk } -min $mintime_bclk_in [get_ports {ad1939_adc_abclk}]
set_input_delay -clock { ad1939_adc_abclk } -max $maxtime_bclk_in [get_ports {ad1939_adc_abclk}]
set_input_delay -clock { ad1939_adc_abclk } -min $mintime_bclk_in [get_ports {ad1939_adc_asdata2}]
set_input_delay -clock { ad1939_adc_abclk } -max $maxtime_bclk_in [get_ports {ad1939_adc_asdata2}]
set_input_delay -clock { ad1939_adc_alrclk } -min $mintime_lrclk_in [get_ports {ad1939_adc_alrclk}]
set_input_delay -clock { ad1939_adc_alrclk } -max $maxtime_lrclk_in [get_ports {ad1939_adc_alrclk}]
set_input_delay -clock { u0|hps|fpga_interfaces|peripheral_spim0|sclk_out } -min $mintime_spiclk_in [get_ports {hps_spim_miso}]
set_input_delay -clock { u0|hps|fpga_interfaces|peripheral_spim0|sclk_out } -max $maxtime_spiclk_in [get_ports {hps_spim_miso}]
set_input_delay -clock { u0|hps|fpga_interfaces|peripheral_spim0|sclk_out } -min $mintime_spiclk_in [get_ports {ad1939_spi_cout}]
set_input_delay -clock { u0|hps|fpga_interfaces|peripheral_spim0|sclk_out } -max $maxtime_spiclk_in [get_ports {ad1939_spi_cout}]
set_input_delay -clock { fpga_clk1_50 } -min $mintime_sysclk_in [get_ports {audio_mini_switches[*]}]
set_input_delay -clock { fpga_clk1_50 } -max $maxtime_sysclk_in [get_ports {audio_mini_switches[*]}]
set_input_delay -clock { fpga_clk1_50 } -min $mintime_sysclk_in [get_ports {key[1]}]
set_input_delay -clock { fpga_clk1_50 } -max $maxtime_sysclk_in [get_ports {key[1]}]
set_input_delay -clock { fpga_clk1_50 } -min $mintime_sysclk_in [get_ports {hps_uart_rx}]
set_input_delay -clock { fpga_clk1_50 } -max $maxtime_sysclk_in [get_ports {hps_uart_rx}]
set_input_delay -clock { u0|hps|fpga_interfaces|peripheral_i2c0|out_clk } -min $mintime_i2cclk_in [get_ports {hps_i2c1_sdat}]
set_input_delay -clock { u0|hps|fpga_interfaces|peripheral_i2c0|out_clk } -max $maxtime_i2cclk_in [get_ports {hps_i2c1_sdat}]
set_input_delay -clock { u0|hps|fpga_interfaces|peripheral_i2c0|out_clk } -min $mintime_i2cclk_in [get_ports {tpa6130_i2c_scl}]
set_input_delay -clock { u0|hps|fpga_interfaces|peripheral_i2c0|out_clk } -max $maxtime_i2cclk_in [get_ports {tpa6130_i2c_scl}]
set_input_delay -clock { u0|hps|fpga_interfaces|peripheral_i2c0|out_clk } -min $mintime_i2cclk_in [get_ports {tpa6130_i2c_sda}]
set_input_delay -clock { u0|hps|fpga_interfaces|peripheral_i2c0|out_clk } -max $maxtime_i2cclk_in [get_ports {tpa6130_i2c_sda}]
set_input_delay -clock { hps_enet_rx_clk } -min $mintime_eclk_in [get_ports {hps_enet_mdio}]
set_input_delay -clock { hps_enet_rx_clk } -max $maxtime_eclk_in [get_ports {hps_enet_mdio}]
set_input_delay -clock { hps_enet_rx_clk } -min $mintime_eclk_in [get_ports {hps_enet_rx_data[*]}]
set_input_delay -clock { hps_enet_rx_clk } -max $maxtime_eclk_in [get_ports {hps_enet_rx_data[*]}]
set_input_delay -clock { hps_enet_rx_clk } -min $mintime_eclk_in [get_ports {hps_enet_rx_dv}]
set_input_delay -clock { hps_enet_rx_clk } -max $maxtime_eclk_in [get_ports {hps_enet_rx_dv}]
set_input_delay -clock { hps_sd_clk } -min $mintime_sdclk_in [get_ports {hps_sd_cmd}]
set_input_delay -clock { hps_sd_clk } -max $maxtime_sdclk_in [get_ports {hps_sd_cmd}]
set_input_delay -clock { hps_sd_clk } -min $mintime_sdclk_in [get_ports {hps_sd_data[*]}]
set_input_delay -clock { hps_sd_clk } -max $maxtime_sdclk_in [get_ports {hps_sd_data[*]}]

#**************************************************************
# Set Output Delay
#**************************************************************
set maxtime_lrclk_out  0.200
set maxtime_bclk_out   0.200
set maxtime_mclk_out   0.200
set maxtime_sysclk_out 0.500
set maxtime_spiclk_out 0.200
set maxtime_i2cclk_out 0.300
set maxtime_sdclk_out  0.200
set maxtime_eclk_out   0.200

set mintime_lrclk_out  0.200
set mintime_bclk_out   0.200
set mintime_mclk_out   0.200
set mintime_sysclk_out 0.200
set mintime_spiclk_out 0.200
set mintime_i2cclk_out 0.300
set mintime_sdclk_out  0.200
set mintime_eclk_out   0.200

set_output_delay -clock { ad1939_adc_abclk } -min $mintime_bclk_out [get_ports {ad1939_dac_dbclk}]
set_output_delay -clock { ad1939_adc_abclk } -max $maxtime_bclk_out [get_ports {ad1939_dac_dbclk}]
set_output_delay -clock { ad1939_adc_abclk } -min $mintime_bclk_out [get_ports {ad1939_dac_dsdata1}]
set_output_delay -clock { ad1939_adc_abclk } -max $maxtime_bclk_out [get_ports {ad1939_dac_dsdata1}]
set_output_delay -clock { ad1939_adc_alrclk } -min $maxtime_lrclk_out [get_ports {ad1939_dac_dlrclk}]
set_output_delay -clock { ad1939_adc_alrclk } -max $mintime_lrclk_out [get_ports {ad1939_dac_dlrclk}]
set_output_delay -clock { u0|hps|fpga_interfaces|peripheral_spim0|sclk_out } -min $mintime_spiclk_out [get_ports {ad1939_spi_cclk}]
set_output_delay -clock { u0|hps|fpga_interfaces|peripheral_spim0|sclk_out } -max $maxtime_spiclk_out [get_ports {ad1939_spi_cclk}]
set_output_delay -clock { u0|hps|fpga_interfaces|peripheral_spim0|sclk_out } -min $mintime_spiclk_out [get_ports {ad1939_spi_cin}]
set_output_delay -clock { u0|hps|fpga_interfaces|peripheral_spim0|sclk_out } -max $maxtime_spiclk_out [get_ports {ad1939_spi_cin}]
set_output_delay -clock { u0|hps|fpga_interfaces|peripheral_spim0|sclk_out } -min $mintime_spiclk_out [get_ports {ad1939_spi_clatch_n}]
set_output_delay -clock { u0|hps|fpga_interfaces|peripheral_spim0|sclk_out } -max $maxtime_spiclk_out [get_ports {ad1939_spi_clatch_n}]
set_output_delay -clock { u0|hps|fpga_interfaces|peripheral_spim0|sclk_out } -min $mintime_spiclk_out [get_ports {hps_spim_mosi}]
set_output_delay -clock { u0|hps|fpga_interfaces|peripheral_spim0|sclk_out } -max $maxtime_spiclk_out [get_ports {hps_spim_mosi}]
set_output_delay -clock { u0|hps|fpga_interfaces|peripheral_spim0|sclk_out } -min $mintime_spiclk_out [get_ports {hps_spim_ss}]
set_output_delay -clock { u0|hps|fpga_interfaces|peripheral_spim0|sclk_out } -max $maxtime_spiclk_out [get_ports {hps_spim_ss}]
set_output_delay -clock { fpga_clk1_50 } -min $mintime_sysclk_out [get_ports {audio_mini_leds[*]}]
set_output_delay -clock { fpga_clk1_50 } -max $maxtime_sysclk_out [get_ports {audio_mini_leds[*]}]
set_output_delay -clock { fpga_clk1_50 } -min $mintime_sysclk_out [get_ports {hps_uart_tx}]
set_output_delay -clock { fpga_clk1_50 } -max $maxtime_sysclk_out [get_ports {hps_uart_tx}]
set_output_delay -clock { hps_enet_rx_clk } -min $mintime_eclk_out [get_ports {hps_enet_gtx_clk}]
set_output_delay -clock { hps_enet_rx_clk } -max $maxtime_eclk_out [get_ports {hps_enet_gtx_clk}]
set_output_delay -clock { hps_enet_rx_clk } -min $mintime_eclk_out [get_ports {hps_enet_mdc}]
set_output_delay -clock { hps_enet_rx_clk } -max $maxtime_eclk_out [get_ports {hps_enet_mdc}]
set_output_delay -clock { hps_enet_rx_clk } -min $mintime_eclk_out [get_ports {hps_enet_tx_data[*]}]
set_output_delay -clock { hps_enet_rx_clk } -max $maxtime_eclk_out [get_ports {hps_enet_tx_data[*]}]
set_output_delay -clock { hps_enet_rx_clk } -min $mintime_eclk_out [get_ports {hps_enet_tx_en}]
set_output_delay -clock { hps_enet_rx_clk } -max $maxtime_eclk_out [get_ports {hps_enet_tx_en}]
set_output_delay -clock { hps_sd_clk } -min $mintime_sdclk_out [get_ports {hps_sd_cmd}]
set_output_delay -clock { hps_sd_clk } -max $maxtime_sdclk_out [get_ports {hps_sd_cmd}]
set_output_delay -clock { hps_sd_clk } -min $mintime_sdclk_out [get_ports {hps_sd_data[*]}]
set_output_delay -clock { hps_sd_clk } -max $maxtime_sdclk_out [get_ports {hps_sd_data[*]}]

#**************************************************************
# Set Ouput Port Path Delays
#**************************************************************
set maxdelays 20
set mindelays 5

set_max_delay -from {soc_system:u0|soc_system_hps:hps|soc_system_hps_hps_io:hps_io|soc_system_hps_hps_io_border:border|intermediate[0]} -to [get_ports {hps_enet_mdio}] $maxdelays
set_max_delay -from {soc_system:u0|soc_system_hps:hps|soc_system_hps_hps_io:hps_io|soc_system_hps_hps_io_border:border|intermediate[1]} -to [get_ports {hps_enet_mdio}] $maxdelays
set_max_delay -from {soc_system:u0|soc_system_hps:hps|soc_system_hps_hps_io:hps_io|soc_system_hps_hps_io_border:border|i2c1_inst~FF_4791} -to [get_ports {hps_i2c1_sdat}] $maxdelays
set_max_delay -from {u0|hps|fpga_interfaces|peripheral_i2c0|out_clk} -to [get_ports {tpa6130_i2c_scl}] $maxdelays
set_max_delay -from {soc_system:u0|soc_system_hps:hps|soc_system_hps_fpga_interfaces:fpga_interfaces|peripheral_i2c0~FF_4791} -to [get_ports {tpa6130_i2c_sda}] $maxdelays

set_min_delay -from {soc_system:u0|soc_system_hps:hps|soc_system_hps_hps_io:hps_io|soc_system_hps_hps_io_border:border|intermediate[0]} -to [get_ports {hps_enet_mdio}] $mindelays
set_min_delay -from {soc_system:u0|soc_system_hps:hps|soc_system_hps_hps_io:hps_io|soc_system_hps_hps_io_border:border|intermediate[1]} -to [get_ports {hps_enet_mdio}] $mindelays
set_min_delay -from {soc_system:u0|soc_system_hps:hps|soc_system_hps_hps_io:hps_io|soc_system_hps_hps_io_border:border|i2c1_inst~FF_4791} -to [get_ports {hps_i2c1_sdat}] $mindelays
set_min_delay -from {u0|hps|fpga_interfaces|peripheral_i2c0|out_clk} -to [get_ports {tpa6130_i2c_scl}] $mindelays
set_min_delay -from {soc_system:u0|soc_system_hps:hps|soc_system_hps_fpga_interfaces:fpga_interfaces|peripheral_i2c0~FF_4791} -to [get_ports {tpa6130_i2c_sda}] $mindelays

#**************************************************************
# Set False Path
#**************************************************************

#set_false_path  -fall_from  [get_clocks {soc_system:u0|soc_system_hps:hps|soc_system_hps_hps_io:hps_io|soc_system_hps_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk_write_clk}]  -to  [get_clocks {HPS_DDR3_CK_P}]
#set_false_path  -from  [get_clocks {soc_system:u0|soc_system_hps:hps|soc_system_hps_hps_io:hps_io|soc_system_hps_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk_write_clk}]  -to  [get_clocks {*_IN}]
#set_false_path  -from  [get_clocks *]  -to  [get_clocks {u0|hps|hps_io|border|hps_sdram_inst|hps_sdram_p0_sampling_clock}]
#set_false_path -from [get_registers {*|alt_jtag_atlantic:*|jupdate}] -to [get_registers {*|alt_jtag_atlantic:*|jupdate1*}]
#set_false_path -from [get_registers {*|alt_jtag_atlantic:*|rdata[*]}] -to [get_registers {*|alt_jtag_atlantic*|td_shift[*]}]
#set_false_path -from [get_registers {*|alt_jtag_atlantic:*|read}] -to [get_registers {*|alt_jtag_atlantic:*|read1*}]
#set_false_path -from [get_registers {*|alt_jtag_atlantic:*|read_req}] 
#set_false_path -from [get_registers {*|alt_jtag_atlantic:*|rvalid}] -to [get_registers {*|alt_jtag_atlantic*|td_shift[*]}]
#set_false_path -from [get_registers {*|t_dav}] -to [get_registers {*|alt_jtag_atlantic:*|tck_t_dav}]
#set_false_path -from [get_registers {*|alt_jtag_atlantic:*|user_saw_rvalid}] -to [get_registers {*|alt_jtag_atlantic:*|rvalid0*}]
#set_false_path -from [get_registers {*|alt_jtag_atlantic:*|wdata[*]}] -to [get_registers *]
#set_false_path -from [get_registers {*|alt_jtag_atlantic:*|write}] -to [get_registers {*|alt_jtag_atlantic:*|write1*}]
#set_false_path -from [get_registers {*|alt_jtag_atlantic:*|write_stalled}] -to [get_registers {*|alt_jtag_atlantic:*|t_ena*}]
#set_false_path -from [get_registers {*|alt_jtag_atlantic:*|write_stalled}] -to [get_registers {*|alt_jtag_atlantic:*|t_pause*}]
#set_false_path -from [get_registers {*|alt_jtag_atlantic:*|write_valid}] 
#set_false_path -to [get_keepers {*altera_std_synchronizer:*|din_s1}]
#set_false_path -to [get_pins -nocase -compatibility_mode {*|alt_rst_sync_uq1|altera_reset_synchronizer_int_chain*|clrn}]
#set_false_path -fall_from [get_clocks {soc_system:u0|soc_system_hps:hps|soc_system_hps_hps_io:hps_io|soc_system_hps_hps_io_border:border|hps_sdram:hps_sdram_inst|hps_sdram_pll:pll|afi_clk_write_clk}] -to [get_ports {{HPS_DDR3_ADDR[0]} {HPS_DDR3_ADDR[10]} {HPS_DDR3_ADDR[11]} {HPS_DDR3_ADDR[12]} {HPS_DDR3_ADDR[13]} {HPS_DDR3_ADDR[14]} {HPS_DDR3_ADDR[1]} {HPS_DDR3_ADDR[2]} {HPS_DDR3_ADDR[3]} {HPS_DDR3_ADDR[4]} {HPS_DDR3_ADDR[5]} {HPS_DDR3_ADDR[6]} {HPS_DDR3_ADDR[7]} {HPS_DDR3_ADDR[8]} {HPS_DDR3_ADDR[9]} {HPS_DDR3_BA[0]} {HPS_DDR3_BA[1]} {HPS_DDR3_BA[2]} HPS_DDR3_CAS_N HPS_DDR3_CKE HPS_DDR3_CS_N HPS_DDR3_ODT HPS_DDR3_RAS_N HPS_DDR3_WE_N}]
#set_false_path -from [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*c0|hmc_inst~FF_*}] -to [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*umemphy|*uio_pads|*uaddr_cmd_pads|*ddio_out*}]
#set_false_path -from [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*umemphy|hphy_inst~FF_*}] -to [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*lfifo~LFIFO_IN_READ_EN_DFF}]
#set_false_path -from [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*c0|hmc_inst~FF_*}] -to [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*lfifo~LFIFO_IN_READ_EN_DFF}]
#set_false_path -from [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*umemphy|hphy_inst~FF_*}] -to [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*vfifo~INC_WR_PTR_DFF}]
#set_false_path -from [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*c0|hmc_inst~FF_*}] -to [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*altdq_dqs2_inst|vfifo~QVLD_IN_DFF}]
#set_false_path -from [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*lfifo~LFIFO_OUT_RDATA_VALID_DFF}] -to [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*umemphy|hphy_inst~FF_*}]
#set_false_path -from [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*umemphy|hphy_inst~FF_*}] -to [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*altdq_dqs2_inst|vfifo~QVLD_IN_DFF}]
#set_false_path -from [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*umemphy|hphy_inst~FF_*}] -to [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*lfifo~RD_LATENCY_DFF*}]
#set_false_path -from [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*umemphy|hphy_inst~FF_*}] -to [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*umemphy|*uio_pads|*uaddr_cmd_pads|*ddio_out*}]
#set_false_path -from [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*umemphy|hphy_inst~FF_*}] -to [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*umemphy|*altdq_dqs2_inst|*output_path_gen[*].ddio_out*}]
#set_false_path -from [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*umemphy|hphy_inst~FF_*}] -to [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*umemphy|*altdq_dqs2_inst|extra_output_pad_gen[*].ddio_out*}]
#set_false_path -from [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*umemphy|hphy_inst~FF_*}] -to [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*umemphy|hphy_inst~FF_*}]
#set_false_path -from [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*c0|hmc_inst~FF_*}] -to [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*umemphy|hphy_inst~FF_*}]
#set_false_path -from [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*umemphy|hphy_inst~FF_*}] -to [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*c0|hmc_inst~FF_*}]
#set_false_path -from [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*umemphy|hphy_inst~FF_*}] -to [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*phase_align_os~DFF*}]
#set_false_path -from [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*altdq_dqs2_inst|*read_fifo~OUTPUT_DFF_*}] -to [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*umemphy|hphy_inst~FF_*}]
#set_false_path -to [get_ports {HPS_DDR3_DQS_N[0]}]
#set_false_path -to [get_ports {HPS_DDR3_DQS_N[1]}]
#set_false_path -to [get_ports {HPS_DDR3_DQS_N[2]}]
#set_false_path -to [get_ports {HPS_DDR3_DQS_N[3]}]
#set_false_path -to [get_ports {HPS_DDR3_CK_P}]
#set_false_path -to [get_ports {HPS_DDR3_CK_N}]
#set_false_path -to [get_ports {HPS_DDR3_RESET_N}]
#set_false_path -from [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*umemphy|hphy_inst~FF_*}] -to [get_clocks {HPS_DDR3_DQS_P[0]_OUT}]
#set_false_path -from [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*umemphy|hphy_inst~FF_*}] -to [get_clocks {HPS_DDR3_DQS_P[1]_OUT}]
#set_false_path -from [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*umemphy|hphy_inst~FF_*}] -to [get_clocks {HPS_DDR3_DQS_P[2]_OUT}]
#set_false_path -from [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*umemphy|hphy_inst~FF_*}] -to [get_clocks {HPS_DDR3_DQS_P[3]_OUT}]
#set_false_path -from [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*altdq_dqs2_inst|dqs_enable_ctrl~*}] -to [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*altdq_dqs2_inst|dqs_delay_chain~POSTAMBLE_DFF}]
#set_false_path -from [get_registers {*altera_jtag_src_crosser:*|sink_data_buffer*}] -to [get_registers {*altera_jtag_src_crosser:*|src_data*}]

#**************************************************************
# Set Multicycle Path
#**************************************************************

#**************************************************************
# Multicycles define the launch and latch edges for setup and hold analysis 
#**************************************************************
#  - Best Practices for the Quartus II TimeQuest Timing Analyzer 7-20

set soc_setup 1
set soc_hold 1
set_multicycle_path -from {soc_system:u0|soc_system_hps:hps|soc_system_hps_fpga_interfaces:fpga_interfaces|hps2fpga_light_weight~FF_*} -to {soc_system:u0|soc_system_mm_interconnect_1:mm_interconnect_1|altera_merlin_*} -hold $soc_hold
set_multicycle_path -from {soc_system:u0|soc_system_hps:hps|soc_system_hps_fpga_interfaces:fpga_interfaces|hps2fpga_light_weight~FF_*} -to {soc_system:u0|soc_system_mm_interconnect_1:mm_interconnect_1|altera_merlin_*} -setup $soc_setup

# set_multicycle_path -from {soc_system:u0|soc_system_hps:hps|soc_system_hps_fpga_interfaces:fpga_interfaces|hps2fpga_light_weight~FF_*} -to {soc_system:u0|soc_system_mm_interconnect_1:mm_interconnect_1|altera_merlin_traffic_limiter:hps_h2f_lw_axi_master_rd_limiter|last_channel[*]} -hold 1
# set_multicycle_path -from {soc_system:u0|soc_system_hps:hps|soc_system_hps_fpga_interfaces:fpga_interfaces|hps2fpga_light_weight~FF_*} -to {soc_system:u0|soc_system_mm_interconnect_1:mm_interconnect_1|altera_merlin_burst_adapter:jtag_uart_avalon_jtag_slave_burst_adapter|altera_merlin_burst_adapter_13_1:altera_merlin_burst_adapter_13_1.burst_adapter|in_size_reg[*]} -hold  1
# set_multicycle_path -from {soc_system:u0|soc_system_hps:hps|soc_system_hps_fpga_interfaces:fpga_interfaces|hps2fpga_light_weight~FF_*} -to {soc_system:u0|soc_system_mm_interconnect_1:mm_interconnect_1|altera_merlin_burst_adapter:jtag_uart_avalon_jtag_slave_burst_adapter|altera_merlin_burst_adapter_13_1:altera_merlin_burst_adapter_13_1.burst_adapter|in_size_reg[*]} -setup  1
# set_multicycle_path -from {soc_system:u0|soc_system_hps:hps|soc_system_hps_fpga_interfaces:fpga_interfaces|hps2fpga_light_weight~FF_*} -to {soc_system:u0|soc_system_mm_interconnect_1:mm_interconnect_1|altera_merlin_burst_adapter:jtag_uart_avalon_jtag_slave_burst_adapter|altera_merlin_burst_adapter_13_1:altera_merlin_burst_adapter_13_1.burst_adapter|in_byteen_reg[*]} -hold  $soc_hold
# set_multicycle_path -from {soc_system:u0|soc_system_hps:hps|soc_system_hps_fpga_interfaces:fpga_interfaces|hps2fpga_light_weight~FF_*} -to {soc_system:u0|soc_system_mm_interconnect_1:mm_interconnect_1|altera_merlin_burst_adapter:jtag_uart_avalon_jtag_slave_burst_adapter|altera_merlin_burst_adapter_13_1:altera_merlin_burst_adapter_13_1.burst_adapter|in_byteen_reg[*]} -setup $soc_setup
# set_multicycle_path -from {soc_system:u0|soc_system_hps:hps|soc_system_hps_fpga_interfaces:fpga_interfaces|hps2fpga_light_weight~FF_*} -to {soc_system:u0|soc_system_mm_interconnect_1:mm_interconnect_1|altera_merlin_burst_adapter:jtag_uart_avalon_jtag_slave_burst_adapter|altera_merlin_burst_adapter_13_1:altera_merlin_burst_adapter_13_1.burst_adapter|in_data_reg[*]} -hold $soc_hold 
# set_multicycle_path -from {soc_system:u0|soc_system_hps:hps|soc_system_hps_fpga_interfaces:fpga_interfaces|hps2fpga_light_weight~FF_*} -to {soc_system:u0|soc_system_mm_interconnect_1:mm_interconnect_1|altera_merlin_burst_adapter:jtag_uart_avalon_jtag_slave_burst_adapter|altera_merlin_burst_adapter_13_1:altera_merlin_burst_adapter_13_1.burst_adapter|in_data_reg[*]} -setup $soc_setup
# set_multicycle_path -from {soc_system:u0|soc_system_hps:hps|soc_system_hps_fpga_interfaces:fpga_interfaces|hps2fpga_light_weight~FF_*} -to {soc_system:u0|soc_system_mm_interconnect_1:mm_interconnect_1|altera_merlin_axi_master_ni:hps_h2f_lw_axi_master_agent|altera_merlin_address_alignment:align_address_to_size|address_burst[*]} -hold $soc_hold
# set_multicycle_path -from {soc_system:u0|soc_system_hps:hps|soc_system_hps_fpga_interfaces:fpga_interfaces|hps2fpga_light_weight~FF_*} -to {soc_system:u0|soc_system_mm_interconnect_1:mm_interconnect_1|altera_merlin_axi_master_ni:hps_h2f_lw_axi_master_agent|altera_merlin_address_alignment:align_address_to_size|address_burst[*]} -setup $soc_setup

set_multicycle_path -setup -from [get_clocks {ad1939_adc_alrclk}]  -to  [get_clocks {u0|ad1939_subsystem|sys_clk_from_ad1939_mclk_pll|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] 2
set_multicycle_path -hold -from [get_clocks {ad1939_adc_alrclk}]  -to  [get_clocks {u0|ad1939_subsystem|sys_clk_from_ad1939_mclk_pll|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk}] 2

# set_multicycle_path -from [get_clocks {FPGA_CLK1_50}] -to [get_clocks {FPGA_CLK1_50}] -setup 2
# set_multicycle_path -from [get_clocks {FPGA_CLK1_50}] -to [get_clocks {FPGA_CLK1_50}] -hold 1

# set_multicycle_path -setup -from {soc_system:u0|soc_system_hps:hps|soc_system_hps_fpga_interfaces:fpga_interfaces|hps2fpga_light_weight~FF_1556} -to {soc_system:u0|soc_system_mm_interconnect_1:mm_interconnect_1|altera_merlin_axi_master_ni:hps_h2f_lw_axi_master_agent|altera_merlin_address_alignment:align_address_to_size|address_burst[*]} 2
# set_multicycle_path -hold -from {soc_system:u0|soc_system_hps:hps|soc_system_hps_fpga_interfaces:fpga_interfaces|hps2fpga_light_weight~FF_1556} -to {soc_system:u0|soc_system_mm_interconnect_1:mm_interconnect_1|altera_merlin_axi_master_ni:hps_h2f_lw_axi_master_agent|altera_merlin_address_alignment:align_address_to_size|address_burst[*]} 1

#set_multicycle_path -setup -to [get_ports AD1939_ADC_ALRCLK] -from [get_ports FPGA_CLK1_50] 4
#set_multicycle_path -hold -to [get_ports AD1939_ADC_ALRCLK] -from [get_ports FPGA_CLK1_50] 3

#set_multicycle_path -setup -end -from  [get_clocks {u0|hps|hps_io|border|hps_sdram_inst|hps_sdram_p0_sampling_clock}]  -to  [get_clocks *] 2
#set_multicycle_path -hold -end -from  [get_clocks {u0|hps|hps_io|border|hps_sdram_inst|hps_sdram_p0_sampling_clock}]  -to  [get_clocks *] 2
#set_multicycle_path -setup -end -to [get_registers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*umemphy|*uio_pads|*uaddr_cmd_pads|*clock_gen[*].umem_ck_pad|*}] 4
#set_multicycle_path -hold -end -to [get_registers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*umemphy|*uio_pads|*uaddr_cmd_pads|*clock_gen[*].umem_ck_pad|*}] 4
#set_multicycle_path -setup -end -from [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*umemphy|hphy_inst~FF_*}] -to [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*lfifo~LFIFO_IN_READ_EN_FULL_DFF}] 2
#set_multicycle_path -hold -end -from [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*umemphy|hphy_inst~FF_*}] -to [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*lfifo~LFIFO_IN_READ_EN_FULL_DFF}] 1
#set_multicycle_path -setup -end -from [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*umemphy|hphy_inst~FF_*}] -to [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*altdq_dqs2_inst|*read_fifo~READ_ADDRESS_DFF}] 2
#set_multicycle_path -hold -end -from [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*umemphy|hphy_inst~FF_*}] -to [get_keepers {*:u0|*:hps|*:hps_io|*:border|*:hps_sdram_inst|*p0|*altdq_dqs2_inst|*read_fifo~READ_ADDRESS_DFF}] 1

#**************************************************************
# Set Maximum Delay
#**************************************************************



#**************************************************************
# Set Minimum Delay
#**************************************************************



#**************************************************************
# Set Input Transition
#**************************************************************



#**************************************************************
# Set Load
#**************************************************************



