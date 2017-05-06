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

`ifndef __ISA_HEADER__
`define __ISA_HEADER__

	/******** Instruction Format ********/
	// opcode
`define IF_OPCODE_W				6			// opcode Width
`define IfOpcodeBus				5:0			// opcode Bus
`define IfOpcodeLoc				31:26		// opcode Location Bus

	// rs/rt/rd
`define IF_REG_W				5			// Register Width
`define IfRegBus				4:0			// Register Bus
`define IfRsLoc					25:21		// rs Location Bus
`define IfRtLoc					20:16		// rt Location Bus
`define IfRdLoc					15:11		// rd Location Bus

	// sa(Shift Ammount)
`define IF_SA_W					5
`define IfSaBus					4:0
`define IfSaLoc					10:6

	// function
`define IF_FUNCTION_W			6			// function Width
`define IfFunctionBus			5:0			// function Bus
`define IfFunctionLoc			5:0			// function Location Bus

	// immediate/offset
`define IF_IMMEDIATE_W			16
`define IfImmediateBus			15:0
`define IfImmediateLoc			15:0
`define IF_IMMEDIATE_MSB		15
`define IF_OFFSET_W				16
`define IfOffsetBus				15:0
`define IfOffsetLoc				15:0
`define IF_OFFSET_MSB			15

	// instr_index
`define IF_INSTR_INDEX_W		26
`define IfInstr_indexBus		25:0
`define IfInstr_indexLoc		25:0
`define IfInstr_indexUpLoc		29:26

	// base
`define IF_BASE_W				5
`define IfBaseBus				4:0
`define IfBaseLoc				25:21

	// code
`define IF_CODE_W				20
`define IfCodeBus				19:0
`define IfCodeLoc				25:6

	/******** ir ********/
`define IR_NOP					32'h0		// Null OPeration

	/******** opcode ********/
`define OPCODE_SPECIAL			6'b000000	// SPECIAL
`define OPCODE_REGIMM			6'b000001	// REGIMM
`define OPCODE_J				6'b000010	// Jump
`define OPCODE_JAL				6'b000011	// Jump And Link
`define OPCODE_BEQ				6'b000100	// Branch on Equal
`define OPCODE_BNE				6'b000101	// Branch on Not Equal
`define OPCODE_BLEZ				6'b000110
`define OPCODE_BGTZ				6'b000111
`define OPCODE_ADDI				6'b001000
`define OPCODE_ADDIU			6'b001001
`define OPCODE_SLTI				6'b001010
`define OPCODE_SLTIU			6'b001011
`define OPCODE_ANDI				6'b001100
`define OPCODE_ORI				6'b001101
`define OPCODE_XORI				6'b001110
`define OPCODE_LUI				6'b001111
`define OPCODE_COP0				6'b010000
//`define OPCODE_COP1			6'b010001
//`define OPCODE_COP2			6'b010010
//`define OPCODE_COP1X			6'b010011
//`define OPCODE_BEQL			6'b010100
//`define OPCODE_BNEL			6'b010101
//`define OPCODE_BLEZL			6'b010110
//`define OPCODE_BGTZL			6'b010111
//`define OPCODE_DADDI			6'b011000
//`define OPCODE_DADDIU			6'b011001
//`define OPCODE_LDL			6'b011010
//`define OPCODE_LDR			6'b011011
//`define OPCODE_				6'b011100
//`define OPCODE_				6'b011101
//`define OPCODE_				6'b011110
//`define OPCODE_				6'b011111
`define OPCODE_LB				6'b100000
`define OPCODE_LH				6'b100001
//`define OPCODE_LWL			6'b100010
`define OPCODE_LW				6'b100011
`define OPCODE_LBU				6'b100100
`define OPCODE_LHU				6'b100101
//`define OPCODE_LWR			6'b100110
//`define OPCODE_LWU			6'b100111
`define OPCODE_SB				6'b101000
`define OPCODE_SH				6'b101001
//`define OPCODE_SWL			6'b101010
`define OPCODE_SW				6'b101011
//`define OPCODE_SDL			6'b101100
//`define OPCODE_SDR			6'b101101
//`define OPCODE_SWR			6'b101110
//`define OPCODE_				6'b101111
//`define OPCODE_LL				6'b110000
//`define OPCODE_LWC1			6'b110001
//`define OPCODE_LWC2			6'b110010
//`define OPCODE_PREF			6'b110011
//`define OPCODE_LLD			6'b110100
//`define OPCODE_LDC1			6'b110101
//`define OPCODE_LDC2			6'b110110
//`define OPCODE_LD				6'b110111
//`define OPCODE_SC				6'b111000
//`define OPCODE_SWC1			6'b111001
//`define OPCODE_SWC2			6'b111010
//`define OPCODE_				6'b111011
//`define OPCODE_SCD			6'b111100
//`define OPCODE_SDC1			6'b111101
//`define OPCODE_SDC2			6'b111110
//`define OPCODE_SD				6'b111111

	/******** Function ********/
