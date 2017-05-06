/*----------------------------------------------------------------------------*
 *	SMIPS
 *
 *	File	: pu_wb.v
 *	Date	: 2012-05-05T11:41:11+9:00
 *	Author	: toshinaga
 *
 *	Description :
 *		***
 *----------------------------------------------------------------------------*/

`include "config.h"

`include "stddef.h"
`include "pu.h"

module pu_wb(
	/******** Clock and Reset ********/
	input wire							clk,
	input wire							rst_,
	/******** Coprocessor Access ********/
	// Pipeline Control
	input wire [`PuPidBus]				pid,
	input wire [`PuTidBus]				tid,
	input wire [`PuTmodeBus]			tmode,
	input wire							wb_flush,
	input wire							wb_stall,
	output wire							wb_busy,
	// COP Control
	output wire							wb_en,
	output wire [`WordAddrBus]			wb_pc,
	output wire [`PuCopOpBus]			wb_cop_op,
	output wire [`WordDataBus]			wb_cop_data,
	output wire [`PuGprAddrBus]			wb_rd_addr,
	output wire							wb_rd_en,
	output wire [`WordDataBus]			wb_rd_data,
	output wire							wb_hi_en,
	output wire [`WordDataBus]			wb_hi_data,
	output wire							wb_lo_en,
	output wire [`WordDataBus]			wb_lo_data,
	output wire							wb_bd,
	output wire [`PuExpDaBus]			wb_exp,
	/******** ID Access ********/
	// WB Forwarding
	output wire [`PuCopOpBus]			fwd_wb_cop_op,
	output wire [`PuGprAddrBus]			fwd_wb_rd_addr,
	output wire							fwd_wb_rd_en,
	output wire [`WordDataBus]			fwd_wb_rd_data,
	output wire							fwd_wb_hi_en,
	output wire [`WordDataBus]			fwd_wb_hi_data,
	output wire							fwd_wb_lo_en,
	output wire [`WordDataBus]			fwd_wb_lo_data,
	/******** DA Access ********/
	// DA/WB Pipeline Register
	input wire							da_pr_en,
	input wire [`WordAddrBus]			da_pr_pc,
	input wire [`PuCopOpBus]			da_pr_cop_op,
	input wire [`WordDataBus]			da_pr_cop_data,
	input wire [`PuGprAddrBus]			da_pr_rd_addr,
	input wire							da_pr_rd_en,
	input wire [`WordDataBus]			da_pr_rd_data,
	input wire							da_pr_hi_en,
	input wire [`WordDataBus]			da_pr_hi_data,
	input wire							da_pr_lo_en,
	input wire [`WordDataBus]			da_pr_lo_data,
	input wire							da_pr_bd,
	input wire [`PuExpDaBus]			da_pr_exp
);

/*----------------------------------------------------------------------------*
 * Combinational Logic
 *----------------------------------------------------------------------------*/
	/********  ********/
	assign wb_busy			= `DISABLE;

	/******** Control COP ********/
	assign wb_en			= da_pr_en;
	assign wb_pc			= da_pr_pc;
	assign wb_cop_op		= da_pr_cop_op;
	assign wb_cop_data		= da_pr_cop_data;
	assign wb_rd_addr		= da_pr_rd_addr;
	assign wb_rd_en			= da_pr_rd_en;
	assign wb_rd_data		= da_pr_rd_data;
	assign wb_hi_en			= da_pr_hi_en;
	assign wb_hi_data		= da_pr_hi_data;
	assign wb_lo_en			= da_pr_lo_en;
	assign wb_lo_data		= da_pr_lo_data;
	assign wb_bd			= da_pr_bd;
	assign wb_exp			= da_pr_exp;

	/******** Forwarding ********/
	assign fwd_wb_cop_op	= da_pr_cop_op;
	assign fwd_wb_rd_addr	= da_pr_rd_addr;
	assign fwd_wb_rd_en		= da_pr_rd_en;
	assign fwd_wb_rd_data	= da_pr_rd_data;
	assign fwd_wb_hi_en		= da_pr_hi_en;
	assign fwd_wb_hi_data	= da_pr_hi_data;
	assign fwd_wb_lo_en		= da_pr_lo_en;
	assign fwd_wb_lo_data	= da_pr_lo_data;

/*----------------------------------------------------------------------------*
 * Debug
 *----------------------------------------------------------------------------*/
`ifdef DEBUG
	/********  ********/
	wire [`ByteAddrBus] WB_BPC = {da_pr_pc, `WORD_BO_W'h0};
`endif

endmodule

