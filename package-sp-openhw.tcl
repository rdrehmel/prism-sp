set ip_name "prism_sp_openhw"
set ip_repo_path "$::env(IP_REPO_BASE_PATH)/${ip_name}"
set ip_src_path [file dirname [info script]]
set fpga_part "xczu9eg-ffvb1156-2-e"
set core_revision 15

file delete -force -- ${ip_repo_path}
create_project -force -part ${fpga_part} temporary_project /tmp/temporary_project

# Only import the files that are needed to parse the top-level wrapper.
# As of version 2021.1, Vivado has problems with some other files
# (e.g., modports other than 'master' and 'slave').
# We import all other files after bus interface creation.
add_files -norecurse $ip_src_path/sp/sp_unit_config.sv -force
add_files -norecurse $ip_src_path/sp/gem_tx_interface.sv -force
add_files -norecurse $ip_src_path/sp/gem_rx_interface.sv -force
add_files -norecurse $ip_src_path/core/taiga_config.sv -force
add_files -norecurse $ip_src_path/l2_arbiter/l2_external_interfaces.sv -force
add_files -norecurse $ip_src_path/local_memory/local_memory_interface.sv -force
add_files -norecurse $ip_src_path/core/external_interfaces.sv -force
add_files -norecurse $ip_src_path/l2_arbiter/l2_config_and_types.sv -force
add_files -norecurse $ip_src_path/sp/prism_sp_duo_wrapper.sv -force

set_property top prism_sp_duo_wrapper [current_fileset]

update_compile_order -fileset sources_1
ipx::package_project -root_dir ${ip_repo_path} -import_files -force
update_compile_order -fileset sources_1

