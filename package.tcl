set ip_name "prism_sp"
set ip_repo_path "$::env(IP_REPO_BASE_PATH)/${ip_name}"
set ip_src_path [file dirname [info script]]
set fpga_part "xczu9eg-ffvb1156-2-e"
set core_revision 11

file delete -force -- ${ip_repo_path}
create_project -force -part ${fpga_part} temporary_project /tmp/temporary_project

# Only import the files that are needed to parse the top-level wrapper.
# As of version 2021.1, Vivado has problems with some other files
# (e.g., modports other than 'master' and 'slave').
# We import all other files after bus interface creation.
add_files -norecurse $ip_src_path/core/sp/prism_sp_wrapper.sv -force
add_files -norecurse $ip_src_path/l2_arbiter/l2_external_interfaces.sv -force
add_files -norecurse $ip_src_path/local_memory/local_memory_interface.sv -force
add_files -norecurse $ip_src_path/core/external_interfaces.sv -force
add_files -norecurse $ip_src_path/core/taiga_config.sv -force
add_files -norecurse $ip_src_path/l2_arbiter/l2_config_and_types.sv -force

set_property top prism_sp_wrapper [current_fileset]

update_compile_order -fileset sources_1
ipx::package_project -root_dir ${ip_repo_path} -import_files -force
update_compile_order -fileset sources_1

# Set the identification
set_property name $ip_name [ipx::current_core]
set_property core_revision $core_revision [ipx::current_core]

ipx::add_ports_from_hdl [ipx::current_core] -top_level_hdl_file ${ip_repo_path}/src/prism_sp_wrapper.sv -top_module_name prism_sp_wrapper

ipx::infer_bus_interface { \
	s_axil_awvalid \
	s_axil_awready \
	s_axil_awaddr \
	s_axil_awprot \
	s_axil_wvalid \
	s_axil_wready \
	s_axil_wdata \
	s_axil_wstrb \
	s_axil_bvalid \
	s_axil_bready \
	s_axil_bresp \
	s_axil_arvalid \
	s_axil_arready \
	s_axil_araddr \
	s_axil_arprot \
	s_axil_rvalid \
	s_axil_rready \
	s_axil_rdata \
	s_axil_rresp } \
	xilinx.com:interface:aximm_rtl:1.0 [ipx::current_core]

ipx::infer_bus_interface { \
	m_axi_io_awvalid \
	m_axi_io_awready \
	m_axi_io_awid \
	m_axi_io_awaddr \
	m_axi_io_awlen \
	m_axi_io_awsize \
	m_axi_io_awburst \
	m_axi_io_awlock \
	m_axi_io_awcache \
	m_axi_io_awprot \
	m_axi_io_awqos \
	m_axi_io_awregion \
	m_axi_io_wvalid \
	m_axi_io_wready \
	m_axi_io_wdata \
	m_axi_io_wstrb \
	m_axi_io_wlast \
	m_axi_io_bvalid \
	m_axi_io_bready \
	m_axi_io_bid \
	m_axi_io_bresp \
	m_axi_io_arvalid \
	m_axi_io_arready \
	m_axi_io_arid \
	m_axi_io_araddr \
	m_axi_io_arlen \
	m_axi_io_arsize \
	m_axi_io_arburst \
	m_axi_io_arlock \
	m_axi_io_arcache \
	m_axi_io_arprot \
	m_axi_io_arqos \
	m_axi_io_arregion \
	m_axi_io_rvalid \
	m_axi_io_rready \
	m_axi_io_rid \
	m_axi_io_rdata \
	m_axi_io_rresp
	m_axi_io_rlast } \
	xilinx.com:interface:aximm_rtl:1.0 [ipx::current_core]

ipx::infer_bus_interface { \
	m_axi_dma_awvalid \
	m_axi_dma_awready \
	m_axi_dma_awid \
	m_axi_dma_awaddr \
	m_axi_dma_awlen \
	m_axi_dma_awsize \
	m_axi_dma_awburst \
	m_axi_dma_awlock \
	m_axi_dma_awcache \
	m_axi_dma_awprot \
	m_axi_dma_awqos \
	m_axi_dma_awregion \
	m_axi_dma_wvalid \
	m_axi_dma_wready \
	m_axi_dma_wdata \
	m_axi_dma_wstrb \
	m_axi_dma_wlast \
	m_axi_dma_bvalid \
	m_axi_dma_bready \
	m_axi_dma_bid \
	m_axi_dma_bresp \
	m_axi_dma_arvalid \
	m_axi_dma_arready \
	m_axi_dma_arid \
	m_axi_dma_araddr \
	m_axi_dma_arlen \
	m_axi_dma_arsize \
	m_axi_dma_arburst \
	m_axi_dma_arlock \
	m_axi_dma_arcache \
	m_axi_dma_arprot \
	m_axi_dma_arqos \
	m_axi_dma_arregion \
	m_axi_dma_rvalid \
	m_axi_dma_rready \
	m_axi_dma_rid \
	m_axi_dma_rdata \
	m_axi_dma_rresp
	m_axi_dma_rlast } \
	xilinx.com:interface:aximm_rtl:1.0 [ipx::current_core]

