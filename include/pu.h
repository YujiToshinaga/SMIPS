/*----------------------------------------------------------------------------*
 *	SMIPS
 *
 *	File	: l2c.v
 *	Date	: 2012-05-05T11:41:11+9:00
 *	Author	: toshinaga
 *
 *	Description :
 *		***
 *----------------------------------------------------------------------------*/

`ifndef __PU_HEADER__
`define __PU_HEADER__

	/******** Common ********/
`define PU_PUID_W				4
`define PuPuidBus				3:0

`define PU_PID_NUM				4
`define PU_PID_W				2
`define PuPidBus				1:0

`define PU_TID_W				32
`define PuTidBus				31:0
`define PuTidLoc				31:0

`define PU_TMODE_W				1
`define PuTmodeBus				0:0
`define PU_TMODE_KERNEL			1'b0	// Kernel Mode
`define PU_TMODE_USER			1'b1	// User Mode

	/******** Coprocessor ********/
	// Coprocessor Operation
`define PU_COP_OP_W				4
`define PuCopOpBus				3:0
`define PU_COP_OP_NO			4'h0
`define PU_COP_OP_MT			4'h1
`define PU_COP_OP_MKTH			4'h2
`define PU_COP_OP_DELTH			4'h3
`define PU_COP_OP_SWTH			4'h4
`define PU_COP_OP_NEXTTH		4'h5
`define PU_COP_OP_SWITCH		4'h6
`define PU_COP_OP_VMT			4'h7
`define PU_COP_OP_VRSV			4'h8
`define PU_COP_OP_VRLS			4'h9
`define PU_COP_OP_VRSVR			4'ha
`define PU_COP_OP_VRLSR			4'hb
`define PU_COP_OP_VWAKE			4'hc
`define PU_COP_OP_VSLEEP		4'hd

//`define PU_COP_OP_			4'hf

	// CPR Address
`define PU_CPR_ADDR_W			5
`define PuCprAddrBus			4:0
`define PU_CPR_ADDR_PUID		5'd0
`define PU_CPR_ADDR_PID			5'd1
`define PU_CPR_ADDR_CTRL		5'd2
`define PU_CPR_ADDR_STATUS		5'd3
`define PU_CPR_ADDR_TID			5'd4
`define PU_CPR_ADDR_NPC			5'd5
`define PU_CPR_ADDR_CAUSE		5'd6
`define PU_CPR_ADDR_EPC			5'd7
`define PU_CPR_ADDR_VUS			5'd8

	// Processor Unit ID Register
`define PU_CPR_PUID_ID_W		4
`define PuCprPuidIdBus			3:0
`define PuCprPuidIdLoc			3:0

	// Pipeine ID Register
`define PU_CPR_PID_ID_W			2
`define PuCprPidIdBus			1:0
`define PuCprPidIdLoc			1:0

	// Control Register
`define PU_CPR_CTRL_ITLB_W		1		// ITLB
`define PuCprCtrlItlbBus		0:0
`define PuCprCtrlItlbLoc		4:4

`define PU_CPR_CTRL_IC_W		1		// IC
`define PuCprCtrlIcBus			0:0
`define PuCprCtrlIcLoc			3:3

`define PU_CPR_CTRL_DTLB_W		1		// DTLB
`define PuCprCtrlDtlbBus		0:0
`define PuCprCtrlDtlbLoc		2:2

`define PU_CPR_CTRL_DC_W		1		// DC
`define PuCprCtrlDcBus			0:0
`define PuCprCtrlDcLoc			1:1

`define PU_CPR_CTRL_L2C_W		1		// L2C
`define PuCprCtrlL2cBus			0:0
`define PuCprCtrlL2cLoc			0:0

	// Status Register
`define PU_CPR_STATUS_EN_W		1		// Enable
`define PuCprStatusEnBus		0:0
`define PuCprStatusEnLoc		31:31

`define PU_CPR_STATUS_ACT_W		1		// Active
`define PuCprStatusActBus		0:0
`define PuCprStatusActLoc		30:30

`define PU_CPR_STATUS_NE_W		1		// Next Enable
`define PuCprStatusNeBus		0:0
`define PuCprStatusNeLoc		29:29

`define PU_CPR_STATUS_IM_W		8		// Interrupt MASK
`define PuCprStatusImBus		7:0
`define PuCprStatusImLoc		15:8

