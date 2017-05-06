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

module l2c_cout(
	/******** Clock and Reset ********/
	input wire							clk,
	input wire							rst_,

	/********  ********/
	input wire							cbus_req,
	input wire [`CoreUidBus]			cbus_uid,
	input wire [`CoreDataBus]			cbus_data,

	output reg							cbus_ack,

	/********  ********/
	input wire							xu_req,
	input wire [`CoreUidBus]			xu_uid,
	input wire [`CoreDataBus]			xu_data,

	output reg							xu_ack,

	/******** Cache Bus Access ********/
	output reg							rdy,
	output reg [`CoreUidBus]			uid,
	output reg [`CoreDataBus]			data
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
	arb_2ch_rr l2c_cout_arb(
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
		rdy			= `DISABLE;
		uid			= `CORE_UID_W'h0;
		data		= `CORE_DATA_W'h0;

		cbus_ack	= `DISABLE;
		xu_ack		= `DISABLE;

		if (cbus_grnt == `ENABLE) begin
			rdy			= `ENABLE;
			uid			= cbus_uid;
			data		= cbus_data;

			cbus_ack	= `ENABLE;
		end else if (xu_grnt == `ENABLE) begin
			rdy			= `ENABLE;
			uid			= xu_uid;
			data		= xu_data;

			xu_ack		= `ENABLE;
		end
	end

/*----------------------------------------------------------------------------*
 * Debug
 *----------------------------------------------------------------------------*/
`ifdef DEBUG
	/********  ********/
`endif

endmodule

