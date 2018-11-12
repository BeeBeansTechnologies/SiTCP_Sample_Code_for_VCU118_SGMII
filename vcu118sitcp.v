`default_nettype none

module vcu118sitcp (
	input	wire			CLK_125MHZ_P		,
	input	wire			CLK_125MHZ_N		,
	input	wire			SGMII_CLK_P			,
	input	wire			SGMII_CLK_N			,
	output	wire			PHY1_SGMII_IN_P		,	// out	: Tx signal line
	output	wire			PHY1_SGMII_IN_N		,	// out	: 
	input	wire			PHY1_SGMII_OUT_P	,	// in	: Rx signal line
	input	wire			PHY1_SGMII_OUT_N	,	// in	: 
	output	wire			PHY1_RESET_B		,	// out	: PHY Rst
	// Management IF
	output	wire			PHY1_MDC			,
	inout	wire			PHY1_MDIO_IN		,
	// connect EEPROM
	inout	wire			IIC_MAIN_SDA		,
	output	wire			IIC_MAIN_SCL		,
	//DIPswitch
	input	wire	[ 3:0]	GPIO_DIP_SW			,
	// reset switch
	output	wire	[ 7:0]	GPIO_LED			
);

	wire			CLK_125M;
	wire			SYSCLK_200M;
	reg				SYS_RSTn;
	reg		[29:0]	INICNT;
	wire			SGMII_CLK;		
	wire			GMII_TX_EN;		// out: Tx enable
	wire	[7:0]	GMII_TXD;		// out: Tx data[7:0]
	wire			GMII_TX_ER;		// out: TX error
	wire			GMII_RX_CLK;	// in : Rx clock
	wire			GMII_RX_DV;		// in : Rx data valid
	wire	[7:0]	GMII_RXD;		// in : Rx data[7:0]
	wire			GMII_RX_ER;		// in : Rx error
	wire			SiTCP_RST;		// out: Reset for SiTCP and related circuits
	wire			TCP_CLOSE_REQ;	// out: Connection close request
	wire	[15:0]	STATUS_VECTOR;	// out: Core status.[15:0]	
	wire 	[7:0]	TCP_RX_DATA;
	wire 	[7:0]	TCP_TX_DATA;
	wire 			TCP_RX_WR;
	wire 			TCP_TX_FULL;
	wire			TCP_OPEN_ACK;
	wire	[11:0]	FIFO_DATA_COUNT;
	wire			FIFO_RD_VALID;
	
	wire	[31:0]	RBCP_ADDR;
	wire	[7:0]	RBCP_WD;
	wire			RBCP_WE;
	wire			RBCP_RE;
	wire			RBCP_ACK;
	wire	[ 7:0]	RBCP_RD;

	wire			Duplex_mode;
	wire	[ 1:0]	LED_LINKSpeed;
	wire			SGMII_CLK_EN;
	reg		[ 1:0]	SGMII_LINK;
	wire			MMCM_CLKFB;
	wire			MMCM_LOCKED;
	wire			EEPROM_CS;
	wire			EEPROM_SK;
	wire			EEPROM_DI;
	wire			EEPROM_DO;
	wire			SGMII_125M_OUT;
	wire			RST_EEPROM;
	wire			GMII_MDIO_OE;
	wire			GMII_MDC;
	wire			GMII_MDIO_OUT;
	wire			MUX_MDIO_OE;
	wire			MUX_MDIO_OUT;
	wire			PHY_Link;
	wire			LINK_SYNC;
	wire			LINK_STATUS;
	reg		[ 8:0]	MDIO_DVCT;
	reg		[10:0]	MDIO_EXCT;
	reg				SGMII_MDC;
	reg		[31:0]	SGMII_MDIO;
	reg		[ 1:0]	SGMII_MDOE;
	reg		[20:0]	SGMII_RCNT;
	reg				SGMII_RESET;
	reg		[31:0]	SEL_CMD;
	reg				LOD_CMD;
	wire			TX_PLL_LOCKED;
	wire			RX_PLL_LOCKED;
	wire			ALL_PLL_LOCKED;
	wire	[31:0]	MDIO_CMD[0:8];


//------------------------------------------------------------------------------
// MMCM
//------------------------------------------------------------------------------
	IBUFDS	pre_clk_ibuf(.O(CLK_125M),.I(CLK_125MHZ_P),.IB(CLK_125MHZ_N));


	MMCME3_BASE	#(
		.BANDWIDTH			("OPTIMIZED"),
		.CLKFBOUT_MULT_F	(8.000),
		.CLKFBOUT_PHASE		(0.000),
		.CLKIN1_PERIOD		(8.000),
		.CLKOUT0_DIVIDE_F	(5.000),
		.CLKOUT0_DUTY_CYCLE	(0.500),
		.CLKOUT0_PHASE		(0.000),
		.DIVCLK_DIVIDE		(1),
		.REF_JITTER1		(0.010)
	)
	MMCME3_BASE(
		.CLKFBOUT	(MMCM_CLKFB),
		.CLKOUT0	(SYSCLK_200M),
		.LOCKED		(MMCM_LOCKED),
		.CLKFBIN	(MMCM_CLKFB),
		.CLKIN1		(CLK_125M),
		.PWRDWN		(1'b0),
		.RST		(1'b0)
	);


	always@(posedge SYSCLK_200M)begin
		if (~MMCM_LOCKED) begin
			INICNT[29:0]	<=	30'd0;
			SYS_RSTn		<=	1'b0;
		end else begin
			INICNT[29:0]		<=	INICNT[29]? INICNT[29:0]:	(INICNT[29:0] + 30'd1);
			SYS_RSTn			<=	INICNT[29];
			SGMII_LINK[1:0]			<=	(
				((STATUS_VECTOR[11:10]==2'b10)?	2'b00:	2'b00)|
				((STATUS_VECTOR[11:10]==2'b01)?	2'b11:	2'b00)|
				((STATUS_VECTOR[11:10]==2'b00)?	2'b10:	2'b00)
			);
		end
	end

	assign	ALL_PLL_LOCKED		= TX_PLL_LOCKED & RX_PLL_LOCKED;
	assign	Duplex_mode			= LINK_STATUS?	STATUS_VECTOR[12]:		1'b0;
	assign	LED_LINKSpeed[1:0]	= LINK_STATUS?	STATUS_VECTOR[11:10]:	2'b00;
	assign	PHY_Link			= STATUS_VECTOR[7] & LINK_STATUS;
	assign	LINK_SYNC			= STATUS_VECTOR[1] & ALL_PLL_LOCKED;
	assign	LINK_STATUS			= STATUS_VECTOR[0] & ALL_PLL_LOCKED;

	assign	GPIO_LED[7:5]	= {SGMII_RESET, LED_LINKSpeed[1:0]};
	assign	GPIO_LED[4:2]	= {PHY_Link, LINK_SYNC, LINK_STATUS};
	assign	GPIO_LED[1:0]	= {TX_PLL_LOCKED, RX_PLL_LOCKED};


	AT93C46_IIC #(
		.PCA9548_AD			(7'b1110_101),			// PCA9548 Device Address (VCU118 TCA9548(U80) setting)
		.PCA9548_SL			(8'b0000_1000),			// PCA9548 Select code (Ch3,Ch4 enable)
		.IIC_MEM_AD			(7'b1010_100),			// IIC Memory Dvice Address (VCU118 M24C08(U12) setting)
		.FREQUENCY			(8'd200),				// CLK_IN Frequency  > 10MHz
		.DRIVE				(4),					// Output Buffer Strength
		.IOSTANDARD			("LVCMOS18"),			// I/O Standard
		.SLEW				("SLOW")				// Outputbufer Slew rate
	)
	AT93C46_IIC(
		.CLK_IN				(SYSCLK_200M),			// System Clock
		.RESET_IN			(~SYS_RSTn),			// Reset
		.IIC_INIT_OUT		(RST_EEPROM),			// IIC , AT93C46 Initialize (0=Initialize End)
		.EEPROM_CS_IN		(EEPROM_CS),			// AT93C46 Chip select
		.EEPROM_SK_IN		(EEPROM_SK),			// AT93C46 Serial data clock
		.EEPROM_DI_IN		(EEPROM_DI),			// AT93C46 Serial write data (Master to Memory)
		.EEPROM_DO_OUT		(EEPROM_DO),			// AT93C46 Serial read data(Slave to Master)
		.INIT_ERR_OUT		(),						// PCA9548 Initialize Error
		.IIC_REQ_IN			(1'b0),					// IIC ch0 Request
		.IIC_NUM_IN			(8'h00),				// IIC ch0 Number of Access[7:0]	0x00:1Byte , 0xff:256Byte
		.IIC_DAD_IN			(7'b0),					// IIC ch0 Device Address[6:0]
		.IIC_ADR_IN			(8'b0),					// IIC ch0 Word Address[7:0]
		.IIC_RNW_IN			(1'b0),					// IIC ch0 Read(1) / Write(0)
		.IIC_WDT_IN			(8'b0),					// IIC ch0 Write Data[7:0]
		.IIC_RAK_OUT		(),						// IIC ch0 Request Acknowledge
		.IIC_WDA_OUT		(),						// IIC ch0 Wite Data Acknowledge(Next Data Request)
		.IIC_WAE_OUT		(),						// IIC ch0 Wite Last Data Acknowledge(same as IIC_WDA timing)
		.IIC_BSY_OUT		(),						// IIC ch0 Busy
		.IIC_RDT_OUT		(),						// IIC ch0 Read Data[7:0]
		.IIC_RVL_OUT		(),						// IIC ch0 Read Data Valid
		.IIC_EOR_OUT		(),						// IIC ch0 End of Read Data(same as IIC_RVL timing)
		.IIC_ERR_OUT		(),						// IIC ch0 Error Detect
		// Device Interface
		.IIC_SCL_OUT		(IIC_MAIN_SCL),			// IIC Clock
		.IIC_SDA_IO			(IIC_MAIN_SDA)			// IIC Data
	);

	assign	PHY1_MDC		= (SGMII_RESET & ~SiTCP_RST)?		SGMII_MDC:			GMII_MDC;
	assign	MUX_MDIO_OE		= (SGMII_RESET & ~SiTCP_RST)?		SGMII_MDOE[1]:		GMII_MDIO_OE;
	assign	MUX_MDIO_OUT	= (SGMII_RESET & ~SiTCP_RST)?		SGMII_MDIO[31]:		GMII_MDIO_OUT;
	assign	PHY1_MDIO_IN	= MUX_MDIO_OE?		MUX_MDIO_OUT:		1'bz;


	WRAP_SiTCP_GMII_XCVUP_32K	#(.TIM_PERIOD(8'd200))	SiTCP(
		.CLK				(SYSCLK_200M   		),	// in	: System Clock >129MHz
		.RST				(RST_EEPROM			),	// in	: System reset
	// Configuration parameters
		.FORCE_DEFAULTn		(GPIO_DIP_SW[0]		),	// in	: Load default parameters
		.EXT_IP_ADDR		(32'd0				),	// in	: IP address[31:0]
		.EXT_TCP_PORT		(16'd0				),	// in	: TCP port #[15:0]
		.EXT_RBCP_PORT		(16'd0				),	// in	: RBCP port #[15:0]
		.PHY_ADDR			(5'b00011			),	// in	: PHY-device MIF address[4:0]
	// EEPROM
		.EEPROM_CS			(EEPROM_CS			),	// out	: Chip select
		.EEPROM_SK			(EEPROM_SK			),	// out	: Serial data clock
		.EEPROM_DI			(EEPROM_DI			),	// out	: Serial write data
		.EEPROM_DO			(EEPROM_DO			),	// in	: Serial read data
		// user data, intialial values are stored in the EEPROM, 0xFFFF_FC3C-3F
		.USR_REG_X3C		(					),	// out	: Stored at 0xFFFF_FF3C
		.USR_REG_X3D		(					),	// out	: Stored at 0xFFFF_FF3D
		.USR_REG_X3E		(					),	// out	: Stored at 0xFFFF_FF3E
		.USR_REG_X3F		(					),	// out	: Stored at 0xFFFF_FF3F
	// MII interface
		.GMII_RSTn			(PHY1_RESET_B		),	// out	: PHY reset Active low
		.GMII_1000M			(1'b1				),	// in	: GMII mode (0:MII, 1:GMII)
		// TX
		.GMII_TX_CLK		(SGMII_CLK			),	// in	: Tx clock
		.GMII_TX_EN			(GMII_TX_EN			),	// out	: Tx enable
		.GMII_TXD			(GMII_TXD[7:0]		),	// out	: Tx data[7:0]
		.GMII_TX_ER			(GMII_TX_ER			),	// out	: TX error
		// RX
		.GMII_RX_CLK		(SGMII_CLK			),	// in	: Rx clock
		.GMII_RX_DV			(GMII_RX_DV			),	// in	: Rx data valid
		.GMII_RXD			(GMII_RXD[7:0]		),	// in	: Rx data[7:0]
		.GMII_RX_ER			(GMII_RX_ER			),	// in	: Rx error
		.GMII_CRS			(1'b0				),	// in	: Carrier sense
		.GMII_COL			(1'b0				),	// in	: Collision detected
		// Management IF
		.GMII_MDC			(GMII_MDC			),	// out	: Clock for MDIO
		.GMII_MDIO_IN		(PHY1_MDIO_IN		),	// in	: Data
		.GMII_MDIO_OUT		(GMII_MDIO_OUT		),	// out	: Data
		.GMII_MDIO_OE		(GMII_MDIO_OE		),	// out	: MDIO output enable
	// User I/F
		.SiTCP_RST			(SiTCP_RST			),	// out	: Reset for SiTCP and related circuits
		// TCP connection control
		.TCP_OPEN_REQ		(1'b0				),	// in	: Reserved input, shoud be 0
		.TCP_OPEN_ACK		(TCP_OPEN_ACK		),	// out	: Acknowledge for open (=Socket busy)
		.TCP_ERROR			(					),	// out	: TCP error, its active period is equal to MSL
		.TCP_CLOSE_REQ		(TCP_CLOSE_REQ		),	// out	: Connection close request
		.TCP_CLOSE_ACK		(TCP_CLOSE_REQ		),	// in	: Acknowledge for closing
		// FIFO I/F
		.TCP_RX_WC			({4'b1111,FIFO_DATA_COUNT[11:0]}),	// in	: Rx FIFO write count[15:0] (Unused bits should be set 1)
		.TCP_RX_WR			(TCP_RX_WR			),	// out	: Write enable
		.TCP_RX_DATA		(TCP_RX_DATA[7:0]	),	// out	: Write data[7:0]
		.TCP_TX_FULL		(TCP_TX_FULL		),	// out	: Almost full flag
		.TCP_TX_WR			(FIFO_RD_VALID		),	// in	: Write enable
		.TCP_TX_DATA		(TCP_TX_DATA[7:0]	),	// in	: Write data[7:0]
		// RBCP
		.RBCP_ACT			(					),	// out	: RBCP active
		.RBCP_ADDR			(RBCP_ADDR[31:0]	),	// out	: Address[31:0]
		.RBCP_WD			(RBCP_WD[7:0]		),	// out	: Data[7:0]
		.RBCP_WE			(RBCP_WE			),	// out	: Write enable
		.RBCP_RE			(RBCP_RE			),	// out	: Read enable
		.RBCP_ACK			(RBCP_ACK			),	// in	: Access acknowledge
		.RBCP_RD			(RBCP_RD[7:0]		)	// in	: Read data[7:0]
	);	

// FIFO
	fifo_generator_v11_0 fifo_generator_v11_0(
		.clk				(SYSCLK_200M		),	//in	:
		.rst				(~TCP_OPEN_ACK		),	//in	:
		.din				(TCP_RX_DATA[7:0]	),	//in	:
		.wr_en				(TCP_RX_WR			),	//in	:
		.full				(					),	//out	:
		.dout				(TCP_TX_DATA[7:0]	),	//out	:
		.valid				(FIFO_RD_VALID		),	//out	:active h
		.rd_en				(~TCP_TX_FULL		),	//in	:
		.empty				(					),	//out	:
		.data_count			(FIFO_DATA_COUNT[11:0])	//out	:
	);


	BUFGCE	BUF_SGMII(.O(SGMII_CLK), .CE(SGMII_CLK_EN), .I(SGMII_125M_OUT));


	WRAP_gig_ethernet_pcs_pma	WRAP_gig_ethernet_pcs_pma_inst(
	// LVDS transceiver Interface
	//---------------------------
		.PHY1_SGMII_IN_P		(PHY1_SGMII_IN_P	),	// out	: Tx signal line
		.PHY1_SGMII_IN_N		(PHY1_SGMII_IN_N	),	// out	: 
		.PHY1_SGMII_OUT_P		(PHY1_SGMII_OUT_P	),	// in	: Rx signal line
		.PHY1_SGMII_OUT_N		(PHY1_SGMII_OUT_N	),	// in	: 
		.GMII_TXD				(GMII_TXD[7:0]		),	// in:	[7:0] Transmit data from client MAC.
		.GMII_TX_EN				(GMII_TX_EN			),	// in:	Transmit control signal from client MAC.
		.GMII_TX_ER				(GMII_TX_ER			),	// in:	Transmit control signal from client MAC.
		.GMII_RXD				(GMII_RXD[7:0]		),	// out:	[7:0] Received Data to client MAC.
		.GMII_RX_DV				(GMII_RX_DV			),	// out:	Received control signal to client MAC.
		.GMII_RX_ER				(GMII_RX_ER			),	// out:	Received control signal to client MAC.
		.SGMII_CLK_EN			(SGMII_CLK_EN		),
	// Speed Control
		//1 Gbps Operation
		//	set speed_is_10_100 to logic 0
		//100 Mbps Operation
		//	set speed_is_10_100 to logic 1
		//	set speed_is_100 to logic 1
		//10 Mbps Operation
		//	set speed_is_10_100 to logic 1
		//	set speed_is_100 to logic 0
		.SGMII_LINK				(SGMII_LINK[1:0]	),
	// General IO's
	//-------------
		// status vector
			// [15:14]	:	Pause 
			// [13] 	:	Remote Fault
			// [12] 	:	Duplex mode(1:Full, 0:Half)
			// [11:10]	:	Speed(11:Reserved, 10:1000Mb/s, 01:100Mb/s, 00:10Mb/s)
			// [ 9: 8]	:	Remote Fault Encoding
			// [ 7]		:	PHY Link Status (SGMII mode only)
			// [ 6]		:	RXNOTINTABLE
			// [ 5]		:	RXDISPERR
			// [ 4]		:	RUDI(INVALID)
			// [ 3]		:	RUDI(/I/)
			// [ 2]		:	RUDI(/C/)
			// [ 1]		:	Link Synchronization
			// [ 0]		:	Link Status
		.STATUS_VECTOR			(STATUS_VECTOR[15:0]),
	// Management: Alternative to MDIO Interface
	//------------------------------------------
		.SGMII_CLK_P			(SGMII_CLK_P		),
		.SGMII_CLK_N			(SGMII_CLK_N		),
		.SGMII_125M_OUT			(SGMII_125M_OUT		),
		.RX_PLL_LOCKED			(RX_PLL_LOCKED		),
		.TX_PLL_LOCKED			(TX_PLL_LOCKED		),
		.SGMII_RESET			(SGMII_RESET		)
	);


//------------------------------------------------------------------------------
//     MDIO CONTROL (DP83867)
//------------------------------------------------------------------------------

	assign	MDIO_CMD[8]	= 32'hffff_ffff;
	assign	MDIO_CMD[7]	= {2'b01,2'b01,5'b00011,5'h0d,2'b10,16'h001f};	// REGCR(0x0d) <= 0x001f
	assign	MDIO_CMD[6]	= {2'b01,2'b01,5'b00011,5'h0e,2'b10,16'h00d3};	// REGAR(0x0e) <= 0x00d3 SGMII Control Register 1 (SGMIICTL1)
	assign	MDIO_CMD[5]	= {2'b01,2'b01,5'b00011,5'h0d,2'b10,16'h401f};	// REGCR(0x0d) <= 0x401f
	assign	MDIO_CMD[4]	= {2'b01,2'b01,5'b00011,5'h0e,2'b10,16'h4000};	// REGAR(0x0e) <= 0x4000 SGMII_TYPE = 6-wire mode

	assign	MDIO_CMD[3]	= {2'b01,2'b01,5'b00011,5'h0d,2'b10,16'h001f};	// REGCR(0x0d) <= 0x001f
	assign	MDIO_CMD[2]	= {2'b01,2'b01,5'b00011,5'h0e,2'b10,16'h0031};	// REGAR(0x0e) <= 0x0031 Configuration Register 4 (CFG4),
	assign	MDIO_CMD[1]	= {2'b01,2'b01,5'b00011,5'h0d,2'b10,16'h401f};	// REGCR(0x0d) <= 0x401f
	assign	MDIO_CMD[0]	= {2'b01,2'b01,5'b00011,5'h0e,2'b10,16'h0050};	// REGAR(0x0e) <= 0x0050 SGMII_AUTONEG_TIMER = 800us

	always@(posedge SYSCLK_200M or posedge SiTCP_RST)begin
		if (SiTCP_RST) begin
			MDIO_DVCT[8:0]		<= 9'd198;
			MDIO_EXCT[10:0]		<= {1'b1,4'h8,6'h3f};
			SGMII_MDC			<= 1'b1;
			SGMII_MDIO[31:0]	<= 32'hffff_ffff;
			SGMII_MDOE[1:0]		<= 2'b00;
			SGMII_RCNT[20:0]	<= 21'd0;
			SGMII_RESET			<= 1'b1;
		end else begin
			MDIO_DVCT[8:0]		<= MDIO_DVCT[8]?	9'd198:		(MDIO_DVCT[8:0] -  9'd1);
			if (MDIO_DVCT[8]) begin
				MDIO_EXCT[10:0]		<= SGMII_MDC?	MDIO_EXCT[10:0]:		(MDIO_EXCT[10:0] - 10'd1);
				SGMII_MDC			<= SGMII_MDC ^ MDIO_EXCT[10];
				SGMII_MDIO[31:0]	<= SGMII_MDC?		(LOD_CMD?		SEL_CMD[31:0]:			{SGMII_MDIO[30:0],1'b1}):		SGMII_MDIO[31:0];
				SGMII_MDOE[0]		<= SGMII_MDOE[0] | (SGMII_MDC & LOD_CMD);
				SGMII_MDOE[1]		<= SGMII_MDOE[1] | (SGMII_MDC & LOD_CMD & SGMII_MDOE[0]);
			end
			SGMII_RCNT[20:0]	<=  SGMII_RCNT[20]?		SGMII_RCNT[20:0]:	(SGMII_RCNT[20:0] + (MDIO_EXCT[10]?	21'd0:	21'd1));
			SGMII_RESET			<=  SGMII_RESET & ~SGMII_RCNT[20];
		end
	end

	always@(posedge SYSCLK_200M)begin
		SEL_CMD[31:0]	<= (
			((MDIO_EXCT[9:6] == 4'd8)?		MDIO_CMD[8]:	32'hffff_ffff)&
			((MDIO_EXCT[9:6] == 4'd7)?		MDIO_CMD[7]:	32'hffff_ffff)&
			((MDIO_EXCT[9:6] == 4'd6)?		MDIO_CMD[6]:	32'hffff_ffff)&
			((MDIO_EXCT[9:6] == 4'd5)?		MDIO_CMD[5]:	32'hffff_ffff)&
			((MDIO_EXCT[9:6] == 4'd4)?		MDIO_CMD[4]:	32'hffff_ffff)&
			((MDIO_EXCT[9:6] == 4'd3)?		MDIO_CMD[3]:	32'hffff_ffff)&
			((MDIO_EXCT[9:6] == 4'd2)?		MDIO_CMD[2]:	32'hffff_ffff)&
			((MDIO_EXCT[9:6] == 4'd1)?		MDIO_CMD[1]:	32'hffff_ffff)&
			((MDIO_EXCT[9:6] == 4'd0)?		MDIO_CMD[0]:	32'hffff_ffff)
		);
		LOD_CMD			<= (MDIO_EXCT[5:0] == 6'h30);
	end
//------------------------------------------------------------------------------
//     RBCP	TEST PROGRAM
//------------------------------------------------------------------------------
	
	RBCP	RBCP(
		.CLK_200M	(SYSCLK_200M),		//in
		.DIP		(GPIO_DIP_SW[3:1]),	//in
		.RBCP_WE	(RBCP_WE),			//in
		.RBCP_RE	(RBCP_RE),			//in
		.RBCP_WD	(RBCP_WD[7:0]),		//in
		.RBCP_ADDR	(RBCP_ADDR),		//in
		.RBCP_RD	(RBCP_RD[7:0]),		//out
		.RBCP_ACK	(RBCP_ACK)			//out
	
	);

endmodule

`default_nettype wire