`define PU_CPR_STATUS_KU_W		1		// Kernel User
`define PuCprStatusKuBus		0:0
`define PuCprStatusKuLoc		1:1

`define PU_CPR_STATUS_IE_W		1		// Interrupt Enable
`define PuCprStatusIeBus		0:0
`define PuCprStatusIeLoc		0:0

	// Thread ID Register
`define PU_CPR_TID_ID_W			32
`define PuCprTidIdBus			31:0
`define PuCprTidIdLoc			31:0

	// New PC Register

	// Cause Register
`define PU_CPR_CAUSE_BD_W		1		// Branch Delay
`define PuCprCauseBdBus			0:0
`define PuCprCauseBdLoc			31:31

`define PU_CPR_CAUSE_IP_W		6		// Interrupt Pending
`define PuCprCauseIpBus			5:0
`define PuCprCauseIpLoc			15:10

`define PU_CPR_CAUSE_SW_W		2		// Software Interrupt
`define PuCprCauseSwBus			1:0
`define PuCprCauseSwLoc			9:8

`define PU_CPR_CAUSE_EC_W		4		// Exception Code
`define PuCprCauseEcBus			3:0
`define PuCprCauseEcLoc			5:2

	// EPC Regsiter

	// VUS Status Register
`define PU_CPR_VUS_TILEID_W		4
`define PuCprVusTileidBus		3:0
`define PuCprVusTileidLoc		7:4

`define PU_CPR_VUS_MODE_W		2
`define PuCprVusModeBus			1:0
`define PuCprVusModeLoc			1:0

	// VCR Address
`define PU_VCR_ADDR_W			5
`define PuVcrAddrBus			4:0
`define PU_VCR_ADDR_STATUS		5'd0

	// Status Register
`define PU_VCR_STATUS_SW_W		1
`define PuVcrStatusSwBus		0:0
`define PuVcrStatusSwLoc		31:31

`define PU_VCR_STATUS_LEN_W		7
`define PuVcrStatusLenBus		6:0
`define PuVcrStatusLenLoc		22:16

`define PU_VCR_STATUS_RFB_W		6
`define PuVcrStatusRfbBus		5:0
`define PuVcrStatusRfbLoc		5:0

	// EXP
`define PU_EXP_W				3
`define PuExpBus				2:0
`define PU_EXP_NO				3'h0
`define PU_EXP_SC				3'h1	// System Call
`define PU_EXP_BP				3'h2	// Break Point
`define PU_EXP_PIF				3'h3	// Privileged Instruction Fault
`define PU_EXP_UI				3'h4	// Undefined Instruction
`define PU_EXP_OVF				3'h5	// OVer Flow
`define PU_EXP_MA				3'h6	// Miss Align

	// IA
`define PU_EXP_IA_W				1
`define PuExpIaBus				0:0
`define PU_EXP_IA_NO			1'h0

	// ID
`define PU_EXP_ID_W				3
`define PuExpIdBus				2:0
`define PU_EXP_ID_NO			3'h0
`define PU_EXP_ID_SC			3'h1
`define PU_EXP_ID_BP			3'h2
`define PU_EXP_ID_PIF			3'h3
`define PU_EXP_ID_UI			3'h4

	// EX
`define PU_EXP_EX_W				3
`define PuExpExBus				2:0
`define PU_EXP_EX_NO			3'h0
`define PU_EXP_EX_SC			3'h1
`define PU_EXP_EX_BP			3'h2
`define PU_EXP_EX_PIF			3'h3
`define PU_EXP_EX_UI			3'h4
`define PU_EXP_EX_OVF			3'h5

	// DA
`define PU_EXP_DA_W				3
`define PuExpDaBus				2:0
`define PU_EXP_DA_NO			3'h0
`define PU_EXP_DA_SC			3'h1
`define PU_EXP_DA_BP			3'h2
`define PU_EXP_DA_PIF			3'h3
`define PU_EXP_DA_UI			3'h4
`define PU_EXP_DA_OVF			3'h5
`define PU_EXP_DA_MA			3'h6

	// WB
`define PU_EXP_WB_W				3
`define PuExpWbBus				2:0
`define PU_EXP_WB_NO			3'h0
`define PU_EXP_WB_SC			3'h1
`define PU_EXP_WB_BP			3'h2
`define PU_EXP_WB_PIF			3'h3
`define PU_EXP_WB_UI			3'h4
`define PU_EXP_WB_OVF			3'h5
`define PU_EXP_WB_MA			3'h6

	/******** Load and Store ********/
