verdiSetActWin -win $_OneSearch
simSetSimulator "-vcssv" -exec "/home/student/Documents/harsha-189/run/simv" \
           -args
debImport "-dbdir" "/home/student/Documents/harsha-189/run/simv.daidir"
debLoadSimResult /home/student/Documents/harsha-189/run/dump.fsdb
wvCreateWindow
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
srcSignalViewSelect "axi_interconnect_tb.m01_axi_awqos\[3:0\]"
verdiSetActWin -dock widgetDock_<Signal_List>
srcSignalViewSelectAll -curPage
wvAddSignal -win $_nWave2 "axi_interconnect_tb/DATA_WIDTH"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/ADDR_WIDTH"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/STRB_WIDTH"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/ID_WIDTH"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/AWUSER_WIDTH"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/WUSER_WIDTH"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/BUSER_WIDTH"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/ARUSER_WIDTH"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/RUSER_WIDTH"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/COMMON_BASE_ADDR\[31:0\]"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/CLK_PERIOD"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/TIMEOUT_CYCLES"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/obs_m00_awvalid"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/obs_m00_wvalid"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/obs_m01_awvalid"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/obs_m01_wvalid"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/obs_m02_awvalid"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/obs_m02_wvalid"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/obs_m03_awvalid"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/obs_m03_wvalid"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/obs_m04_awvalid"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/obs_m04_wvalid"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/obs_m05_awvalid"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/obs_m05_wvalid"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/obs_m06_awvalid"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/obs_m06_wvalid"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/obs_m07_awvalid"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/obs_m07_wvalid"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/obs_m00_awaddr\[31:0\]"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/obs_m01_awaddr\[31:0\]"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/obs_m02_awaddr\[31:0\]"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/obs_m03_awaddr\[31:0\]"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/obs_m04_awaddr\[31:0\]"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/obs_m05_awaddr\[31:0\]"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/obs_m06_awaddr\[31:0\]"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/obs_m07_awaddr\[31:0\]"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/obs_m00_wdata\[31:0\]"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/obs_m01_wdata\[31:0\]"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/obs_m02_wdata\[31:0\]"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/obs_m03_wdata\[31:0\]"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/obs_m04_wdata\[31:0\]"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/obs_m05_wdata\[31:0\]"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/obs_m06_wdata\[31:0\]"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/obs_m07_wdata\[31:0\]"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/bresp_received"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/final_bresp\[1:0\]"
wvAddSignal -win $_nWave2 "axi_interconnect_tb/timeout"
wvAddSignal -win $_nWave2 "/axi_interconnect_tb/clk" "/axi_interconnect_tb/rst" \
           "/axi_interconnect_tb/s00_axi_awid\[7:0\]" \
           "/axi_interconnect_tb/s00_axi_awaddr\[31:0\]" \
           "/axi_interconnect_tb/s00_axi_awlen\[7:0\]" \
           "/axi_interconnect_tb/s00_axi_awsize\[2:0\]" \
           "/axi_interconnect_tb/s00_axi_awburst\[1:0\]" \
           "/axi_interconnect_tb/s00_axi_awlock" \
           "/axi_interconnect_tb/s00_axi_awcache\[3:0\]" \
           "/axi_interconnect_tb/s00_axi_awprot\[2:0\]" \
           "/axi_interconnect_tb/s00_axi_awqos\[3:0\]" \
           "/axi_interconnect_tb/s00_axi_awuser\[0:0\]" \
           "/axi_interconnect_tb/s00_axi_awvalid" \
           "/axi_interconnect_tb/s00_axi_awready" \
           "/axi_interconnect_tb/s00_axi_wdata\[31:0\]" \
           "/axi_interconnect_tb/s00_axi_wstrb\[3:0\]" \
           "/axi_interconnect_tb/s00_axi_wlast" \
           "/axi_interconnect_tb/s00_axi_wuser\[0:0\]" \
           "/axi_interconnect_tb/s00_axi_wvalid" \
           "/axi_interconnect_tb/s00_axi_wready" \
           "/axi_interconnect_tb/s00_axi_bid\[7:0\]" \
           "/axi_interconnect_tb/s00_axi_bresp\[1:0\]" \
           "/axi_interconnect_tb/s00_axi_buser\[0:0\]" \
           "/axi_interconnect_tb/s00_axi_bvalid" \
           "/axi_interconnect_tb/s00_axi_bready" \
           "/axi_interconnect_tb/s00_axi_arid\[7:0\]" \
           "/axi_interconnect_tb/s00_axi_araddr\[31:0\]" \
           "/axi_interconnect_tb/s00_axi_arlen\[7:0\]" \
           "/axi_interconnect_tb/s00_axi_arsize\[2:0\]" \
           "/axi_interconnect_tb/s00_axi_arburst\[1:0\]" \
           "/axi_interconnect_tb/s00_axi_arlock" \
           "/axi_interconnect_tb/s00_axi_arcache\[3:0\]" \
           "/axi_interconnect_tb/s00_axi_arprot\[2:0\]" \
           "/axi_interconnect_tb/s00_axi_arqos\[3:0\]" \
           "/axi_interconnect_tb/s00_axi_aruser\[0:0\]" \
           "/axi_interconnect_tb/s00_axi_arvalid" \
           "/axi_interconnect_tb/s00_axi_arready" \
           "/axi_interconnect_tb/s00_axi_rid\[7:0\]" \
           "/axi_interconnect_tb/s00_axi_rdata\[31:0\]" \
           "/axi_interconnect_tb/s00_axi_rresp\[1:0\]" \
           "/axi_interconnect_tb/s00_axi_rlast" \
           "/axi_interconnect_tb/s00_axi_ruser\[0:0\]" \
           "/axi_interconnect_tb/s00_axi_rvalid" \
           "/axi_interconnect_tb/s00_axi_rready" \
           "/axi_interconnect_tb/s01_axi_awid\[7:0\]" \
           "/axi_interconnect_tb/s01_axi_awaddr\[31:0\]" \
           "/axi_interconnect_tb/s01_axi_awlen\[7:0\]" \
           "/axi_interconnect_tb/s01_axi_awsize\[2:0\]" \
           "/axi_interconnect_tb/s01_axi_awburst\[1:0\]" \
           "/axi_interconnect_tb/s01_axi_awlock" \
           "/axi_interconnect_tb/s01_axi_awcache\[3:0\]" \
           "/axi_interconnect_tb/s01_axi_awprot\[2:0\]" \
           "/axi_interconnect_tb/s01_axi_awqos\[3:0\]" \
           "/axi_interconnect_tb/s01_axi_awuser\[0:0\]" \
           "/axi_interconnect_tb/s01_axi_awvalid" \
           "/axi_interconnect_tb/s01_axi_awready" \
           "/axi_interconnect_tb/s01_axi_wdata\[31:0\]" \
           "/axi_interconnect_tb/s01_axi_wstrb\[3:0\]" \
           "/axi_interconnect_tb/s01_axi_wlast" \
           "/axi_interconnect_tb/s01_axi_wuser\[0:0\]" \
           "/axi_interconnect_tb/s01_axi_wvalid" \
           "/axi_interconnect_tb/s01_axi_wready" \
           "/axi_interconnect_tb/s01_axi_bid\[7:0\]" \
           "/axi_interconnect_tb/s01_axi_bresp\[1:0\]" \
           "/axi_interconnect_tb/s01_axi_buser\[0:0\]" \
           "/axi_interconnect_tb/s01_axi_bvalid" \
           "/axi_interconnect_tb/s01_axi_bready" \
           "/axi_interconnect_tb/s01_axi_arid\[7:0\]" \
           "/axi_interconnect_tb/s01_axi_araddr\[31:0\]" \
           "/axi_interconnect_tb/s01_axi_arlen\[7:0\]" \
           "/axi_interconnect_tb/s01_axi_arsize\[2:0\]" \
           "/axi_interconnect_tb/s01_axi_arburst\[1:0\]" \
           "/axi_interconnect_tb/s01_axi_arlock" \
           "/axi_interconnect_tb/s01_axi_arcache\[3:0\]" \
           "/axi_interconnect_tb/s01_axi_arprot\[2:0\]" \
           "/axi_interconnect_tb/s01_axi_arqos\[3:0\]" \
           "/axi_interconnect_tb/s01_axi_aruser\[0:0\]" \
           "/axi_interconnect_tb/s01_axi_arvalid" \
           "/axi_interconnect_tb/s01_axi_arready" \
           "/axi_interconnect_tb/s01_axi_rid\[7:0\]" \
           "/axi_interconnect_tb/s01_axi_rdata\[31:0\]" \
           "/axi_interconnect_tb/s01_axi_rresp\[1:0\]" \
           "/axi_interconnect_tb/s01_axi_rlast" \
           "/axi_interconnect_tb/s01_axi_ruser\[0:0\]" \
           "/axi_interconnect_tb/s01_axi_rvalid" \
           "/axi_interconnect_tb/s01_axi_rready" \
           "/axi_interconnect_tb/m00_axi_awid\[7:0\]" \
           "/axi_interconnect_tb/m00_axi_awaddr\[31:0\]" \
           "/axi_interconnect_tb/m00_axi_awlen\[7:0\]" \
           "/axi_interconnect_tb/m00_axi_awsize\[2:0\]" \
           "/axi_interconnect_tb/m00_axi_awburst\[1:0\]" \
           "/axi_interconnect_tb/m00_axi_awlock" \
           "/axi_interconnect_tb/m00_axi_awcache\[3:0\]" \
           "/axi_interconnect_tb/m00_axi_awprot\[2:0\]" \
           "/axi_interconnect_tb/m00_axi_awqos\[3:0\]" \
           "/axi_interconnect_tb/m00_axi_awregion\[3:0\]" \
           "/axi_interconnect_tb/m00_axi_awuser\[0:0\]" \
           "/axi_interconnect_tb/m00_axi_awvalid" \
           "/axi_interconnect_tb/m00_axi_awready" \
           "/axi_interconnect_tb/m00_axi_wdata\[31:0\]" \
           "/axi_interconnect_tb/m00_axi_wstrb\[3:0\]" \
           "/axi_interconnect_tb/m00_axi_wlast" \
           "/axi_interconnect_tb/m00_axi_wuser\[0:0\]" \
           "/axi_interconnect_tb/m00_axi_wvalid" \
           "/axi_interconnect_tb/m00_axi_wready" \
           "/axi_interconnect_tb/m00_axi_bid\[7:0\]" \
           "/axi_interconnect_tb/m00_axi_bresp\[1:0\]" \
           "/axi_interconnect_tb/m00_axi_buser\[0:0\]" \
           "/axi_interconnect_tb/m00_axi_bvalid" \
           "/axi_interconnect_tb/m00_axi_bready" \
           "/axi_interconnect_tb/m00_axi_arid\[7:0\]" \
           "/axi_interconnect_tb/m00_axi_araddr\[31:0\]" \
           "/axi_interconnect_tb/m00_axi_arlen\[7:0\]" \
           "/axi_interconnect_tb/m00_axi_arsize\[2:0\]" \
           "/axi_interconnect_tb/m00_axi_arburst\[1:0\]" \
           "/axi_interconnect_tb/m00_axi_arlock" \
           "/axi_interconnect_tb/m00_axi_arcache\[3:0\]" \
           "/axi_interconnect_tb/m00_axi_arprot\[2:0\]" \
           "/axi_interconnect_tb/m00_axi_arqos\[3:0\]" \
           "/axi_interconnect_tb/m00_axi_arregion\[3:0\]" \
           "/axi_interconnect_tb/m00_axi_aruser\[0:0\]" \
           "/axi_interconnect_tb/m00_axi_arvalid" \
           "/axi_interconnect_tb/m00_axi_arready" \
           "/axi_interconnect_tb/m00_axi_rid\[7:0\]" \
           "/axi_interconnect_tb/m00_axi_rdata\[31:0\]" \
           "/axi_interconnect_tb/m00_axi_rresp\[1:0\]" \
           "/axi_interconnect_tb/m00_axi_rlast" \
           "/axi_interconnect_tb/m00_axi_ruser\[0:0\]" \
           "/axi_interconnect_tb/m00_axi_rvalid" \
           "/axi_interconnect_tb/m00_axi_rready" \
           "/axi_interconnect_tb/m01_axi_awid\[7:0\]" \
           "/axi_interconnect_tb/m01_axi_awaddr\[31:0\]" \
           "/axi_interconnect_tb/m01_axi_awlen\[7:0\]" \
           "/axi_interconnect_tb/m01_axi_awsize\[2:0\]" \
           "/axi_interconnect_tb/m01_axi_awburst\[1:0\]" \
           "/axi_interconnect_tb/m01_axi_awlock" \
           "/axi_interconnect_tb/m01_axi_awcache\[3:0\]" \
           "/axi_interconnect_tb/m01_axi_awprot\[2:0\]" \
           "/axi_interconnect_tb/m01_axi_awqos\[3:0\]" \
           "/axi_interconnect_tb/m01_axi_awregion\[3:0\]" \
           "/axi_interconnect_tb/m01_axi_awuser\[0:0\]" \
           "/axi_interconnect_tb/m01_axi_awvalid" \
           "/axi_interconnect_tb/m01_axi_awready" \
           "/axi_interconnect_tb/m01_axi_wdata\[31:0\]" \
           "/axi_interconnect_tb/m01_axi_wstrb\[3:0\]" \
           "/axi_interconnect_tb/m01_axi_wlast" \
           "/axi_interconnect_tb/m01_axi_wuser\[0:0\]" \
           "/axi_interconnect_tb/m01_axi_wvalid" \
           "/axi_interconnect_tb/m01_axi_wready" \
           "/axi_interconnect_tb/m01_axi_bid\[7:0\]" \
           "/axi_interconnect_tb/m01_axi_bresp\[1:0\]" \
           "/axi_interconnect_tb/m01_axi_buser\[0:0\]" \
           "/axi_interconnect_tb/m01_axi_bvalid" \
           "/axi_interconnect_tb/m01_axi_bready" \
           "/axi_interconnect_tb/m01_axi_arid\[7:0\]" \
           "/axi_interconnect_tb/m01_axi_araddr\[31:0\]" \
           "/axi_interconnect_tb/m01_axi_arlen\[7:0\]" \
           "/axi_interconnect_tb/m01_axi_arsize\[2:0\]" \
           "/axi_interconnect_tb/m01_axi_arburst\[1:0\]" \
           "/axi_interconnect_tb/m01_axi_arlock" \
           "/axi_interconnect_tb/m01_axi_arcache\[3:0\]" \
           "/axi_interconnect_tb/m01_axi_arprot\[2:0\]" \
           "/axi_interconnect_tb/m01_axi_arqos\[3:0\]" \
           "/axi_interconnect_tb/m01_axi_arregion\[3:0\]" \
           "/axi_interconnect_tb/m01_axi_aruser\[0:0\]" \
           "/axi_interconnect_tb/m01_axi_arvalid" \
           "/axi_interconnect_tb/m01_axi_arready" \
           "/axi_interconnect_tb/m01_axi_rid\[7:0\]" \
           "/axi_interconnect_tb/m01_axi_rdata\[31:0\]" \
           "/axi_interconnect_tb/m01_axi_rresp\[1:0\]" \
           "/axi_interconnect_tb/m01_axi_rlast" \
           "/axi_interconnect_tb/m01_axi_ruser\[0:0\]" \
           "/axi_interconnect_tb/m01_axi_rvalid" \
           "/axi_interconnect_tb/m01_axi_rready" \
           "/axi_interconnect_tb/m02_axi_awid\[7:0\]" \
           "/axi_interconnect_tb/m02_axi_awaddr\[31:0\]" \
           "/axi_interconnect_tb/m02_axi_awlen\[7:0\]" \
           "/axi_interconnect_tb/m02_axi_awsize\[2:0\]" \
           "/axi_interconnect_tb/m02_axi_awburst\[1:0\]" \
           "/axi_interconnect_tb/m02_axi_awlock" \
           "/axi_interconnect_tb/m02_axi_awcache\[3:0\]" \
           "/axi_interconnect_tb/m02_axi_awprot\[2:0\]" \
           "/axi_interconnect_tb/m02_axi_awqos\[3:0\]" \
           "/axi_interconnect_tb/m02_axi_awregion\[3:0\]" \
           "/axi_interconnect_tb/m02_axi_awuser\[0:0\]" \
           "/axi_interconnect_tb/m02_axi_awvalid" \
           "/axi_interconnect_tb/m02_axi_awready" \
           "/axi_interconnect_tb/m02_axi_wdata\[31:0\]" \
           "/axi_interconnect_tb/m02_axi_wstrb\[3:0\]" \
           "/axi_interconnect_tb/m02_axi_wlast" \
           "/axi_interconnect_tb/m02_axi_wuser\[0:0\]" \
           "/axi_interconnect_tb/m02_axi_wvalid" \
           "/axi_interconnect_tb/m02_axi_wready" \
           "/axi_interconnect_tb/m02_axi_bid\[7:0\]" \
           "/axi_interconnect_tb/m02_axi_bresp\[1:0\]" \
           "/axi_interconnect_tb/m02_axi_buser\[0:0\]" \
           "/axi_interconnect_tb/m02_axi_bvalid" \
           "/axi_interconnect_tb/m02_axi_bready" \
           "/axi_interconnect_tb/m02_axi_arid\[7:0\]" \
           "/axi_interconnect_tb/m02_axi_araddr\[31:0\]" \
           "/axi_interconnect_tb/m02_axi_arlen\[7:0\]" \
           "/axi_interconnect_tb/m02_axi_arsize\[2:0\]" \
           "/axi_interconnect_tb/m02_axi_arburst\[1:0\]" \
           "/axi_interconnect_tb/m02_axi_arlock" \
           "/axi_interconnect_tb/m02_axi_arcache\[3:0\]" \
           "/axi_interconnect_tb/m02_axi_arprot\[2:0\]" \
           "/axi_interconnect_tb/m02_axi_arqos\[3:0\]" \
           "/axi_interconnect_tb/m02_axi_arregion\[3:0\]" \
           "/axi_interconnect_tb/m02_axi_aruser\[0:0\]" \
           "/axi_interconnect_tb/m02_axi_arvalid" \
           "/axi_interconnect_tb/m02_axi_arready" \
           "/axi_interconnect_tb/m02_axi_rid\[7:0\]" \
           "/axi_interconnect_tb/m02_axi_rdata\[31:0\]" \
           "/axi_interconnect_tb/m02_axi_rresp\[1:0\]" \
           "/axi_interconnect_tb/m02_axi_rlast" \
           "/axi_interconnect_tb/m02_axi_ruser\[0:0\]" \
           "/axi_interconnect_tb/m02_axi_rvalid" \
           "/axi_interconnect_tb/m02_axi_rready" \
           "/axi_interconnect_tb/m03_axi_awid\[7:0\]" \
           "/axi_interconnect_tb/m03_axi_awaddr\[31:0\]" \
           "/axi_interconnect_tb/m03_axi_awlen\[7:0\]" \
           "/axi_interconnect_tb/m03_axi_awsize\[2:0\]" \
           "/axi_interconnect_tb/m03_axi_awburst\[1:0\]" \
           "/axi_interconnect_tb/m03_axi_awlock" \
           "/axi_interconnect_tb/m03_axi_awcache\[3:0\]" \
           "/axi_interconnect_tb/m03_axi_awprot\[2:0\]" \
           "/axi_interconnect_tb/m03_axi_awqos\[3:0\]" \
           "/axi_interconnect_tb/m03_axi_awregion\[3:0\]" \
           "/axi_interconnect_tb/m03_axi_awuser\[0:0\]" \
           "/axi_interconnect_tb/m03_axi_awvalid" \
           "/axi_interconnect_tb/m03_axi_awready" \
           "/axi_interconnect_tb/m03_axi_wdata\[31:0\]" \
           "/axi_interconnect_tb/m03_axi_wstrb\[3:0\]" \
           "/axi_interconnect_tb/m03_axi_wlast" \
           "/axi_interconnect_tb/m03_axi_wuser\[0:0\]" \
           "/axi_interconnect_tb/m03_axi_wvalid" \
           "/axi_interconnect_tb/m03_axi_wready" \
           "/axi_interconnect_tb/m03_axi_bid\[7:0\]" \
           "/axi_interconnect_tb/m03_axi_bresp\[1:0\]" \
           "/axi_interconnect_tb/m03_axi_buser\[0:0\]" \
           "/axi_interconnect_tb/m03_axi_bvalid" \
           "/axi_interconnect_tb/m03_axi_bready" \
           "/axi_interconnect_tb/m03_axi_arid\[7:0\]" \
           "/axi_interconnect_tb/m03_axi_araddr\[31:0\]" \
           "/axi_interconnect_tb/m03_axi_arlen\[7:0\]" \
           "/axi_interconnect_tb/m03_axi_arsize\[2:0\]" \
           "/axi_interconnect_tb/m03_axi_arburst\[1:0\]" \
           "/axi_interconnect_tb/m03_axi_arlock" \
           "/axi_interconnect_tb/m03_axi_arcache\[3:0\]" \
           "/axi_interconnect_tb/m03_axi_arprot\[2:0\]" \
           "/axi_interconnect_tb/m03_axi_arqos\[3:0\]" \
           "/axi_interconnect_tb/m03_axi_arregion\[3:0\]" \
           "/axi_interconnect_tb/m03_axi_aruser\[0:0\]" \
           "/axi_interconnect_tb/m03_axi_arvalid" \
           "/axi_interconnect_tb/m03_axi_arready" \
           "/axi_interconnect_tb/m03_axi_rid\[7:0\]" \
           "/axi_interconnect_tb/m03_axi_rdata\[31:0\]" \
           "/axi_interconnect_tb/m03_axi_rresp\[1:0\]" \
           "/axi_interconnect_tb/m03_axi_rlast" \
           "/axi_interconnect_tb/m03_axi_ruser\[0:0\]" \
           "/axi_interconnect_tb/m03_axi_rvalid" \
           "/axi_interconnect_tb/m03_axi_rready" \
           "/axi_interconnect_tb/m04_axi_awid\[7:0\]" \
           "/axi_interconnect_tb/m04_axi_awaddr\[31:0\]" \
           "/axi_interconnect_tb/m04_axi_awlen\[7:0\]" \
           "/axi_interconnect_tb/m04_axi_awsize\[2:0\]" \
           "/axi_interconnect_tb/m04_axi_awburst\[1:0\]" \
           "/axi_interconnect_tb/m04_axi_awlock" \
           "/axi_interconnect_tb/m04_axi_awcache\[3:0\]" \
           "/axi_interconnect_tb/m04_axi_awprot\[2:0\]" \
           "/axi_interconnect_tb/m04_axi_awqos\[3:0\]" \
           "/axi_interconnect_tb/m04_axi_awregion\[3:0\]" \
           "/axi_interconnect_tb/m04_axi_awuser\[0:0\]" \
           "/axi_interconnect_tb/m04_axi_awvalid" \
           "/axi_interconnect_tb/m04_axi_awready" \
           "/axi_interconnect_tb/m04_axi_wdata\[31:0\]" \
           "/axi_interconnect_tb/m04_axi_wstrb\[3:0\]" \
           "/axi_interconnect_tb/m04_axi_wlast" \
           "/axi_interconnect_tb/m04_axi_wuser\[0:0\]" \
           "/axi_interconnect_tb/m04_axi_wvalid" \
           "/axi_interconnect_tb/m04_axi_wready" \
           "/axi_interconnect_tb/m04_axi_bid\[7:0\]" \
           "/axi_interconnect_tb/m04_axi_bresp\[1:0\]" \
           "/axi_interconnect_tb/m04_axi_buser\[0:0\]" \
           "/axi_interconnect_tb/m04_axi_bvalid" \
           "/axi_interconnect_tb/m04_axi_bready" \
           "/axi_interconnect_tb/m04_axi_arid\[7:0\]" \
           "/axi_interconnect_tb/m04_axi_araddr\[31:0\]" \
           "/axi_interconnect_tb/m04_axi_arlen\[7:0\]" \
           "/axi_interconnect_tb/m04_axi_arsize\[2:0\]" \
           "/axi_interconnect_tb/m04_axi_arburst\[1:0\]" \
           "/axi_interconnect_tb/m04_axi_arlock" \
           "/axi_interconnect_tb/m04_axi_arcache\[3:0\]" \
           "/axi_interconnect_tb/m04_axi_arprot\[2:0\]" \
           "/axi_interconnect_tb/m04_axi_arqos\[3:0\]" \
           "/axi_interconnect_tb/m04_axi_arregion\[3:0\]" \
           "/axi_interconnect_tb/m04_axi_aruser\[0:0\]" \
           "/axi_interconnect_tb/m04_axi_arvalid" \
           "/axi_interconnect_tb/m04_axi_arready" \
           "/axi_interconnect_tb/m04_axi_rid\[7:0\]" \
           "/axi_interconnect_tb/m04_axi_rdata\[31:0\]" \
           "/axi_interconnect_tb/m04_axi_rresp\[1:0\]" \
           "/axi_interconnect_tb/m04_axi_rlast" \
           "/axi_interconnect_tb/m04_axi_ruser\[0:0\]" \
           "/axi_interconnect_tb/m04_axi_rvalid" \
           "/axi_interconnect_tb/m04_axi_rready" \
           "/axi_interconnect_tb/m05_axi_awid\[7:0\]" \
           "/axi_interconnect_tb/m05_axi_awaddr\[31:0\]" \
           "/axi_interconnect_tb/m05_axi_awlen\[7:0\]" \
           "/axi_interconnect_tb/m05_axi_awsize\[2:0\]" \
           "/axi_interconnect_tb/m05_axi_awburst\[1:0\]" \
           "/axi_interconnect_tb/m05_axi_awlock" \
           "/axi_interconnect_tb/m05_axi_awcache\[3:0\]" \
           "/axi_interconnect_tb/m05_axi_awprot\[2:0\]" \
           "/axi_interconnect_tb/m05_axi_awqos\[3:0\]" \
           "/axi_interconnect_tb/m05_axi_awregion\[3:0\]" \
           "/axi_interconnect_tb/m05_axi_awuser\[0:0\]" \
           "/axi_interconnect_tb/m05_axi_awvalid" \
           "/axi_interconnect_tb/m05_axi_awready" \
           "/axi_interconnect_tb/m05_axi_wdata\[31:0\]" \
           "/axi_interconnect_tb/m05_axi_wstrb\[3:0\]" \
           "/axi_interconnect_tb/m05_axi_wlast" \
           "/axi_interconnect_tb/m05_axi_wuser\[0:0\]" \
           "/axi_interconnect_tb/m05_axi_wvalid" \
           "/axi_interconnect_tb/m05_axi_wready" \
           "/axi_interconnect_tb/m05_axi_bid\[7:0\]" \
           "/axi_interconnect_tb/m05_axi_bresp\[1:0\]" \
           "/axi_interconnect_tb/m05_axi_buser\[0:0\]" \
           "/axi_interconnect_tb/m05_axi_bvalid" \
           "/axi_interconnect_tb/m05_axi_bready" \
           "/axi_interconnect_tb/m05_axi_arid\[7:0\]" \
           "/axi_interconnect_tb/m05_axi_araddr\[31:0\]" \
           "/axi_interconnect_tb/m05_axi_arlen\[7:0\]" \
           "/axi_interconnect_tb/m05_axi_arsize\[2:0\]" \
           "/axi_interconnect_tb/m05_axi_arburst\[1:0\]" \
           "/axi_interconnect_tb/m05_axi_arlock" \
           "/axi_interconnect_tb/m05_axi_arcache\[3:0\]" \
           "/axi_interconnect_tb/m05_axi_arprot\[2:0\]" \
           "/axi_interconnect_tb/m05_axi_arqos\[3:0\]" \
           "/axi_interconnect_tb/m05_axi_arregion\[3:0\]" \
           "/axi_interconnect_tb/m05_axi_aruser\[0:0\]" \
           "/axi_interconnect_tb/m05_axi_arvalid" \
           "/axi_interconnect_tb/m05_axi_arready" \
           "/axi_interconnect_tb/m05_axi_rid\[7:0\]" \
           "/axi_interconnect_tb/m05_axi_rdata\[31:0\]" \
           "/axi_interconnect_tb/m05_axi_rresp\[1:0\]" \
           "/axi_interconnect_tb/m05_axi_rlast" \
           "/axi_interconnect_tb/m05_axi_ruser\[0:0\]" \
           "/axi_interconnect_tb/m05_axi_rvalid" \
           "/axi_interconnect_tb/m05_axi_rready" \
           "/axi_interconnect_tb/m06_axi_awid\[7:0\]" \
           "/axi_interconnect_tb/m06_axi_awaddr\[31:0\]" \
           "/axi_interconnect_tb/m06_axi_awlen\[7:0\]" \
           "/axi_interconnect_tb/m06_axi_awsize\[2:0\]" \
           "/axi_interconnect_tb/m06_axi_awburst\[1:0\]" \
           "/axi_interconnect_tb/m06_axi_awlock" \
           "/axi_interconnect_tb/m06_axi_awcache\[3:0\]" \
           "/axi_interconnect_tb/m06_axi_awprot\[2:0\]" \
           "/axi_interconnect_tb/m06_axi_awqos\[3:0\]" \
           "/axi_interconnect_tb/m06_axi_awregion\[3:0\]" \
           "/axi_interconnect_tb/m06_axi_awuser\[0:0\]" \
           "/axi_interconnect_tb/m06_axi_awvalid" \
           "/axi_interconnect_tb/m06_axi_awready" \
           "/axi_interconnect_tb/m06_axi_wdata\[31:0\]" \
           "/axi_interconnect_tb/m06_axi_wstrb\[3:0\]" \
           "/axi_interconnect_tb/m06_axi_wlast" \
           "/axi_interconnect_tb/m06_axi_wuser\[0:0\]" \
           "/axi_interconnect_tb/m06_axi_wvalid" \
           "/axi_interconnect_tb/m06_axi_wready" \
           "/axi_interconnect_tb/m06_axi_bid\[7:0\]" \
           "/axi_interconnect_tb/m06_axi_bresp\[1:0\]" \
           "/axi_interconnect_tb/m06_axi_buser\[0:0\]" \
           "/axi_interconnect_tb/m06_axi_bvalid" \
           "/axi_interconnect_tb/m06_axi_bready" \
           "/axi_interconnect_tb/m06_axi_arid\[7:0\]" \
           "/axi_interconnect_tb/m06_axi_araddr\[31:0\]" \
           "/axi_interconnect_tb/m06_axi_arlen\[7:0\]" \
           "/axi_interconnect_tb/m06_axi_arsize\[2:0\]" \
           "/axi_interconnect_tb/m06_axi_arburst\[1:0\]" \
           "/axi_interconnect_tb/m06_axi_arlock" \
           "/axi_interconnect_tb/m06_axi_arcache\[3:0\]" \
           "/axi_interconnect_tb/m06_axi_arprot\[2:0\]" \
           "/axi_interconnect_tb/m06_axi_arqos\[3:0\]" \
           "/axi_interconnect_tb/m06_axi_arregion\[3:0\]" \
           "/axi_interconnect_tb/m06_axi_aruser\[0:0\]" \
           "/axi_interconnect_tb/m06_axi_arvalid" \
           "/axi_interconnect_tb/m06_axi_arready" \
           "/axi_interconnect_tb/m06_axi_rid\[7:0\]" \
           "/axi_interconnect_tb/m06_axi_rdata\[31:0\]" \
           "/axi_interconnect_tb/m06_axi_rresp\[1:0\]" \
           "/axi_interconnect_tb/m06_axi_rlast" \
           "/axi_interconnect_tb/m06_axi_ruser\[0:0\]" \
           "/axi_interconnect_tb/m06_axi_rvalid" \
           "/axi_interconnect_tb/m06_axi_rready" \
           "/axi_interconnect_tb/m07_axi_awid\[7:0\]" \
           "/axi_interconnect_tb/m07_axi_awaddr\[31:0\]" \
           "/axi_interconnect_tb/m07_axi_awlen\[7:0\]" \
           "/axi_interconnect_tb/m07_axi_awsize\[2:0\]" \
           "/axi_interconnect_tb/m07_axi_awburst\[1:0\]" \
           "/axi_interconnect_tb/m07_axi_awlock" \
           "/axi_interconnect_tb/m07_axi_awcache\[3:0\]" \
           "/axi_interconnect_tb/m07_axi_awprot\[2:0\]" \
           "/axi_interconnect_tb/m07_axi_awqos\[3:0\]" \
           "/axi_interconnect_tb/m07_axi_awregion\[3:0\]" \
           "/axi_interconnect_tb/m07_axi_awuser\[0:0\]" \
           "/axi_interconnect_tb/m07_axi_awvalid" \
           "/axi_interconnect_tb/m07_axi_awready" \
           "/axi_interconnect_tb/m07_axi_wdata\[31:0\]" \
           "/axi_interconnect_tb/m07_axi_wstrb\[3:0\]" \
           "/axi_interconnect_tb/m07_axi_wlast" \
           "/axi_interconnect_tb/m07_axi_wuser\[0:0\]" \
           "/axi_interconnect_tb/m07_axi_wvalid" \
           "/axi_interconnect_tb/m07_axi_wready" \
           "/axi_interconnect_tb/m07_axi_bid\[7:0\]" \
           "/axi_interconnect_tb/m07_axi_bresp\[1:0\]" \
           "/axi_interconnect_tb/m07_axi_buser\[0:0\]" \
           "/axi_interconnect_tb/m07_axi_bvalid" \
           "/axi_interconnect_tb/m07_axi_bready" \
           "/axi_interconnect_tb/m07_axi_arid\[7:0\]" \
           "/axi_interconnect_tb/m07_axi_araddr\[31:0\]" \
           "/axi_interconnect_tb/m07_axi_arlen\[7:0\]" \
           "/axi_interconnect_tb/m07_axi_arsize\[2:0\]" \
           "/axi_interconnect_tb/m07_axi_arburst\[1:0\]" \
           "/axi_interconnect_tb/m07_axi_arlock" \
           "/axi_interconnect_tb/m07_axi_arcache\[3:0\]" \
           "/axi_interconnect_tb/m07_axi_arprot\[2:0\]" \
           "/axi_interconnect_tb/m07_axi_arqos\[3:0\]" \
           "/axi_interconnect_tb/m07_axi_arregion\[3:0\]" \
           "/axi_interconnect_tb/m07_axi_aruser\[0:0\]" \
           "/axi_interconnect_tb/m07_axi_arvalid" \
           "/axi_interconnect_tb/m07_axi_arready" \
           "/axi_interconnect_tb/m07_axi_rid\[7:0\]" \
           "/axi_interconnect_tb/m07_axi_rdata\[31:0\]" \
           "/axi_interconnect_tb/m07_axi_rresp\[1:0\]" \
           "/axi_interconnect_tb/m07_axi_rlast" \
           "/axi_interconnect_tb/m07_axi_ruser\[0:0\]" \
           "/axi_interconnect_tb/m07_axi_rvalid" \
           "/axi_interconnect_tb/m07_axi_rready"
