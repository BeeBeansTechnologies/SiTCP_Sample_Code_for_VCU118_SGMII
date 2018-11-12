module
	RBCP(
		input	wire		CLK_200M,	//in
		input	wire[ 2:0]	DIP,		//in
		input	wire		RBCP_WE,	//in
		input	wire		RBCP_RE,	//in
		input	wire[ 7:0]	RBCP_WD,	//in
		input	wire[31:0]	RBCP_ADDR,	//in
		output	reg	[ 7:0]	RBCP_RD,	//out
		output	reg			RBCP_ACK	//out
	);
	reg		[ 7:0]	x00Reg;
	reg		[ 7:0]	x01Reg;
	reg		[ 7:0]	x02Reg;
	reg		[ 7:0]	x03Reg;
	//for pipeline
	reg				P1WE;
	reg				P0WE;
	reg				P1RE;
	reg				P0RE;
	reg		[15:0]	ADDR_U;//アドレス処理
	reg		[13:0]	ADDR_D;//アドレス処理
	reg		[ 1:0]	P0RE_ADDR;//アドレス下位2bit
	reg		[ 1:0]	P1RE_ADDR;//アドレス下位2bit
	reg		[ 1:0]	ADDR_RW;//書き込み読み込みアドレス条件
	reg				WR_ADDR;//ACK返答用
	always@(posedge CLK_200M )begin
		//パイプライン化
		//一段目
		P0WE			<=	RBCP_WE;
		P0RE			<=	RBCP_RE;
		ADDR_U[15:0]	<=	RBCP_ADDR[31:16];
		ADDR_D[13:0]	<=	RBCP_ADDR[15: 2];
		P0RE_ADDR[ 1:0]	<=	RBCP_ADDR[ 1: 0];
		//二段目
		P1WE			<=	P0WE;
		P1RE			<=	P0RE;
		P1RE_ADDR[1:0]	<=	P0RE_ADDR[1:0];
		ADDR_RW[1]		<=	(ADDR_U[15:0] == 16'd0);
		ADDR_RW[0]		<=	(ADDR_D[13:0] == 14'd0);
		//三段目
		//レジスタへの記述
		x00Reg[7:0]	<=	{5'd0,DIP[2:0]};//read DIPswitch
		x01Reg[7:0]	<=	((&ADDR_RW[1:0]) & (P1RE_ADDR[1:0] == 2'd1)& P1WE)?	RBCP_WD[7:0]:x01Reg[7:0];
		x02Reg[7:0]	<=	((&ADDR_RW[1:0]) & (P1RE_ADDR[1:0] == 2'd2)& P1WE)?	RBCP_WD[7:0]:x02Reg[7:0];
		x03Reg[7:0]	<=	((&ADDR_RW[1:0]) & (P1RE_ADDR[1:0] == 2'd3)& P1WE)?	RBCP_WD[7:0]:x03Reg[7:0];//write value in reg

		//レジスタ値読み出し
		RBCP_RD[ 7:0] 	<=	(
			(((&ADDR_RW[1:0]) & P1RE_ADDR[1:0] == 2'd0)?	x00Reg[7:0]:8'd0)|
			(((&ADDR_RW[1:0]) & P1RE_ADDR[1:0] == 2'd1)?	x01Reg[7:0]:8'd0)|
			(((&ADDR_RW[1:0]) & P1RE_ADDR[1:0] == 2'd2)?	x02Reg[7:0]:8'd0)|
			(((&ADDR_RW[1:0]) & P1RE_ADDR[1:0] == 2'd3)?	x03Reg[7:0]:8'd0)
		);
		//ACK返答
		RBCP_ACK  	<= 	(&ADDR_RW[1:0]) & (P1RE | P1WE);
	end
endmodule

	