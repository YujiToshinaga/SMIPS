/*----------------------------------------------------------------------------*
 *	SMIPS
 *
 *	File	: cbus_mux.v
 *	Date	: 2012-05-05T11:41:11+9:00
 *	Author	: toshinaga
 *
 *	Description :
 *		***
 *----------------------------------------------------------------------------*/

`include "config.h"

`include "stddef.h"
`include "l2c.h"
`include "cbus.h"

module cbus_mux(
	/******** Master 0 ********/
	input wire							m0_grnt,

	input wire							m0_req,
	input wire [`L2cCbusCmdBus]			m0_cmd,
	input wire [`CoreAddrBus]			m0_addr,
	input wire [`CoreDataBeBus]			m0_data_be,
	input wire [`CoreDataBus]			m0_data,

	output reg							m0_ack,

	output reg							s0_rdy,
	output reg [`CoreDataBus]			s0_data,

	/******** Master 1 ********/
	input wire							m1_grnt,

	input wire							m1_req,
	input wire [`L2cCbusCmdBus]			m1_cmd,
	input wire [`CoreAddrBus]			m1_addr,
	input wire [`CoreDataBeBus]			m1_data_be,
	input wire [`CoreDataBus]			m1_data,

	output reg							m1_ack,

	output reg							s1_rdy,
	output reg [`CoreDataBus]			s1_data,

	/******** Master 2 ********/
	input wire							m2_grnt,

	input wire							m2_req,
	input wire [`L2cCbusCmdBus]			m2_cmd,
	input wire [`CoreAddrBus]			m2_addr,
	input wire [`CoreDataBeBus]			m2_data_be,
	input wire [`CoreDataBus]			m2_data,

	output reg							m2_ack,

	output reg							s2_rdy,
	output reg [`CoreDataBus]			s2_data,

	/******** Master 3 ********/
	input wire							m3_grnt,

	input wire							m3_req,
	input wire [`L2cCbusCmdBus]			m3_cmd,
	input wire [`CoreAddrBus]			m3_addr,
	input wire [`CoreDataBeBus]			m3_data_be,
	input wire [`CoreDataBus]			m3_data,

	output reg							m3_ack,

	output reg							s3_rdy,
	output reg [`CoreDataBus]			s3_data,

	/******** Slave ********/
	output reg							m_req,
	output reg [`L2cCbusCmdBus]			m_cmd,
	output reg [`CoreAddrBus]			m_addr,
	output reg [`CoreUidBus]			m_uid,
	output reg [`CoreDataBeBus]			m_data_be,
	output reg [`CoreDataBus]			m_data,

	input wire							m_ack,

	input wire							s_rdy,
	input wire [`CoreUidBus]			s_uid,
	input wire [`CoreDataBus]			s_data
);

/*----------------------------------------------------------------------------*
 * Sequential Logic
 *----------------------------------------------------------------------------*/
	/********  ********/
	always @(*) begin
		m_req		= `DISABLE;
		m_cmd		= `L2C_CBUS_CMD_NO;
		m_addr		= `CORE_ADDR_W'h0;
		m_uid		= `CORE_UID_W'h0;
		m_data_be	= {`CORE_DATA_BE_W{`DISABLE}};
		m_data		= `CORE_DATA_W'h0;

		m0_ack		= `DISABLE;
		m1_ack		= `DISABLE;
		m2_ack		= `DISABLE;
		m3_ack		= `DISABLE;

		if (m0_grnt == `ENABLE) begin
			m_req		= m0_req;
			m_cmd		= m0_cmd;
			m_addr		= m0_addr;
			m_uid		= `CORE_UID_W'h0;
			m_data_be	= m0_data_be;
			m_data		= m0_data;

			m0_ack		= m_ack;
		end else if (m1_grnt == `ENABLE) begin
			m_req		= m1_req;
			m_cmd		= m1_cmd;
			m_addr		= m1_addr;
			m_uid		= `CORE_UID_W'h1;
			m_data_be	= m1_data_be;
			m_data		= m1_data;

			m1_ack		= m_ack;
		end else if (m2_grnt == `ENABLE) begin
			m_req		= m2_req;
			m_cmd		= m2_cmd;
			m_addr		= m2_addr;
			m_uid		= `CORE_UID_W'h2;
			m_data_be	= m2_data_be;
			m_data		= m2_data;

			m2_ack		= m_ack;
		end else if (m3_grnt == `ENABLE) begin
			m_req		= m3_req;
			m_cmd		= m3_cmd;
			m_addr		= m3_addr;
			m_uid		= `CORE_UID_W'h3;
			m_data_be	= m3_data_be;
			m_data		= m3_data;

			m3_ack		= m_ack;
		end
	end

	/********  ********/
	always @(*) begin
		s0_rdy	= `DISABLE;
		s0_data	= `CORE_DATA_W'h0;
		s1_rdy	= `DISABLE;
		s1_data	= `CORE_DATA_W'h0;
		s2_rdy	= `DISABLE;
		s2_data	= `CORE_DATA_W'h0;
		s3_rdy	= `DISABLE;
		s3_data	= `CORE_DATA_W'h0;

		case (s_uid)
		`CORE_UID_W'h0: begin
			s0_rdy	= s_rdy;
			s0_data	= s_data;
		end
		`CORE_UID_W'h1: begin
			s1_rdy	= s_rdy;
			s1_data	= s_data;
		end
		`CORE_UID_W'h2: begin
			s2_rdy	= s_rdy;
			s2_data	= s_data;
		end
		`CORE_UID_W'h3: begin
			s3_rdy	= s_rdy;
			s3_data	= s_data;
		end
		endcase
	end

endmodule

