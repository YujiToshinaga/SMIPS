/*----------------------------------------------------------------------------*
 *	SMIPS
 *
 *	File	: pu_ex.v
 *	Date	: 2012-05-05T11:41:11+9:00
 *	Author	: toshinaga
 *
 *	Description :
 *		***
 *----------------------------------------------------------------------------*/

`include "config.h"

`include "stddef.h"
`include "pu.h"

module pu_ex(
	/******** Clock and Reset ********/
	input wire							clk,
	input wire							rst_,
	/******** Coprocessor Access ********/
	// Pipeline Control
	input wire [`PuPidBus]				pid,
	input wire [`PuTidBus]				tid,
	input wire [`PuTmodeBus]			tmode,
	input wire							ex_flush,
	input wire							ex_stall,
	output wire							ex_busy,
	/******** ID Access ********/
	// ID Forwarding
	output wire [`PuCopOpBus]			fwd_ex_cop_op,
	output wire [`PuLsOpBus]			fwd_ex_ls_op,
	output wire [`PuGprAddrBus]			fwd_ex_rd_addr,
	output wire							fwd_ex_rd_en,
	output wire [`WordDataBus]			fwd_ex_rd_data,
	output wire							fwd_ex_hi_en,
	output wire [`WordDataBus]			fwd_ex_hi_data,
	output wire							fwd_ex_lo_en,
	output wire [`WordDataBus]			fwd_ex_lo_data,
	// ID/EX Pipeline Register
	input wire							id_pr_en,
	input wire [`WordAddrBus]			id_pr_pc,
	input wire [`PuCopOpBus]			id_pr_cop_op,
	input wire [`PuLsOpBus]				id_pr_ls_op,
	input wire [`PuIaOpBus]				id_pr_ia_op,
	input wire [`WordDataBus]			id_pr_in0,
	input wire [`WordDataBus]			id_pr_in1,
	input wire [`WordDataBus]			id_pr_st_data,
	input wire [`PuGprAddrBus]			id_pr_rd_addr,
	input wire							id_pr_rd_en,
	input wire							id_pr_hi_en,
	input wire							id_pr_lo_en,
	input wire							id_pr_bd,
	input wire [`PuExpIdBus]			id_pr_exp,
	/******** DA Access ********/
	// EX/DA Non Pipeline
	output reg [`WordDataBus]			ex_np_out,
	// EX/DA Pipeline Register
	output reg							ex_pr_en,
	output reg [`WordAddrBus]			ex_pr_pc,
	output reg [`PuCopOpBus]			ex_pr_cop_op,
	output reg [`PuLsOpBus]				ex_pr_ls_op,
	output reg [`WordDataBus]			ex_pr_out,
	output reg [`WordDataBus]			ex_pr_st_data,
	output reg [`PuGprAddrBus]			ex_pr_rd_addr,
	output reg							ex_pr_rd_en,
	output reg							ex_pr_hi_en,
	output reg [`WordDataBus]			ex_pr_hi_data,
	output reg							ex_pr_lo_en,
	output reg [`WordDataBus]			ex_pr_lo_data,
	output reg							ex_pr_bd,
	output reg [`PuExpExBus]			ex_pr_exp
);

/*----------------------------------------------------------------------------*
 * Wire and Reg
 *----------------------------------------------------------------------------*/
	/******** Integer Arthmetic ********/
	wire [`WordDataBus]					ia_out;
	wire [`WordDataBus]					ia_hi;
	wire [`WordDataBus]					ia_lo;
	wire								ia_ovf;

/*----------------------------------------------------------------------------*
 * Module Instance
 *----------------------------------------------------------------------------*/
	/******** Integer Arthmetic ********/
	pu_ex_ia pu_ex_ia(
		.op						(id_pr_ia_op),
		.in0					(id_pr_in0),
		.in1					(id_pr_in1),

		.out					(ia_out),
		.hi						(ia_hi),
		.lo						(ia_lo),
		.ovf					(ia_ovf)
	);

