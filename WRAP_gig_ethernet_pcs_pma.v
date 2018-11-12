`default_nettype none

module WRAP_gig_ethernet_pcs_pma (
	output	wire			PHY1_SGMII_IN_P		,	// out	: Tx signal line
	output	wire			PHY1_SGMII_IN_N		,	// out	: 
	input	wire			PHY1_SGMII_OUT_P	,	// in	: Rx signal line
	input	wire			PHY1_SGMII_OUT_N	,	// in	: 
	input	wire	[ 7:0]	GMII_TXD			,	// in:	[7:0] Transmit data from client MAC.
	input	wire			GMII_TX_EN			,	// in:	Transmit control signal from client MAC.
	input	wire			GMII_TX_ER			,	// in:	Transmit control signal from client MAC.
	output	wire	[ 7:0]	GMII_RXD			,	// out:	[7:0] Received Data to client MAC.
	output	wire			GMII_RX_DV			,	// out:	Received control signal to client MAC.
	output	wire			GMII_RX_ER			,	// out:	Received control signal to client MAC.
	output	wire			SGMII_CLK_EN		,
	input	wire	[ 1:0]	SGMII_LINK			,
	output	wire	[15:0]	STATUS_VECTOR		,
	input	wire			SGMII_CLK_P			,
	input	wire			SGMII_CLK_N			,
	output	wire			SGMII_125M_OUT		,
	output	wire			RX_PLL_LOCKED		,
	output	wire			TX_PLL_LOCKED		,
	input	wire			SGMII_RESET
);


endmodule

`default_nettype wire
