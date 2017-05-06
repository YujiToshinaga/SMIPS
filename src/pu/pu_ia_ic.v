/*----------------------------------------------------------------------------*
 *	SMIPS
 *
 *	File	: pu_ia_ic.v
 *	Date	: 2012-05-05T11:41:11+9:00
 *	Author	: toshinaga
 *
 *	Description :
 *		***
 *----------------------------------------------------------------------------*/

`include "config.h"

`include "stddef.h"
`include "core.h"
`include "pu.h"

module pu_ia_ic(
	/******** Clock and Reset ********/
	input wire							clk,
	input wire							rst_,
	/******** Control ********/
	input wire							on,
	/******** Memory ********/
	input wire [`PuIcIndexBus]			rw_index,

	input wire							wr_en,
	input wire [`PuIcTagBus]			wr_ptag,
	input wire							wr_valid,
	input wire [`CoreDataBus]			wr_data,

	output wire [`PuIcTagBus]			rd_ptag,
	output wire							rd_valid,
	output wire [`CoreDataBus]			rd_data
);

/*----------------------------------------------------------------------------*
 * Module Instance
 *----------------------------------------------------------------------------*/
	/******** Tag ********/
	ram_s2rw#(
		.ADDR_W					(`PU_IC_INDEX_W),
		.DATA_W					(`PU_IC_TAG_W),
		.MASK_W					(1)
	) pu_ia_mem_tag(
		.rst_					(rst_),

		.cs						(`ENABLE),

		.rw0_clk				(clk),
		.rw0_addr				(mem_rw_index),
		.rw0_as					(`ENABLE),
		.rw0_rw					(mem_wr_en),
		.wr0_mask				(mem_wr_en),
		.wr0_data				(mem_wr_ptag),

		.rw0_rdy				(),
		.rd0_data				(mem_rd_ptag),

		.rw1_clk				(clk),
		.rw1_addr				(inv_rw_index),
		.rw1_as					(`ENABLE),
		.rw1_rw					(inv_wr_en),
		.wr1_mask				(inv_wr_en),
		.wr1_data				(inv_wr_ptag),

		.rw1_rdy				(),
		.rd1_data				(inv_rd_ptag)
	);

	/******** Valid ********/
	ram_s2rw#(
		.ADDR_W					(`PU_IC_INDEX_W),
		.DATA_W					(1),
		.MASK_W					(1)
	) pu_ia_mem_valid(
		.rst_					(rst_),

		.cs						(`ENABLE),

		.rw0_clk				(clk),
		.rw0_addr				(mem_rw_index),
		.rw0_as					(`ENABLE),
		.rw0_rw					(mem_wr_en),
		.wr0_mask				(mem_wr_en),
		.wr0_data				(mem_wr_valid),

		.rw0_rdy				(),
		.rd0_data				(mem_rd_valid),

		.rw1_clk				(clk),
		.rw1_addr				(inv_rw_index),
		.rw1_as					(`ENABLE),
		.rw1_rw					(inv_wr_en),
		.wr1_mask				(inv_wr_en),
		.wr1_data				(inv_wr_valid),

		.rw1_rdy				(),
		.rd1_data				(inv_rd_valid)
	);

	/******** Data ********/
	ram_srw#(
		.ADDR_W					(`PU_IC_INDEX_W),
		.DATA_W					(`CORE_DATA_W),
		.MASK_W					(1)
	) pu_ia_mem_data(
		.rst_					(rst_),

		.cs						(`ENABLE),

		.rw_clk					(clk),
		.rw_addr				(mem_rw_index),
		.rw_as					(`ENABLE),
		.rw_rw					(mem_wr_en),
		.wr_mask				(mem_wr_en),
		.wr_data				(mem_wr_data),

		.rw_rdy					(),
		.rd_data				(mem_rd_data)
	);

endmodule