/*----------------------------------------------------------------------------*
 * Combinational Logic
 *----------------------------------------------------------------------------*/
	/******** Forwarding ********/
	assign fwd_ex_cop_op	= id_pr_cop_op;
	assign fwd_ex_ls_op		= id_pr_ls_op;
	assign fwd_ex_rd_addr	= id_pr_rd_addr;
	assign fwd_ex_rd_en		= id_pr_rd_en;
	assign fwd_ex_rd_data	= ia_out;
	assign fwd_ex_hi_en		= id_pr_hi_en;
	assign fwd_ex_hi_data	= ia_hi;
	assign fwd_ex_lo_en		= id_pr_hi_en;
	assign fwd_ex_lo_data	= ia_lo;

	/********  ********/
	assign ex_busy = `DISABLE;

	/********  ********/
	always @(*) begin
		if (rst_ == `ENABLE_) begin
			ex_np_out = `WORD_DATA_W'h0;
		end else begin
			if (ex_flush == `ENABLE) begin
				if (ex_stall == `DISABLE) begin
					ex_np_out = `WORD_DATA_W'h0;
				end else begin
					ex_np_out = ex_pr_out;
				end
			end else if (id_pr_en == `DISABLE) begin
				if (ex_stall == `DISABLE) begin
					ex_np_out = `WORD_DATA_W'h0;
				end else begin
					ex_np_out = ex_pr_out;
				end
			end else if (id_pr_exp != `PU_EXP_ID_NO) begin
				if (ex_stall == `DISABLE) begin
					ex_np_out = `WORD_DATA_W'h0;
				end else begin
					ex_np_out = ex_pr_out;
				end
			end else if (ia_ovf == `ENABLE) begin
				if (ex_stall == `DISABLE) begin
					ex_np_out = `WORD_DATA_W'h0;
				end else begin
					ex_np_out = ex_pr_out;
				end
			end else begin
				if (ex_stall == `DISABLE) begin
					ex_np_out = ia_out;
				end else begin
					ex_np_out = ex_pr_out;
				end
			end
		end
	end

