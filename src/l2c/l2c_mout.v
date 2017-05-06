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

`include "config.h"

`include "stddef.h"
`include "core.h"
`include "l2c.h"
`include "cbus.h"
`include "xu.h"

module l2c_mout(
	/******** Clock and Reset ********/
	input wire							clk,
	input wire							rst_,

	/********  ********/
	input wire									cbus_rw_req,
	input wire [`L2cIndexBus]					cbus_rw_index,
	input wire [1*`L2C_WAY_NUM-1:0]				cbus_wr_en_pack,
	input wire [`L2C_TAG_W*`L2C_WAY_NUM-1:0]	cbus_wr_tag_pack,
	input wire [1*`L2C_WAY_NUM-1:0]				cbus_wr_valid_pack,
	input wire [1*`L2C_WAY_NUM-1:0]				cbus_wr_dirty_pack,
	input wire [`CORE_DATA_W*`L2C_WAY_NUM-1:0]	cbus_wr_data_pack,

	output reg									cbus_rw_rdy,
	output reg [`L2C_TAG_W*`L2C_WAY_NUM-1:0]	cbus_rd_tag_pack,
	output reg [1*`L2C_WAY_NUM-1:0]				cbus_rd_valid_pack,
	output reg [1*`L2C_WAY_NUM-1:0]				cbus_rd_dirty_pack,
	output reg [`CORE_DATA_W*`L2C_WAY_NUM-1:0]	cbus_rd_data_pack,

	/********  ********/
	input wire									xu_rw_req,
	input wire [`L2cIndexBus]					xu_rw_index,
	input wire [1*`L2C_WAY_NUM-1:0]				xu_wr_en_pack,
	input wire [`L2C_TAG_W*`L2C_WAY_NUM-1:0]	xu_wr_tag_pack,
	input wire [1*`L2C_WAY_NUM-1:0]				xu_wr_valid_pack,
	input wire [1*`L2C_WAY_NUM-1:0]				xu_wr_dirty_pack,
	input wire [`CORE_DATA_W*`L2C_WAY_NUM-1:0]	xu_wr_data_pack,

	output reg									xu_rw_rdy,
	output reg [`L2C_TAG_W*`L2C_WAY_NUM-1:0]	xu_rd_tag_pack,
	output reg [1*`L2C_WAY_NUM-1:0]				xu_rd_valid_pack,
	output reg [1*`L2C_WAY_NUM-1:0]				xu_rd_dirty_pack,
	output reg [`CORE_DATA_W*`L2C_WAY_NUM-1:0]	xu_rd_data_pack,

	/********  ********/
	output reg									rw_req,
	output reg [`L2cIndexBus]					rw_index,
	output reg [1*`L2C_WAY_NUM-1:0]				wr_en_pack,
	output reg [`L2C_TAG_W*`L2C_WAY_NUM-1:0]	wr_tag_pack,
	output reg [1*`L2C_WAY_NUM-1:0]				wr_valid_pack,
	output reg [1*`L2C_WAY_NUM-1:0]				wr_dirty_pack,
	output reg [`CORE_DATA_W*`L2C_WAY_NUM-1:0]	wr_data_pack,

	input wire									rw_rdy,
	input wire [`L2C_TAG_W*`L2C_WAY_NUM-1:0]	rd_tag_pack,
	input wire [1*`L2C_WAY_NUM-1:0]				rd_valid_pack,
	input wire [1*`L2C_WAY_NUM-1:0]				rd_dirty_pack,
	input wire [`CORE_DATA_W*`L2C_WAY_NUM-1:0]	rd_data_pack
);

/*----------------------------------------------------------------------------*
 * Wire and Reg
 *----------------------------------------------------------------------------*/
	/********  ********/
	wire								cbus_rw_grnt;
	wire								xu_rw_grnt;

/*----------------------------------------------------------------------------*
 * Module Instance
 *----------------------------------------------------------------------------*/
	/********  ********/
	arb_2ch_rr l2c_mout_arb(
		.clk					(clk),
		.rst_					(rst_),

		.request_0				(cbus_rw_req),
		.request_1				(xu_rw_req),

		.grant_0				(cbus_rw_grnt),
		.grant_1				(xu_rw_grnt)
	);

/*----------------------------------------------------------------------------*
 * Combinational Logic
 *----------------------------------------------------------------------------*/
	/********  ********/
	always @(*) begin
		rw_req				= `DISABLE;
		rw_index			= `L2C_INDEX_W'h0;
		wr_en_pack			= {1*`L2C_WAY_NUM{`DISABLE}};
		wr_tag_pack			= {`L2C_TAG_W*`L2C_WAY_NUM{1'b0}};
		wr_valid_pack		= {1*`L2C_WAY_NUM{`DISABLE}};
		wr_dirty_pack		= {1*`L2C_WAY_NUM{`DISABLE}};
		wr_data_pack		= {`CORE_DATA_W*`L2C_WAY_NUM{1'b0}};

		cbus_rw_rdy			= `DISABLE;
		cbus_rd_tag_pack	= {`L2C_TAG_W*`L2C_WAY_NUM{1'b0}};
		cbus_rd_valid_pack	= {1*`L2C_WAY_NUM{`DISABLE}};
		cbus_rd_dirty_pack	= {1*`L2C_WAY_NUM{`DISABLE}};
		cbus_rd_data_pack	= {`CORE_DATA_W*`L2C_WAY_NUM{1'b0}};

		xu_rw_rdy			= `DISABLE;
		xu_rd_tag_pack		= {`L2C_TAG_W*`L2C_WAY_NUM{1'b0}};
		xu_rd_valid_pack	= {1*`L2C_WAY_NUM{`DISABLE}};
		xu_rd_dirty_pack	= {1*`L2C_WAY_NUM{`DISABLE}};
		xu_rd_data_pack		= {`CORE_DATA_W*`L2C_WAY_NUM{1'b0}};

		if (cbus_rw_grnt == `ENABLE) begin
			rw_req				= cbus_rw_req;
			rw_index			= cbus_rw_index;
			wr_en_pack			= cbus_wr_en_pack;
			wr_tag_pack			= cbus_wr_tag_pack;
			wr_valid_pack		= cbus_wr_valid_pack;
			wr_dirty_pack		= cbus_wr_dirty_pack;
			wr_data_pack		= cbus_wr_data_pack;

			cbus_rw_rdy			= rw_rdy;
			cbus_rd_tag_pack	= rd_tag_pack;
			cbus_rd_valid_pack	= rd_valid_pack;
			cbus_rd_dirty_pack	= rd_dirty_pack;
			cbus_rd_data_pack	= rd_data_pack;
		end else if (xu_rw_grnt == `ENABLE) begin
			rw_req				= xu_rw_req;
			rw_index			= xu_rw_index;
			wr_en_pack			= xu_wr_en_pack;
			wr_tag_pack			= xu_wr_tag_pack;
			wr_valid_pack		= xu_wr_valid_pack;
			wr_dirty_pack		= xu_wr_dirty_pack;
			wr_data_pack		= xu_wr_data_pack;

			xu_rw_rdy			= rw_rdy;
			xu_rd_tag_pack		= rd_tag_pack;
			xu_rd_valid_pack	= rd_valid_pack;
			xu_rd_dirty_pack	= rd_dirty_pack;
			xu_rd_data_pack		= rd_data_pack;
		end
	end

/*----------------------------------------------------------------------------*
 * Debug
 *----------------------------------------------------------------------------*/
`ifdef DEBUG
	/********  ********/
`endif

endmodule