`define PU_LS_OP_W				4
`define PuLsOpBus				3:0
`define PU_LS_OP_NO				4'h0
`define PU_LS_OP_LB				4'h1
`define PU_LS_OP_LH				4'h2
`define PU_LS_OP_LW				4'h3
`define PU_LS_OP_LBU			4'h4
`define PU_LS_OP_LHU			4'h5
`define PU_LS_OP_SB				4'h6
`define PU_LS_OP_SH				4'h7
`define PU_LS_OP_SW				4'h8
//`define PU_LS_OP_				4'h9
//`define PU_LS_OP_				4'ha
//`define PU_LS_OP_				4'hb
//`define PU_LS_OP_				4'hc
//`define PU_LS_OP_				4'hd
//`define PU_LS_OP_				4'he
//`define PU_LS_OP_				4'hf

	/******** Integer Arthmetic ********/
`define PU_IA_OP_W				5
`define PuIaOpBus				4:0
`define PU_IA_OP_NO				5'h00
`define PU_IA_OP_THA			5'h01
`define PU_IA_OP_SLL			5'h02
`define PU_IA_OP_SRL			5'h03
`define PU_IA_OP_SRA			5'h04
`define PU_IA_OP_ADD			5'h05
`define PU_IA_OP_ADDU			5'h06
`define PU_IA_OP_SUB			5'h07
`define PU_IA_OP_SUBU			5'h08
`define PU_IA_OP_AND			5'h09
`define PU_IA_OP_OR				5'h0a
`define PU_IA_OP_XOR			5'h0b
`define PU_IA_OP_NOR			5'h0c
`define PU_IA_OP_SLT			5'h0d
`define PU_IA_OP_SLTU			5'h0e
`define PU_IA_OP_THHI			5'h0f
`define PU_IA_OP_THLO			5'h10
`define PU_IA_OP_MULT			5'h11
`define PU_IA_OP_MULTU			5'h12
`define PU_IA_OP_DIV			5'h13
`define PU_IA_OP_DIVU			5'h14

	/******** GPR ********/
`define PU_GPR_NUM				32

`define PU_GPR_ADDR_W			5
`define PuGprAddrBus			4:0
`define PU_GPR_ADDR_ZERO		5'd00
`define PU_GPR_ADDR_AT			5'd01
`define PU_GPR_ADDR_V0			5'd02
`define PU_GPR_ADDR_V1			5'd03
`define PU_GPR_ADDR_A0			5'd04
`define PU_GPR_ADDR_A1			5'd05
`define PU_GPR_ADDR_A2			5'd06
`define PU_GPR_ADDR_A3			5'd07
`define PU_GPR_ADDR_T0			5'd08
`define PU_GPR_ADDR_T1			5'd09
`define PU_GPR_ADDR_T2			5'd10
`define PU_GPR_ADDR_T3			5'd11
`define PU_GPR_ADDR_T4			5'd12
`define PU_GPR_ADDR_T5			5'd13
`define PU_GPR_ADDR_T6			5'd14
`define PU_GPR_ADDR_T7			5'd15
`define PU_GPR_ADDR_S0			5'd16
`define PU_GPR_ADDR_S1			5'd17
`define PU_GPR_ADDR_S2			5'd18
`define PU_GPR_ADDR_S3			5'd19
`define PU_GPR_ADDR_S4			5'd20
`define PU_GPR_ADDR_S5			5'd21
`define PU_GPR_ADDR_S6			5'd22
`define PU_GPR_ADDR_S7			5'd23
`define PU_GPR_ADDR_T8			5'd24
`define PU_GPR_ADDR_T9			5'd25
`define PU_GPR_ADDR_K0			5'd26
`define PU_GPR_ADDR_K1			5'd27
`define PU_GPR_ADDR_GP			5'd28
`define PU_GPR_ADDR_SP			5'd29
`define PU_GPR_ADDR_FP			5'd30
`define PU_GPR_ADDR_RA			5'd31

	/********** ITLB **********/

	/******** IC ********/
`define PU_IC_TAG_W				20
`define PuIcTagBus				19:0
`define PuIcTagLoc				31:12

`define PU_IC_INDEX_W			7
`define PuIcIndexBus			6:0
`define PuIcIndexLoc			11:5

	/********** DTLB **********/

	/******** DC ********/
`define PU_DC_TAG_W				20
`define PuDcTagBus				19:0
`define PuDcTagLoc				31:12

`define PU_DC_INDEX_W			7
`define PuDcIndexBus			6:0
`define PuDcIndexLoc			11:5

	/******** IRQ ********/
`define PU_IRQ_W				32
`define PuIrqBus				31:0

`endif