/*----------------------------------------------------------------------------*
 * Sequential Logic
 *----------------------------------------------------------------------------*/
	/******** EX State Transition ********/
	always @(posedge clk or negedge rst_) begin
		if (rst_ == `ENABLE_) begin // Reset
			ex_pr_en			<= #1 `DISABLE;
			ex_pr_pc			<= #1 `WORD_ADDR_W'h0;
			ex_pr_cop_op		<= #1 `PU_COP_OP_NO;
			ex_pr_ls_op			<= #1 `PU_LS_OP_NO;
			ex_pr_out			<= #1 `WORD_DATA_W'h0;
			ex_pr_st_data		<= #1 `WORD_DATA_W'h0;
			ex_pr_rd_addr		<= #1 `PU_GPR_ADDR_W'h0;
			ex_pr_rd_en			<= #1 `DISABLE;
			ex_pr_hi_en			<= #1 `DISABLE;
			ex_pr_hi_data		<= #1 `WORD_DATA_W'h0;
			ex_pr_lo_en			<= #1 `DISABLE;
			ex_pr_lo_data		<= #1 `WORD_DATA_W'h0;
			ex_pr_bd			<= #1 `DISABLE;
			ex_pr_exp			<= #1 `PU_EXP_EX_NO;
		end else begin
			if (ex_flush == `ENABLE) begin // Pipeline Flush
				if (ex_stall == `DISABLE) begin
					ex_pr_en			<= #1 `DISABLE;
					ex_pr_pc			<= #1 `WORD_ADDR_W'h0;
					ex_pr_cop_op		<= #1 `PU_COP_OP_NO;
					ex_pr_ls_op			<= #1 `PU_LS_OP_NO;
					ex_pr_out			<= #1 `WORD_DATA_W'h0;
					ex_pr_st_data		<= #1 `WORD_DATA_W'h0;
					ex_pr_rd_addr		<= #1 `PU_GPR_ADDR_W'h0;
					ex_pr_rd_en			<= #1 `DISABLE;
					ex_pr_hi_en			<= #1 `DISABLE;
					ex_pr_hi_data		<= #1 `WORD_DATA_W'h0;
					ex_pr_lo_en			<= #1 `DISABLE;
					ex_pr_lo_data		<= #1 `WORD_DATA_W'h0;
					ex_pr_bd			<= #1 `DISABLE;
					ex_pr_exp			<= #1 `PU_EXP_EX_NO;
				end
			end else if (id_pr_en == `DISABLE) begin // Pipeline Enable
				if (ex_stall == `DISABLE) begin
					ex_pr_en			<= #1 `DISABLE;
					ex_pr_pc			<= #1 `WORD_ADDR_W'h0;
					ex_pr_cop_op		<= #1 `PU_COP_OP_NO;
					ex_pr_ls_op			<= #1 `PU_LS_OP_NO;
					ex_pr_out			<= #1 `WORD_DATA_W'h0;
					ex_pr_st_data		<= #1 `WORD_DATA_W'h0;
					ex_pr_rd_addr		<= #1 `PU_GPR_ADDR_W'h0;
					ex_pr_rd_en			<= #1 `DISABLE;
					ex_pr_hi_en			<= #1 `DISABLE;
					ex_pr_hi_data		<= #1 `WORD_DATA_W'h0;
					ex_pr_lo_en			<= #1 `DISABLE;
					ex_pr_lo_data		<= #1 `WORD_DATA_W'h0;
					ex_pr_bd			<= #1 `DISABLE;
					ex_pr_exp			<= #1 `PU_EXP_EX_NO;
				end
			end else if (id_pr_exp != `PU_EXP_ID_NO) begin // Exception
				if (ex_stall == `DISABLE) begin
					ex_pr_en			<= #1 `ENABLE;
					ex_pr_pc			<= #1 id_pr_pc;
					ex_pr_cop_op		<= #1 `PU_COP_OP_NO;
					ex_pr_ls_op			<= #1 `PU_LS_OP_NO;
					ex_pr_out			<= #1 `WORD_DATA_W'h0;
					ex_pr_st_data		<= #1 `WORD_DATA_W'h0;
					ex_pr_rd_addr		<= #1 `PU_GPR_ADDR_W'h0;
					ex_pr_rd_en			<= #1 `DISABLE;
					ex_pr_hi_en			<= #1 `DISABLE;
					ex_pr_hi_data		<= #1 `WORD_DATA_W'h0;
					ex_pr_lo_en			<= #1 `DISABLE;
					ex_pr_lo_data		<= #1 `WORD_DATA_W'h0;
					ex_pr_bd			<= #1 id_pr_bd;
					ex_pr_exp			<= #1 id_pr_exp;
				end
			end else if (ia_ovf == `ENABLE) begin
				if (ex_stall == `DISABLE) begin
					ex_pr_en			<= #1 `ENABLE;
					ex_pr_pc			<= #1 id_pr_pc;
					ex_pr_cop_op		<= #1 `PU_COP_OP_NO;
					ex_pr_ls_op			<= #1 `PU_LS_OP_NO;
					ex_pr_out			<= #1 `WORD_DATA_W'h0;
					ex_pr_st_data		<= #1 `WORD_DATA_W'h0;
					ex_pr_rd_addr		<= #1 `PU_GPR_ADDR_W'h0;
					ex_pr_rd_en			<= #1 `DISABLE;
					ex_pr_hi_en			<= #1 `DISABLE;
					ex_pr_hi_data		<= #1 `WORD_DATA_W'h0;
					ex_pr_lo_en			<= #1 `DISABLE;
					ex_pr_lo_data		<= #1 `WORD_DATA_W'h0;
					ex_pr_bd			<= #1 id_pr_bd;
					ex_pr_exp			<= #1 `PU_EXP_EX_OVF;
				end
			end else begin
				if (ex_stall == `DISABLE) begin
					ex_pr_en			<= #1 `ENABLE;
					ex_pr_pc			<= #1 id_pr_pc;
					ex_pr_cop_op		<= #1 id_pr_cop_op;
					ex_pr_ls_op			<= #1 id_pr_ls_op;
					ex_pr_out			<= #1 ia_out;
					ex_pr_st_data		<= #1 id_pr_st_data;
					ex_pr_rd_addr		<= #1 id_pr_rd_addr;
					ex_pr_rd_en			<= #1 id_pr_rd_en;
					ex_pr_hi_en			<= #1 id_pr_hi_en;
					ex_pr_hi_data		<= #1 ia_hi;
					ex_pr_lo_en			<= #1 id_pr_lo_en;
					ex_pr_lo_data		<= #1 ia_lo;
					ex_pr_bd			<= #1 id_pr_bd;
					ex_pr_exp			<= #1 `PU_EXP_EX_NO;
				end
			end
		end
	end

/*----------------------------------------------------------------------------*
 * Debug
 *----------------------------------------------------------------------------*/
`ifdef DEBUG
	/********  ********/
	wire [`ByteAddrBus] EX_BPC = {id_pr_pc, `WORD_BO_W'h0};
`endif

endmodule