if {0} {
#
# Create the IBRAM interface
#
ipx::add_bus_interface ibram [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:bram_rtl:1.0 [ipx::get_bus_interfaces ibram -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:bram:1.0 [ipx::get_bus_interfaces ibram -of_objects [ipx::current_core]]
set_property interface_mode master [ipx::get_bus_interfaces ibram -of_objects [ipx::current_core]]
ipx::add_bus_parameter MASTER_TYPE [ipx::get_bus_interfaces ibram -of_objects [ipx::current_core]]
set_property value BRAM_CTRL [ipx::get_bus_parameters MASTER_TYPE -of_objects [ipx::get_bus_interfaces ibram -of_objects [ipx::current_core]]]
ipx::add_port_map RST [ipx::get_bus_interfaces ibram -of_objects [ipx::current_core]]
set_property physical_name ibram_rstb [ipx::get_port_maps RST -of_objects [ipx::get_bus_interfaces ibram -of_objects [ipx::current_core]]]
ipx::add_port_map CLK [ipx::get_bus_interfaces ibram -of_objects [ipx::current_core]]
set_property physical_name ibram_clkb [ipx::get_port_maps CLK -of_objects [ipx::get_bus_interfaces ibram -of_objects [ipx::current_core]]]
ipx::add_port_map DIN [ipx::get_bus_interfaces ibram -of_objects [ipx::current_core]]
set_property physical_name ibram_dinb [ipx::get_port_maps DIN -of_objects [ipx::get_bus_interfaces ibram -of_objects [ipx::current_core]]]
ipx::add_port_map EN [ipx::get_bus_interfaces ibram -of_objects [ipx::current_core]]
set_property physical_name ibram_enb [ipx::get_port_maps EN -of_objects [ipx::get_bus_interfaces ibram -of_objects [ipx::current_core]]]
ipx::add_port_map DOUT [ipx::get_bus_interfaces ibram -of_objects [ipx::current_core]]
set_property physical_name ibram_doutb [ipx::get_port_maps DOUT -of_objects [ipx::get_bus_interfaces ibram -of_objects [ipx::current_core]]]
ipx::add_port_map WE [ipx::get_bus_interfaces ibram -of_objects [ipx::current_core]]
set_property physical_name ibram_web [ipx::get_port_maps WE -of_objects [ipx::get_bus_interfaces ibram -of_objects [ipx::current_core]]]
ipx::add_port_map ADDR [ipx::get_bus_interfaces ibram -of_objects [ipx::current_core]]
set_property physical_name ibram_addrb [ipx::get_port_maps ADDR -of_objects [ipx::get_bus_interfaces ibram -of_objects [ipx::current_core]]]

#
# Create the DBRAM interface
#
ipx::add_bus_interface dbram [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:bram_rtl:1.0 [ipx::get_bus_interfaces dbram -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:bram:1.0 [ipx::get_bus_interfaces dbram -of_objects [ipx::current_core]]
set_property interface_mode master [ipx::get_bus_interfaces dbram -of_objects [ipx::current_core]]
ipx::add_bus_parameter MASTER_TYPE [ipx::get_bus_interfaces dbram -of_objects [ipx::current_core]]
set_property value BRAM_CTRL [ipx::get_bus_parameters MASTER_TYPE -of_objects [ipx::get_bus_interfaces dbram -of_objects [ipx::current_core]]]
ipx::add_port_map RST [ipx::get_bus_interfaces dbram -of_objects [ipx::current_core]]
set_property physical_name dbram_rstb [ipx::get_port_maps RST -of_objects [ipx::get_bus_interfaces dbram -of_objects [ipx::current_core]]]
ipx::add_port_map CLK [ipx::get_bus_interfaces dbram -of_objects [ipx::current_core]]
set_property physical_name dbram_clkb [ipx::get_port_maps CLK -of_objects [ipx::get_bus_interfaces dbram -of_objects [ipx::current_core]]]
ipx::add_port_map DIN [ipx::get_bus_interfaces dbram -of_objects [ipx::current_core]]
set_property physical_name dbram_dinb [ipx::get_port_maps DIN -of_objects [ipx::get_bus_interfaces dbram -of_objects [ipx::current_core]]]
ipx::add_port_map EN [ipx::get_bus_interfaces dbram -of_objects [ipx::current_core]]
set_property physical_name dbram_enb [ipx::get_port_maps EN -of_objects [ipx::get_bus_interfaces dbram -of_objects [ipx::current_core]]]
ipx::add_port_map DOUT [ipx::get_bus_interfaces dbram -of_objects [ipx::current_core]]
set_property physical_name dbram_doutb [ipx::get_port_maps DOUT -of_objects [ipx::get_bus_interfaces dbram -of_objects [ipx::current_core]]]
ipx::add_port_map WE [ipx::get_bus_interfaces dbram -of_objects [ipx::current_core]]
set_property physical_name dbram_web [ipx::get_port_maps WE -of_objects [ipx::get_bus_interfaces dbram -of_objects [ipx::current_core]]]
ipx::add_port_map ADDR [ipx::get_bus_interfaces dbram -of_objects [ipx::current_core]]
set_property physical_name dbram_addrb [ipx::get_port_maps ADDR -of_objects [ipx::get_bus_interfaces dbram -of_objects [ipx::current_core]]]
}

#
# Create the GEM port
#
ipx::add_bus_interface gem [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:user:zynq_fifo_gem_rtl:1.0 [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:user:zynq_fifo_gem:1.0 [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]
set_property interface_mode slave [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]
ipx::add_port_map TX_R_UNDERFLOW [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]
set_property physical_name gem_tx_r_underflow [ipx::get_port_maps TX_R_UNDERFLOW -of_objects [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]]
ipx::add_port_map TX_R_DATA [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]
set_property physical_name gem_tx_r_data [ipx::get_port_maps TX_R_DATA -of_objects [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]]
ipx::add_port_map RX_W_SOP [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]
set_property physical_name gem_rx_w_sop [ipx::get_port_maps RX_W_SOP -of_objects [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]]
ipx::add_port_map TX_R_STATUS [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]
set_property physical_name gem_tx_r_status [ipx::get_port_maps TX_R_STATUS -of_objects [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]]
ipx::add_port_map TX_R_FLUSHED [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]
set_property physical_name gem_tx_r_flushed [ipx::get_port_maps TX_R_FLUSHED -of_objects [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]]
ipx::add_port_map DMA_TX_STATUS_TOG [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]
set_property physical_name gem_dma_tx_status_tog [ipx::get_port_maps DMA_TX_STATUS_TOG -of_objects [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]]
ipx::add_port_map TX_R_RD [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]
set_property physical_name gem_tx_r_rd [ipx::get_port_maps TX_R_RD -of_objects [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]]
ipx::add_port_map TX_R_EOP [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]
set_property physical_name gem_tx_r_eop [ipx::get_port_maps TX_R_EOP -of_objects [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]]
ipx::add_port_map TX_R_ERR [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]
set_property physical_name gem_tx_r_err [ipx::get_port_maps TX_R_ERR -of_objects [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]]
ipx::add_port_map TX_R_DATA_RDY [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]
set_property physical_name gem_tx_r_data_rdy [ipx::get_port_maps TX_R_DATA_RDY -of_objects [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]]
ipx::add_port_map RX_W_STATUS [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]
set_property physical_name gem_rx_w_status [ipx::get_port_maps RX_W_STATUS -of_objects [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]]
ipx::add_port_map TX_R_VALID [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]
set_property physical_name gem_tx_r_valid [ipx::get_port_maps TX_R_VALID -of_objects [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]]
ipx::add_port_map RX_W_WR [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]
set_property physical_name gem_rx_w_wr [ipx::get_port_maps RX_W_WR -of_objects [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]]
ipx::add_port_map RX_W_EOP [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]
set_property physical_name gem_rx_w_eop [ipx::get_port_maps RX_W_EOP -of_objects [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]]
ipx::add_port_map TX_R_CONTROL [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]
set_property physical_name gem_tx_r_control [ipx::get_port_maps TX_R_CONTROL -of_objects [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]]
ipx::add_port_map RX_W_ERR [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]
set_property physical_name gem_rx_w_err [ipx::get_port_maps RX_W_ERR -of_objects [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]]
ipx::add_port_map RX_W_FLUSH [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]
set_property physical_name gem_rx_w_flush [ipx::get_port_maps RX_W_FLUSH -of_objects [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]]
ipx::add_port_map RX_W_DATA [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]
set_property physical_name gem_rx_w_data [ipx::get_port_maps RX_W_DATA -of_objects [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]]
ipx::add_port_map DMA_TX_END_TOG [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]
set_property physical_name gem_dma_tx_end_tog [ipx::get_port_maps DMA_TX_END_TOG -of_objects [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]]
ipx::add_port_map RX_W_OVERFLOW [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]
set_property physical_name gem_rx_w_overflow [ipx::get_port_maps RX_W_OVERFLOW -of_objects [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]]
ipx::add_port_map TX_R_SOP [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]
set_property physical_name gem_tx_r_sop [ipx::get_port_maps TX_R_SOP -of_objects [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]]
# Warning! This one is necessary but missing in the GUI for whatever reason.
ipx::add_port_map TX_R_FIXED_LAT [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]
set_property physical_name gem_tx_r_fixed_lat [ipx::get_port_maps TX_R_FIXED_LAT -of_objects [ipx::get_bus_interfaces gem -of_objects [ipx::current_core]]]

set_property value "m_axi_io:m_axi_dma:s_axil" [ipx::get_bus_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_bus_interfaces clock -of_objects [ipx::current_core]]]
ipx::associate_bus_interfaces -busif m_axi_io -clock clock [ipx::current_core]
ipx::associate_bus_interfaces -busif m_axi_dma -clock clock [ipx::current_core]

add_files "${ip_src_path}/core"
add_files "${ip_src_path}/mmr"

update_compile_order -fileset sources_1
ipx::merge_project_changes files [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]

close_project -delete