`define FUNCTION_SLL			6'b000000
//`define FUNCTION_MOVCI		6'b000001
`define FUNCTION_SRL			6'b000010
`define FUNCTION_SRA			6'b000011
`define FUNCTION_SLLV			6'b000100
//`define FUNCTION_				6'b000101
`define FUNCTION_SRLV			6'b000110
`define FUNCTION_SRAV			6'b000111
`define FUNCTION_JR				6'b001000		// Jump Register
`define FUNCTION_JALR			6'b001001		// Jump And Link Register
//`define FUNCTION_MOVZ			6'b001010
//`define FUNCTION_MOVN			6'b001011
`define FUNCTION_SYSCALL		6'b001100
`define FUNCTION_BREAK			6'b001101
//`define FUNCTION_				6'b001110
`define FUNCTION_SYNC			6'b001111
`define FUNCTION_MFHI			6'b010000
`define FUNCTION_MTHI			6'b010001
`define FUNCTION_MFLO			6'b010010
`define FUNCTION_MTLO			6'b010011
//`define FUNCTION_DSLLV		6'b010100
//`define FUNCTION_				6'b010101
//`define FUNCTION_DSRLV		6'b010110
//`define FUNCTION_DSRAV		6'b010111
`define FUNCTION_MULT			6'b011000
`define FUNCTION_MULTU			6'b011001
`define FUNCTION_DIV			6'b011010
`define FUNCTION_DIVU			6'b011011
//`define FUNCTION_DMULT		6'b011100
//`define FUNCTION_DMULTU		6'b011101
//`define FUNCTION_DDIV			6'b011110
//`define FUNCTION_DDIVU		6'b011111
`define FUNCTION_ADD			6'b100000
`define FUNCTION_ADDU			6'b100001
`define FUNCTION_SUB			6'b100010
`define FUNCTION_SUBU			6'b100011
`define FUNCTION_AND			6'b100100
`define FUNCTION_OR				6'b100101
`define FUNCTION_XOR			6'b100110
`define FUNCTION_NOR			6'b100111
//`define FUNCTION_				6'b101000
//`define FUNCTION_				6'b101001
`define FUNCTION_SLT			6'b101010
`define FUNCTION_SLTU			6'b101011
//`define FUNCTION_DADD			6'b101100
//`define FUNCTION_DADDU		6'b101101
//`define FUNCTION_DSUB			6'b101110
//`define FUNCTION_DSUBU		6'b101111
//`define FUNCTION_TGE			6'b110000
//`define FUNCTION_TGEU			6'b110001
//`define FUNCTION_TLT			6'b110010
//`define FUNCTION_TLTU			6'b110011
//`define FUNCTION_TEQ			6'b110100
//`define FUNCTION_				6'b110101
//`define FUNCTION_TNE			6'b110110
//`define FUNCTION_				6'b110111
//`define FUNCTION_DSLL			6'b111000
//`define FUNCTION_				6'b111001
//`define FUNCTION_DSRL			6'b111010
//`define FUNCTION_DSRA			6'b111011
//`define FUNCTION_DSLL32		6'b111100
//`define FUNCTION_				6'b111101
//`define FUNCTION_DSRL32		6'b111110
//`define FUNCTION_DSRA32		6'b111111

	/******** rs ********/
`define RS_MF					5'b00000
//`define RS_					5'b00001
//`define RS_					5'b00010
//`define RS_					5'b00011
`define RS_MT					5'b00100
//`define RS_					5'b00101
//`define RS_					5'b00110
//`define RS_					5'b00111
//`define RS_					5'b01000
//`define RS_					5'b01001
//`define RS_					5'b01010
//`define RS_					5'b01011
//`define RS_					5'b01100
//`define RS_					5'b01101
//`define RS_					5'b01110
//`define RS_					5'b01111
//`define RS_					5'b10000
//`define RS_					5'b10001
//`define RS_					5'b10010
//`define RS_					5'b10011
//`define RS_					5'b10100
//`define RS_					5'b10101
//`define RS_					5'b10110
//`define RS_					5'b10111
//`define RS_					5'b11000
//`define RS_					5'b11001
//`define RS_					5'b11010
//`define RS_					5'b11011
//`define RS_					5'b11100
//`define RS_					5'b11101
//`define RS_					5'b11110
//`define RS_					5'b11111

	/******** rt ********/
