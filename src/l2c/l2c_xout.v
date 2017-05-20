/*----------------------------------------------------------------------------*
 *	***
 *
 *	Author	: toshi
 *	File	: l2c_xout.v
 *	Version	: 1.0
 *	Date	: 2012-10-15T16:04:46+9:00
 *	Update	: 2012-10-15T16:25:39+9:00
 *
 *	Description :
 *		***
 *
 *	Histoy :
 *		2012-10-15 1.0	original
 *----------------------------------------------------------------------------*/

`include "config.h"

`include "stddef.h"
`include "cpu.h"
`include "core.h"
`include "l2c.h"
`include "cbus.h"
`include "xu.h"

module l2c_xout(
	/******** Clock and Reset ********/
	input wire							clk,
	input wire							rst_,

	/********  ********/
	input wire							cbus_req,
	input wire [`XuL2cCmdBus]			cbus_cmd,
	input wire [`CoreAddrBus]			cbus_addr,
	input wire [`CoreUidBus]			cbus_uid,
	input wire [`CpuTileIdBus]			cbus_src,
	input wire [`CoreDataBeBus]			cbus_data_be,
	input wire [`CoreDataBus]			cbus_data,

	output reg							cbus_ack,

	/********  ********/
	input wire							xu_req,
	input wire [`XuL2cCmdBus]			xu_cmd,
	input wire [`CoreAddrBus]			xu_addr,
	input wire [`CoreUidBus]			xu_uid,
	input wire [`CpuTileIdBus]			xu_src,
	input wire [`CoreDataBeBus]			xu_data_be,
	input wire [`CoreDataBus]			xu_data,

	output reg							xu_ack,

	/******** Cross Unit Access ********/
	output reg							req,
	output reg [`XuL2cCmdBus]			cmd,
	output reg [`CoreAddrBus]			addr,
	output reg [`CoreUidBus]			uid,
	output reg [`CpuTileIdBus]			src,
	output reg [`CoreDataBeBus]			data_be,
	output reg [`CoreDataBus]			data,

	input wire							ack
);

/*----------------------------------------------------------------------------*
 * Wire and Reg
 *----------------------------------------------------------------------------*/
	/********  ********/
	wire								cbus_grnt;
	wire								xu_grnt;

/*----------------------------------------------------------------------------*
 * Module Instance
 *----------------------------------------------------------------------------*/
	/********  ********/
	arb_2ch_rr l2c_xout_arb(
		.clk					(clk),
		.rst_					(rst_),

		.request_0				(cbus_req),
		.request_1				(xu_req),

		.grant_0				(cbus_grnt),
		.grant_1				(xu_grnt)
	);

/*----------------------------------------------------------------------------*
 * Combinational Logic
 *----------------------------------------------------------------------------*/
	/********  ********/
	always @(*) begin
		req			= `DISABLE;
		cmd			= `XU_L2C_CMD_NO;
		addr		= `CORE_ADDR_W'h0;
		uid			= `CORE_UID_W'h0;
		src			= `CPU_TILE_ID_W'h0;
		data_be		= {`CORE_DATA_BE_W{`DISABLE}};
		data		= `CORE_DATA_W'h0;

		cbus_ack	= `DISABLE;
		xu_ack		= `DISABLE;

		if (cbus_grnt == `ENABLE) begin
			req			= cbus_req;
			cmd			= cbus_cmd;
			addr		= cbus_addr;
			uid			= cbus_uid;
			src			= cbus_src;
			data_be		= cbus_data_be;
			data		= cbus_data;

			cbus_ack	= ack;
		end else if (xu_grnt == `ENABLE) begin
			req			= xu_req;
			cmd			= xu_cmd;
			addr		= xu_addr;
			uid			= xu_uid;
			src			= xu_src;
			data_be		= xu_data_be;
			data		= xu_data;

			xu_ack		= ack;
		end
	end

/*----------------------------------------------------------------------------*
 * Debug
 *----------------------------------------------------------------------------*/
`ifdef DEBUG
	/********  ********/
`endif

endmodule

