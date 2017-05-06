/*----------------------------------------------------------------------------*
 *	SMIPS
 *
 *	File	: pu_id_dec.v
 *	Date	: 2012-05-05T11:41:11+9:00
 *	Author	: toshinaga
 *
 *	Description :
 *		***
 *----------------------------------------------------------------------------*/

`include "config.h"

`include "stddef.h"
`include "pu.h"
`include "isa.h"
`include "vu.h"
`include "vus.h"

module pu_id_dec#(
	parameter							PUID				= 0,
	parameter							VU_EN				= 0
)(
	/******** Input Signal ********/
	input wire [`PuTmodeBus]			tmode,
	input wire [`WordDataBus]			inst,
	input wire [`WordAddrBus]			pc,
`ifdef IMP_VUS
	input wire [`VusModeBus]			vus_mode,
	input wire [`CpuTileIdBus]			vus_tileid,
`endif
	/******** GPR ********/
	output wire [`PuGprAddrBus]			rs_addr,
	output wire [`PuGprAddrBus]			rt_addr,
	input wire [`WordDataBus]			rs_data,
	input wire [`WordDataBus]			rt_data,
	/******** HLR ********/
	input wire [`WordDataBus]			hi_data,
	input wire [`WordDataBus]			lo_data,
	/******** CPR ********/
	output wire [`PuCprAddrBus]			cpr_rd_addr,
	input wire [`WordDataBus]			cpr_rd_data,
	/******** VCR ********/
	output wire [`PuVcrAddrBus]			vcr_rd_addr,
	input wire [`WordDataBus]			vcr_rd_data,
	/******** Branch ********/
	output reg							branch_en,
	output reg [`WordAddrBus]			branch_pc,
	/******** Vector Unit SR ********/
	output wire [`VuRfAddrBus]			vu_sr_rd_addr,
	input wire [`DwordDataBus]			vu_sr_rd_data,
	/******** Output Signal ********/
	output reg [`PuCopOpBus]			dec_cop_op,
	output reg [`PuLsOpBus]				dec_ls_op,
	output reg [`PuIaOpBus]				dec_ia_op,
	output reg [`WordDataBus]			dec_in0,
	output reg [`WordDataBus]			dec_in1,
	output reg [`WordDataBus]			dec_st_data,
	output reg [`PuGprAddrBus]			dec_rd_addr,
	output reg							dec_rd_en,
	output reg							dec_hi_en,
	output reg							dec_lo_en,
	output reg							dec_bi,			// Branch Instruction
	output reg							dec_sync,
	output reg							dec_sc,			// System Call
	output reg							dec_bp,			// Break Point
	output reg							dec_pif,		// Priv Inst Fault
	output reg							dec_vu_dd_enq,
	output reg [`VuDdBus]				dec_vu_dd
`ifdef IMP_VUS
	,output reg [`VusOpBus]				dec_vus_op,
	output reg [`VuStatusBus]			dec_vus_status,
	output reg [`CpuTileIdBus]			dec_vus_tileid,
	output reg [`WordAddrLoc]			dec_vus_pc
`endif
);

/*----------------------------------------------------------------------------*
 * Wire and Reg
 *----------------------------------------------------------------------------*/
	/******** Instruction Format ********/
	wire [`IfOpcodeBus]					if_opcode;		// opcode
	wire [`IfRegBus]					if_rs;			// rs
	wire [`IfRegBus]					if_rt;			// rt
	wire [`IfRegBus]					if_rd;			// rd
	wire [`IfSaBus]						if_sa;			// sa
	wire [`IfFunctionBus]				if_function;	// function
	wire [`IfImmediateBus]				if_immediate;	// immidiate
	wire [`IfOffsetBus]					if_offset;		// offset
	wire [`IfInstr_indexBus]			if_instr_index; // instr_index
//	wire [`IfBaseBus]					if_base;		// base
	wire [`IfVSizeBus]					if_vsize;
	wire								if_vss_en;
	wire								if_vst_en;

	/******** Sign Extention ********/
	wire [`WordDataBus]					immidiate_u;	// immidiate Unsigned
	wire [`WordDataBus]					immidiate_s;	// immidiate Signed
	wire [`WordDataBus]					offset_s;		// offset Signed
	wire [`WordDataBus]					sa_u;			// sa Unsigned
	wire [`WordDataBus]					immidiate_up;

	/******** Branch ********/
	wire [`WordAddrBus]					npc;			// Next PC

	wire [`WordAddrBus]					abs_pc;			// Absolute PC
	wire [`WordAddrBus]					rel_pc;			// Relational PC
	wire [`WordAddrBus]					ret_pc;			// Return PC
	wire [`WordAddrBus]					reg_pc;			// Register PC

	wire [`ByteAddrBus]					abs_addr;		// Absolute Address
	wire [`ByteAddrBus]					rel_addr;		// Relational Address
	wire [`ByteAddrBus]					ret_addr;		// Return Address
	wire [`ByteAddrBus]					reg_addr;		// Register Address

/*----------------------------------------------------------------------------*
 * Combinational Logic
 *----------------------------------------------------------------------------*/
	/******** Instruction Format ********/
	assign if_opcode		= inst[`IfOpcodeLoc];
	assign if_rs			= inst[`IfRsLoc];
	assign if_rt			= inst[`IfRtLoc];
	assign if_rd			= inst[`IfRdLoc];
	assign if_sa			= inst[`IfSaLoc];
	assign if_function		= inst[`IfFunctionLoc];
	assign if_immediate		= inst[`IfImmediateLoc];
	assign if_offset		= inst[`IfOffsetLoc];
	assign if_instr_index	= inst[`IfInstr_indexLoc];
