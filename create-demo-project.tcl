set _xil_proj_name_ "vivado-zcu102-prism-sp-openhw-demo"
set part "xczu9eg-ffvb1156-2-e"
set ip_repo_base_path "$::env(IP_REPO_BASE_PATH)"
set proj_path "./${_xil_proj_name_}"

start_gui

create_project -part ${part} ${_xil_proj_name_} ${proj_path}

# Set some essential properties.
set_property -name "board_part" -value "xilinx.com:zcu102:part0:3.4" -objects [current_project]
set_property -name "xpm_libraries" -value "XPM_FIFO XPM_MEMORY" -objects [current_project]
set_property -name "platform.board_id" -value "zcu102" -objects [current_project]

# Set the IP repository path of the Prism SP IP core.
set_property "ip_repo_paths" [file normalize "${ip_repo_base_path}/prism_sp_openhw"] [current_project]
update_ip_catalog -rebuild

# Create the block design.
create_bd_design "design_1"

# Make the wrapper (automatically updated by Vivado).
make_wrapper -files [get_files "${proj_path}/${_xil_proj_name_}.srcs/sources_1/bd/design_1/design_1.bd"] -top
# Add the wrapper.
add_files -norecurse "${proj_path}/${_xil_proj_name_}.gen/sources_1/bd/design_1/hdl/design_1_wrapper.v"
# Set the wrapper to be the top-level module.
set_property -name "top" -value "design_1_wrapper" -objects [current_fileset]

set zynq_ultra_ps_e_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.5 zynq_ultra_ps_e_0 ]
apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e -config {apply_board_preset "1" }  [get_bd_cells zynq_ultra_ps_e_0]
set prism_sp_openhw_gem3 [ create_bd_cell -type ip -vlnv drehmel.com:user:prism_sp_openhw:1.0 prism_sp_openhw_gem3 ]
set_property -dict [ list \
	CONFIG.C_M_AXI_DMA_DATA_WIDTH {128} \
] $prism_sp_openhw_gem3

set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]
set proc_sys_reset_gem3_tx [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_gem3_tx ]
set proc_sys_reset_gem3_rx [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_gem3_rx ]
set axi_uartlite_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_uartlite:2.0 axi_uartlite_0 ]

set_property -dict [ list \
	CONFIG.C_BAUDRATE {115200}  \
	CONFIG.UARTLITE_BOARD_INTERFACE {uart2_pl} \
] $axi_uartlite_0

apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {uart2_pl ( UART ) } Manual_Source {Auto}} [get_bd_intf_pins axi_uartlite_0/UART]

# We add a Smartconnect IP for the AXI-Lite interfaces of the SP.
set smartconnect_sp_axil [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_sp_axil ]
set_property -dict [ list \
	CONFIG.NUM_MI {2} \
	CONFIG.NUM_SI {1} \
] $smartconnect_sp_axil

# We add a Smartconnect IP for the ACP interfaces of the SP.
set smartconnect_sp_acp [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_sp_acp ]
set_property -dict [ list \
	CONFIG.NUM_MI {1} \
	CONFIG.NUM_SI {2} \
] $smartconnect_sp_acp

# We add a Smartconnect IP for the I/O interfaces of the SP.
set smartconnect_sp_io [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_sp_io ]
set_property -dict [ list \
	CONFIG.NUM_MI {2} \
	CONFIG.NUM_SI {2} \
] $smartconnect_sp_io

set xlconcat_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0 ]
set_property CONFIG.NUM_PORTS {3} $xlconcat_0

# We add a constant zero to keep pl_acpinact low.
set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
set_property CONFIG.CONST_VAL {0} $xlconstant_0

