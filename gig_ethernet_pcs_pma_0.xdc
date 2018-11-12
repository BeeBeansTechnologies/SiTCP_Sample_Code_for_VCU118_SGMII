


###############################################
##Rx Elastic Buffer Constraints 
###############################################
set_max_delay -from [get_cells -hier -filter {name =~ */rx_elastic_buffer_inst/wr_addr_*_reg[*]}] -to [get_pins -hier -filter { name =~ *reclock_wr_addrgray[*].sync_wr_addrgray/data_sync*/D}] 8 -datapath_only 
set_max_delay -from [get_cells -hier -filter {name =~  */rx_elastic_buffer_inst/rd_addr_*_reg[*]}] -to [get_pins -hier -filter { name =~ *reclock_rd_addrgray[*].sync_rd_addrgray/data_sync*/D}] 8 -datapath_only
set_false_path  -from [get_pins  -hierarchical -filter { name =~  */rx_elastic_buffer_inst/initialize_ram_complete_reg/C}] -to [get_pins -hierarchical -filter { name =~ *rx_elastic_buffer_inst/sync_initialize_ram_comp/data_sync_reg*/D } ] 

set_false_path -from [get_clocks -of_objects  [get_cells -hier -filter {name =~ */rx_elastic_buffer_inst/wr_addr_*_reg[*]}]] -to [get_pins -hierarchical -filter { name =~ */rx_elastic_buffer_inst/rd_data_reg[*]/D}]


# false path constraints to async inputs coming directly to synchronizer
set_false_path -to [get_pins -hier -filter {name =~ *SYNC_*/data_sync*/D }]
set_false_path -to [get_pins -hier -filter {name =~ *SYNC_*/reset_sync*/PRE }]
set_false_path -to [get_pins -hier -filter { name =~ */reset_sync_*/*/PRE}]

set_false_path -to [get_pins -hier -filter {name =~ */IntActTx_TByteinPip_reg[0]/D}]
set_false_path -to [get_pins -hier -filter {name =~ */gen_io_logic/IntActTx_TByteinPip_reg[*]/CLR}]
set_false_path -to [get_pins -hier -filter { name =~ */BaseX_Byte_I_Tx_Nibble/Gen_1.Nibble_I_BitsliceCntrl/TBYTE_IN[*]}]
set_false_path -from [get_pins -hier -filter {name =~ */*ram_inst*/RAM*/CLK}] -to [get_pins -hier -filter {name =~ */gb_out_inst/DataOut_reg[*]/D}]
set_false_path -from [get_pins -hier -filter {name =~ */*ram_inst*/RAM*/CLK}] -to [get_pins -hier -filter {name =~  */gb_out_inst/IntLastOut_reg[*]/D}]
set_false_path -from [get_pins -hier -filter {name =~ */gb_out_inst/IntRdEna_reg/C}] -to [get_pins -hier -filter {name  =~  */gb_out_inst/IntRdEna_Sync_reg[*]/D}]
set_false_path -to [get_pins -hier -filter {name  =~  */gb_out_inst/Reset_Sync_reg[*]/PRE}]


set_false_path -to [get_pins -hier -filter {name =~ */*sync_speed_10*/data_sync*/D }]
set_false_path -to [get_pins -hier -filter {name =~ */gen_lvds_transceiver.gen_lvds_transceiver_logic[*].lvds_transceiver_inst/serdes_1_to_10_i/IntRx_BtVal_reg[*]/D}]