wvSetPosition -win $_nWave2 {("G1" 0)}
wvSetPosition -win $_nWave2 {("G1" 438)}
wvSetPosition -win $_nWave2 {("G1" 438)}
wvUnknownSaveResult -win $_nWave2 -clear
srcSignalView -off
verdiDockWidgetMaximize -dock windowDock_nWave_2
verdiSetActWin -win $_nWave2
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 2
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 2
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 2
wvScrollUp -win $_nWave2 2
wvScrollUp -win $_nWave2 2
wvScrollUp -win $_nWave2 2
wvScrollUp -win $_nWave2 2
wvScrollUp -win $_nWave2 2
wvScrollUp -win $_nWave2 2
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 7
wvScrollUp -win $_nWave2 6
wvScrollUp -win $_nWave2 10
wvScrollUp -win $_nWave2 9
wvScrollUp -win $_nWave2 10
wvScrollUp -win $_nWave2 6
wvScrollUp -win $_nWave2 9
wvScrollUp -win $_nWave2 6
wvScrollUp -win $_nWave2 5
wvScrollUp -win $_nWave2 5
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 5
wvScrollUp -win $_nWave2 2
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 2
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 2
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 2
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 2
wvScrollDown -win $_nWave2 0
wvScrollUp -win $_nWave2 2
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 2
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 2
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 2
wvScrollUp -win $_nWave2 2
wvScrollUp -win $_nWave2 2
wvScrollUp -win $_nWave2 2
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 2
wvScrollUp -win $_nWave2 2
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 2
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 2
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 2
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 7
wvScrollUp -win $_nWave2 12
wvScrollUp -win $_nWave2 7
wvScrollUp -win $_nWave2 6
wvScrollUp -win $_nWave2 2
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 2
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 2
wvScrollUp -win $_nWave2 4
wvScrollUp -win $_nWave2 3
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 2
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 3
wvSelectSignal -win $_nWave2 {( "G1" 13 )} 
wvSetCursor -win $_nWave2 149738.960182 -snap {("G1" 13)}
wvSetCursor -win $_nWave2 152545.932119 -snap {("G1" 16)}
wvSelectSignal -win $_nWave2 {( "G1" 16 )} 
wvSelectSignal -win $_nWave2 {( "G1" 13 )} 
wvSetPosition -win $_nWave2 {("G1" 13)}
wvSetPosition -win $_nWave2 {("G1" 12)}
wvSetPosition -win $_nWave2 {("G1" 11)}
wvSetPosition -win $_nWave2 {("G1" 10)}
wvSetPosition -win $_nWave2 {("G1" 9)}
wvSetPosition -win $_nWave2 {("G1" 8)}
wvSetPosition -win $_nWave2 {("G1" 7)}
wvSetPosition -win $_nWave2 {("G1" 6)}
wvSetPosition -win $_nWave2 {("G1" 5)}
wvSetPosition -win $_nWave2 {("G1" 4)}
wvSetPosition -win $_nWave2 {("G1" 3)}
wvMoveSelected -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 3)}
wvSetPosition -win $_nWave2 {("G1" 4)}
wvSelectSignal -win $_nWave2 {( "G1" 14 )} 
wvSetPosition -win $_nWave2 {("G1" 14)}
wvSetPosition -win $_nWave2 {("G1" 13)}
wvSetPosition -win $_nWave2 {("G1" 12)}
wvSetPosition -win $_nWave2 {("G1" 11)}
wvSetPosition -win $_nWave2 {("G1" 10)}
wvSetPosition -win $_nWave2 {("G1" 5)}
wvSetPosition -win $_nWave2 {("G1" 6)}
wvSetPosition -win $_nWave2 {("G1" 5)}
wvSetPosition -win $_nWave2 {("G1" 4)}
wvMoveSelected -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 4)}
wvSetPosition -win $_nWave2 {("G1" 5)}
wvSelectSignal -win $_nWave2 {( "G1" 7 )} 
wvSetPosition -win $_nWave2 {("G1" 7)}
wvSetPosition -win $_nWave2 {("G1" 6)}
wvSetPosition -win $_nWave2 {("G1" 5)}
wvSetPosition -win $_nWave2 {("G1" 4)}
wvSetPosition -win $_nWave2 {("G1" 3)}
wvMoveSelected -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 3)}
wvSetPosition -win $_nWave2 {("G1" 4)}
wvSelectSignal -win $_nWave2 {( "G1" 19 )} 
wvSetPosition -win $_nWave2 {("G1" 19)}
wvSetPosition -win $_nWave2 {("G1" 18)}
wvSetPosition -win $_nWave2 {("G1" 17)}
wvSetPosition -win $_nWave2 {("G1" 16)}
wvSetPosition -win $_nWave2 {("G1" 15)}
wvSetPosition -win $_nWave2 {("G1" 14)}
wvMoveSelected -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 14)}
wvSetPosition -win $_nWave2 {("G1" 15)}
wvSelectSignal -win $_nWave2 {( "G1" 20 )} 
wvSetPosition -win $_nWave2 {("G1" 20)}
wvSetPosition -win $_nWave2 {("G1" 19)}
wvSetPosition -win $_nWave2 {("G1" 18)}
wvSetPosition -win $_nWave2 {("G1" 17)}
wvSetPosition -win $_nWave2 {("G1" 16)}
wvSetPosition -win $_nWave2 {("G1" 15)}
wvMoveSelected -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 15)}
wvSetPosition -win $_nWave2 {("G1" 16)}
wvSelectSignal -win $_nWave2 {( "G1" 22 )} 
wvSelectSignal -win $_nWave2 {( "G1" 24 )} 
wvSetPosition -win $_nWave2 {("G1" 24)}
wvSetPosition -win $_nWave2 {("G1" 23)}
wvSetPosition -win $_nWave2 {("G1" 22)}
wvSetPosition -win $_nWave2 {("G1" 21)}
wvMoveSelected -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 21)}
wvSetPosition -win $_nWave2 {("G1" 22)}
wvSelectSignal -win $_nWave2 {( "G1" 24 25 )} 
wvSelectSignal -win $_nWave2 {( "G1" 25 )} 
wvSetPosition -win $_nWave2 {("G1" 25)}
wvSetPosition -win $_nWave2 {("G1" 24)}
wvSetPosition -win $_nWave2 {("G1" 23)}
wvSetPosition -win $_nWave2 {("G1" 22)}
wvSetPosition -win $_nWave2 {("G1" 23)}
wvSetPosition -win $_nWave2 {("G1" 24)}
wvSetPosition -win $_nWave2 {("G1" 23)}
wvSetPosition -win $_nWave2 {("G1" 22)}
wvMoveSelected -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 22)}
wvSetPosition -win $_nWave2 {("G1" 23)}
wvSearchPrev -win $_nWave2
wvZoomAll -win $_nWave2
wvScrollDown -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 2
wvScrollDown -win $_nWave2 8
wvScrollDown -win $_nWave2 2
wvScrollDown -win $_nWave2 53
wvScrollDown -win $_nWave2 3
wvScrollDown -win $_nWave2 2
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvSetCursor -win $_nWave2 229258.910473 -snap {("G1" 24)}
wvSetCursor -win $_nWave2 229258.910473 -snap {("G1" 24)}
wvSetCursor -win $_nWave2 72691.849662 -snap {("G1" 25)}
wvSetCursor -win $_nWave2 65236.275338 -snap {("G1" 25)}
srcActiveTrace "axi_interconnect_tb.s00_axi_buser\[0:0\]" -TraceByDConWave \
           -TraceTime 0 -TraceValue 0 -win $_nTrace1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvSelectSignal -win $_nWave2 {( "G1" 88 )} 
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 2
wvScrollDown -win $_nWave2 3
wvScrollDown -win $_nWave2 4
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 2
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 3
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 5
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvSetCursor -win $_nWave2 108105.827703 -snap {("G1" 125)}
wvSetCursor -win $_nWave2 108105.827703 -snap {("G1" 125)}
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvSelectSignal -win $_nWave2 {( "G1" 7 )} 
wvSelectSignal -win $_nWave2 {( "G1" 17 )} 
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvSetCursor -win $_nWave2 341406.250000 -snap {("G1" 17)}
wvSelectSignal -win $_nWave2 {( "G1" 17 )} 
wvSetRadix -win $_nWave2 -format Bin
wvSelectSignal -win $_nWave2 {( "G1" 17 )} 
wvSetRadix -win $_nWave2 -format Hex
wvSetCursor -win $_nWave2 147842.826019 -snap {("G1" 19)}
wvSetCursor -win $_nWave2 190347.638500 -snap {("G1" 15)}
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvSetCursor -win $_nWave2 509511.731602 -snap {("G1" 5)}
wvSetCursor -win $_nWave2 151376.673882 -snap {("G1" 15)}
wvSetCursor -win $_nWave2 173529.357864 -snap {("G1" 16)}
wvSetCursor -win $_nWave2 524280.187590 -snap {("G1" 6)}
wvSetCursor -win $_nWave2 533510.472583 -snap {("G1" 6)}
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvSetCursor -win $_nWave2 579661.897547 -snap {("G1" 39)}
wvSetCursor -win $_nWave2 655350.234488 -snap {("G1" 39)}
wvSetCursor -win $_nWave2 753191.255411 -snap {("G1" 39)}
wvSetCursor -win $_nWave2 847340.162338 -snap {("G1" 39)}
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvSetCursor -win $_nWave2 227065.010823 -snap {("G1" 100)}
wvSetCursor -win $_nWave2 345212.658730 -snap {("G1" 100)}
wvSetCursor -win $_nWave2 407978.596681 -snap {("G1" 100)}
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvSetCursor -win $_nWave2 149530.616883 -snap {("G1" 100)}
wvSetCursor -win $_nWave2 367365.342713 -snap {("G1" 100)}
wvSetCursor -win $_nWave2 151376.673882 -snap {("G1" 100)}
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvSetCursor -win $_nWave2 494305.464606 -snap {("G1" 100)}
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollUp -win $_nWave2 35
wvScrollUp -win $_nWave2 15
srcSignalView -on
srcSignalView -off
srcSignalView -on
verdiDockWidgetRestore -dock windowDock_nWave_2
wvGetSignalOpen -win $_nWave2
wvGetSignalSetScope -win $_nWave2 "/axi_interconnect_tb"
srcHBSelect "axi_interconnect_tb.DUT" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Inst._Tree>
wvSelectSignal -win $_nWave2 {( "G1" 17 )} 
verdiSetActWin -win $_nWave2
wvScrollUp -win $_nWave2 30
wvSelectSignal -win $_nWave2 {( "G1" 1 )} 
wvSelectSignal -win $_nWave2 {( "G1" 1 )} 
wvSelectSignal -win $_nWave2 {( "G1" 1 )} 
wvSetPosition -win $_nWave2 {("G1" 1)}
wvSetPosition -win $_nWave2 {("G1" 2)}
wvSetPosition -win $_nWave2 {("G1" 4)}
wvSetPosition -win $_nWave2 {("G1" 5)}
wvSetPosition -win $_nWave2 {("G1" 7)}
wvSetPosition -win $_nWave2 {("G1" 9)}
wvSetPosition -win $_nWave2 {("G1" 10)}
wvSetPosition -win $_nWave2 {("G1" 12)}
wvSetPosition -win $_nWave2 {("G1" 14)}
wvSetPosition -win $_nWave2 {("G1" 15)}
wvSetPosition -win $_nWave2 {("G1" 17)}
wvSetPosition -win $_nWave2 {("G1" 19)}
wvSetPosition -win $_nWave2 {("G1" 20)}
wvSetPosition -win $_nWave2 {("G1" 21)}
wvSetPosition -win $_nWave2 {("G1" 23)}
wvUndo -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 23)}
wvSetPosition -win $_nWave2 {("G1" 23)}
wvSetPosition -win $_nWave2 {("G1" 22)}
wvUndo -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 22)}
wvSetPosition -win $_nWave2 {("G1" 23)}
wvUndo -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 23)}
wvSetPosition -win $_nWave2 {("G1" 23)}
wvSetPosition -win $_nWave2 {("G1" 22)}
wvUndo -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 22)}
wvSetPosition -win $_nWave2 {("G1" 23)}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 23)}
wvSetPosition -win $_nWave2 {("G1" 22)}
wvSelectGroup -win $_nWave2 {G1}
wvSelectSignal -win $_nWave2 {( "G1" 1 )} 
wvSelectSignal -win $_nWave2 {( "G1" 1 )} 
wvSelectSignal -win $_nWave2 {( "G1" 1 )} 
wvSetPosition -win $_nWave2 {("G1" 1)}
wvSetPosition -win $_nWave2 {("G1" 2)}
wvSetPosition -win $_nWave2 {("G1" 3)}
wvSetPosition -win $_nWave2 {("G1" 4)}
wvSetPosition -win $_nWave2 {("G1" 5)}
wvSetPosition -win $_nWave2 {("G1" 6)}
wvSetPosition -win $_nWave2 {("G1" 7)}
wvSetPosition -win $_nWave2 {("G1" 9)}
wvSetPosition -win $_nWave2 {("G1" 11)}
wvSetPosition -win $_nWave2 {("G1" 12)}
wvSetPosition -win $_nWave2 {("G1" 14)}
wvSetPosition -win $_nWave2 {("G1" 15)}
wvSetPosition -win $_nWave2 {("G1" 16)}
wvSetPosition -win $_nWave2 {("G1" 18)}
wvSetPosition -win $_nWave2 {("G1" 19)}
wvMoveSelected -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 19)}
wvScrollDown -win $_nWave2 19
wvGetSignalClose -win $_nWave2
wvCloseWindow -win $_nWave2
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcSignalViewSelect \
           "axi_interconnect_tb.DUT.axi_interconnect_inst.s_axi_arlock\[1:0\]"
