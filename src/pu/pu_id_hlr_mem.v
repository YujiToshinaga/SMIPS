/*----------------------------------------------------------------------------*
 *	SMIPS
 *
 *	File	: pu_id_hlr_mem.v
 *	Date	: 2012-05-05T11:41:11+9:00
 *	Author	: toshinaga
 *
 *	Description :
 *		***
 *----------------------------------------------------------------------------*/

`include "config.h"

`include "stddef.h"
`include "pu.h"

module pu_id_hlr_mem(
	/******** Clock and Reset ********/
	input wire							clk,
	input wire							rst_,
	/********  ********/
	output wire [`WordDataBus]			hi_rd_data,
	output wire [`WordDataBus]			lo_rd_data,

	/********  ********/
	input wire							hi_wr_en,
	input wire [`WordDataBus]			hi_wr_data,
	input wire							lo_wr_en,
	input wire [`WordDataBus]			lo_wr_data
);

/*----------------------------------------------------------------------------*
 * Wire and Reg
 *----------------------------------------------------------------------------*/
	/******** High and Low Register ********/
	reg [`WordDataBus]					hi;
	reg [`WordDataBus]					lo;

/*----------------------------------------------------------------------------*
 * Combinational Logic
 *----------------------------------------------------------------------------*/
	/********  ********/
	assign hi_rd_data = hi;
	assign lo_rd_data = lo;

/*----------------------------------------------------------------------------*
 * Sequential Logic
 *----------------------------------------------------------------------------*/
	/********  ********/
	always @(posedge clk or negedge rst_) begin
		if (rst_ == `ENABLE_) begin // Reset
			hi <= #1 `WORD_DATA_W'h0;
			lo <= #1 `WORD_DATA_W'h0;
		end else begin // No Reset
			if (hi_wr_en == `ENABLE) begin
				hi <= #1 hi_wr_data;
			end
			if (lo_wr_en == `ENABLE) begin
				lo <= #1 lo_wr_data;
			end
		end
	end

/*----------------------------------------------------------------------------*
 * Debug
 *----------------------------------------------------------------------------*/
`ifdef DEBUG
	/********  ********/
`endif

endmodule

