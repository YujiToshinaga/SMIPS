/*----------------------------------------------------------------------------*
 *	SMIPS
 *
 *	File	: pu_id_gpr.v
 *	Date	: 2012-05-05T11:41:11+9:00
 *	Author	: toshinaga
 *
 *	Description :
 *		***
 *----------------------------------------------------------------------------*/

`include "config.h"

`include "stddef.h"
`include "pu.h"

module pu_id_gpr(
	/******** Clock and Reset ********/
	input wire							clk,
	input wire							rst_,
	/********  ********/
	input wire [`PuPidBus]				pid,
	/********  ********/
	input wire [`PuGprAddrBus]			rd0_addr,
	output wire [`WordDataBus]			rd0_data,
	input wire [`PuGprAddrBus]			rd1_addr,
	output wire [`WordDataBus]			rd1_data,
	input wire [`PuGprAddrBus]			wr_addr,
	input wire							wr_en,
	input wire [`WordDataBus]			wr_data
);

/*----------------------------------------------------------------------------*
 * Wire and Reg
 *----------------------------------------------------------------------------*/
	/********  ********/
	reg [`PuGprAddrBus]					_rd0_addr[0:`PU_PID_NUM-1];
	reg [`PuGprAddrBus]					_rd1_addr[0:`PU_PID_NUM-1];

	wire [`WordDataBus]					_rd0_data[0:`PU_PID_NUM-1];
	wire [`WordDataBus]					_rd1_data[0:`PU_PID_NUM-1];

	reg [`PuGprAddrBus]					_wr_addr[0:`PU_PID_NUM-1];
	reg									_wr_en[0:`PU_PID_NUM-1];
	reg [`WordDataBus]					_wr_data[0:`PU_PID_NUM-1];

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
		for (gi = 0; gi < `PU_PID_NUM; gi = gi + 1) begin : PU_ID_GPR_MEM
			pu_id_gpr_mem pu_id_gpr_mem(
				.clk					(clk),
				.rst_					(rst_),

				.rd0_addr				(_rd0_addr[gi]),

				.rd0_data				(_rd0_data[gi]),

				.rd1_addr				(_rd1_addr[gi]),

				.rd1_data				(_rd1_data[gi]),

				.wr_addr				(_wr_addr[gi]),
				.wr_en					(_wr_en[gi]),
				.wr_data				(_wr_data[gi])
			);
		end
	endgenerate

/*----------------------------------------------------------------------------*
 * Combinational Logic
 *----------------------------------------------------------------------------*/
	/********  ********/
	always @(*) begin
		for (i = 0; i < `PU_PID_NUM; i = i + 1) begin
			_rd0_addr[i]	= `PU_GPR_ADDR_W'h0;
			_rd1_addr[i]	= `PU_GPR_ADDR_W'h0;
		end
		_rd0_addr[pid]	= rd0_addr;
		_rd1_addr[pid]	= rd1_addr;
	end

	assign rd0_data = _rd0_data[pid];
	assign rd1_data = _rd1_data[pid];

	always @(*) begin
		for (i = 0; i < `PU_PID_NUM; i = i + 1) begin
			_wr_addr[i]		= `PU_GPR_ADDR_W'h0;
			_wr_en[i]		= `DISABLE;
			_wr_data[i]		= `WORD_DATA_W'h0;
		end
		_wr_addr[pid]	= wr_addr;
		_wr_en[pid]		= wr_en;
		_wr_data[pid]	= wr_data;
	end

endmodule