verdiSetActWin -dock widgetDock_<Signal_List>
nsMsgSwitchTab -tab general
debImport "-f" "/home/student/Documents/harsha-189/run/run.f" -path \
          {/home/student/Documents/harsha-189/run}
nsMsgSwitchTab -tab general
debLoadSimResult /home/student/Documents/harsha-189/run/dump.fsdb
verdiSetActWin -win $_OneSearch
srcSignalView -off
wvCreateWindow
verdiSetActWin -win $_nWave3
wvGetSignalOpen -win $_nWave3
wvGetSignalSetScope -win $_nWave3 "/axi_interconnect_tb"
wvSetPosition -win $_nWave3 {("G1" 11)}
wvSetPosition -win $_nWave3 {("G1" 11)}
wvAddSignal -win $_nWave3 -clear
wvAddSignal -win $_nWave3 -group {"G1" \
{/axi_interconnect_tb/clk} \
{/axi_interconnect_tb/m00_axi_araddr\[31:0\]} \
{/axi_interconnect_tb/m00_axi_arready} \
{/axi_interconnect_tb/m00_axi_arvalid} \
{/axi_interconnect_tb/m00_axi_awaddr\[31:0\]} \
{/axi_interconnect_tb/m00_axi_awready} \
{/axi_interconnect_tb/m00_axi_awvalid} \
{/axi_interconnect_tb/m00_axi_rready} \
{/axi_interconnect_tb/m00_axi_rvalid} \
{/axi_interconnect_tb/m00_axi_wdata\[31:0\]} \
{/axi_interconnect_tb/m00_axi_wvalid} \
}
wvAddSignal -win $_nWave3 -group {"G2" \
}
wvSelectSignal -win $_nWave3 {( "G1" 1 2 3 4 5 6 7 8 9 10 11 )} 
wvSetPosition -win $_nWave3 {("G1" 11)}
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvZoomOut -win $_nWave3
wvGetSignalOpen -win $_nWave3
wvSetPosition -win $_nWave3 {("G1" 12)}
wvSetPosition -win $_nWave3 {("G1" 12)}
wvAddSignal -win $_nWave3 -clear
wvAddSignal -win $_nWave3 -group {"G1" \
{/axi_interconnect_tb/clk} \
{/axi_interconnect_tb/m00_axi_araddr\[31:0\]} \
{/axi_interconnect_tb/m00_axi_arready} \
{/axi_interconnect_tb/m00_axi_arvalid} \
{/axi_interconnect_tb/m00_axi_awaddr\[31:0\]} \
{/axi_interconnect_tb/m00_axi_awready} \
{/axi_interconnect_tb/m00_axi_awvalid} \
{/axi_interconnect_tb/m00_axi_rready} \
{/axi_interconnect_tb/m00_axi_rvalid} \
{/axi_interconnect_tb/m00_axi_wdata\[31:0\]} \
{/axi_interconnect_tb/m00_axi_wvalid} \
{/axi_interconnect_tb/m00_axi_wready} \
}
wvAddSignal -win $_nWave3 -group {"G2" \
}
wvSelectSignal -win $_nWave3 {( "G1" 12 )} 
wvSetPosition -win $_nWave3 {("G1" 12)}
wvSelectSignal -win $_nWave3 {( "G1" 7 )} 
wvSetPosition -win $_nWave3 {("G1" 7)}
wvSetPosition -win $_nWave3 {("G1" 6)}
wvMoveSelected -win $_nWave3
wvSetPosition -win $_nWave3 {("G1" 6)}
wvSetPosition -win $_nWave3 {("G1" 7)}
wvSetPosition -win $_nWave3 {("G1" 6)}
wvSetPosition -win $_nWave3 {("G1" 5)}
wvMoveSelected -win $_nWave3
wvSetPosition -win $_nWave3 {("G1" 5)}
wvSetPosition -win $_nWave3 {("G1" 6)}
wvSelectSignal -win $_nWave3 {( "G1" 5 6 7 )} 
wvSelectSignal -win $_nWave3 {( "G1" 5 )} 
wvSetPosition -win $_nWave3 {("G1" 5)}
wvSetPosition -win $_nWave3 {("G1" 6)}
wvSetPosition -win $_nWave3 {("G1" 7)}
wvMoveSelected -win $_nWave3
wvSetPosition -win $_nWave3 {("G1" 7)}
wvSelectSignal -win $_nWave3 {( "G1" 2 )} 
wvSelectSignal -win $_nWave3 {( "G1" 11 )} 
wvSetPosition -win $_nWave3 {("G1" 11)}
wvSetPosition -win $_nWave3 {("G1" 10)}
wvSetPosition -win $_nWave3 {("G1" 9)}
wvMoveSelected -win $_nWave3
wvSetPosition -win $_nWave3 {("G1" 9)}
wvSetPosition -win $_nWave3 {("G1" 10)}
wvSelectSignal -win $_nWave3 {( "G1" 12 )} 
wvSetPosition -win $_nWave3 {("G1" 12)}
wvSetPosition -win $_nWave3 {("G1" 11)}
wvSetPosition -win $_nWave3 {("G1" 10)}
wvMoveSelected -win $_nWave3
wvSetPosition -win $_nWave3 {("G1" 10)}
wvSetPosition -win $_nWave3 {("G1" 11)}
wvSetCursor -win $_nWave3 191039.714785 -snap {("G2" 0)}
wvSelectGroup -win $_nWave3 {G2}
wvSelectSignal -win $_nWave3 {( "G1" 12 )} 
wvSelectGroup -win $_nWave3 {G2}
wvSelectSignal -win $_nWave3 {( "G1" 12 )} 
wvSelectGroup -win $_nWave3 {G2}
wvSelectSignal -win $_nWave3 {( "G1" 12 )} 
wvGetSignalOpen -win $_nWave3
wvSetPosition -win $_nWave3 {("G1" 17)}
wvSetPosition -win $_nWave3 {("G1" 17)}
wvAddSignal -win $_nWave3 -clear
wvAddSignal -win $_nWave3 -group {"G1" \
{/axi_interconnect_tb/clk} \
{/axi_interconnect_tb/m00_axi_araddr\[31:0\]} \
{/axi_interconnect_tb/m00_axi_arready} \
{/axi_interconnect_tb/m00_axi_arvalid} \
{/axi_interconnect_tb/m00_axi_awvalid} \
{/axi_interconnect_tb/m00_axi_awready} \
{/axi_interconnect_tb/m00_axi_awaddr\[31:0\]} \
{/axi_interconnect_tb/m00_axi_rready} \
{/axi_interconnect_tb/m00_axi_rvalid} \
{/axi_interconnect_tb/m00_axi_wvalid} \
{/axi_interconnect_tb/m00_axi_wready} \
{/axi_interconnect_tb/s00_axi_araddr\[31:0\]} \
{/axi_interconnect_tb/s00_axi_arready} \
{/axi_interconnect_tb/s00_axi_arvalid} \
{/axi_interconnect_tb/s00_axi_rdata\[31:0\]} \
{/axi_interconnect_tb/s00_axi_rready} \
{/axi_interconnect_tb/s00_axi_rvalid} \
{/axi_interconnect_tb/m00_axi_wdata\[31:0\]} \
}
wvAddSignal -win $_nWave3 -group {"G2" \
}
wvSelectSignal -win $_nWave3 {( "G1" 12 13 14 15 16 17 )} 
wvSetPosition -win $_nWave3 {("G1" 17)}
wvSetPosition -win $_nWave3 {("G1" 17)}
wvSetPosition -win $_nWave3 {("G1" 17)}
wvAddSignal -win $_nWave3 -clear
wvAddSignal -win $_nWave3 -group {"G1" \
{/axi_interconnect_tb/clk} \
{/axi_interconnect_tb/m00_axi_araddr\[31:0\]} \
{/axi_interconnect_tb/m00_axi_arready} \
{/axi_interconnect_tb/m00_axi_arvalid} \
{/axi_interconnect_tb/m00_axi_awvalid} \
{/axi_interconnect_tb/m00_axi_awready} \
{/axi_interconnect_tb/m00_axi_awaddr\[31:0\]} \
{/axi_interconnect_tb/m00_axi_rready} \
{/axi_interconnect_tb/m00_axi_rvalid} \
{/axi_interconnect_tb/m00_axi_wvalid} \
{/axi_interconnect_tb/m00_axi_wready} \
{/axi_interconnect_tb/s00_axi_araddr\[31:0\]} \
{/axi_interconnect_tb/s00_axi_arready} \
{/axi_interconnect_tb/s00_axi_arvalid} \
{/axi_interconnect_tb/s00_axi_rdata\[31:0\]} \
{/axi_interconnect_tb/s00_axi_rready} \
{/axi_interconnect_tb/s00_axi_rvalid} \
{/axi_interconnect_tb/m00_axi_wdata\[31:0\]} \
}
wvAddSignal -win $_nWave3 -group {"G2" \
}
wvSelectSignal -win $_nWave3 {( "G1" 12 13 14 15 16 17 )} 
wvSetPosition -win $_nWave3 {("G1" 17)}
wvGetSignalClose -win $_nWave3
wvSelectSignal -win $_nWave3 {( "G1" 16 )} 
wvSelectSignal -win $_nWave3 {( "G1" 18 )} 
wvSetPosition -win $_nWave3 {("G1" 18)}
wvSetPosition -win $_nWave3 {("G1" 17)}
wvSetPosition -win $_nWave3 {("G1" 16)}
wvSetPosition -win $_nWave3 {("G1" 15)}
wvSetPosition -win $_nWave3 {("G1" 14)}
wvSetPosition -win $_nWave3 {("G1" 13)}
wvSetPosition -win $_nWave3 {("G1" 12)}
wvSetPosition -win $_nWave3 {("G1" 11)}
wvMoveSelected -win $_nWave3
wvSetPosition -win $_nWave3 {("G1" 11)}
wvSetPosition -win $_nWave3 {("G1" 12)}
wvSelectSignal -win $_nWave3 {( "G1" 15 )} 
wvSetPosition -win $_nWave3 {("G1" 15)}
wvSetPosition -win $_nWave3 {("G1" 14)}
wvSetPosition -win $_nWave3 {("G1" 13)}
wvSetPosition -win $_nWave3 {("G1" 12)}
wvMoveSelected -win $_nWave3
wvSetPosition -win $_nWave3 {("G1" 12)}
wvSetPosition -win $_nWave3 {("G1" 13)}
wvSelectSignal -win $_nWave3 {( "G1" 15 )} 
wvSetPosition -win $_nWave3 {("G1" 15)}
wvSetPosition -win $_nWave3 {("G1" 14)}
wvSetPosition -win $_nWave3 {("G1" 13)}
wvMoveSelected -win $_nWave3
wvSetPosition -win $_nWave3 {("G1" 13)}
wvSetPosition -win $_nWave3 {("G1" 14)}
wvSelectSignal -win $_nWave3 {( "G1" 15 16 )} 
wvSelectSignal -win $_nWave3 {( "G1" 16 )} 
wvSelectSignal -win $_nWave3 {( "G1" 17 )} 
wvSetPosition -win $_nWave3 {("G1" 17)}
wvSetPosition -win $_nWave3 {("G1" 16)}
wvSetPosition -win $_nWave3 {("G1" 15)}
wvMoveSelected -win $_nWave3
wvSetPosition -win $_nWave3 {("G1" 15)}
wvSetPosition -win $_nWave3 {("G1" 16)}
wvSelectSignal -win $_nWave3 {( "G1" 18 )} 
wvSetPosition -win $_nWave3 {("G1" 18)}
wvSetPosition -win $_nWave3 {("G1" 17)}
wvSetPosition -win $_nWave3 {("G1" 16)}
wvSetPosition -win $_nWave3 {("G1" 15)}
wvMoveSelected -win $_nWave3
wvSetPosition -win $_nWave3 {("G1" 15)}
wvSetPosition -win $_nWave3 {("G1" 16)}
wvGetSignalOpen -win $_nWave3
wvGetSignalSetScope -win $_nWave3 "/axi_interconnect_tb"
wvGetSignalSetScope -win $_nWave3 "/axi_interconnect_tb"
wvSetPosition -win $_nWave3 {("G1" 22)}
wvSetPosition -win $_nWave3 {("G1" 22)}
wvAddSignal -win $_nWave3 -clear
wvAddSignal -win $_nWave3 -group {"G1" \
{/axi_interconnect_tb/clk} \
{/axi_interconnect_tb/m00_axi_araddr\[31:0\]} \
{/axi_interconnect_tb/m00_axi_arready} \
{/axi_interconnect_tb/m00_axi_arvalid} \
{/axi_interconnect_tb/m00_axi_awvalid} \
{/axi_interconnect_tb/m00_axi_awready} \
{/axi_interconnect_tb/m00_axi_awaddr\[31:0\]} \
{/axi_interconnect_tb/m00_axi_rready} \
{/axi_interconnect_tb/m00_axi_rvalid} \
{/axi_interconnect_tb/m00_axi_wvalid} \
{/axi_interconnect_tb/m00_axi_wready} \
{/axi_interconnect_tb/m00_axi_wdata\[31:0\]} \
{/axi_interconnect_tb/s00_axi_arvalid} \
{/axi_interconnect_tb/s00_axi_arready} \
{/axi_interconnect_tb/s00_axi_araddr\[31:0\]} \
{/axi_interconnect_tb/s00_axi_rvalid} \
{/axi_interconnect_tb/s00_axi_awaddr\[31:0\]} \
{/axi_interconnect_tb/s00_axi_awready} \
{/axi_interconnect_tb/s00_axi_awvalid} \
{/axi_interconnect_tb/s00_axi_wdata\[31:0\]} \
{/axi_interconnect_tb/s00_axi_wready} \
{/axi_interconnect_tb/s00_axi_wvalid} \
{/axi_interconnect_tb/s00_axi_rready} \
{/axi_interconnect_tb/s00_axi_rdata\[31:0\]} \
}
wvAddSignal -win $_nWave3 -group {"G2" \
}
wvSelectSignal -win $_nWave3 {( "G1" 17 18 19 20 21 22 )} 
wvSetPosition -win $_nWave3 {("G1" 22)}
verdiDockWidgetMaximize -dock windowDock_nWave_3
wvSetCursor -win $_nWave3 194810.235471 -snap {("G2" 0)}
wvSelectSignal -win $_nWave3 {( "G1" 22 )} 
wvSetCursor -win $_nWave3 150820.827462 -snap {("G1" 20)}
wvSetCursor -win $_nWave3 155848.188377 -snap {("G1" 12)}
wvSelectSignal -win $_nWave3 {( "G1" 19 )} 
wvSelectSignal -win $_nWave3 {( "G1" 20 )} 
wvSetPosition -win $_nWave3 {("G1" 20)}
wvSetPosition -win $_nWave3 {("G1" 21)}
wvSetPosition -win $_nWave3 {("G1" 22)}
wvSetPosition -win $_nWave3 {("G1" 23)}
wvSetPosition -win $_nWave3 {("G1" 22)}
wvMoveSelected -win $_nWave3
wvSetPosition -win $_nWave3 {("G1" 22)}
wvSelectSignal -win $_nWave3 {( "G1" 18 )} 
wvSelectSignal -win $_nWave3 {( "G1" 18 )} 
wvSetPosition -win $_nWave3 {("G1" 18)}
wvSetPosition -win $_nWave3 {("G1" 17)}
wvSetPosition -win $_nWave3 {("G1" 16)}
wvMoveSelected -win $_nWave3
wvSetPosition -win $_nWave3 {("G1" 16)}
wvSetPosition -win $_nWave3 {("G1" 17)}
wvSelectSignal -win $_nWave3 {( "G1" 19 )} 
wvSetPosition -win $_nWave3 {("G1" 19)}
wvSetPosition -win $_nWave3 {("G1" 18)}
wvSetPosition -win $_nWave3 {("G1" 17)}
wvSetPosition -win $_nWave3 {("G1" 16)}
wvMoveSelected -win $_nWave3
wvSetPosition -win $_nWave3 {("G1" 16)}
wvSetPosition -win $_nWave3 {("G1" 17)}
wvSelectSignal -win $_nWave3 {( "G1" 21 )} 
wvSetPosition -win $_nWave3 {("G1" 21)}
wvSetPosition -win $_nWave3 {("G1" 20)}
wvSetPosition -win $_nWave3 {("G1" 19)}
wvMoveSelected -win $_nWave3
wvSetPosition -win $_nWave3 {("G1" 19)}
wvSetPosition -win $_nWave3 {("G1" 20)}
wvSetCursor -win $_nWave3 299127.974466 -snap {("G2" 0)}
wvSetCursor -win $_nWave3 217433.359590 -snap {("G1" 22)}
wvSetCursor -win $_nWave3 211149.158446 -snap {("G1" 22)}
verdiWindowResize -win $_Verdi_1 -1 "461" "1431" "628"
