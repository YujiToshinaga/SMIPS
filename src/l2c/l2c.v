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
`include "cpu.h"
`include "core.h"
`include "l2c.h"
`include "cbus.h"
`include "xu.h"

module l2c#(
	parameter							L2CID				= 0
)(
	/******** Clock and Reset ********/
	input wire							clk,
	input wire							rst_,

	/******** Processor Unit Access ********/
	input wire							l2c_on,

	output wire							inv_ia_en,
	output wire [`CoreAddrBus]			inv_ia_addr,

	output wire							inv_da_en,
	output wire [`CoreAddrBus]			inv_da_addr,

	/******** Cache Bus Access ********/
	// Master
	input wire							cbus_m_req,
	input wire [`L2cCbusCmdBus]			cbus_m_cmd,
	input wire [`CoreAddrBus]			cbus_m_addr,
	input wire [`CoreUidBus]			cbus_m_uid,
	input wire [`CoreDataBeBus]			cbus_m_data_be,
	input wire [`CoreDataBus]			cbus_m_data,

	output wire							cbus_m_ack,

	// Slave
	output wire							cbus_s_rdy,
	output wire [`CoreUidBus]			cbus_s_uid,
	output wire [`CoreDataBus]			cbus_s_data,

	/******** Cross Unit Access ********/
	// Master
	output wire							dl_pot,

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

	output wire							xu_s_ack
);

