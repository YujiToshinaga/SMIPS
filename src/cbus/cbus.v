/*----------------------------------------------------------------------------*
 *	SMIPS
 *
 *	File	: cbus.v
 *	Date	: 2012-05-05T11:41:11+9:00
 *	Author	: toshinaga
 *
 *	Description :
 *		***
 *----------------------------------------------------------------------------*/

`include "config.h"

`include "stddef.h"
`include "core.h"
`include "cbus.h"
`include "l2c.h"

module cbus(
	/******** Clock and Reset ********/
	input wire							clk,
	input wire							rst_,

	/******** Master 0 ********/
	input wire							m0_req,
	input wire [`L2cCbusCmdBus]			m0_cmd,
	input wire [`CoreAddrBus]			m0_addr,
	input wire [`CoreDataBeBus]			m0_data_be,
	input wire [`CoreDataBus]			m0_data,

	output wire							m0_ack,

	output wire							s0_rdy,
	output wire [`CoreDataBus]			s0_data,

	/******** Master 1 ********/
	input wire							m1_req,
	input wire [`L2cCbusCmdBus]			m1_cmd,
	input wire [`CoreAddrBus]			m1_addr,
	input wire [`CoreDataBeBus]			m1_data_be,
	input wire [`CoreDataBus]			m1_data,

	output wire							m1_ack,

	output wire							s1_rdy,
	output wire [`CoreDataBus]			s1_data,

	/******** Master 2 ********/
	input wire							m2_req,
	input wire [`L2cCbusCmdBus]			m2_cmd,
	input wire [`CoreAddrBus]			m2_addr,
	input wire [`CoreDataBeBus]			m2_data_be,
	input wire [`CoreDataBus]			m2_data,

	output wire							m2_ack,

	output wire							s2_rdy,
	output wire [`CoreDataBus]			s2_data,

	/******** Master 3 ********/
	input wire							m3_req,
	input wire [`L2cCbusCmdBus]			m3_cmd,
	input wire [`CoreAddrBus]			m3_addr,
	input wire [`CoreDataBeBus]			m3_data_be,
	input wire [`CoreDataBus]			m3_data,

	output wire							m3_ack,

	output wire							s3_rdy,
	output wire [`CoreDataBus]			s3_data,

	/******** Slave ********/
	output wire							m_req,
	output wire [`L2cCbusCmdBus]		m_cmd,
	output wire [`CoreAddrBus]			m_addr,
	output wire [`CoreUidBus]			m_uid,
	output wire [`CoreDataBeBus]		m_data_be,
	output wire [`CoreDataBus]			m_data,

	input wire							m_ack,

	input wire							s_rdy,
	input wire [`CoreUidBus]			s_uid,
	input wire [`CoreDataBus]			s_data
);

/*----------------------------------------------------------------------------*
 * Wire and Reg
 *----------------------------------------------------------------------------*/
	/********  ********/
	wire								m0_grnt;
	wire								m1_grnt;
	wire								m2_grnt;
	wire								m3_grnt;

/*----------------------------------------------------------------------------*
 * Module Instance
 *----------------------------------------------------------------------------*/
	/********  ********/
	arb_4ch_rr cbus_arb(
		.clk					(clk),
		.rst_					(rst_),

		.request_0				(m0_req),

		.grant_0				(m0_grnt),

		.request_1				(m1_req),

		.grant_1				(m1_grnt),

		.request_2				(m2_req),

		.grant_2				(m2_grnt),

		.request_3				(m3_req),

		.grant_3				(m3_grnt)
	);

	/********  ********/
	cbus_mux cbus_mux(
		.m0_grnt				(m0_grnt),

		.m0_req					(m0_req),
		.m0_addr				(m0_addr),
		.m0_cmd					(m0_cmd),
		.m0_data_be				(m0_data_be),
		.m0_data				(m0_data),

		.m0_ack					(m0_ack),

		.s0_rdy					(s0_rdy),
		.s0_data				(s0_data),

		.m1_grnt				(m1_grnt),

		.m1_req					(m1_req),
		.m1_addr				(m1_addr),
		.m1_cmd					(m1_cmd),
		.m1_data_be				(m1_data_be),
		.m1_data				(m1_data),

		.m1_ack					(m1_ack),

		.s1_rdy					(s1_rdy),
		.s1_data				(s1_data),

		.m2_grnt				(m2_grnt),

		.m2_req					(m2_req),
		.m2_addr				(m2_addr),
		.m2_cmd					(m2_cmd),
		.m2_data_be				(m2_data_be),
		.m2_data				(m2_data),

		.m2_ack					(m2_ack),

		.s2_rdy					(s2_rdy),
		.s2_data				(s2_data),

		.m3_grnt				(m3_grnt),

		.m3_req					(m3_req),
		.m3_addr				(m3_addr),
		.m3_cmd					(m3_cmd),
		.m3_data_be				(m3_data_be),
		.m3_data				(m3_data),

		.m3_ack					(m3_ack),

		.s3_rdy					(s3_rdy),
		.s3_data				(s3_data),

		.m_req					(m_req),
		.m_cmd					(m_cmd),
		.m_addr					(m_addr),
		.m_uid					(m_uid),
		.m_data_be				(m_data_be),
		.m_data					(m_data),

		.m_ack					(m_ack),

		.s_rdy					(s_rdy),
		.s_uid					(s_uid),
		.s_data					(s_data)
	);

endmodule

