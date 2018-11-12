
set_property PACKAGE_PIN AY24 [get_ports "CLK_125MHZ_P"]
set_property IOSTANDARD LVDS [get_ports "CLK_125MHZ_P"]
set_property PACKAGE_PIN AY23 [get_ports "CLK_125MHZ_N"]
set_property IOSTANDARD LVDS [get_ports "CLK_125MHZ_N"]

#SGMII_TX
set_property PACKAGE_PIN AU21 [get_ports "PHY1_SGMII_IN_P"]
set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports "PHY1_SGMII_IN_P"]
set_property PACKAGE_PIN AV21 [get_ports "PHY1_SGMII_IN_N"]
set_property IOSTANDARD DIFF_HSTL_I_18 [get_ports "PHY1_SGMII_IN_N"]

#SGMII_RX
set_property PACKAGE_PIN AT22 [get_ports "SGMII_CLK_P"]
set_property IOSTANDARD DIFF_HSTL_I_DCI_18 [get_ports "SGMII_CLK_P"]
set_property PACKAGE_PIN AU22 [get_ports "SGMII_CLK_N"]
set_property IOSTANDARD DIFF_HSTL_I_DCI_18 [get_ports "SGMII_CLK_N"]

set_property PACKAGE_PIN AU24 [get_ports "PHY1_SGMII_OUT_P"]
set_property IOSTANDARD DIFF_HSTL_I_DCI_18 [get_ports "PHY1_SGMII_OUT_P"]
set_property PACKAGE_PIN AV24 [get_ports "PHY1_SGMII_OUT_N"]
set_property IOSTANDARD DIFF_HSTL_I_DCI_18 [get_ports "PHY1_SGMII_OUT_N"]

set_property DCI_CASCADE {64} [get_iobanks 65]

set_property PACKAGE_PIN BA21 [get_ports "PHY1_RESET_B"]
set_property IOSTANDARD LVCMOS18 [get_ports "PHY1_RESET_B"]

set_property PACKAGE_PIN AV23 [get_ports "PHY1_MDC"]
set_property IOSTANDARD LVCMOS18 [get_ports "PHY1_MDC"]
set_property PACKAGE_PIN AR23 [get_ports "PHY1_MDIO_IN"]
set_property IOSTANDARD LVCMOS18 [get_ports "PHY1_MDIO_IN"]

#IIC
set_property PACKAGE_PIN AM24 [get_ports "IIC_MAIN_SCL"]
set_property IOSTANDARD LVCMOS18 [get_ports "IIC_MAIN_SCL"]
set_property PACKAGE_PIN AL24 [get_ports "IIC_MAIN_SDA"]
set_property IOSTANDARD LVCMOS18 [get_ports "IIC_MAIN_SDA"]

#GPIO_DIP_SW
set_property PACKAGE_PIN B17 [get_ports "GPIO_DIP_SW[0]"]
set_property IOSTANDARD LVCMOS12 [get_ports "GPIO_DIP_SW[0]"]
set_property PACKAGE_PIN G16 [get_ports "GPIO_DIP_SW[1]"]
set_property IOSTANDARD LVCMOS12 [get_ports "GPIO_DIP_SW[1]"]
set_property PACKAGE_PIN J16 [get_ports "GPIO_DIP_SW[2]"]
set_property IOSTANDARD LVCMOS12 [get_ports "GPIO_DIP_SW[2]"]
set_property PACKAGE_PIN D21 [get_ports "GPIO_DIP_SW[3]"]
set_property IOSTANDARD LVCMOS12 [get_ports "GPIO_DIP_SW[3]"]

# GPIO_LEDs
set_property PACKAGE_PIN AT32 [get_ports "GPIO_LED[0]"]
set_property IOSTANDARD LVCMOS12 [get_ports "GPIO_LED[0]"]
set_property PACKAGE_PIN AV34 [get_ports "GPIO_LED[1]"]
set_property IOSTANDARD LVCMOS12 [get_ports "GPIO_LED[1]"]
set_property PACKAGE_PIN AY30 [get_ports "GPIO_LED[2]"]
set_property IOSTANDARD LVCMOS12 [get_ports "GPIO_LED[2]"]
set_property PACKAGE_PIN BB32 [get_ports "GPIO_LED[3]"]
set_property IOSTANDARD LVCMOS12 [get_ports "GPIO_LED[3]"]
set_property PACKAGE_PIN BF32 [get_ports "GPIO_LED[4]"]
set_property IOSTANDARD LVCMOS12 [get_ports "GPIO_LED[4]"]
set_property PACKAGE_PIN AU37 [get_ports "GPIO_LED[5]"]
set_property IOSTANDARD LVCMOS12 [get_ports "GPIO_LED[5]"]
set_property PACKAGE_PIN AV36 [get_ports "GPIO_LED[6]"]
set_property IOSTANDARD LVCMOS12 [get_ports "GPIO_LED[6]"]
set_property PACKAGE_PIN BA37 [get_ports "GPIO_LED[7]"]
set_property IOSTANDARD LVCMOS12 [get_ports "GPIO_LED[7]"]

#Clock Constraints
create_clock -period 8.000 [get_ports CLK_125MHZ_P] -waveform {0.000 4.000}
#create_clock -period 8.000 [get_ports CLK_125MHZ_N] -waveform {0.000 4.000}
create_clock -period 1.600 [get_ports SGMII_CLK_P] -waveform {0.000 0.800}
#create_clock -period 1.600 [get_ports SGMII_CLK_N] -waveform {0.000 0.800}

#MISC
set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]