/*----------------------------------------------------------------------------*
 * Wire and Reg
 *----------------------------------------------------------------------------*/
	/******** Memory ********/
	wire									mem_rw_rdy;
	wire [`L2C_TAG_W*`L2C_WAY_NUM-1:0]		mem_rd_tag_pack;
	wire [1*`L2C_WAY_NUM-1:0]				mem_rd_valid_pack;
	wire [1*`L2C_WAY_NUM-1:0]				mem_rd_dirty_pack;
	wire [`CORE_DATA_W*`L2C_WAY_NUM-1:0]	mem_rd_data_pack;

	/******** Cache Bus ********/
	wire								dmp_en;
	wire [`CoreUidBus]					dmp_uid;
	wire [`CoreDataBeBus]				dmp_data_be;
	wire [`CoreDataBus]					dmp_data;

	wire									mem_cbus_rw_req;
	wire [`L2cIndexBus]						mem_cbus_rw_index;
	wire [1*`L2C_WAY_NUM-1:0]				mem_cbus_wr_en_pack;
	wire [`L2C_TAG_W*`L2C_WAY_NUM-1:0]		mem_cbus_wr_tag_pack;
	wire [1*`L2C_WAY_NUM-1:0]				mem_cbus_wr_valid_pack;
	wire [1*`L2C_WAY_NUM-1:0]				mem_cbus_wr_dirty_pack;
	wire [`CORE_DATA_W*`L2C_WAY_NUM-1:0]	mem_cbus_wr_data_pack;

	wire								cbus_cbus_req;
	wire [`CoreUidBus]					cbus_cbus_uid;
	wire [`CoreDataBus]					cbus_cbus_data;

	wire								xu_cbus_req;
	wire [`XuL2cCmdBus]					xu_cbus_cmd;
	wire [`CoreAddrBus]					xu_cbus_addr;
	wire [`CoreUidBus]					xu_cbus_uid;
	wire [`CpuTileIdBus]				xu_cbus_src;
	wire [`CoreDataBeBus]				xu_cbus_data_be;
	wire [`CoreDataBus]					xu_cbus_data;

	/******** Cross Unit ********/
	wire									mem_xu_rw_req;
	wire [`L2cIndexBus]						mem_xu_rw_index;
	wire [1*`L2C_WAY_NUM-1:0]				mem_xu_wr_en_pack;
	wire [`L2C_TAG_W*`L2C_WAY_NUM-1:0]		mem_xu_wr_tag_pack;
	wire [1*`L2C_WAY_NUM-1:0]				mem_xu_wr_valid_pack;
	wire [1*`L2C_WAY_NUM-1:0]				mem_xu_wr_dirty_pack;
	wire [`CORE_DATA_W*`L2C_WAY_NUM-1:0]	mem_xu_wr_data_pack;

	wire								cbus_xu_req;
	wire [`CoreUidBus]					cbus_xu_uid;
	wire [`CoreDataBus]					cbus_xu_data;

	wire								xu_xu_req;
	wire [`XuL2cCmdBus]					xu_xu_cmd;
	wire [`CoreAddrBus]					xu_xu_addr;
	wire [`CoreUidBus]					xu_xu_uid;
	wire [`CpuTileIdBus]				xu_xu_src;
	wire [`CoreDataBeBus]				xu_xu_data_be;
	wire [`CoreDataBus]					xu_xu_data;

	/******** Memory Out ********/
	wire									mem_cbus_rw_rdy;
	wire [`L2C_TAG_W*`L2C_WAY_NUM-1:0]		mem_cbus_rd_tag_pack;
	wire [1*`L2C_WAY_NUM-1:0]				mem_cbus_rd_valid_pack;
	wire [1*`L2C_WAY_NUM-1:0]				mem_cbus_rd_dirty_pack;
	wire [`CORE_DATA_W*`L2C_WAY_NUM-1:0]	mem_cbus_rd_data_pack;

	wire									mem_xu_rw_rdy;
	wire [`L2C_TAG_W*`L2C_WAY_NUM-1:0]		mem_xu_rd_tag_pack;
	wire [1*`L2C_WAY_NUM-1:0]				mem_xu_rd_valid_pack;
	wire [1*`L2C_WAY_NUM-1:0]				mem_xu_rd_dirty_pack;
	wire [`CORE_DATA_W*`L2C_WAY_NUM-1:0]	mem_xu_rd_data_pack;

	wire									mem_rw_req;
	wire [`L2cIndexBus]						mem_rw_index;
	wire [1*`L2C_WAY_NUM-1:0]				mem_wr_en_pack;
	wire [`L2C_TAG_W*`L2C_WAY_NUM-1:0]		mem_wr_tag_pack;
	wire [1*`L2C_WAY_NUM-1:0]				mem_wr_valid_pack;
	wire [1*`L2C_WAY_NUM-1:0]				mem_wr_dirty_pack;
	wire [`CORE_DATA_W*`L2C_WAY_NUM-1:0]	mem_wr_data_pack;

	/******** Cache Bus Out ********/
	wire								cbus_cbus_ack;

	wire								cbus_xu_ack;

	/******** Cross Unit Out ********/
	wire								xu_cbus_ack;

	wire								xu_xu_ack;

/*----------------------------------------------------------------------------*
 * Module Instance
 *----------------------------------------------------------------------------*/
	/********  ********/
	l2c_mem l2c_mem(
		.clk					(clk),
		.rst_					(rst_),

		.rw_req					(mem_rw_req),
		.rw_index				(mem_rw_index),
		.wr_en_pack				(mem_wr_en_pack),
		.wr_tag_pack			(mem_wr_tag_pack),
		.wr_valid_pack			(mem_wr_valid_pack),
		.wr_dirty_pack			(mem_wr_dirty_pack),
		.wr_data_pack			(mem_wr_data_pack),

		.rw_rdy					(mem_rw_rdy),
		.rd_tag_pack			(mem_rd_tag_pack),
		.rd_valid_pack			(mem_rd_valid_pack),
		.rd_dirty_pack			(mem_rd_dirty_pack),
		.rd_data_pack			(mem_rd_data_pack)
	);

	/********  ********/
	l2c_cbus#(
		.L2CID					(L2CID)
	) l2c_cbus(
		.clk					(clk),
		.rst_					(rst_),

		.dmp_en					(dmp_en),
		.dmp_uid				(dmp_uid),
		.dmp_data_be            (dmp_data_be),
		.dmp_data               (dmp_data),

		.mem_rw_req				(mem_cbus_rw_req),
		.mem_rw_index			(mem_cbus_rw_index),
		.mem_wr_en_pack			(mem_cbus_wr_en_pack),
		.mem_wr_tag_pack		(mem_cbus_wr_tag_pack),
		.mem_wr_valid_pack		(mem_cbus_wr_valid_pack),
		.mem_wr_dirty_pack		(mem_cbus_wr_dirty_pack),
		.mem_wr_data_pack		(mem_cbus_wr_data_pack),

		.mem_rw_rdy				(mem_cbus_rw_rdy),
		.mem_rd_tag_pack		(mem_cbus_rd_tag_pack),
		.mem_rd_valid_pack		(mem_cbus_rd_valid_pack),
		.mem_rd_dirty_pack		(mem_cbus_rd_dirty_pack),
		.mem_rd_data_pack		(mem_cbus_rd_data_pack),

		.cbus_req				(cbus_cbus_req),
		.cbus_uid				(cbus_cbus_uid),
		.cbus_data				(cbus_cbus_data),

		.cbus_ack				(cbus_cbus_ack),

		.xu_req					(xu_cbus_req),
		.xu_cmd					(xu_cbus_cmd),
		.xu_addr				(xu_cbus_addr),
		.xu_uid					(xu_cbus_uid),
		.xu_src					(xu_cbus_src),
		.xu_data_be				(xu_cbus_data_be),
		.xu_data				(xu_cbus_data),

		.xu_ack					(xu_cbus_ack),

		.req					(cbus_m_req),
		.cmd					(cbus_m_cmd),
		.addr					(cbus_m_addr),
		.uid					(cbus_m_uid),
		.data_be				(cbus_m_data_be),
		.data					(cbus_m_data),

		.ack					(cbus_m_ack)
	);

	/********  ********/
	l2c_xu#(
		.L2CID					(L2CID)
	) l2c_xu(
		.clk					(clk),
		.rst_					(rst_),

		.dmp_en					(dmp_en),
		.dmp_uid				(dmp_uid),
		.dmp_data_be            (dmp_data_be),
		.dmp_data               (dmp_data),

		.mem_rw_req				(mem_xu_rw_req),
		.mem_rw_index			(mem_xu_rw_index),
		.mem_wr_en_pack			(mem_xu_wr_en_pack),
		.mem_wr_tag_pack		(mem_xu_wr_tag_pack),
		.mem_wr_valid_pack		(mem_xu_wr_valid_pack),
		.mem_wr_dirty_pack		(mem_xu_wr_dirty_pack),
		.mem_wr_data_pack		(mem_xu_wr_data_pack),

		.mem_rw_rdy				(mem_xu_rw_rdy),
		.mem_rd_tag_pack		(mem_xu_rd_tag_pack),
		.mem_rd_valid_pack		(mem_xu_rd_valid_pack),
		.mem_rd_dirty_pack		(mem_xu_rd_dirty_pack),
		.mem_rd_data_pack		(mem_xu_rd_data_pack),

		.cbus_req				(cbus_xu_req),
		.cbus_uid				(cbus_xu_uid),
		.cbus_data				(cbus_xu_data),

		.cbus_ack				(cbus_xu_ack),

		.dl_pot					(dl_pot),

		.xu_req					(xu_xu_req),
		.xu_cmd					(xu_xu_cmd),
		.xu_addr				(xu_xu_addr),
		.xu_uid					(xu_xu_uid),
		.xu_src					(xu_xu_src),
		.xu_data_be				(xu_xu_data_be),
		.xu_data				(xu_xu_data),

		.xu_ack					(xu_xu_ack),

		.inv_ia_en				(inv_ia_en),
		.inv_ia_addr            (inv_ia_addr),

		.inv_da_en              (inv_da_en),
		.inv_da_addr            (inv_da_addr),

		.req					(xu_s_req),
		.cmd                    (xu_s_cmd),
		.addr                   (xu_s_addr),
		.uid                    (xu_s_uid),
		.src                    (xu_s_src),
		.data                	(xu_s_data),

		.ack                    (xu_s_ack)
	);

	/********  ********/
	l2c_mout l2c_mout(
		.clk					(clk),
		.rst_					(rst_),

		.cbus_rw_req			(mem_cbus_rw_req),
		.cbus_rw_index			(mem_cbus_rw_index),
		.cbus_wr_en_pack		(mem_cbus_wr_en_pack),
		.cbus_wr_tag_pack		(mem_cbus_wr_tag_pack),
		.cbus_wr_valid_pack		(mem_cbus_wr_valid_pack),
		.cbus_wr_dirty_pack		(mem_cbus_wr_dirty_pack),
		.cbus_wr_data_pack		(mem_cbus_wr_data_pack),

		.cbus_rw_rdy			(mem_cbus_rw_rdy),
		.cbus_rd_tag_pack		(mem_cbus_rd_tag_pack),
		.cbus_rd_valid_pack		(mem_cbus_rd_valid_pack),
		.cbus_rd_dirty_pack		(mem_cbus_rd_dirty_pack),
		.cbus_rd_data_pack		(mem_cbus_rd_data_pack),

		.xu_rw_req				(mem_xu_rw_req),
		.xu_rw_index			(mem_xu_rw_index),
		.xu_wr_en_pack			(mem_xu_wr_en_pack),
		.xu_wr_tag_pack			(mem_xu_wr_tag_pack),
		.xu_wr_valid_pack		(mem_xu_wr_valid_pack),
		.xu_wr_dirty_pack		(mem_xu_wr_dirty_pack),
		.xu_wr_data_pack		(mem_xu_wr_data_pack),

		.xu_rw_rdy				(mem_xu_rw_rdy),
		.xu_rd_tag_pack			(mem_xu_rd_tag_pack),
		.xu_rd_valid_pack		(mem_xu_rd_valid_pack),
		.xu_rd_dirty_pack		(mem_xu_rd_dirty_pack),
		.xu_rd_data_pack		(mem_xu_rd_data_pack),

		.rw_req					(mem_rw_req),
		.rw_index				(mem_rw_index),
		.wr_en_pack				(mem_wr_en_pack),
		.wr_tag_pack			(mem_wr_tag_pack),
		.wr_valid_pack			(mem_wr_valid_pack),
		.wr_dirty_pack			(mem_wr_dirty_pack),
		.wr_data_pack			(mem_wr_data_pack),

		.rw_rdy					(mem_rw_rdy),
		.rd_tag_pack			(mem_rd_tag_pack),
		.rd_valid_pack			(mem_rd_valid_pack),
		.rd_dirty_pack			(mem_rd_dirty_pack),
		.rd_data_pack			(mem_rd_data_pack)
	);

	/********  ********/
	l2c_cout l2c_cout(
		.clk					(clk),
		.rst_					(rst_),

		.cbus_req				(cbus_cbus_req),
		.cbus_uid				(cbus_cbus_uid),
		.cbus_data				(cbus_cbus_data),

		.cbus_ack				(cbus_cbus_ack),

		.xu_req					(cbus_xu_req),
		.xu_uid					(cbus_xu_uid),
		.xu_data				(cbus_xu_data),

		.xu_ack					(cbus_xu_ack),

		.rdy					(cbus_s_rdy),
		.uid					(cbus_s_uid),
		.data					(cbus_s_data)
	);

	/********  ********/
	l2c_xout l2c_xout(
		.clk					(clk),
		.rst_					(rst_),

		.cbus_req				(xu_cbus_req),
		.cbus_cmd				(xu_cbus_cmd),
		.cbus_addr				(xu_cbus_addr),
		.cbus_uid				(xu_cbus_uid),
		.cbus_src				(xu_cbus_src),
		.cbus_data_be			(xu_cbus_data_be),
		.cbus_data				(xu_cbus_data),

		.cbus_ack				(xu_cbus_ack),

		.xu_req					(xu_xu_req),
		.xu_cmd					(xu_xu_cmd),
		.xu_addr				(xu_xu_addr),
		.xu_uid					(xu_xu_uid),
		.xu_src					(xu_xu_src),
		.xu_data_be				(xu_xu_data_be),
		.xu_data				(xu_xu_data),

		.xu_ack					(xu_xu_ack),

		.req					(xu_m_req),
		.cmd					(xu_m_cmd),
		.addr					(xu_m_addr),
		.uid					(xu_m_uid),
		.src					(xu_m_src),
		.data_be				(xu_m_data_be),
		.data					(xu_m_data),

		.ack					(xu_m_ack)
	);

/*----------------------------------------------------------------------------*
 * Debug
 *----------------------------------------------------------------------------*/
`ifdef DEBUG
	/********  ********/
`endif

endmodule

