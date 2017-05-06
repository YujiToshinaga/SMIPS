/*----------------------------------------------------------------------------*
 *	SMIPS
 *
 *	File	: pu_ia_cbusif.v
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
`include "cbus.h"

module pu_ia_cbusif(
	/******** Clock and Reset ********/
	input wire							clk,
	input wire							rst_,
	/******** Processor Control ********/
	output reg							busy,
	input wire							req,
	input wire							nc,
	input wire [`CbusAddrBus]			addr,
	output reg							ack,
	output reg [`CbusDataBus]			rd_data
	/******** Cache Bus Access ********/
	output reg							cbus_req,
	input wire							cbus_grt,
	output reg [`CbusCmdBus]			cbus_cmd,
	output reg [`CbusAddrBus]			cbus_addr,
	output wire [`CbusDataBeBus]		cbus_wr_data_be,
	output wire [`CbusDataBus]			cbus_wr_data,
	input wire							cbus_rdy,
	input wire [`CbusDataBus]			cbus_rd_data
);

/*----------------------------------------------------------------------------*
 * Wire and Reg
 *----------------------------------------------------------------------------*/
	/******** Local Parameter ********/
	localparam STATE_W			= 2;
	localparam STATE_IDLE		= 2'h0;
	localparam STATE_RD_REQ		= 2'h1;
	localparam STATE_RD_GRT		= 2'h2;
	localparam STATE_RD_RDY		= 2'h3;
	/******** State Transition ********/
	reg [STATE_W-1:0]					state;

/*----------------------------------------------------------------------------*
 * Combinational Logic
 *----------------------------------------------------------------------------*/
	/******** Cache Bus Busy Signal ********/
	always @(*) begin
		case (state)
		STATE_IDLE : begin
			if (req == `ENABLE) begin
				busy = `ENABLE;
			end else begin
				busy = `DISABLE;
			end
		end
		STATE_RD_REQ : begin
			busy = `ENABLE;
		end
		STATE_RD_GRT : begin
			busy = `ENABLE;
		end
		STATE_RD_RDY : begin
			busy = `ENABLE;
		end
		default : begin
			busy = `DISABLE;
		end
		endcase
	end

	/******** Write Data Signal ********/
	assign cbus_wr_data_be	= {`CORE_DATA_BE_W{`DISABLE}};
	assign cbus_wr_data		= `CORE_DATA_W'h0;

/*----------------------------------------------------------------------------*
 * Sequential Logic
 *----------------------------------------------------------------------------*/
	/******** State Transition ********/
	always @(posedge clk or negedge rst_) begin
		if (rst_ == `ENABLE_) begin
			state		<= STATE_IDLE;
			cbus_req	<= `DISABLE;
			cbus_cmd	<= `CBUS_CMD_NO;
			cbus_addr	<= `CBUS_ADDR_W'h0;
			ack			<= `DISABLE;
			rd_data		<= `CBUS_DATA_W'h0;
		end else begin
			case (state)
			STATE_IDLE : begin
				if (req == `ENABLE) begin
					state		<= STATE_RD_REQ;
					cbus_req	<= `ENABLE;
//					cbus_cmd	<= `CBUS_CMD_NO;
//					cbus_addr	<= `CBUS_ADDR_W'h0;
//					ack			<= `DISABLE;
//					rd_data		<= `CBUS_DATA_W'h0;
				end
			end
			STATE_RD_REQ : begin
				if (cbus_grt == `ENABLE) begin
					if (nc == `ENABLE) begin
						state		<= STATE_RD_GRT;
//						cbus_req	<= `ENABLE;
						cbus_cmd	<= `CBUS_CMD_RN;
						cbus_addr	<= addr;
//						ack			<= `DISABLE;
//						rd_data		<= `CBUS_DATA_W'h0;
					end else begin
						state		<= STATE_RD_GRT;
//						cbus_req	<= `ENABLE;
						cbus_cmd	<= `CBUS_CMD_RD;
						cbus_addr	<= addr;
//						ack			<= `DISABLE;
//						rd_data		<= `CBUS_DATA_W'h0;
					end
				end
			end
			STATE_RD_GRT : begin
				if (cbus_rdy == `ENABLE) begin
					state		<= STATE_RD_RDY;
//					cbus_req	<= `ENABLE;
//					cbus_cmd	<= `CBUS_CMD_RN / _RD;
//					cbus_addr	<= addr;
					ack			<= `ENABLE;
					rd_data		<= cbus_rd_data;
				end
			end
			STATE_RD_RDY : begin
				state		<= STATE_IDLE
				cbus_req	<= `DISABLE;
				cbus_cmd	<= `CBUS_CMD_NO;
				cbus_addr	<= `CBUS_ADDR_W'h0;
				ack			<= `DISABLE;
				rd_data		<= `CBUS_DATA_W'h0;
			end
			endcase
		end
	end

endmodule

