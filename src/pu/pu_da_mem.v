/*----------------------------------------------------------------------------*
 *	SMIPS
 *
 *	File	: pu_da_mem.v
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

module pu_da_mem(
	/******** Clock and Reset ********/
	input wire							clk,
	input wire							rst_,

	/******** Memory ********/
	input wire [`PuDcIndexBus]			mem_rw_index,

	input wire							mem_wr_en,
	input wire [`PuDcTagBus]			mem_wr_ptag,
	input wire							mem_wr_valid,
	input wire [`CoreDataBus]			mem_wr_data,

	output wire [`PuDcTagBus]			mem_rd_ptag,
	output wire							mem_rd_valid,
	output wire [`CoreDataBus]			mem_rd_data,

	/******** Invalidate ********/
	input wire [`PuDcIndexBus]			inv_rw_index,

	input wire							inv_wr_en,
	input wire [`PuDcTagBus]			inv_wr_ptag,
	input wire							inv_wr_valid,

	output wire [`PuDcTagBus]			inv_rd_ptag,
	output wire							inv_rd_valid
);

/*----------------------------------------------------------------------------*
 * Module Instance
 *----------------------------------------------------------------------------*/

`ifdef LIB_TSMC130


`elsif LIB_TSMC65

	/******** Tag and Valid ********/
	sram_dp_128x21 pu_da_mem_tagvalid(
		.QA						({mem_rd_ptag, mem_rd_valid}),
		.QB						({inv_rd_ptag, inv_rd_valid}),
		.CLKA					(clk),
		.CENA					(`ENABLE_),
		.WENA					(~mem_wr_en),
		.AA						(mem_rw_index),
		.DA						({mem_wr_ptag, mem_wr_valid}),
		.CLKB					(clk),
		.CENB					(`ENABLE_),
		.WENB					(~inv_wr_en),
		.AB						(inv_rw_index),
		.DB						({inv_wr_ptag, inv_wr_valid}),
		.EMAA					(3'h0),
		.EMAB					(3'h0),
		.RETN					(`DISABLE_)
	);

	/******** Data ********/
	wire [127:0]						mem_rd_data_high;
	wire [127:0]						mem_rd_data_low;
	assign mem_rd_data = {mem_rd_data_high, mem_rd_data_low};
	rf_sp_128x128 pu_da_mem_data_high(
		.Q						(mem_rd_data_high),
		.CLK					(clk),
		.CEN					(`ENABLE_),
		.WEN					(~mem_wr_en),
		.A						(mem_rw_index),
		.D						(mem_wr_data[255:128]),
		.EMA					(3'h0),
		.RETN					(`DISABLE_)
	);
	rf_sp_128x128 pu_da_mem_data_low(
		.Q						(mem_rd_data_low),
		.CLK					(clk),
		.CEN					(`ENABLE_),
		.WEN					(~mem_wr_en),
		.A						(mem_rw_index),
		.D						(mem_wr_data[127:0]),
		.EMA					(3'h0),
		.RETN					(`DISABLE_)
	);

`else

	/******** Tag ********/
	ram_s2rw#(
		.ADDR_W					(`PU_DC_INDEX_W),
		.DATA_W					(`PU_DC_TAG_W),
		.MASK_W					(1)
	) pu_da_mem_tag(
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
		.ADDR_W					(`PU_DC_INDEX_W),
		.DATA_W					(1),
		.MASK_W					(1)
	) pu_da_mem_valid(
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
		.ADDR_W					(`PU_DC_INDEX_W),
		.DATA_W					(`CORE_DATA_W),
		.MASK_W					(1)
	) pu_da_mem_data(
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

`endif

endmodule