`define RT_BLTZ					5'b00000
`define RT_BGEZ					5'b00001
//`define RT_BLTZL				5'b00010
//`define RT_BGEZL				5'b00011
//`define RT_					5'b00100
//`define RT_					5'b00101
//`define RT_					5'b00110
//`define RT_					5'b00111
//`define RT_TGEI				5'b01000
//`define RT_TGEIU				5'b01001
//`define RT_TLTI				5'b01010
//`define RT_TLTIU				5'b01011
//`define RT_TEQI				5'b01100
//`define RT_					5'b01101
//`define RT_TNEI				5'b01110
//`define RT_					5'b01111
`define RT_BLTZAL				5'b10000
`define RT_BGEZAL				5'b10001
//`define RT_BLTZALL			5'b10010
//`define RT_BGEZALL			5'b10011
//`define RT_					5'b10100
//`define RT_					5'b10101
//`define RT_					5'b10110
//`define RT_					5'b10111
//`define RT_					5'b11000
//`define RT_					5'b11001
//`define RT_					5'b11010
//`define RT_					5'b11011
//`define RT_					5'b11100
//`define RT_					5'b11101
//`define RT_					5'b11110
//`define RT_					5'b11111


	/******** THREAD ********/
`define OPCODE_THREAD			6'b011101

`define FUNCTION_MKTH			6'b000000
`define FUNCTION_DELTH			6'b000001
`define FUNCTION_SWTH			6'b000010
`define FUNCTION_NEXTTH			6'b000011

	/******** Vector Function ********/
`define IfVSizeBus				2:0
`define IfVSizeLoc				10:8
`define IfVSsEnLoc				7
`define IfVStEnLoc				6

`define OPCODE_VECTOR			6'b011110

`define FUNCTION_VADD			6'b000000
//`define FUNCTION_VADDU		6'b000001
`define FUNCTION_VSUB			6'b000010
//`define FUNCTION_VSUBU		6'b000011
`define FUNCTION_VMULT			6'b000100
//`define FUNCTION_VMULTU		6'b000101
//`define FUNCTION_VDIV			6'b000110
//`define FUNCTION_VDIVU		6'b000111
`define FUNCTION_VMADD			6'b001000
//`define FUNCTION_				6'b001001
//`define FUNCTION_VMSUB		6'b001010
//`define FUNCTION_				6'b001011
`define FUNCTION_VACC			6'b001100
//`define FUNCTION_				6'b001101
//`define FUNCTION_				6'b001110
//`define FUNCTION_				6'b001111
`define FUNCTION_VMSFV			6'b010000
`define FUNCTION_VMSTV			6'b010001
//`define FUNCTION_				6'b010010
//`define FUNCTION_				6'b010011
//`define FUNCTION_				6'b010100
//`define FUNCTION_				6'b010101
//`define FUNCTION_				6'b010110
//`define FUNCTION_				6'b010111
`define FUNCTION_VLD			6'b011000
`define FUNCTION_VST			6'b011001
//`define FUNCTION_				6'b011010
//`define FUNCTION_				6'b011011
//`define FUNCTION_				6'b011100
//`define FUNCTION_				6'b011101
//`define FUNCTION_				6'b011110
//`define FUNCTION_				6'b011111
`define FUNCTION_VMFC			6'b100000
`define FUNCTION_VMTC			6'b100001
`define FUNCTION_VMFSL			6'b100010
`define FUNCTION_VMTSL			6'b100011
`define FUNCTION_VMFSH			6'b100100
`define FUNCTION_VMTSH			6'b100101
//`define FUNCTION_				6'b100110
//`define FUNCTION_				6'b100111
//`define FUNCTION_				6'b101000
//`define FUNCTION_				6'b101001
//`define FUNCTION_				6'b101010
//`define FUNCTION_				6'b101011
//`define FUNCTION_				6'b101100
//`define FUNCTION_				6'b101101
//`define FUNCTION_				6'b101110
//`define FUNCTION_				6'b101111
`define FUNCTION_VRSV			6'b110000
`define FUNCTION_VRLS			6'b110001
`define FUNCTION_VSTART			6'b110010
`define FUNCTION_VEND			6'b110011
//`define FUNCTION_				6'b110100
//`define FUNCTION_				6'b110101
//`define FUNCTION_				6'b110110
//`define FUNCTION_				6'b110111
//`define FUNCTION_				6'b111000
//`define FUNCTION_				6'b111001
//`define FUNCTION_				6'b111010
//`define FUNCTION_				6'b111011
//`define FUNCTION_				6'b111100
//`define FUNCTION_				6'b111101
//`define FUNCTION_				6'b111110
//`define FUNCTION_				6'b111111

`endif

