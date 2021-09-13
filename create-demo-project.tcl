set _xil_proj_name_ "vivado-zcu102-prism-sp-demo"
set part "xczu9eg-ffvb1156-2-e"
set ip_repo_base_path "$::env(IP_REPO_BASE_PATH)"

start_gui

create_project ${_xil_proj_name_} "./${_xil_proj_name_}" -part ${part}

# Set some essential properties.
set_property -name "board_part" -value "xilinx.com:zcu102:part0:3.4" -objects [current_project]
set_property -name "xpm_libraries" -value "XPM_FIFO XPM_MEMORY" -objects [current_project]
set_property -name "platform.board_id" -value "zcu102" -objects [current_project]

# Set the IP repository path of the PRISM SP IP core.
set_property "ip_repo_paths" [file normalize "${ip_repo_base_path}/prism_sp"] [current_project]
update_ip_catalog -rebuild

# Create the block design.
create_bd_design "design_1"

# Make the wrapper (automatically updated by Vivado).
make_wrapper -files [get_files "${proj_path}/${_xil_proj_name_}/${_xil_proj_name_}.srcs/sources_1/bd/design_1/design_1.bd"] -top
# Add the wrapper.
add_files -norecurse "${proj_path}/${_xil_proj_name_}/${_xil_proj_name_}.gen/sources_1/bd/design_1/hdl/design_1_wrapper.v"
# Set the wrapper to be the top-level module.
set_property -name "top" -value "design_1_wrapper" -objects [current_fileset]

set zynq_ultra_ps_e_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.3 zynq_ultra_ps_e_0 ]
apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e -config {apply_board_preset "1" }  [get_bd_cells zynq_ultra_ps_e_0]
set prism_sp_0 [ create_bd_cell -type ip -vlnv user.org:user:prism_sp:1.0 prism_sp_0 ]
set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]
set proc_sys_reset_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_1 ]
set proc_sys_reset_2 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_2 ]
set smartconnect_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_0 ]
set_property -dict [ list \
	CONFIG.NUM_MI {1} \
	CONFIG.NUM_SI {1} \
] $smartconnect_0
set smartconnect_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 smartconnect_1 ]
set util_vector_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_0 ]
set_property -dict [ list \
	CONFIG.C_OPERATION {or} \
	CONFIG.C_SIZE {1} \
	CONFIG.LOGO_FILE {data/sym_orgate.png} \
] $util_vector_logic_0

set_property -dict [ list \
	CONFIG.PSU__CRL_APB__PL0_REF_CTRL__ACT_FREQMHZ {249.975021} \
	CONFIG.PSU__CRL_APB__PL0_REF_CTRL__DIVISOR0 {6} \
	CONFIG.PSU__CRL_APB__PL0_REF_CTRL__FREQMHZ {250} \
	CONFIG.PSU__ENET3__FIFO__ENABLE {1} \
	CONFIG.PSU__EXPAND__LOWER_LPS_SLAVES {1} \
	CONFIG.PSU__EXPAND__UPPER_LPS_SLAVES {1} \
	CONFIG.PSU__IRQ_P2F_ENT3__INT {1} \
	CONFIG.PSU__PROTECTION__MASTERS {USB1:NonSecure;0|USB0:NonSecure;1|S_AXI_LPD:NA;0|S_AXI_HPC1_FPD:NA;0|S_AXI_HPC0_FPD:NA;0|S_AXI_HP3_FPD:NA;0|S_AXI_HP2_FPD:NA;0|S_AXI_HP1_FPD:NA;0|S_AXI_HP0_FPD:NA;1|S_AXI_ACP:NA;0|S_AXI_ACE:NA;0|SD1:NonSecure;1|SD0:NonSecure;0|SATA1:NonSecure;1|SATA0:NonSecure;1|RPU1:Secure;1|RPU0:Secure;1|QSPI:NonSecure;1|PMU:NA;1|PCIe:NonSecure;1|NAND:NonSecure;0|LDMA:NonSecure;1|GPU:NonSecure;1|GEM3:NonSecure;1|GEM2:NonSecure;0|GEM1:NonSecure;0|GEM0:NonSecure;0|FDMA:NonSecure;1|DP:NonSecure;1|DAP:NA;1|Coresight:NA;1|CSU:NA;1|APU:NA;1} \
	CONFIG.PSU__SAXIGP0__DATA_WIDTH {32} \
	CONFIG.PSU__USE__M_AXI_GP1 {0} \
	CONFIG.PSU__USE__S_AXI_GP0 {0} \
	CONFIG.PSU__USE__S_AXI_GP2 {1} \
] $zynq_ultra_ps_e_0