# Set the identification
set_property vendor {drehmel.com} [ipx::current_core]
set_property library {user} [ipx::current_core]
set_property name $ip_name [ipx::current_core]
set_property version {1.0} [ipx::current_core]
set_property display_name {Prism Stream Processor OpenHW} [ipx::current_core]
set_property description {Prism Stream Processor OpenHW} [ipx::current_core]
set_property vendor_display_name {Drehmel} [ipx::current_core]
set_property company_url {https://www.drehmel.com} [ipx::current_core]
set_property core_revision $core_revision [ipx::current_core]

ipx::add_ports_from_hdl [ipx::current_core] -top_level_hdl_file ${ip_repo_path}/src/prism_sp_duo_wrapper.sv -top_module_name prism_sp_duo_wrapper

ipx::infer_bus_interface { \
	s_axil_0_awvalid \
	s_axil_0_awready \
	s_axil_0_awaddr \
	s_axil_0_awprot \
	s_axil_0_wvalid \
	s_axil_0_wready \
	s_axil_0_wdata \
	s_axil_0_wstrb \
	s_axil_0_bvalid \
	s_axil_0_bready \
	s_axil_0_bresp \
	s_axil_0_arvalid \
	s_axil_0_arready \
	s_axil_0_araddr \
	s_axil_0_arprot \
	s_axil_0_rvalid \
	s_axil_0_rready \
	s_axil_0_rdata \
	s_axil_0_rresp } \
	xilinx.com:interface:aximm_rtl:1.0 [ipx::current_core]

ipx::infer_bus_interface { \
	s_axil_1_awvalid \
	s_axil_1_awready \
	s_axil_1_awaddr \
	s_axil_1_awprot \
	s_axil_1_wvalid \
	s_axil_1_wready \
	s_axil_1_wdata \
	s_axil_1_wstrb \
	s_axil_1_bvalid \
	s_axil_1_bready \
	s_axil_1_bresp \
	s_axil_1_arvalid \
	s_axil_1_arready \
	s_axil_1_araddr \
	s_axil_1_arprot \
	s_axil_1_rvalid \
	s_axil_1_rready \
	s_axil_1_rdata \
	s_axil_1_rresp } \
	xilinx.com:interface:aximm_rtl:1.0 [ipx::current_core]

ipx::infer_bus_interface { \
	m_axi_io_0_awvalid \
	m_axi_io_0_awready \
	m_axi_io_0_awid \
	m_axi_io_0_awaddr \
	m_axi_io_0_awlen \
	m_axi_io_0_awsize \
	m_axi_io_0_awburst \
	m_axi_io_0_awlock \
	m_axi_io_0_awcache \
	m_axi_io_0_awprot \
	m_axi_io_0_awqos \
	m_axi_io_0_awregion \
	m_axi_io_0_wvalid \
	m_axi_io_0_wready \
	m_axi_io_0_wdata \
	m_axi_io_0_wstrb \
	m_axi_io_0_wlast \
	m_axi_io_0_bvalid \
	m_axi_io_0_bready \
	m_axi_io_0_bid \
	m_axi_io_0_bresp \
	m_axi_io_0_arvalid \
	m_axi_io_0_arready \
	m_axi_io_0_arid \
	m_axi_io_0_araddr \
	m_axi_io_0_arlen \
	m_axi_io_0_arsize \
	m_axi_io_0_arburst \
	m_axi_io_0_arlock \
	m_axi_io_0_arcache \
	m_axi_io_0_arprot \
	m_axi_io_0_arqos \
	m_axi_io_0_arregion \
	m_axi_io_0_rvalid \
	m_axi_io_0_rready \
	m_axi_io_0_rid \
	m_axi_io_0_rdata \
	m_axi_io_0_rresp \
	m_axi_io_0_rlast } \
	xilinx.com:interface:aximm_rtl:1.0 [ipx::current_core]

ipx::infer_bus_interface { \
	m_axi_io_1_awvalid \
	m_axi_io_1_awready \
	m_axi_io_1_awid \
	m_axi_io_1_awaddr \
	m_axi_io_1_awlen \
	m_axi_io_1_awsize \
	m_axi_io_1_awburst \
	m_axi_io_1_awlock \
	m_axi_io_1_awcache \
	m_axi_io_1_awprot \
	m_axi_io_1_awqos \
	m_axi_io_1_awregion \
	m_axi_io_1_wvalid \
	m_axi_io_1_wready \
	m_axi_io_1_wdata \
	m_axi_io_1_wstrb \
	m_axi_io_1_wlast \
	m_axi_io_1_bvalid \
	m_axi_io_1_bready \
	m_axi_io_1_bid \
	m_axi_io_1_bresp \
	m_axi_io_1_arvalid \
	m_axi_io_1_arready \
	m_axi_io_1_arid \
	m_axi_io_1_araddr \
	m_axi_io_1_arlen \
	m_axi_io_1_arsize \
	m_axi_io_1_arburst \
	m_axi_io_1_arlock \
	m_axi_io_1_arcache \
	m_axi_io_1_arprot \
	m_axi_io_1_arqos \
	m_axi_io_1_arregion \
	m_axi_io_1_rvalid \
	m_axi_io_1_rready \
	m_axi_io_1_rid \
	m_axi_io_1_rdata \
	m_axi_io_1_rresp \
	m_axi_io_1_rlast } \
	xilinx.com:interface:aximm_rtl:1.0 [ipx::current_core]

ipx::infer_bus_interface { \
	m_axi_acp_0_awid \
	m_axi_acp_0_awaddr \
	m_axi_acp_0_awlen \
	m_axi_acp_0_awsize \
	m_axi_acp_0_awburst \
	m_axi_acp_0_awlock \
	m_axi_acp_0_awcache \
	m_axi_acp_0_awprot \
	m_axi_acp_0_awqos \
	m_axi_acp_0_awuser \
	m_axi_acp_0_awvalid \
	m_axi_acp_0_awready \
	m_axi_acp_0_wdata \
	m_axi_acp_0_wstrb \
	m_axi_acp_0_wlast \
	m_axi_acp_0_wvalid \
	m_axi_acp_0_wready \
	m_axi_acp_0_bid \
	m_axi_acp_0_bresp \
	m_axi_acp_0_bvalid \
	m_axi_acp_0_bready \
	m_axi_acp_0_arid \
	m_axi_acp_0_araddr \
	m_axi_acp_0_arlen \
	m_axi_acp_0_arsize \
	m_axi_acp_0_arburst \
	m_axi_acp_0_arlock \
	m_axi_acp_0_arcache \
	m_axi_acp_0_arprot \
	m_axi_acp_0_arqos \
	m_axi_acp_0_aruser \
	m_axi_acp_0_arvalid \
	m_axi_acp_0_arready \
	m_axi_acp_0_rvalid \
	m_axi_acp_0_rready \
	m_axi_acp_0_rid \
	m_axi_acp_0_rdata \
	m_axi_acp_0_rresp \
	m_axi_acp_0_rlast } \
	xilinx.com:interface:aximm_rtl:1.0 [ipx::current_core]

ipx::infer_bus_interface { \
	m_axi_acp_1_awid \
	m_axi_acp_1_awaddr \
	m_axi_acp_1_awlen \
	m_axi_acp_1_awsize \
	m_axi_acp_1_awburst \
	m_axi_acp_1_awlock \
	m_axi_acp_1_awcache \
	m_axi_acp_1_awprot \
	m_axi_acp_1_awqos \
	m_axi_acp_1_awuser \
	m_axi_acp_1_awvalid \
	m_axi_acp_1_awready \
	m_axi_acp_1_wdata \
	m_axi_acp_1_wstrb \
	m_axi_acp_1_wlast \
	m_axi_acp_1_wvalid \
	m_axi_acp_1_wready \
	m_axi_acp_1_bid \
	m_axi_acp_1_bresp \
	m_axi_acp_1_bvalid \
	m_axi_acp_1_bready \
	m_axi_acp_1_arid \
	m_axi_acp_1_araddr \
	m_axi_acp_1_arlen \
	m_axi_acp_1_arsize \
	m_axi_acp_1_arburst \
	m_axi_acp_1_arlock \
	m_axi_acp_1_arcache \
	m_axi_acp_1_arprot \
	m_axi_acp_1_arqos \
	m_axi_acp_1_aruser \
	m_axi_acp_1_arvalid \
	m_axi_acp_1_arready \
	m_axi_acp_1_rvalid \
	m_axi_acp_1_rready \
	m_axi_acp_1_rid \
	m_axi_acp_1_rdata \
	m_axi_acp_1_rresp \
	m_axi_acp_1_rlast } \
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
	m_axi_dma_rresp \
	m_axi_dma_rlast } \
	xilinx.com:interface:aximm_rtl:1.0 [ipx::current_core]

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

set_property value "s_axil_0:s_axil_1:m_axi_io_0:m_axi_io_1:m_axi_dma:m_axi_acp_0:m_axi_acp_1" [ipx::get_bus_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_bus_interfaces clock -of_objects [ipx::current_core]]]
ipx::associate_bus_interfaces -busif s_axil_0 -clock clock [ipx::current_core]
ipx::associate_bus_interfaces -busif s_axil_1 -clock clock [ipx::current_core]
ipx::associate_bus_interfaces -busif m_axi_io_0 -clock clock [ipx::current_core]
ipx::associate_bus_interfaces -busif m_axi_io_1 -clock clock [ipx::current_core]
ipx::associate_bus_interfaces -busif m_axi_dma -clock clock [ipx::current_core]
ipx::associate_bus_interfaces -busif m_axi_acp_0 -clock clock [ipx::current_core]
ipx::associate_bus_interfaces -busif m_axi_acp_1 -clock clock [ipx::current_core]

add_files "${ip_src_path}/sp"
add_files "${ip_src_path}/core"
add_files "${ip_src_path}/mmr"

update_compile_order -fileset sources_1
ipx::merge_project_changes files [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::save_core [ipx::current_core]

close_project -delete
