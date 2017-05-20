/*----------------------------------------------------------------------------*
 *	SMIPS
 *
 *	File	: pu_id_hlr.v
 *	Date	: 2012-05-05T11:41:11+9:00
 *	Author	: toshinaga
 *
 *	Description :
 *		***
 *----------------------------------------------------------------------------*/

`include "config.h"

`include "stddef.h"
`include "pu.h"

module pu_id_hlr(
	/******** Clock and Reset ********/
	input wire							clk,
	input wire							rst_,
	/********  ********/
	input wire [`PuPidBus]				pid,
	/********  ********/
	output wire [`WordDataBus]			hi_rd_data,
	output wire [`WordDataBus]			lo_rd_data,
	input wire							hi_wr_en,
	input wire [`WordDataBus]			hi_wr_data,
	input wire							lo_wr_en,
	input wire [`WordDataBus]			lo_wr_data
);

/*----------------------------------------------------------------------------*
 * Wire and Reg
 *----------------------------------------------------------------------------*/
	/********  ********/
	wire [`WordDataBus]					_hi_rd_data[0:`PU_PID_NUM-1];
	wire [`WordDataBus]					_lo_rd_data[0:`PU_PID_NUM-1];
	reg									_hi_wr_en[0:`PU_PID_NUM-1];
	reg [`WordDataBus]					_hi_wr_data[0:`PU_PID_NUM-1];
	reg									_lo_wr_en[0:`PU_PID_NUM-1];
	reg [`WordDataBus]					_lo_wr_data[0:`PU_PID_NUM-1];
	/******** Iterator ********/
	integer								i;
	generate
		genvar								gi;
	endgenerate

/*----------------------------------------------------------------------------*
 * Module Instance
 *----------------------------------------------------------------------------*/
	/********  ********/
	generate
		for (gi = 0; gi < `PU_PID_NUM; gi = gi + 1) begin : PU_ID_HLR_MEM
			pu_id_hlr_mem pu_id_hlr_mem(
				.clk					(clk),
				.rst_					(rst_),
				.hi_rd_data				(_hi_rd_data[gi]),
				.lo_rd_data				(_lo_rd_data[gi]),
				.hi_wr_en				(_hi_wr_en[gi]),
				.hi_wr_data				(_hi_wr_data[gi]),
				.lo_wr_en				(_lo_wr_en[gi]),
				.lo_wr_data				(_lo_wr_data[gi])
			);
		end
	endgenerate

/*----------------------------------------------------------------------------*
 * Combinational Logic
 *----------------------------------------------------------------------------*/
	/********  ********/
	assign hi_rd_data = _hi_rd_data[pid];
	assign lo_rd_data = _lo_rd_data[pid];

	always @(*) begin
		for (i = 0; i < `PU_PID_NUM; i = i + 1) begin
			_hi_wr_en[i]	= `DISABLE;
			_hi_wr_data[i]	= `WORD_DATA_W'h0;
			_lo_wr_en[i]	= `DISABLE;
			_lo_wr_data[i]	= `WORD_DATA_W'h0;
		end
		_hi_wr_en[pid]	= hi_wr_en;
		_hi_wr_data[pid]= hi_wr_data;
		_lo_wr_en[pid]	= lo_wr_en;
		_lo_wr_data[pid]= lo_wr_data;
	end

endmodule