# S_AXI_GP0 is HPC0
# S_AXI_GP2 is HP0
# M_AXI_GP0 is HPM0
set_property -dict [ list \
	CONFIG.PSU__CRL_APB__PL0_REF_CTRL__FREQMHZ {300} \
	CONFIG.PSU__ENET3__FIFO__ENABLE {1} \
	CONFIG.PSU__EXPAND__LOWER_LPS_SLAVES {1} \
	CONFIG.PSU__EXPAND__UPPER_LPS_SLAVES {1} \
	CONFIG.PSU__IRQ_P2F_ENT3__INT {1} \
	CONFIG.PSU__PROTECTION__MASTERS {USB1:NonSecure;0|USB0:NonSecure;1|S_AXI_LPD:NA;0|S_AXI_HPC1_FPD:NA;0|S_AXI_HPC0_FPD:NA;0|S_AXI_HP3_FPD:NA;0|S_AXI_HP2_FPD:NA;0|S_AXI_HP1_FPD:NA;0|S_AXI_HP0_FPD:NA;1|S_AXI_ACP:NA;0|S_AXI_ACE:NA;0|SD1:NonSecure;1|SD0:NonSecure;0|SATA1:NonSecure;1|SATA0:NonSecure;1|RPU1:Secure;1|RPU0:Secure;1|QSPI:NonSecure;1|PMU:NA;1|PCIe:NonSecure;1|NAND:NonSecure;0|LDMA:NonSecure;1|GPU:NonSecure;1|GEM3:NonSecure;1|GEM2:NonSecure;0|GEM1:NonSecure;0|GEM0:NonSecure;0|FDMA:NonSecure;1|DP:NonSecure;1|DAP:NA;1|Coresight:NA;1|CSU:NA;1|APU:NA;1} \
	CONFIG.PSU__SAXIGP0__DATA_WIDTH {128} \
	CONFIG.PSU__SAXIGP2__DATA_WIDTH {128} \
	CONFIG.PSU__MAXIGP0__DATA_WIDTH {128} \
	CONFIG.PSU__USE__S_AXI_GP0 {1} \
	CONFIG.PSU__USE__S_AXI_GP1 {0} \
	CONFIG.PSU__USE__S_AXI_GP2 {1} \
	CONFIG.PSU__USE__M_AXI_GP0 {1} \
	CONFIG.PSU__USE__M_AXI_GP1 {0} \
  	CONFIG.PSU__USE__S_AXI_ACP {1} \
] $zynq_ultra_ps_e_0

# Connect the GEM external FIFO interface.
connect_bd_intf_net [get_bd_intf_pins zynq_ultra_ps_e_0/FIFO_ENET3] [get_bd_intf_pins prism_sp_openhw_gem3/gem]

# Connect the UARTLITE
connect_bd_intf_net [get_bd_intf_pins smartconnect_sp_io/M01_AXI] [get_bd_intf_pins axi_uartlite_0/S_AXI]

# Connect the AXI-Lite Smartconnect
connect_bd_intf_net [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM0_FPD] [get_bd_intf_pins smartconnect_sp_axil/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins smartconnect_sp_axil/M00_AXI] [get_bd_intf_pins prism_sp_openhw_gem3/s_axil_0]
connect_bd_intf_net [get_bd_intf_pins smartconnect_sp_axil/M01_AXI] [get_bd_intf_pins prism_sp_openhw_gem3/s_axil_1]

# Connect the ACP Smartconnect
connect_bd_intf_net [get_bd_intf_pins smartconnect_sp_acp/M00_AXI] [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_ACP_FPD]
connect_bd_intf_net [get_bd_intf_pins prism_sp_openhw_gem3/m_axi_acp_0] [get_bd_intf_pins smartconnect_sp_acp/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins prism_sp_openhw_gem3/m_axi_acp_1] [get_bd_intf_pins smartconnect_sp_acp/S01_AXI]

# Connect the SP's DMA interface
connect_bd_intf_net [get_bd_intf_pins prism_sp_openhw_gem3/m_axi_dma] [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HPC0_FPD]

# Connect the I/O Smartconnect
connect_bd_intf_net [get_bd_intf_pins smartconnect_sp_io/M00_AXI] [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP0_FPD]
connect_bd_intf_net [get_bd_intf_pins prism_sp_openhw_gem3/m_axi_io_0] [get_bd_intf_pins smartconnect_sp_io/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins prism_sp_openhw_gem3/m_axi_io_1] [get_bd_intf_pins smartconnect_sp_io/S01_AXI]

# Connect the IRQ lines of the SP
connect_bd_net [get_bd_pins prism_sp_openhw_gem3/gem_irq] [get_bd_pins xlconcat_0/In0]
connect_bd_net [get_bd_pins prism_sp_openhw_gem3/gem_irq_tx] [get_bd_pins xlconcat_0/In1]
connect_bd_net [get_bd_pins prism_sp_openhw_gem3/gem_irq_rx] [get_bd_pins xlconcat_0/In2]
connect_bd_net [get_bd_pins xlconcat_0/dout] [get_bd_pins zynq_ultra_ps_e_0/pl_ps_irq0]

# Connect the constant to the pl_acpinact port.
connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins zynq_ultra_ps_e_0/pl_acpinact]

# Connect the RX reset.
connect_bd_net [get_bd_pins proc_sys_reset_gem3_rx/peripheral_aresetn] [get_bd_pins prism_sp_openhw_gem3/gem_rx_resetn]
connect_bd_net [get_bd_pins proc_sys_reset_gem3_tx/peripheral_aresetn] [get_bd_pins prism_sp_openhw_gem3/gem_tx_resetn]

connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/fmio_gem3_fifo_rx_clk_to_pl_bufg] \
	[get_bd_pins prism_sp_openhw_gem3/gem_rx_clock] \
	[get_bd_pins proc_sys_reset_gem3_rx/slowest_sync_clk]

connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/fmio_gem3_fifo_tx_clk_to_pl_bufg] \
	[get_bd_pins prism_sp_openhw_gem3/gem_tx_clock] \
	[get_bd_pins proc_sys_reset_gem3_tx/slowest_sync_clk] \

connect_bd_net [get_bd_pins proc_sys_reset_0/interconnect_aresetn] \
	[get_bd_pins axi_uartlite_0/s_axi_aresetn] \
	[get_bd_pins smartconnect_sp_acp/aresetn] \
	[get_bd_pins smartconnect_sp_io/aresetn] \
	[get_bd_pins smartconnect_sp_axil/aresetn]

connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins prism_sp_openhw_gem3/resetn]

# Connect the PL clock.
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] \
	[get_bd_pins prism_sp_openhw_gem3/clock] \
	[get_bd_pins proc_sys_reset_0/slowest_sync_clk] \
	[get_bd_pins axi_uartlite_0/s_axi_aclk] \
	[get_bd_pins smartconnect_sp_axil/aclk] \
	[get_bd_pins smartconnect_sp_acp/aclk] \
	[get_bd_pins smartconnect_sp_io/aclk] \
	[get_bd_pins zynq_ultra_ps_e_0/maxihpm0_fpd_aclk] \
	[get_bd_pins zynq_ultra_ps_e_0/saxihpc0_fpd_aclk] \
	[get_bd_pins zynq_ultra_ps_e_0/saxihp0_fpd_aclk] \
	[get_bd_pins zynq_ultra_ps_e_0/saxiacp_fpd_aclk]

# Connect the PL reset.
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0] \
	[get_bd_pins proc_sys_reset_0/ext_reset_in] \
	[get_bd_pins proc_sys_reset_gem3_tx/ext_reset_in] \
	[get_bd_pins proc_sys_reset_gem3_rx/ext_reset_in]

# Make the raw DDR (low) region available to the ACP interfaces.
assign_bd_address -target_address_space /prism_sp_openhw_gem3/m_axi_acp_0 [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIACP/ACP_DDR_LOW] -force
assign_bd_address -target_address_space /prism_sp_openhw_gem3/m_axi_acp_1 [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIACP/ACP_DDR_LOW] -force

# Make the raw DDR (low) region available to the DMA interface.
assign_bd_address -target_address_space /prism_sp_openhw_gem3/m_axi_dma [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP0/HPC0_DDR_LOW] -force

# Make the necessary regions available to the SP I/O interface.
assign_bd_address -target_address_space /prism_sp_openhw_gem3/m_axi_io_0 [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_DDR_LOW] -force
assign_bd_address -target_address_space /prism_sp_openhw_gem3/m_axi_io_0 [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_UART0] -force
assign_bd_address -target_address_space /prism_sp_openhw_gem3/m_axi_io_0 [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_UART1] -force
assign_bd_address -target_address_space /prism_sp_openhw_gem3/m_axi_io_0 [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_GEM3] -force
assign_bd_address -target_address_space /prism_sp_openhw_gem3/m_axi_io_0 [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_CRL_APB] -force
assign_bd_address -offset 0xA0010000 -range 0x00000400 -target_address_space /prism_sp_openhw_gem3/m_axi_io_0 [get_bd_addr_segs axi_uartlite_0/S_AXI/Reg] -force

assign_bd_address -target_address_space /prism_sp_openhw_gem3/m_axi_io_1 [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_DDR_LOW] -force
assign_bd_address -target_address_space /prism_sp_openhw_gem3/m_axi_io_1 [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_UART0] -force
assign_bd_address -target_address_space /prism_sp_openhw_gem3/m_axi_io_1 [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_UART1] -force
assign_bd_address -target_address_space /prism_sp_openhw_gem3/m_axi_io_1 [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_GEM3] -force
assign_bd_address -target_address_space /prism_sp_openhw_gem3/m_axi_io_1 [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_CRL_APB] -force
assign_bd_address -offset 0xA0010000 -range 0x00000400 -target_address_space /prism_sp_openhw_gem3/m_axi_io_1 [get_bd_addr_segs axi_uartlite_0/S_AXI/Reg] -force

# Make the memory-mapped registers of the Prism SP available to the PS->PL interface
assign_bd_address -offset 0xA0006000 -range 0x00000400 -target_address_space /zynq_ultra_ps_e_0/Data [get_bd_addr_segs prism_sp_openhw_gem3/s_axil_0/reg0] -force
assign_bd_address -offset 0xA0007000 -range 0x00000400 -target_address_space /zynq_ultra_ps_e_0/Data [get_bd_addr_segs prism_sp_openhw_gem3/s_axil_1/reg0] -force

regenerate_bd_layout
validate_bd_design
save_bd_design

set_property strategy "Performance_ExploreWithRemap" [get_runs impl_1]