connect_bd_intf_net -intf_net prism_sp_0_m_axi [get_bd_intf_pins smartconnect_1/M00_AXI] [get_bd_intf_pins zynq_ultra_ps_e_0/S_AXI_HP0_FPD]
connect_bd_intf_net -intf_net prism_sp_0_m_axi_dma [get_bd_intf_pins prism_sp_0/m_axi_dma] [get_bd_intf_pins smartconnect_1/S01_AXI]
connect_bd_intf_net -intf_net prism_sp_0_m_axi_io [get_bd_intf_pins prism_sp_0/m_axi_io] [get_bd_intf_pins smartconnect_1/S00_AXI]
connect_bd_intf_net -intf_net smartconnect_0_M00_AXI [get_bd_intf_pins prism_sp_0/s_axil] [get_bd_intf_pins smartconnect_0/M00_AXI]
connect_bd_intf_net -intf_net zynq_ultra_ps_e_0_FIFO_ENET3 [get_bd_intf_pins prism_sp_0/gem] [get_bd_intf_pins zynq_ultra_ps_e_0/FIFO_ENET3]
connect_bd_intf_net -intf_net zynq_ultra_ps_e_0_M_AXI_HPM0_FPD [get_bd_intf_pins smartconnect_0/S00_AXI] [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM0_FPD]

connect_bd_net -net prism_sp_0_gem_irq [get_bd_pins prism_sp_0/gem_irq] [get_bd_pins util_vector_logic_0/Op2]
connect_bd_net -net proc_sys_reset_0_interconnect_aresetn [get_bd_pins proc_sys_reset_0/interconnect_aresetn] [get_bd_pins smartconnect_0/aresetn] [get_bd_pins smartconnect_1/aresetn]
connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins prism_sp_0/resetn] [get_bd_pins proc_sys_reset_0/peripheral_aresetn]
connect_bd_net -net proc_sys_reset_1_peripheral_aresetn [get_bd_pins prism_sp_0/gem_tx_resetn] [get_bd_pins proc_sys_reset_1/peripheral_aresetn]
connect_bd_net -net proc_sys_reset_2_peripheral_aresetn [get_bd_pins prism_sp_0/gem_rx_resetn] [get_bd_pins proc_sys_reset_2/peripheral_aresetn]
connect_bd_net -net util_vector_logic_0_Res [get_bd_pins util_vector_logic_0/Res] [get_bd_pins zynq_ultra_ps_e_0/pl_ps_irq0]
connect_bd_net -net zynq_ultra_ps_e_0_fmio_gem3_fifo_rx_clk_to_pl_bufg [get_bd_pins prism_sp_0/gem_rx_clock] \
	[get_bd_pins proc_sys_reset_2/slowest_sync_clk] \
	[get_bd_pins zynq_ultra_ps_e_0/fmio_gem3_fifo_rx_clk_to_pl_bufg]
connect_bd_net -net zynq_ultra_ps_e_0_fmio_gem3_fifo_tx_clk_to_pl_bufg [get_bd_pins prism_sp_0/gem_tx_clock] \
	[get_bd_pins proc_sys_reset_1/slowest_sync_clk] \
	[get_bd_pins zynq_ultra_ps_e_0/fmio_gem3_fifo_tx_clk_to_pl_bufg]
connect_bd_net -net zynq_ultra_ps_e_0_pl_clk0 [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] \
	[get_bd_pins prism_sp_0/clock] \
	[get_bd_pins proc_sys_reset_0/slowest_sync_clk] \
	[get_bd_pins smartconnect_0/aclk] \
	[get_bd_pins smartconnect_1/aclk] \
	[get_bd_pins zynq_ultra_ps_e_0/maxihpm0_fpd_aclk] \
	[get_bd_pins zynq_ultra_ps_e_0/saxihp0_fpd_aclk]
connect_bd_net -net zynq_ultra_ps_e_0_pl_resetn0 [get_bd_pins proc_sys_reset_0/ext_reset_in] \
	[get_bd_pins proc_sys_reset_1/ext_reset_in] \
	[get_bd_pins proc_sys_reset_2/ext_reset_in] \
	[get_bd_pins zynq_ultra_ps_e_0/pl_resetn0]
connect_bd_net -net zynq_ultra_ps_e_0_ps_pl_irq_enet3 [get_bd_pins util_vector_logic_0/Op1] [get_bd_pins zynq_ultra_ps_e_0/ps_pl_irq_enet3]

assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces prism_sp_0/m_axi_io] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_DDR_LOW] -force
assign_bd_address -offset 0xFF000000 -range 0x00010000 -target_address_space [get_bd_addr_spaces prism_sp_0/m_axi_io] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_UART0] -force
assign_bd_address -offset 0xFF010000 -range 0x00010000 -target_address_space [get_bd_addr_spaces prism_sp_0/m_axi_io] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_UART1] -force
assign_bd_address -offset 0xFF0E0000 -range 0x00010000 -target_address_space [get_bd_addr_spaces prism_sp_0/m_axi_io] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_GEM3] -force
assign_bd_address -offset 0xFF500000 -range 0x00100000 -target_address_space [get_bd_addr_spaces prism_sp_0/m_axi_io] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_CRL_APB] -force
assign_bd_address -offset 0x00000000 -range 0x80000000 -target_address_space [get_bd_addr_spaces prism_sp_0/m_axi_dma] [get_bd_addr_segs zynq_ultra_ps_e_0/SAXIGP2/HP0_DDR_LOW] -force
assign_bd_address -offset 0xA0000000 -range 0x00000400 -target_address_space [get_bd_addr_spaces zynq_ultra_ps_e_0/Data] [get_bd_addr_segs prism_sp_0/s_axil/reg0] -force

regenerate_bd_layout
validate_bd_design
save_bd_design

set_property strategy "Performance_ExploreWithRemap" [get_runs impl_1]
