/*----------------------------------------------------------------------------*
 *	SMIPS
 *
 *	File	: cpu.v
 *	Date	: 2012-05-05T11:41:11+9:00
 *	Author	: toshinaga
 *
 *	Description :
 *		***
 *----------------------------------------------------------------------------*/

`include "config.h"

`include "stddef.h"
`include "cpu.h"
`include "core.h"
`include "pu.h"
`include "vu.h"
`include "vus.h"
`include "cbus.h"
`include "l2c.h"
`include "xu.h"
`include "ni.h"
`include "router.h"

module core#(
	parameter							COREID				= 0,
	parameter							VU_EN				= `VU_EN
)(
	/******** Clock and Reset ********/
	input wire							clk,
	input wire							rst_,

	/******** Cross Unit Access ********/
	output wire							dl_pot,
	// Master
	output wire							xu_m_req,
	output wire [`XuL2cCmdBus]			xu_m_cmd,
	output wire [`CoreAddrBus]			xu_m_addr,
	output wire [`CoreUidBus]			xu_m_uid,
	output wire [`CpuTileIdBus]			xu_m_src,
	output wire [`CoreDataBeBus]		xu_m_data_be,
	output wire [`CoreDataBus]			xu_m_data,

	input wire							xu_m_ack,

	// Slave
	input wire							xu_s_req,
	input wire [`L2cXuCmdBus]			xu_s_cmd,
	input wire [`CoreAddrBus]			xu_s_addr,
	input wire [`CoreUidBus]			xu_s_uid,
	input wire [`CpuTileIdBus]			xu_s_src,
	input wire [`CoreDataBus]			xu_s_data,

	output wire							xu_s_ack,

	/******** Network Interface Access ********/
	// Master
	output wire							vus_m_req,
	output wire [`RouterCmdBus]			vus_m_cmd,
	output wire [`CoreAddrBus]			vus_m_addr,
	output wire [`CoreUidBus]			vus_m_uid,
	output wire [`CpuTileIdBus]			vus_m_src,
	output wire [`CpuTileIdBus]			vus_m_dst,
	output wire [`CoreDataBeBus]		vus_m_data_be,
	output wire [`CoreDataBus]			vus_m_data,

	input wire							vus_m_ack,

	// Slave
	input wire							vus_s_req,
	input wire [`RouterCmdBus]			vus_s_cmd,
	input wire [`CpuTileIdBus]			vus_s_src,
	input wire [`CoreDataBus]			vus_s_data,

	output wire							vus_s_ack,

	/******** IRQ ********/
	input wire [`PuIrqBus]				irq
);

/*----------------------------------------------------------------------------*
 * Wire and Reg
 *----------------------------------------------------------------------------*/
	/******** Master 0 and 1 : Processor Unit ********/
	wire [`PuPidBus]					vu_pid;
	wire [`WordDataBus]					vu_status;

	wire [`VuRfAddrBus]					vu_sr_rd_addr;

	wire								vu_dd_enq;
	wire [`VuDdBus]						vu_dd;

	wire								l2c_on;

	wire								cbus_m0_req;
	wire [`L2cCbusCmdBus]				cbus_m0_cmd;
	wire [`CoreAddrBus]					cbus_m0_addr;
	wire [`CoreDataBeBus]				cbus_m0_data_be;
	wire [`CoreDataBus]					cbus_m0_data;

	wire								cbus_m1_req;
	wire [`L2cCbusCmdBus]				cbus_m1_cmd;
	wire [`CoreAddrBus]					cbus_m1_addr;
	wire [`CoreDataBeBus]				cbus_m1_data_be;
	wire [`CoreDataBus]					cbus_m1_data;

	/******** Master 2 : Vector Unit or Blank ********/
	wire								vu_busy;

	wire								vu_active;

	wire								vu_switch;

	wire [`DwordDataBus]				vu_sr_rd_data;

	wire								cbus_m2_req;
	wire [`L2cCbusCmdBus]				cbus_m2_cmd;
	wire [`CoreAddrBus]					cbus_m2_addr;
	wire [`CoreDataBeBus]				cbus_m2_data_be;
	wire [`CoreDataBus]					cbus_m2_data;

	/******** Master 3 : Blank ********/
	wire								cbus_m3_req;
	wire [`L2cCbusCmdBus]				cbus_m3_cmd;
	wire [`CoreAddrBus]					cbus_m3_addr;
	wire [`CoreDataBeBus]				cbus_m3_data_be;
	wire [`CoreDataBus]					cbus_m3_data;

	/******** Slave : L2 Cache ********/
	wire								inv_ia_en;
	wire [`CoreAddrBus]					inv_ia_addr;

	wire								inv_da_en;
	wire [`CoreAddrBus]					inv_da_addr;

	wire								cbus_m_ack;

	wire								cbus_s_rdy;
	wire [`CoreUidBus]					cbus_s_uid;
	wire [`CoreDataBus]					cbus_s_data;

	/******** Cache Bus ********/
	// Master 0
	wire								cbus_m0_ack;

	wire								cbus_s0_rdy;
	wire [`CoreDataBus]					cbus_s0_data;

	// Master 1
	wire								cbus_m1_ack;

	wire								cbus_s1_rdy;
	wire [`CoreDataBus]					cbus_s1_data;

	// Master 2
	wire								cbus_m2_ack;

	wire								cbus_s2_rdy;
	wire [`CoreDataBus]					cbus_s2_data;

	// Master 3
	wire								cbus_m3_ack;

	wire								cbus_s3_rdy;
	wire [`CoreDataBus]					cbus_s3_data;

	// Slave
	wire								cbus_m_req;
	wire [`L2cCbusCmdBus]				cbus_m_cmd;
	wire [`CoreAddrBus]					cbus_m_addr;
	wire [`CoreUidBus]					cbus_m_uid;
	wire [`CoreDataBeBus]				cbus_m_data_be;
	wire [`CoreDataBus]					cbus_m_data;

/*----------------------------------------------------------------------------*
 * Module Instance
 *----------------------------------------------------------------------------*/
	/******** Master 0 and 1 : Processor Unit ********/
	pu#(
		.PUID					(COREID),
		.VU_EN					(VU_EN)
	) pu(
		.clk					(clk),
		.rst_					(rst_),

		.vu_pid					(vu_pid),
		.vu_status				(vu_status),

		.vu_busy				(vu_busy),

		.vu_active				(vu_active),

		.vu_switch				(vu_switch),

		.vu_sr_rd_addr			(vu_sr_rd_addr),

		.vu_sr_rd_data			(vu_sr_rd_data),

		.vu_dd_enq				(vu_dd_enq),
		.vu_dd					(vu_dd),

		.l2c_on					(l2c_on),

		.inv_ia_en				(inv_ia_en),
		.inv_ia_addr			(inv_ia_addr),

		.inv_da_en				(inv_da_en),
		.inv_da_addr			(inv_da_addr),

		.cbus_ia_req			(cbus_m0_req),
		.cbus_ia_cmd			(cbus_m0_cmd),
		.cbus_ia_addr			(cbus_m0_addr),
		.cbus_ia_wr_data_be		(cbus_m0_data_be),
		.cbus_ia_wr_data		(cbus_m0_data),

		.cbus_ia_ack			(cbus_m0_ack),

		.cbus_ia_rdy			(cbus_s0_rdy),
		.cbus_ia_rd_data		(cbus_s0_data),

		.cbus_da_req			(cbus_m1_req),
		.cbus_da_cmd			(cbus_m1_cmd),
		.cbus_da_addr			(cbus_m1_addr),
		.cbus_da_wr_data_be		(cbus_m1_data_be),
		.cbus_da_wr_data		(cbus_m1_data),

		.cbus_da_ack			(cbus_m1_ack),

		.cbus_da_rdy			(cbus_s1_rdy),
		.cbus_da_rd_data		(cbus_s1_data),

`ifdef IMP_VUS
		.vus_m_req				(vus_m_req),
		.vus_m_cmd				(vus_m_cmd),
		.vus_m_addr				(vus_m_addr),
		.vus_m_uid				(vus_m_uid),
		.vus_m_src				(vus_m_src),
		.vus_m_dst				(vus_m_dst),
		.vus_m_data_be			(vus_m_data_be),
		.vus_m_data				(vus_m_data),

		.vus_m_ack				(vus_m_ack),

		.vus_s_req				(vus_s_req),
		.vus_s_cmd				(vus_s_cmd),
		.vus_s_src				(vus_s_src),
		.vus_s_data				(vus_s_data),

		.vus_s_ack				(vus_s_ack),
`endif

		.irq					(irq)
	);

	/******** Master 2 : Vector Unit or Blank ********/
	generate
		if (VU_EN == 1) begin : VU
			vu vu(
				.clk					(clk),
				.rst_					(rst_),

				.pid					(vu_pid),
				.status					(vu_status),

				.busy					(vu_busy),

				.active					(vu_active),

				.switch					(vu_switch),

				.sr_rd_addr				(vu_sr_rd_addr),

				.sr_rd_data				(vu_sr_rd_data),

				.dd_enq					(vu_dd_enq),
				.dd						(vu_dd),

				.cbus_req				(cbus_m2_req),
				.cbus_cmd				(cbus_m2_cmd),
				.cbus_addr				(cbus_m2_addr),
				.cbus_wr_data_be		(cbus_m2_data_be),
				.cbus_wr_data			(cbus_m2_data),

				.cbus_ack				(cbus_m2_ack),

				.cbus_rdy				(cbus_s2_rdy),
				.cbus_rd_data			(cbus_s2_data)
			);
		end else begin
			assign vu_busy			= `DISABLE;
			assign vu_active		= `DISABLE;
			assign vu_switch		= `DISABLE;
			assign vu_sr_rd_data	= `DWORD_DATA_W'h0;

			assign cbus_m2_req		= `DISABLE;
			assign cbus_m2_cmd		= `L2C_CBUS_CMD_NO;
			assign cbus_m2_addr		= `CORE_ADDR_W'h0;
			assign cbus_m2_data_be	= {`CORE_DATA_BE_W{`DISABLE}};
			assign cbus_m2_data		= `CORE_DATA_W'h0;
		end
	endgenerate

	/******** Master 3 : Blank ********/
	assign cbus_m3_req		= `DISABLE;
	assign cbus_m3_cmd		= `L2C_CBUS_CMD_NO;
	assign cbus_m3_addr		= `CORE_ADDR_W'h0;
	assign cbus_m3_data_be	= {`CORE_DATA_BE_W{`DISABLE}};
	assign cbus_m3_data		= `CORE_DATA_W'h0;

	/******** Cache Bus ********/
	cbus cbus(
		.clk					(clk),
		.rst_					(rst_),

		.m0_req					(cbus_m0_req),
		.m0_cmd					(cbus_m0_cmd),
		.m0_addr				(cbus_m0_addr),
		.m0_data_be				(cbus_m0_data_be),
		.m0_data				(cbus_m0_data),

		.m0_ack					(cbus_m0_ack),

		.s0_rdy					(cbus_s0_rdy),
		.s0_data				(cbus_s0_data),

		.m1_req					(cbus_m1_req),
		.m1_cmd					(cbus_m1_cmd),
		.m1_addr				(cbus_m1_addr),
		.m1_data_be				(cbus_m1_data_be),
		.m1_data				(cbus_m1_data),

		.m1_ack					(cbus_m1_ack),

		.s1_rdy					(cbus_s1_rdy),
		.s1_data				(cbus_s1_data),

		.m2_req					(cbus_m2_req),
		.m2_cmd					(cbus_m2_cmd),
		.m2_addr				(cbus_m2_addr),
		.m2_data_be				(cbus_m2_data_be),
		.m2_data				(cbus_m2_data),

		.m2_ack					(cbus_m2_ack),

		.s2_rdy					(cbus_s2_rdy),
		.s2_data				(cbus_s2_data),

		.m3_req					(cbus_m3_req),
		.m3_cmd					(cbus_m3_cmd),
		.m3_addr				(cbus_m3_addr),
		.m3_data_be				(cbus_m3_data_be),
		.m3_data				(cbus_m3_data),

		.m3_ack					(cbus_m3_ack),

		.s3_rdy					(cbus_s3_rdy),
		.s3_data				(cbus_s3_data),

		.m_req					(cbus_m_req),
		.m_cmd					(cbus_m_cmd),
		.m_addr					(cbus_m_addr),
		.m_uid					(cbus_m_uid),
		.m_data_be				(cbus_m_data_be),
		.m_data					(cbus_m_data),

		.m_ack					(cbus_m_ack),

		.s_rdy					(cbus_s_rdy),
		.s_uid					(cbus_s_uid),
		.s_data					(cbus_s_data)
	);

	/******** Slave : L2 Cache ********/
	l2c#(
		.L2CID					(COREID)
	) l2c(
		.clk					(clk),
		.rst_					(rst_),

		.l2c_on					(l2c_on),

		.inv_ia_en				(inv_ia_en),
		.inv_ia_addr			(inv_ia_addr),

		.inv_da_en				(inv_da_en),
		.inv_da_addr			(inv_da_addr),

		.cbus_m_req				(cbus_m_req),
		.cbus_m_cmd				(cbus_m_cmd),
		.cbus_m_addr			(cbus_m_addr),
		.cbus_m_uid				(cbus_m_uid),
		.cbus_m_data_be			(cbus_m_data_be),
		.cbus_m_data			(cbus_m_data),

		.cbus_m_ack				(cbus_m_ack),

		.cbus_s_rdy				(cbus_s_rdy),
		.cbus_s_uid				(cbus_s_uid),
		.cbus_s_data			(cbus_s_data),

		.dl_pot					(dl_pot),

		.xu_m_req				(xu_m_req),
		.xu_m_cmd				(xu_m_cmd),
		.xu_m_addr				(xu_m_addr),
		.xu_m_uid				(xu_m_uid),
		.xu_m_src				(xu_m_src),
		.xu_m_data_be			(xu_m_data_be),
		.xu_m_data				(xu_m_data),

		.xu_m_ack				(xu_m_ack),

		.xu_s_req				(xu_s_req),
		.xu_s_cmd				(xu_s_cmd),
		.xu_s_addr				(xu_s_addr),
		.xu_s_uid				(xu_s_uid),
		.xu_s_src				(xu_s_src),
		.xu_s_data				(xu_s_data),

		.xu_s_ack				(xu_s_ack)
	);

endmodule

