verdiSetActWin -dock widgetDock_<Message>
simSetSimulator "-vcssv" -exec \
           "/home/student/1602-23-735-189/IPs/aes_core-master/run/simv_axi" \
           -args
debImport "-dbdir" \
          "/home/student/1602-23-735-189/IPs/aes_core-master/run/simv_axi.daidir"
debLoadSimResult \
           /home/student/1602-23-735-189/IPs/aes_core-master/run/dump_axi_slave.fsdb
wvCreateWindow
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
srcHBSelect "tb_aes_axi_slave.dut" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcHBSelect "tb_aes_axi_slave" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Signal_List>
srcHBSelect "tb_aes_axi_slave.dut" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Inst._Tree>
srcHBSelect "tb_aes_axi_slave.dut" -win $_nTrace1
srcSetScope "tb_aes_axi_slave.dut" -delim "." -win $_nTrace1
srcHBSelect "tb_aes_axi_slave.dut" -win $_nTrace1
verdiSetActWin -dock widgetDock_<Signal_List>
srcSignalViewSelect "tb_aes_axi_slave.dut.S_AXI_ACLK"
srcSignalViewSelect "tb_aes_axi_slave.dut.S_AXI_ACLK"
srcSignalViewSelectAll -curPage
wvAddSignal -win $_nWave2 "tb_aes_axi_slave/dut/C_S_AXI_DATA_WIDTH"
wvAddSignal -win $_nWave2 "tb_aes_axi_slave/dut/C_S_AXI_ADDR_WIDTH"
wvAddSignal -win $_nWave2 "/tb_aes_axi_slave/dut/S_AXI_ACLK" \
           "/tb_aes_axi_slave/dut/S_AXI_ARESETN" \
           "/tb_aes_axi_slave/dut/S_AXI_AWADDR\[6:0\]" \
           "/tb_aes_axi_slave/dut/S_AXI_AWVALID" \
           "/tb_aes_axi_slave/dut/S_AXI_AWREADY" \
           "/tb_aes_axi_slave/dut/S_AXI_WDATA\[31:0\]" \
           "/tb_aes_axi_slave/dut/S_AXI_WSTRB\[3:0\]" \
           "/tb_aes_axi_slave/dut/S_AXI_WVALID" \
           "/tb_aes_axi_slave/dut/S_AXI_WREADY" \
           "/tb_aes_axi_slave/dut/S_AXI_BRESP\[1:0\]" \
           "/tb_aes_axi_slave/dut/S_AXI_BVALID" \
           "/tb_aes_axi_slave/dut/S_AXI_BREADY" \
           "/tb_aes_axi_slave/dut/S_AXI_ARADDR\[6:0\]" \
           "/tb_aes_axi_slave/dut/S_AXI_ARVALID" \
           "/tb_aes_axi_slave/dut/S_AXI_ARREADY" \
           "/tb_aes_axi_slave/dut/S_AXI_RDATA\[31:0\]" \
           "/tb_aes_axi_slave/dut/S_AXI_RRESP\[1:0\]" \
           "/tb_aes_axi_slave/dut/S_AXI_RVALID" \
           "/tb_aes_axi_slave/dut/S_AXI_RREADY" \
           "/tb_aes_axi_slave/dut/awready_reg" \
           "/tb_aes_axi_slave/dut/wready_reg" \
           "/tb_aes_axi_slave/dut/bvalid_reg" \
           "/tb_aes_axi_slave/dut/arready_reg" \
           "/tb_aes_axi_slave/dut/rvalid_reg" \
           "/tb_aes_axi_slave/dut/bresp_reg\[1:0\]" \
           "/tb_aes_axi_slave/dut/rresp_reg\[1:0\]" \
           "/tb_aes_axi_slave/dut/rdata_reg\[31:0\]" \
           "/tb_aes_axi_slave/dut/cipher_key0\[31:0\]" \
           "/tb_aes_axi_slave/dut/cipher_key1\[31:0\]" \
           "/tb_aes_axi_slave/dut/cipher_key2\[31:0\]" \
           "/tb_aes_axi_slave/dut/cipher_key3\[31:0\]" \
           "/tb_aes_axi_slave/dut/cipher_tin0\[31:0\]" \
           "/tb_aes_axi_slave/dut/cipher_tin1\[31:0\]" \
           "/tb_aes_axi_slave/dut/cipher_tin2\[31:0\]" \
           "/tb_aes_axi_slave/dut/cipher_tin3\[31:0\]" \
           "/tb_aes_axi_slave/dut/cipher_tout0\[31:0\]" \
           "/tb_aes_axi_slave/dut/cipher_tout1\[31:0\]" \
           "/tb_aes_axi_slave/dut/cipher_tout2\[31:0\]" \
           "/tb_aes_axi_slave/dut/cipher_tout3\[31:0\]" \
           "/tb_aes_axi_slave/dut/inv_key0\[31:0\]" \
           "/tb_aes_axi_slave/dut/inv_key1\[31:0\]" \
           "/tb_aes_axi_slave/dut/inv_key2\[31:0\]" \
           "/tb_aes_axi_slave/dut/inv_key3\[31:0\]" \
           "/tb_aes_axi_slave/dut/inv_tin0\[31:0\]" \
           "/tb_aes_axi_slave/dut/inv_tin1\[31:0\]" \
           "/tb_aes_axi_slave/dut/inv_tin2\[31:0\]" \
           "/tb_aes_axi_slave/dut/inv_tin3\[31:0\]" \
           "/tb_aes_axi_slave/dut/inv_tout0\[31:0\]" \
           "/tb_aes_axi_slave/dut/inv_tout1\[31:0\]" \
           "/tb_aes_axi_slave/dut/inv_tout2\[31:0\]" \
           "/tb_aes_axi_slave/dut/inv_tout3\[31:0\]" \
           "/tb_aes_axi_slave/dut/cipher_start_reg" \
           "/tb_aes_axi_slave/dut/inv_key_load_reg" \
           "/tb_aes_axi_slave/dut/inv_start_reg" \
           "/tb_aes_axi_slave/dut/cipher_done_reg" \
           "/tb_aes_axi_slave/dut/cipher_busy_reg" \
           "/tb_aes_axi_slave/dut/inv_done_reg" \
           "/tb_aes_axi_slave/dut/inv_kdone_reg" \
           "/tb_aes_axi_slave/dut/inv_busy_reg" \
           "/tb_aes_axi_slave/dut/inv_kcnt\[3:0\]" \
           "/tb_aes_axi_slave/dut/cipher_key\[127:0\]" \
           "/tb_aes_axi_slave/dut/cipher_text_in\[127:0\]" \
           "/tb_aes_axi_slave/dut/cipher_text_out\[127:0\]" \
           "/tb_aes_axi_slave/dut/cipher_done" \
           "/tb_aes_axi_slave/dut/inv_key\[127:0\]" \
           "/tb_aes_axi_slave/dut/inv_text_in\[127:0\]" \
           "/tb_aes_axi_slave/dut/inv_text_out\[127:0\]" \
           "/tb_aes_axi_slave/dut/inv_done" \
           "/tb_aes_axi_slave/dut/awaddr_reg\[6:0\]" \
           "/tb_aes_axi_slave/dut/awaddr_valid" \
           "/tb_aes_axi_slave/dut/wdata_reg\[31:0\]" \
           "/tb_aes_axi_slave/dut/wstrb_reg\[3:0\]" \
           "/tb_aes_axi_slave/dut/wdata_valid"
wvSetPosition -win $_nWave2 {("G1" 0)}
wvSetPosition -win $_nWave2 {("G1" 73)}
wvSetPosition -win $_nWave2 {("G1" 73)}
srcSignalView -off
verdiDockWidgetMaximize -dock windowDock_nWave_2
verdiSetActWin -win $_nWave2
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollUp -win $_nWave2 45
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvZoomAll -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
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
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
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
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollDown -win $_nWave2 0
wvScrollUp -win $_nWave2 45
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvSetCursor -win $_nWave2 2556194867.886179 -snap {("G1" 3)}
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 2
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 2
wvScrollDown -win $_nWave2 2
wvZoomIn -win $_nWave2
wvSetCursor -win $_nWave2 2456015244.029330 -snap {("G1" 53)}
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 0
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