//	assign if_base			= inst[`IfBaseLoc];		// = if_rs
	generate
		if (VU_EN == 1) begin
			assign if_vsize			= inst[`IfVSizeLoc];
			assign if_vss_en		= inst[`IfVSsEnLoc];
			assign if_vst_en		= inst[`IfVStEnLoc];
		end else begin
			assign if_vsize			= `VU_VA_SIZE_NO;
			assign if_vss_en		= `DISABLE;
			assign if_vst_en		= `DISABLE;
		end
	endgenerate

	/******** GPR ********/
	assign rs_addr = if_rs;
	assign rt_addr = if_rt;

	/******** CPR ********/
	assign cpr_rd_addr = if_rd;

	/******** VCR ********/
	assign vcr_rd_addr = if_rs;

	/******** Sign Extention ********/
	assign immidiate_u	=
		{{(`WORD_DATA_W - `IF_IMMEDIATE_W){1'b0}}, if_immediate};
	assign immidiate_s	=
		{{(`WORD_DATA_W - `IF_IMMEDIATE_W){if_immediate[`IF_IMMEDIATE_MSB]}},
		if_immediate};
	assign offset_s		=
		{{(`BYTE_ADDR_W - `IF_OFFSET_W){if_offset[`IF_OFFSET_MSB]}},
		if_offset};
	assign sa_u			= {{(`WORD_DATA_W - `IF_SA_W){1'b0}}, if_sa};
	assign immidiate_up =
		{if_immediate, {(`WORD_DATA_W - `IF_IMMEDIATE_W){1'b0}}};

	/******** Branch ********/
	assign npc			= pc + 1'b1;

	assign abs_pc		=
		{npc[`WORD_ADDR_W-1:`IF_INSTR_INDEX_W], if_instr_index};
	assign rel_pc		= npc + offset_s[`WordAddrBus];
	assign ret_pc		= npc + 1'b1;
	assign reg_pc		= rs_data[`WordAddrLoc];

	assign abs_addr		= {abs_pc, `WORD_BO_W'h0};
	assign rel_addr		= {rel_pc, `WORD_BO_W'h0};
	assign ret_addr		= {ret_pc, `WORD_BO_W'h0};
	assign reg_addr		= {reg_pc, `WORD_BO_W'h0};

	/******** Vector Unit ********/
	generate
		if (VU_EN == 1) begin
			assign vu_sr_rd_addr = if_rs;
		end else begin
			assign vu_sr_rd_addr = `PU_GPR_ADDR_W'h0;
		end
	endgenerate

	/******** Instruction Decoder ********/
	generate
		if (VU_EN == 1) begin : INSTRUCTION_DECODER
			always @(*) begin
				branch_en		= `DISABLE;
				branch_pc		= `WORD_ADDR_W'h0;
				dec_cop_op		= `PU_COP_OP_NO;
				dec_ls_op		= `PU_LS_OP_NO;
				dec_ia_op		= `PU_IA_OP_NO;
				dec_in0			= `WORD_DATA_W'h0;
				dec_in1			= `WORD_DATA_W'h0;
				dec_st_data		= `WORD_DATA_W'h0;
				dec_rd_addr		= `PU_GPR_ADDR_W'h0;
				dec_rd_en		= `DISABLE;
				dec_hi_en		= `DISABLE;
				dec_lo_en		= `DISABLE;
				dec_bi			= `DISABLE;
				dec_sync		= `DISABLE;
				dec_sc			= `DISABLE;
				dec_bp			= `DISABLE;
				dec_pif			= `DISABLE;
				dec_vu_dd_enq	= `DISABLE;
				dec_vu_dd		= `VU_DD_W'h0;
`ifdef IMP_VUS
				dec_vus_op		= `VUS_OP_NO;
				dec_vus_status	= `VU_STATUS_W'h0;
				dec_vus_tileid	= `CPU_TILE_ID_W'h0;
				dec_vus_pc		= `WORD_ADDR_W'h0;
`endif

				/******** opcode ********/
				case (if_opcode)
				`OPCODE_SPECIAL : begin
					case (if_function)
					`FUNCTION_SLL : begin
						dec_ia_op		= `PU_IA_OP_SLL;
						dec_in0			= sa_u;
						dec_in1			= rt_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					`FUNCTION_SRL : begin
						dec_ia_op		= `PU_IA_OP_SRL;
						dec_in0			= sa_u;
						dec_in1			= rt_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					`FUNCTION_SRA : begin
						dec_ia_op		= `PU_IA_OP_SRA;
						dec_in0			= sa_u;
						dec_in1			= rt_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					`FUNCTION_SLLV : begin
						dec_ia_op		= `PU_IA_OP_SLL;
						dec_in0			= rs_data;
						dec_in1			= rt_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					`FUNCTION_SRLV : begin
						dec_ia_op		= `PU_IA_OP_SRL;
						dec_in0			= rs_data;
						dec_in1			= rt_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					`FUNCTION_SRAV : begin
						dec_ia_op		= `PU_IA_OP_SRA;
						dec_in0			= rs_data;
						dec_in1			= rt_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					`FUNCTION_JR : begin
						branch_en		= `ENABLE;
						branch_pc		= reg_pc;
						dec_bi			= `ENABLE;
					end
					`FUNCTION_JALR : begin
						branch_en		= `ENABLE;
						branch_pc		= reg_pc;
						dec_ia_op		= `PU_IA_OP_THA;
						dec_in0			= ret_addr;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
						dec_bi			= `ENABLE;
					end
					`FUNCTION_SYSCALL : begin
						dec_sc			= `ENABLE;
					end
					`FUNCTION_BREAK : begin
						dec_bp			= `ENABLE;
					end
					`FUNCTION_SYNC : begin
						dec_sync		= `ENABLE;
					end
					`FUNCTION_MFHI : begin
						dec_ia_op		= `PU_IA_OP_THA;
						dec_in0			= hi_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					`FUNCTION_MTHI : begin
						dec_ia_op		= `PU_IA_OP_THHI;
						dec_in0			= rs_data;
						dec_hi_en		= `ENABLE;
					end
					`FUNCTION_MFLO : begin
						dec_ia_op		= `PU_IA_OP_THA;
						dec_in0			= lo_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					`FUNCTION_MTLO : begin
						dec_ia_op		= `PU_IA_OP_THLO;
						dec_in0			= rs_data;
						dec_lo_en		= `ENABLE;
					end
					`FUNCTION_MULT : begin
						dec_ia_op		= `PU_IA_OP_MULT;
						dec_in0			= rs_data;
						dec_in1			= rt_data;
						dec_hi_en		= `ENABLE;
						dec_lo_en		= `ENABLE;
					end
					`FUNCTION_MULTU : begin
						dec_ia_op		= `PU_IA_OP_MULTU;
						dec_in0			= rs_data;
						dec_in1			= rt_data;
						dec_hi_en		= `ENABLE;
						dec_lo_en		= `ENABLE;
					end
					`FUNCTION_DIV : begin
						dec_ia_op		= `PU_IA_OP_DIV;
						dec_in0			= rs_data;
						dec_in1			= rt_data;
						dec_hi_en		= `ENABLE;
						dec_lo_en		= `ENABLE;
					end
					`FUNCTION_DIVU : begin
						dec_ia_op		= `PU_IA_OP_DIVU;
						dec_in0			= rs_data;
						dec_in1			= rt_data;
						dec_hi_en		= `ENABLE;
						dec_lo_en		= `ENABLE;
					end
					`FUNCTION_ADD : begin
						dec_ia_op		= `PU_IA_OP_ADD;
						dec_in0			= rs_data;
						dec_in1			= rt_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					`FUNCTION_ADDU : begin
						dec_ia_op		= `PU_IA_OP_ADDU;
						dec_in0			= rs_data;
						dec_in1			= rt_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					`FUNCTION_SUB : begin
						dec_ia_op		= `PU_IA_OP_SUB;
						dec_in0			= rs_data;
						dec_in1			= rt_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					`FUNCTION_SUBU : begin
						dec_ia_op		= `PU_IA_OP_SUBU;
						dec_in0			= rs_data;
						dec_in1			= rt_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					`FUNCTION_AND : begin
						dec_ia_op		= `PU_IA_OP_AND;
						dec_in0			= rs_data;
						dec_in1			= rt_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					`FUNCTION_OR : begin
						dec_ia_op		= `PU_IA_OP_OR;
						dec_in0			= rs_data;
						dec_in1			= rt_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					`FUNCTION_XOR : begin
						dec_ia_op		= `PU_IA_OP_XOR;
						dec_in0			= rs_data;
						dec_in1			= rt_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					`FUNCTION_NOR : begin
						dec_ia_op		= `PU_IA_OP_NOR;
						dec_in0			= rs_data;
						dec_in1			= rt_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					`FUNCTION_SLT : begin
						dec_ia_op		= `PU_IA_OP_SLT;
						dec_in0			= rs_data;
						dec_in1			= rt_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					`FUNCTION_SLTU : begin
						dec_ia_op		= `PU_IA_OP_SLTU;
						dec_in0			= rs_data;
						dec_in1			= rt_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					endcase
				end
				`OPCODE_REGIMM : begin
					case (if_rt)
					`RT_BLTZ : begin
						if ($signed(rs_data) < $signed(1'b0)) begin
							branch_en		= `ENABLE;
							branch_pc		= rel_pc;
						end
						dec_bi			= `ENABLE;
					end
					`RT_BGEZ : begin
						if ($signed(rs_data) >= $signed(1'b0)) begin
							branch_en		= `ENABLE;
							branch_pc		= rel_pc;
						end
						dec_bi			= `ENABLE;
					end
					`RT_BLTZAL : begin
						if ($signed(rs_data) < $signed(1'b0)) begin
							branch_en		= `ENABLE;
							branch_pc		= rel_pc;
						end
						dec_ia_op		= `PU_IA_OP_THA;
						dec_in0			= ret_addr;
						dec_rd_addr		= `PU_GPR_ADDR_RA;
						dec_rd_en		= `ENABLE;
						dec_bi			= `ENABLE;
					end
					`RT_BGEZAL : begin
						if ($signed(rs_data) >= $signed(1'b0)) begin
							branch_en		= `ENABLE;
							branch_pc		= rel_pc;
						end
						dec_ia_op		= `PU_IA_OP_THA;
						dec_in0			= ret_addr;
						dec_rd_addr		= `PU_GPR_ADDR_RA;
						dec_rd_en		= `ENABLE;
						dec_bi			= `ENABLE;
					end
					endcase
				end
				`OPCODE_J : begin
					branch_en		= `ENABLE;
					branch_pc		= abs_pc;
					dec_bi			= `ENABLE;
				end
				`OPCODE_JAL : begin
					branch_en		= `ENABLE;
					branch_pc		= abs_pc;
					dec_ia_op		= `PU_IA_OP_THA;
					dec_in0			= ret_addr;
					dec_rd_addr		= `PU_GPR_ADDR_RA;
					dec_rd_en		= `ENABLE;
					dec_bi			= `ENABLE;
				end
				`OPCODE_BEQ : begin
					if (rs_data == rt_data) begin
						branch_en		= `ENABLE;
						branch_pc		= rel_pc;
					end
					dec_bi			= `ENABLE;
				end
				`OPCODE_BNE : begin
					if (rs_data != rt_data) begin
						branch_en		= `ENABLE;
						branch_pc		= rel_pc;
					end
					dec_bi			= `ENABLE;
				end
				`OPCODE_BLEZ : begin
					if ($signed(rs_data) <= $signed(1'b0)) begin
						branch_en		= `ENABLE;
						branch_pc		= rel_pc;
					end
					dec_bi			= `ENABLE;
				end
				`OPCODE_BGTZ : begin
					if ($signed(rs_data) > $signed(1'b0)) begin
						branch_en		= `ENABLE;
						branch_pc		= rel_pc;
					end
					dec_bi			= `ENABLE;
				end
				`OPCODE_ADDI : begin
					dec_ia_op		= `PU_IA_OP_ADD;
					dec_in0			= rs_data;
					dec_in1			= immidiate_s;
					dec_rd_addr		= if_rt;
					dec_rd_en		= `ENABLE;
				end
				`OPCODE_ADDIU : begin
					dec_ia_op		= `PU_IA_OP_ADDU;
					dec_in0			= rs_data;
					dec_in1			= immidiate_s;
					dec_rd_addr		= if_rt;
					dec_rd_en		= `ENABLE;
				end
				`OPCODE_SLTI : begin
					dec_ia_op		= `PU_IA_OP_SLT;
					dec_in0			= rs_data;
					dec_in1			= immidiate_s;
					dec_rd_addr		= if_rt;
					dec_rd_en		= `ENABLE;
				end
				`OPCODE_SLTIU : begin
					dec_ia_op		= `PU_IA_OP_SLTU;
					dec_in0			= rs_data;
					dec_in1			= immidiate_s;
					dec_rd_addr		= if_rt;
					dec_rd_en		= `ENABLE;
				end
				`OPCODE_ANDI : begin
					dec_ia_op		= `PU_IA_OP_AND;
					dec_in0			= rs_data;
					dec_in1			= immidiate_u;
					dec_rd_addr		= if_rt;
					dec_rd_en		= `ENABLE;
				end
				`OPCODE_ORI : begin
					dec_ia_op		= `PU_IA_OP_OR;
					dec_in0			= rs_data;
					dec_in1			= immidiate_u;
					dec_rd_addr		= if_rt;
					dec_rd_en		= `ENABLE;
				end
				`OPCODE_XORI : begin
					dec_ia_op		= `PU_IA_OP_XOR;
					dec_in0			= rs_data;
					dec_in1			= immidiate_u;
					dec_rd_addr		= if_rt;
					dec_rd_en		= `ENABLE;
				end
				`OPCODE_LUI : begin
					dec_ia_op		= `PU_IA_OP_THA;
					dec_in0			= immidiate_up;
					dec_rd_addr		= if_rt;
					dec_rd_en		= `ENABLE;
				end
				`OPCODE_COP0 : begin
					case (if_rs)
					`RS_MF : begin
						case (tmode)
						`PU_TMODE_KERNEL : begin
							dec_ia_op		= `PU_IA_OP_THA;
							dec_in0			= cpr_rd_data;
							dec_rd_addr		= if_rt;
							dec_rd_en		= `ENABLE;
						end
						`PU_TMODE_USER : begin
							dec_pif			= `ENABLE;
						end
						endcase
					end
					`RS_MT : begin
						case (tmode)
						`PU_TMODE_KERNEL : begin
							dec_cop_op		= `PU_COP_OP_MT;
							dec_ia_op		= `PU_IA_OP_THA;
							dec_in0			= rt_data;
							dec_rd_addr		= if_rd;
						end
						`PU_TMODE_USER : begin
							dec_pif			= `ENABLE;
						end
						endcase
					end
					endcase
				end
				`OPCODE_LB : begin
					dec_ls_op		= `PU_LS_OP_LB;
					dec_ia_op		= `PU_IA_OP_ADD;
					dec_in0			= rs_data;
					dec_in1			= offset_s;
					dec_rd_addr		= if_rt;
					dec_rd_en		= `ENABLE;
				end
				`OPCODE_LH : begin
					dec_ls_op		= `PU_LS_OP_LH;
					dec_ia_op		= `PU_IA_OP_ADD;
					dec_in0			= rs_data;
					dec_in1			= offset_s;
					dec_rd_addr		= if_rt;
					dec_rd_en		= `ENABLE;
				end
				`OPCODE_LW : begin
					dec_ls_op		= `PU_LS_OP_LW;
					dec_ia_op		= `PU_IA_OP_ADD;
					dec_in0			= rs_data;
					dec_in1			= offset_s;
					dec_rd_addr		= if_rt;
					dec_rd_en		= `ENABLE;
				end
				`OPCODE_LBU : begin
					dec_ls_op		= `PU_LS_OP_LBU;
					dec_ia_op		= `PU_IA_OP_ADD;
					dec_in0			= rs_data;
					dec_in1			= offset_s;
					dec_rd_addr		= if_rt;
					dec_rd_en		= `ENABLE;
				end
				`OPCODE_LHU : begin
					dec_ls_op		= `PU_LS_OP_LHU;
					dec_ia_op		= `PU_IA_OP_ADD;
					dec_in0			= rs_data;
					dec_in1			= offset_s;
					dec_rd_addr		= if_rt;
					dec_rd_en		= `ENABLE;
				end
				`OPCODE_SB : begin
					dec_ls_op		= `PU_LS_OP_SB;
					dec_ia_op		= `PU_IA_OP_ADD;
					dec_in0			= rs_data;
					dec_in1			= offset_s;
					dec_st_data		= rt_data;
				end
				`OPCODE_SH : begin
					dec_ls_op		= `PU_LS_OP_SH;
					dec_ia_op		= `PU_IA_OP_ADD;
					dec_in0			= rs_data;
					dec_in1			= offset_s;
					dec_st_data		= rt_data;
				end
				`OPCODE_SW : begin
					dec_ls_op		= `PU_LS_OP_SW;
					dec_ia_op		= `PU_IA_OP_ADD;
					dec_in0			= rs_data;
					dec_in1			= offset_s;
					dec_st_data		= rt_data;
				end
				`OPCODE_THREAD : begin
					case (if_function)
					`FUNCTION_MKTH : begin
						case (tmode)
						`PU_TMODE_KERNEL : begin
							dec_cop_op		= `PU_COP_OP_MKTH;
							dec_ia_op		= `PU_IA_OP_THA;
							dec_in0			= rs_data;
							dec_st_data		= rt_data;
							dec_rd_addr		= if_rd;
							dec_rd_en		= `ENABLE;
						end
						`PU_TMODE_USER : begin
							dec_pif			= `ENABLE;
						end
						endcase
					end
					`FUNCTION_DELTH : begin
						case (tmode)
						`PU_TMODE_KERNEL : begin
							dec_cop_op		= `PU_COP_OP_DELTH;
							dec_ia_op		= `PU_IA_OP_THA;
							dec_in0			= rs_data;
							dec_rd_addr		= if_rd;
							dec_rd_en		= `ENABLE;
						end
						`PU_TMODE_USER : begin
							dec_pif			= `ENABLE;
						end
						endcase
					end
					`FUNCTION_SWTH : begin
						case (tmode)
						`PU_TMODE_KERNEL : begin
							dec_cop_op		= `PU_COP_OP_SWTH;
							dec_ia_op		= `PU_IA_OP_THA;
							dec_in0			= rs_data;
							dec_rd_addr		= if_rd;
							dec_rd_en		= `ENABLE;
						end
						`PU_TMODE_USER : begin
							dec_pif			= `ENABLE;
						end
						endcase
					end
					`FUNCTION_NEXTTH : begin
						case (tmode)
						`PU_TMODE_KERNEL : begin
							dec_cop_op		= `PU_COP_OP_NEXTTH;
							dec_rd_addr		= if_rd;
							dec_rd_en		= `ENABLE;
						end
						`PU_TMODE_USER : begin
							dec_pif			= `ENABLE;
						end
						endcase
					end
					endcase
				end
				`OPCODE_VECTOR : begin
					case (if_function)
					`FUNCTION_VADD : begin
						dec_vu_dd_enq				= `ENABLE;
						dec_vu_dd[`VuDdUselLoc]		= `VU_USEL_VA;
						dec_vu_dd[`VuDdVaIaOpLoc]	= `VU_VA_IA_OP_ADD;
						dec_vu_dd[`VuDdVaSizeLoc]	= if_vsize;
						dec_vu_dd[`VuDdRsAddrLoc]	= if_rs;
						dec_vu_dd[`VuDdVsEnLoc]		= ~if_vss_en;
						dec_vu_dd[`VuDdSsEnLoc]		= if_vss_en;
						dec_vu_dd[`VuDdRtAddrLoc]	= if_rt;
						dec_vu_dd[`VuDdVtEnLoc]		= ~if_vst_en;
						dec_vu_dd[`VuDdStEnLoc]		= if_vst_en;
						dec_vu_dd[`VuDdRdAddrLoc]	= if_rd;
						dec_vu_dd[`VuDdVdEnLoc]		= `ENABLE;
					end
					`FUNCTION_VSUB : begin
						dec_vu_dd_enq				= `ENABLE;
						dec_vu_dd[`VuDdUselLoc]		= `VU_USEL_VA;
						dec_vu_dd[`VuDdVaIaOpLoc]	= `VU_VA_IA_OP_SUB;
						dec_vu_dd[`VuDdVaSizeLoc]	= if_vsize;
						dec_vu_dd[`VuDdRsAddrLoc]	= if_rs;
						dec_vu_dd[`VuDdVsEnLoc]		= ~if_vss_en;
						dec_vu_dd[`VuDdSsEnLoc]		= if_vss_en;
						dec_vu_dd[`VuDdRtAddrLoc]	= if_rt;
						dec_vu_dd[`VuDdVtEnLoc]		= ~if_vst_en;
						dec_vu_dd[`VuDdStEnLoc]		= if_vst_en;
						dec_vu_dd[`VuDdRdAddrLoc]	= if_rd;
						dec_vu_dd[`VuDdVdEnLoc]		= `ENABLE;
					end
					`FUNCTION_VMULT : begin
						dec_vu_dd_enq				= `ENABLE;
						dec_vu_dd[`VuDdUselLoc]		= `VU_USEL_VA;
						dec_vu_dd[`VuDdVaIaOpLoc]	= `VU_VA_IA_OP_MULT;
						dec_vu_dd[`VuDdVaSizeLoc]	= if_vsize;
						dec_vu_dd[`VuDdRsAddrLoc]	= if_rs;
						dec_vu_dd[`VuDdVsEnLoc]		= ~if_vss_en;
						dec_vu_dd[`VuDdSsEnLoc]		= if_vss_en;
						dec_vu_dd[`VuDdRtAddrLoc]	= if_rt;
						dec_vu_dd[`VuDdVtEnLoc]		= ~if_vst_en;
						dec_vu_dd[`VuDdStEnLoc]		= if_vst_en;
						dec_vu_dd[`VuDdRdAddrLoc]	= if_rd;
						dec_vu_dd[`VuDdVdEnLoc]		= `ENABLE;
					end
					`FUNCTION_VACC : begin
						dec_vu_dd_enq				= `ENABLE;
						dec_vu_dd[`VuDdUselLoc]		= `VU_USEL_VA;
						dec_vu_dd[`VuDdVaAccOpLoc]	= `VU_VA_ACC_OP_ACC;
						dec_vu_dd[`VuDdVaSizeLoc]	= if_vsize;
						dec_vu_dd[`VuDdRsAddrLoc]	= if_rs;
						dec_vu_dd[`VuDdVsEnLoc]		= `ENABLE;
						dec_vu_dd[`VuDdRdAddrLoc]	= if_rd;
						dec_vu_dd[`VuDdSdEnLoc]		= `ENABLE;
					end
					`FUNCTION_VMSFV : begin
						dec_vu_dd_enq				= `ENABLE;
						dec_vu_dd[`VuDdUselLoc]		= `VU_USEL_VA;
						dec_vu_dd[`VuDdVaDpOpLoc]	= `VU_VA_DP_OP_MVTS;
						dec_vu_dd[`VuDdVaSizeLoc]	= if_vsize;
						dec_vu_dd[`VuDdRsAddrLoc]	= if_rs;
						dec_vu_dd[`VuDdVsEnLoc]		= `ENABLE;
						dec_vu_dd[`VuDdRtAddrLoc]	= if_rt;
						dec_vu_dd[`VuDdStEnLoc]		= `ENABLE;
						dec_vu_dd[`VuDdRuAddrLoc]	= if_rd;
						dec_vu_dd[`VuDdSuEnLoc]		= `ENABLE;
						dec_vu_dd[`VuDdRdAddrLoc]	= if_rd;
						dec_vu_dd[`VuDdSdEnLoc]		= `ENABLE;
					end
					`FUNCTION_VMSTV : begin
						dec_vu_dd_enq				= `ENABLE;
						dec_vu_dd[`VuDdUselLoc]		= `VU_USEL_VA;
						dec_vu_dd[`VuDdVaDpOpLoc]	= `VU_VA_DP_OP_MSTV;
						dec_vu_dd[`VuDdVaSizeLoc]	= if_vsize;
						dec_vu_dd[`VuDdRsAddrLoc]	= if_rs;
						dec_vu_dd[`VuDdSsEnLoc]		= `ENABLE;
						dec_vu_dd[`VuDdRtAddrLoc]	= if_rt;
						dec_vu_dd[`VuDdStEnLoc]		= `ENABLE;
						dec_vu_dd[`VuDdRuAddrLoc]	= if_rd;
						dec_vu_dd[`VuDdVuEnLoc]		= `ENABLE;
						dec_vu_dd[`VuDdRdAddrLoc]	= if_rd;
						dec_vu_dd[`VuDdVdEnLoc]		= `ENABLE;
					end
					`FUNCTION_VLD : begin
						dec_vu_dd_enq				= `ENABLE;
						dec_vu_dd[`VuDdUselLoc]		= `VU_USEL_LS;
						dec_vu_dd[`VuDdLsOpLoc]		= `VU_LS_OP_LD;
						dec_vu_dd[`VuDdLsAddrLoc]	= rs_data[`WordAddrLoc];
						dec_vu_dd[`VuDdRdAddrLoc]	= if_rt;
						dec_vu_dd[`VuDdVdEnLoc]		= `ENABLE;
					end
					`FUNCTION_VST : begin
						dec_vu_dd_enq				= `ENABLE;
						dec_vu_dd[`VuDdUselLoc]		= `VU_USEL_LS;
						dec_vu_dd[`VuDdLsOpLoc]		= `VU_LS_OP_ST;
						dec_vu_dd[`VuDdLsAddrLoc]	= rs_data[`WordAddrLoc];
						dec_vu_dd[`VuDdRsAddrLoc]	= if_rt;
						dec_vu_dd[`VuDdVsEnLoc]		= `ENABLE;
					end
					`FUNCTION_VMFC : begin
						dec_ia_op					= `PU_IA_OP_THA;
						dec_in0						= vcr_rd_data;
						dec_rd_addr					= if_rt;
						dec_rd_en					= `ENABLE;
					end
					`FUNCTION_VMTC : begin
						dec_cop_op					= `PU_COP_OP_VMT;
						dec_ia_op					= `PU_IA_OP_THA;
						dec_in0						= rt_data;
						dec_rd_addr					= if_rd;
					end
					`FUNCTION_VMFSL : begin
						dec_ia_op					= `PU_IA_OP_THA;
						dec_in0						= vu_sr_rd_data[31:0];
						dec_rd_addr					= if_rd;
						dec_rd_en					= `ENABLE;
						dec_sync					= `ENABLE;
					end
					`FUNCTION_VMTSL : begin
						dec_vu_dd_enq				= `ENABLE;
						dec_vu_dd[`VuDdUselLoc]		= `VU_USEL_VA;
						dec_vu_dd[`VuDdVaDpOpLoc]	= `VU_VA_DP_OP_MTS;
						dec_vu_dd[`VuDdVaDataLoc]	= rs_data;
						dec_vu_dd[`VuDdRdAddrLoc]	= if_rd;
						dec_vu_dd[`VuDdSdEnLoc]		= `ENABLE;
					end
`ifdef IMP_VUS
					`FUNCTION_VRSV : begin
						if (rt_data == PUID) begin
							dec_cop_op					= `PU_COP_OP_VRSV;
							dec_ia_op					= `PU_IA_OP_THA;
							dec_in0						= rs_data;
							dec_st_data					= rt_data;
							dec_rd_addr					= if_rd;
							dec_rd_en					= `ENABLE;
						end else begin
							dec_cop_op					= `PU_COP_OP_VRSV;
							dec_st_data					= rt_data;
							dec_rd_addr					= if_rd;
							dec_rd_en					= `ENABLE;
							dec_vus_op					= `VUS_OP_RSV;
							dec_vus_status				= rs_data;
							dec_vus_tileid				= rt_data[`CpuTileIdBus];
						end
					end
					`FUNCTION_VRLS : begin
						if (vus_tileid == PUID) begin
							dec_cop_op					= `PU_COP_OP_VRLS;
							dec_rd_addr					= if_rd;
							dec_rd_en					= `ENABLE;
						end else begin
							dec_cop_op					= `PU_COP_OP_VRLS;
							dec_rd_addr					= if_rd;
							dec_rd_en					= `ENABLE;
							dec_vus_op					= `VUS_OP_RLS;
							dec_vus_tileid				= vus_tileid;
						end
					end
					`FUNCTION_VSTART : begin
						if (vus_mode == `VUS_MODE_SEND) begin
							dec_cop_op		= `PU_COP_OP_VSLEEP;
							dec_vus_op		= `VUS_OP_START;
							dec_vus_tileid	= vus_tileid;
							dec_vus_pc		= npc;
						end
					end
					`FUNCTION_VEND : begin
						if (vus_mode == `VUS_MODE_RECV) begin
							dec_cop_op		= `PU_COP_OP_VSLEEP;
							dec_vus_op		= `VUS_OP_END;
							dec_vus_tileid	= vus_tileid;
							dec_vus_pc		= npc;
						end
					end
`else
					`FUNCTION_VRSV : begin
						dec_cop_op					= `PU_COP_OP_VRSV;
						dec_ia_op					= `PU_IA_OP_THA;
						dec_in0						= rs_data;
						dec_rd_addr					= if_rd;
						dec_rd_en					= `ENABLE;
					end
					`FUNCTION_VRLS : begin
						dec_cop_op					= `PU_COP_OP_VRLS;
						dec_rd_addr					= if_rd;
						dec_rd_en					= `ENABLE;
					end
`endif
					endcase
				end
				endcase
			end
		end else begin
			always @(*) begin
				branch_en		= `DISABLE;
				branch_pc		= `WORD_ADDR_W'h0;
				dec_cop_op		= `PU_COP_OP_NO;
				dec_ls_op		= `PU_LS_OP_NO;
				dec_ia_op		= `PU_IA_OP_NO;
				dec_in0			= `WORD_DATA_W'h0;
				dec_in1			= `WORD_DATA_W'h0;
				dec_st_data		= `WORD_DATA_W'h0;
				dec_rd_addr		= `PU_GPR_ADDR_W'h0;
				dec_rd_en		= `DISABLE;
				dec_hi_en		= `DISABLE;
				dec_lo_en		= `DISABLE;
				dec_bi			= `DISABLE;
				dec_sync		= `DISABLE;
				dec_sc			= `DISABLE;
				dec_bp			= `DISABLE;
				dec_pif			= `DISABLE;
				dec_vu_dd_enq	= `DISABLE;
				dec_vu_dd		= `VU_DD_W'h0;
`ifdef IMP_VUS
				dec_vus_op		= `VUS_OP_NO;
				dec_vus_status	= `VU_STATUS_W'h0;
				dec_vus_tileid	= `CPU_TILE_ID_W'h0;
				dec_vus_pc		= `WORD_ADDR_W'h0;
`endif

				/******** opcode ********/
				case (if_opcode)
				`OPCODE_SPECIAL : begin
					case (if_function)
					`FUNCTION_SLL : begin
						dec_ia_op		= `PU_IA_OP_SLL;
						dec_in0			= sa_u;
						dec_in1			= rt_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					`FUNCTION_SRL : begin
						dec_ia_op		= `PU_IA_OP_SRL;
						dec_in0			= sa_u;
						dec_in1			= rt_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					`FUNCTION_SRA : begin
						dec_ia_op		= `PU_IA_OP_SRA;
						dec_in0			= sa_u;
						dec_in1			= rt_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					`FUNCTION_SLLV : begin
						dec_ia_op		= `PU_IA_OP_SLL;
						dec_in0			= rs_data;
						dec_in1			= rt_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					`FUNCTION_SRLV : begin
						dec_ia_op		= `PU_IA_OP_SRL;
						dec_in0			= rs_data;
						dec_in1			= rt_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					`FUNCTION_SRAV : begin
						dec_ia_op		= `PU_IA_OP_SRA;
						dec_in0			= rs_data;
						dec_in1			= rt_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					`FUNCTION_JR : begin
						branch_en		= `ENABLE;
						branch_pc		= reg_pc;
						dec_bi			= `ENABLE;
					end
					`FUNCTION_JALR : begin
						branch_en		= `ENABLE;
						branch_pc		= reg_pc;
						dec_ia_op		= `PU_IA_OP_THA;
						dec_in0			= ret_addr;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
						dec_bi			= `ENABLE;
					end
					`FUNCTION_SYSCALL : begin
						dec_sc			= `ENABLE;
					end
					`FUNCTION_BREAK : begin
						dec_bp			= `ENABLE;
					end
					`FUNCTION_SYNC : begin
						dec_sync		= `ENABLE;
					end
					`FUNCTION_MFHI : begin
						dec_ia_op		= `PU_IA_OP_THA;
						dec_in0			= hi_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					`FUNCTION_MTHI : begin
						dec_ia_op		= `PU_IA_OP_THHI;
						dec_in0			= rs_data;
						dec_hi_en		= `ENABLE;
					end
					`FUNCTION_MFLO : begin
						dec_ia_op		= `PU_IA_OP_THA;
						dec_in0			= lo_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					`FUNCTION_MTLO : begin
						dec_ia_op		= `PU_IA_OP_THLO;
						dec_in0			= rs_data;
						dec_lo_en		= `ENABLE;
					end
					`FUNCTION_MULT : begin
						dec_ia_op		= `PU_IA_OP_MULT;
						dec_in0			= rs_data;
						dec_in1			= rt_data;
						dec_hi_en		= `ENABLE;
						dec_lo_en		= `ENABLE;
					end
					`FUNCTION_MULTU : begin
						dec_ia_op		= `PU_IA_OP_MULTU;
						dec_in0			= rs_data;
						dec_in1			= rt_data;
						dec_hi_en		= `ENABLE;
						dec_lo_en		= `ENABLE;
					end
					`FUNCTION_DIV : begin
						dec_ia_op		= `PU_IA_OP_DIV;
						dec_in0			= rs_data;
						dec_in1			= rt_data;
						dec_hi_en		= `ENABLE;
						dec_lo_en		= `ENABLE;
					end
					`FUNCTION_DIVU : begin
						dec_ia_op		= `PU_IA_OP_DIVU;
						dec_in0			= rs_data;
						dec_in1			= rt_data;
						dec_hi_en		= `ENABLE;
						dec_lo_en		= `ENABLE;
					end
					`FUNCTION_ADD : begin
						dec_ia_op		= `PU_IA_OP_ADD;
						dec_in0			= rs_data;
						dec_in1			= rt_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					`FUNCTION_ADDU : begin
						dec_ia_op		= `PU_IA_OP_ADDU;
						dec_in0			= rs_data;
						dec_in1			= rt_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					`FUNCTION_SUB : begin
						dec_ia_op		= `PU_IA_OP_SUB;
						dec_in0			= rs_data;
						dec_in1			= rt_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					`FUNCTION_SUBU : begin
						dec_ia_op		= `PU_IA_OP_SUBU;
						dec_in0			= rs_data;
						dec_in1			= rt_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					`FUNCTION_AND : begin
						dec_ia_op		= `PU_IA_OP_AND;
						dec_in0			= rs_data;
						dec_in1			= rt_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					`FUNCTION_OR : begin
						dec_ia_op		= `PU_IA_OP_OR;
						dec_in0			= rs_data;
						dec_in1			= rt_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					`FUNCTION_XOR : begin
						dec_ia_op		= `PU_IA_OP_XOR;
						dec_in0			= rs_data;
						dec_in1			= rt_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					`FUNCTION_NOR : begin
						dec_ia_op		= `PU_IA_OP_NOR;
						dec_in0			= rs_data;
						dec_in1			= rt_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					`FUNCTION_SLT : begin
						dec_ia_op		= `PU_IA_OP_SLT;
						dec_in0			= rs_data;
						dec_in1			= rt_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					`FUNCTION_SLTU : begin
						dec_ia_op		= `PU_IA_OP_SLTU;
						dec_in0			= rs_data;
						dec_in1			= rt_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
					end
					endcase
				end
				`OPCODE_REGIMM : begin
					case (if_rt)
					`RT_BLTZ : begin
						if ($signed(rs_data) < $signed(1'b0)) begin
							branch_en		= `ENABLE;
							branch_pc		= rel_pc;
						end
						dec_bi			= `ENABLE;
					end
					`RT_BGEZ : begin
						if ($signed(rs_data) >= $signed(1'b0)) begin
							branch_en		= `ENABLE;
							branch_pc		= rel_pc;
						end
						dec_bi			= `ENABLE;
					end
					`RT_BLTZAL : begin
						if ($signed(rs_data) < $signed(1'b0)) begin
							branch_en		= `ENABLE;
							branch_pc		= rel_pc;
						end
						dec_ia_op		= `PU_IA_OP_THA;
						dec_in0			= ret_addr;
						dec_rd_addr		= `PU_GPR_ADDR_RA;
						dec_rd_en		= `ENABLE;
						dec_bi			= `ENABLE;
					end
					`RT_BGEZAL : begin
						if ($signed(rs_data) >= $signed(1'b0)) begin
							branch_en		= `ENABLE;
							branch_pc		= rel_pc;
						end
						dec_ia_op		= `PU_IA_OP_THA;
						dec_in0			= ret_addr;
						dec_rd_addr		= `PU_GPR_ADDR_RA;
						dec_rd_en		= `ENABLE;
						dec_bi			= `ENABLE;
					end
					endcase
				end
				`OPCODE_J : begin
					branch_en		= `ENABLE;
					branch_pc		= abs_pc;
					dec_bi			= `ENABLE;
				end
				`OPCODE_JAL : begin
					branch_en		= `ENABLE;
					branch_pc		= abs_pc;
					dec_ia_op		= `PU_IA_OP_THA;
					dec_in0			= ret_addr;
					dec_rd_addr		= `PU_GPR_ADDR_RA;
					dec_rd_en		= `ENABLE;
					dec_bi			= `ENABLE;
				end
				`OPCODE_BEQ : begin
					if (rs_data == rt_data) begin
						branch_en		= `ENABLE;
						branch_pc		= rel_pc;
					end
					dec_bi			= `ENABLE;
				end
				`OPCODE_BNE : begin
					if (rs_data != rt_data) begin
						branch_en		= `ENABLE;
						branch_pc		= rel_pc;
					end
					dec_bi			= `ENABLE;
				end
				`OPCODE_BLEZ : begin
					if ($signed(rs_data) <= $signed(1'b0)) begin
						branch_en		= `ENABLE;
						branch_pc		= rel_pc;
					end
					dec_bi			= `ENABLE;
				end
				`OPCODE_BGTZ : begin
					if ($signed(rs_data) > $signed(1'b0)) begin
						branch_en		= `ENABLE;
						branch_pc		= rel_pc;
					end
					dec_bi			= `ENABLE;
				end
				`OPCODE_ADDI : begin
					dec_ia_op		= `PU_IA_OP_ADD;
					dec_in0			= rs_data;
					dec_in1			= immidiate_s;
					dec_rd_addr		= if_rt;
					dec_rd_en		= `ENABLE;
				end
				`OPCODE_ADDIU : begin
					dec_ia_op		= `PU_IA_OP_ADDU;
					dec_in0			= rs_data;
					dec_in1			= immidiate_s;
					dec_rd_addr		= if_rt;
					dec_rd_en		= `ENABLE;
				end
				`OPCODE_SLTI : begin
					dec_ia_op		= `PU_IA_OP_SLT;
					dec_in0			= rs_data;
					dec_in1			= immidiate_s;
					dec_rd_addr		= if_rt;
					dec_rd_en		= `ENABLE;
				end
				`OPCODE_SLTIU : begin
					dec_ia_op		= `PU_IA_OP_SLTU;
					dec_in0			= rs_data;
					dec_in1			= immidiate_s;
					dec_rd_addr		= if_rt;
					dec_rd_en		= `ENABLE;
				end
				`OPCODE_ANDI : begin
					dec_ia_op		= `PU_IA_OP_AND;
					dec_in0			= rs_data;
					dec_in1			= immidiate_u;
					dec_rd_addr		= if_rt;
					dec_rd_en		= `ENABLE;
				end
				`OPCODE_ORI : begin
					dec_ia_op		= `PU_IA_OP_OR;
					dec_in0			= rs_data;
					dec_in1			= immidiate_u;
					dec_rd_addr		= if_rt;
					dec_rd_en		= `ENABLE;
				end
				`OPCODE_XORI : begin
					dec_ia_op		= `PU_IA_OP_XOR;
					dec_in0			= rs_data;
					dec_in1			= immidiate_u;
					dec_rd_addr		= if_rt;
					dec_rd_en		= `ENABLE;
				end
				`OPCODE_LUI : begin
					dec_ia_op		= `PU_IA_OP_THA;
					dec_in0			= immidiate_up;
					dec_rd_addr		= if_rt;
					dec_rd_en		= `ENABLE;
				end
				`OPCODE_COP0 : begin
					case (if_rs)
					`RS_MF : begin
						case (tmode)
						`PU_TMODE_KERNEL : begin
							dec_ia_op		= `PU_IA_OP_THA;
							dec_in0			= cpr_rd_data;
							dec_rd_addr		= if_rt;
							dec_rd_en		= `ENABLE;
						end
						`PU_TMODE_USER : begin
							dec_pif			= `ENABLE;
						end
						endcase
					end
					`RS_MT : begin
						case (tmode)
						`PU_TMODE_KERNEL : begin
							dec_cop_op		= `PU_COP_OP_MT;
							dec_ia_op		= `PU_IA_OP_THA;
							dec_in0			= rt_data;
							dec_rd_addr		= if_rd;
						end
						`PU_TMODE_USER : begin
							dec_pif			= `ENABLE;
						end
						endcase
					end
					endcase
				end
				`OPCODE_LB : begin
					dec_ls_op		= `PU_LS_OP_LB;
					dec_ia_op		= `PU_IA_OP_ADD;
					dec_in0			= rs_data;
					dec_in1			= offset_s;
					dec_rd_addr		= if_rt;
					dec_rd_en		= `ENABLE;
				end
				`OPCODE_LH : begin
					dec_ls_op		= `PU_LS_OP_LH;
					dec_ia_op		= `PU_IA_OP_ADD;
					dec_in0			= rs_data;
					dec_in1			= offset_s;
					dec_rd_addr		= if_rt;
					dec_rd_en		= `ENABLE;
				end
				`OPCODE_LW : begin
					dec_ls_op		= `PU_LS_OP_LW;
					dec_ia_op		= `PU_IA_OP_ADD;
					dec_in0			= rs_data;
					dec_in1			= offset_s;
					dec_rd_addr		= if_rt;
					dec_rd_en		= `ENABLE;
				end
				`OPCODE_LBU : begin
					dec_ls_op		= `PU_LS_OP_LBU;
					dec_ia_op		= `PU_IA_OP_ADD;
					dec_in0			= rs_data;
					dec_in1			= offset_s;
					dec_rd_addr		= if_rt;
					dec_rd_en		= `ENABLE;
				end
				`OPCODE_LHU : begin
					dec_ls_op		= `PU_LS_OP_LHU;
					dec_ia_op		= `PU_IA_OP_ADD;
					dec_in0			= rs_data;
					dec_in1			= offset_s;
					dec_rd_addr		= if_rt;
					dec_rd_en		= `ENABLE;
				end
				`OPCODE_SB : begin
					dec_ls_op		= `PU_LS_OP_SB;
					dec_ia_op		= `PU_IA_OP_ADD;
					dec_in0			= rs_data;
					dec_in1			= offset_s;
					dec_st_data		= rt_data;
				end
				`OPCODE_SH : begin
					dec_ls_op		= `PU_LS_OP_SH;
					dec_ia_op		= `PU_IA_OP_ADD;
					dec_in0			= rs_data;
					dec_in1			= offset_s;
					dec_st_data		= rt_data;
				end
				`OPCODE_SW : begin
					dec_ls_op		= `PU_LS_OP_SW;
					dec_ia_op		= `PU_IA_OP_ADD;
					dec_in0			= rs_data;
					dec_in1			= offset_s;
					dec_st_data		= rt_data;
				end
				`OPCODE_THREAD : begin
					case (if_function)
					`FUNCTION_MKTH : begin
						case (tmode)
						`PU_TMODE_KERNEL : begin
							dec_cop_op		= `PU_COP_OP_MKTH;
							dec_ia_op		= `PU_IA_OP_THA;
							dec_in0			= rs_data;
							dec_st_data		= rt_data;
							dec_rd_addr		= if_rd;
							dec_rd_en		= `ENABLE;
						end
						`PU_TMODE_USER : begin
							dec_pif			= `ENABLE;
						end
						endcase
					end
					`FUNCTION_DELTH : begin
						case (tmode)
						`PU_TMODE_KERNEL : begin
							dec_cop_op		= `PU_COP_OP_DELTH;
							dec_ia_op		= `PU_IA_OP_THA;
							dec_in0			= rs_data;
							dec_rd_addr		= if_rd;
							dec_rd_en		= `ENABLE;
						end
						`PU_TMODE_USER : begin
							dec_pif			= `ENABLE;
						end
						endcase
					end
					`FUNCTION_SWTH : begin
						case (tmode)
						`PU_TMODE_KERNEL : begin
							dec_cop_op		= `PU_COP_OP_SWTH;
							dec_ia_op		= `PU_IA_OP_THA;
							dec_in0			= rs_data;
							dec_rd_addr		= if_rd;
							dec_rd_en		= `ENABLE;
						end
						`PU_TMODE_USER : begin
							dec_pif			= `ENABLE;
						end
						endcase
					end
					`FUNCTION_NEXTTH : begin
						case (tmode)
						`PU_TMODE_KERNEL : begin
							dec_cop_op		= `PU_COP_OP_NEXTTH;
							dec_rd_addr		= if_rd;
							dec_rd_en		= `ENABLE;
						end
						`PU_TMODE_USER : begin
							dec_pif			= `ENABLE;
						end
						endcase
					end
					endcase
				end
`ifdef IMP_VUS
				`OPCODE_VECTOR : begin
					case (if_function)
					`FUNCTION_VRSV : begin
						dec_cop_op		= `PU_COP_OP_VRSV;
						dec_ia_op		= `PU_IA_OP_THA;
						dec_st_data		= rt_data;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
						dec_vus_op		= `VUS_OP_RSV;
						dec_vus_status	= rs_data;
						dec_vus_tileid	= rt_data[`CpuTileIdBus];
					end
					`FUNCTION_VRLS : begin
						dec_cop_op		= `PU_COP_OP_VRLS;
						dec_ia_op		= `PU_IA_OP_THA;
						dec_rd_addr		= if_rd;
						dec_rd_en		= `ENABLE;
						dec_vus_op		= `VUS_OP_RLS;
						dec_vus_tileid	= vus_tileid;
					end
					`FUNCTION_VSTART : begin
						if (vus_mode == `VUS_MODE_SEND) begin
							dec_cop_op		= `PU_COP_OP_VSLEEP;
							dec_vus_op		= `VUS_OP_START;
							dec_vus_tileid	= vus_tileid;
							dec_vus_pc		= npc;
						end
					end
					`FUNCTION_VEND : begin
					end
					endcase
				end
`endif
				endcase
			end
		end
	endgenerate

endmodule

