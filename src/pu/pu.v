/*----------------------------------------------------------------------------*
 *	SMIPS
 *
 *	File	: pu.v
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
`include "l2c.h"
`include "cbus.h"
`include "ni.h"

module pu#(
	parameter							PUID				= 0
)(
	/******** Clock and Reset ********/
	input wire							clk,
	input wire							rst_,

	/******** L2 Cache Access ********/
	output wire							l2c_on,
	input wire							inv_ia_en,
	input wire [`CoreAddrBus]			inv_ia_addr,
	input wire							inv_da_en,
	input wire [`CoreAddrBus]			inv_da_addr,
	/******** Cache Bus Access ********/
	// IA
	output wire							cbus_ia_req,
	output wire [`L2cCbusCmdBus]		cbus_ia_cmd,
	output wire [`CoreAddrBus]			cbus_ia_addr,
	output wire [`CoreDataBeBus]		cbus_ia_wr_data_be,
	output wire [`CoreDataBus]			cbus_ia_wr_data,
	input wire							cbus_ia_ack,
	input wire							cbus_ia_rdy,
	input wire [`CoreDataBus]			cbus_ia_rd_data,
	// DA
	output wire							cbus_da_req,
	output wire [`L2cCbusCmdBus]		cbus_da_cmd,
	output wire [`CoreAddrBus]			cbus_da_addr,
	output wire [`CoreDataBeBus]		cbus_da_wr_data_be,
	output wire [`CoreDataBus]			cbus_da_wr_data,
	input wire							cbus_da_ack,
	input wire							cbus_da_rdy,
	input wire [`CoreDataBus]			cbus_da_rd_data,

	/******** IRQ ********/
	input wire [`PuIrqBus]				irq
);

/*----------------------------------------------------------------------------*
 * Wire and Reg
 *----------------------------------------------------------------------------*/
	/******** Coprocessor ********/
	wire [`PuPidBus]					pid;
	wire [`PuTidBus]					tid;
	wire [`PuTmodeBus]					tmode;
	wire								ne;
	wire								ia_flush;
	wire								ia_stall;
	wire								itlb_on;
	wire								ic_on;
	wire [`WordAddrBus]					cop_np_pc;
	wire [`WordAddrBus]					cop_pr_pc;
	wire								id_flush;
	wire								id_stall;
	wire [`WordDataBus]					cpr_rd_data;
	wire [`WordDataBus]					vcr_rd_data;
	wire [`PuGprAddrBus]				cop_rd_addr;
	wire								cop_rd_en;
	wire [`WordDataBus]					cop_rd_data;
	wire								cop_hi_en;
	wire [`WordDataBus]					cop_hi_data;
	wire								cop_lo_en;
	wire [`WordDataBus]					cop_lo_data;
	wire								ex_flush;
	wire								ex_stall;
	wire								da_flush;
	wire								da_stall;
	wire								dtlb_on;
	wire								dc_on;
	wire								wb_flush;
	wire								wb_stall;
	/******** IA ********/
	wire								ia_busy;
	wire								ia_pr_en;
	wire [`WordAddrBus]					ia_pr_pc;
	wire [`WordDataBus]					ia_pr_inst;
	wire [`PuExpIaBus]					ia_pr_exp;
	/******** ID ********/
	wire								id_busy;
	wire								id_hazard;
	wire								branch_en;
	wire [`WordAddrBus]					branch_pc;
	wire [`PuCprAddrBus]				cpr_rd_addr;
	wire [`PuVcrAddrBus]				vcr_rd_addr;
	wire								id_pr_en;
	wire [`WordAddrBus]					id_pr_pc;
	wire [`PuCopOpBus]					id_pr_cop_op;
	wire [`PuLsOpBus]					id_pr_ls_op;
	wire [`PuIaOpBus]					id_pr_ia_op;
	wire [`WordDataBus]					id_pr_in0;
	wire [`WordDataBus]					id_pr_in1;
	wire [`WordDataBus]					id_pr_st_data;
	wire [`PuGprAddrBus]				id_pr_rd_addr;
	wire								id_pr_rd_en;
	wire								id_pr_hi_en;
	wire								id_pr_lo_en;
	wire								id_pr_bd;
	wire [`PuExpIdBus]					id_pr_exp;
	/******** EX ********/
	wire								ex_busy;
	wire [`PuCopOpBus]					fwd_ex_cop_op;
	wire [`PuLsOpBus]					fwd_ex_ls_op;
	wire [`PuGprAddrBus]				fwd_ex_rd_addr;
	wire								fwd_ex_rd_en;
	wire [`WordDataBus]					fwd_ex_rd_data;
	wire								fwd_ex_hi_en;
	wire [`WordDataBus]					fwd_ex_hi_data;
	wire								fwd_ex_lo_en;
	wire [`WordDataBus]					fwd_ex_lo_data;
	wire [`WordDataBus]					ex_np_out;
	wire								ex_pr_en;
	wire [`WordAddrBus]					ex_pr_pc;
	wire [`PuCopOpBus]					ex_pr_cop_op;
	wire [`PuLsOpBus]					ex_pr_ls_op;
	wire [`WordDataBus]					ex_pr_out;
	wire [`WordDataBus]					ex_pr_st_data;
	wire [`PuGprAddrBus]				ex_pr_rd_addr;
	wire								ex_pr_rd_en;
	wire								ex_pr_hi_en;
	wire [`WordDataBus]					ex_pr_hi_data;
	wire								ex_pr_lo_en;
	wire [`WordDataBus]					ex_pr_lo_data;
	wire								ex_pr_bd;
	wire [`PuExpExBus]					ex_pr_exp;
	/******** DA ********/
	wire								da_busy;
	wire [`PuCopOpBus]					fwd_da_cop_op;
	wire [`PuLsOpBus]					fwd_da_ls_op;
	wire [`PuGprAddrBus]				fwd_da_rd_addr;
	wire								fwd_da_rd_en;
	wire [`WordDataBus]					fwd_da_rd_data;
	wire								fwd_da_hi_en;
	wire [`WordDataBus]					fwd_da_hi_data;
	wire								fwd_da_lo_en;
	wire [`WordDataBus]					fwd_da_lo_data;
	wire								da_pr_en;
	wire [`WordAddrBus]					da_pr_pc;
	wire [`PuCopOpBus]					da_pr_cop_op;
	wire [`WordDataBus]					da_pr_cop_data;
	wire [`PuGprAddrBus]				da_pr_rd_addr;
	wire								da_pr_rd_en;
	wire [`WordDataBus]					da_pr_rd_data;
	wire								da_pr_hi_en;
	wire [`WordDataBus]					da_pr_hi_data;
	wire								da_pr_lo_en;
	wire [`WordDataBus]					da_pr_lo_data;
	wire								da_pr_bd;
	wire [`PuExpDaBus]					da_pr_exp;
	/******** WB ********/
	wire								wb_busy;
	wire								wb_en;
	wire [`WordAddrBus]					wb_pc;
	wire [`PuCopOpBus]					wb_cop_op;
	wire [`WordDataBus]					wb_cop_data;
	wire [`PuGprAddrBus]				wb_rd_addr;
	wire								wb_rd_en;
	wire [`WordDataBus]					wb_rd_data;
	wire								wb_hi_en;
	wire [`WordDataBus]					wb_hi_data;
	wire								wb_lo_en;
	wire [`WordDataBus]					wb_lo_data;
	wire								wb_bd;
	wire [`PuExpWbBus]					wb_exp;
	wire [`PuCopOpBus]					fwd_wb_cop_op;
	wire [`PuGprAddrBus]				fwd_wb_rd_addr;
	wire								fwd_wb_rd_en;
	wire [`WordDataBus]					fwd_wb_rd_data;
	wire								fwd_wb_hi_en;
	wire [`WordDataBus]					fwd_wb_hi_data;
	wire								fwd_wb_lo_en;
	wire [`WordDataBus]					fwd_wb_lo_data;
	/******** Iterator ********/
	generate
		genvar								gi;
	endgenerate

/*----------------------------------------------------------------------------*
 * Module Instance
 *----------------------------------------------------------------------------*/
	/******** Coprocessor ********/
	pu_cop#(
		.PUID					(PUID)
	) pu_cop(
		.clk					(clk),
		.rst_					(rst_),
		.pid					(pid),
		.tid					(tid),
		.tmode					(tmode),
		.ne						(ne),
		.ia_flush				(ia_flush),
		.ia_stall				(ia_stall),
		.ia_busy				(ia_busy),
		.itlb_on				(itlb_on),
		.ic_on					(ic_on),
		.cop_np_pc				(cop_np_pc),
		.cop_pr_pc				(cop_pr_pc),
		.id_flush				(id_flush),
		.id_stall				(id_stall),
		.id_busy				(id_busy),
		.id_hazard				(id_hazard),
		.branch_en				(branch_en),
		.branch_pc				(branch_pc),
		.cpr_rd_addr			(cpr_rd_addr),
		.cpr_rd_data			(cpr_rd_data),
		.vcr_rd_addr			(vcr_rd_addr),
		.vcr_rd_data			(vcr_rd_data),
		.cop_rd_addr			(cop_rd_addr),
		.cop_rd_en				(cop_rd_en),
		.cop_rd_data			(cop_rd_data),
		.cop_hi_en				(cop_hi_en),
		.cop_hi_data			(cop_hi_data),
		.cop_lo_en				(cop_lo_en),
		.cop_lo_data			(cop_lo_data),
		.ex_flush				(ex_flush),
		.ex_stall				(ex_stall),
		.ex_busy				(ex_busy),
		.da_flush				(da_flush),
		.da_stall				(da_stall),
		.da_busy				(da_busy),
		.dtlb_on				(dtlb_on),
		.dc_on					(dc_on),
		.wb_flush				(wb_flush),
		.wb_stall				(wb_stall),
		.wb_busy				(wb_busy),
		.wb_en					(wb_en),
		.wb_pc					(wb_pc),
		.wb_cop_op				(wb_cop_op),
		.wb_cop_data			(wb_cop_data),
		.wb_rd_addr				(wb_rd_addr),
		.wb_rd_en				(wb_rd_en),
		.wb_rd_data				(wb_rd_data),
		.wb_hi_en				(wb_hi_en),
		.wb_hi_data				(wb_hi_data),
		.wb_lo_en				(wb_lo_en),
		.wb_lo_data				(wb_lo_data),
		.wb_bd					(wb_bd),
		.wb_exp					(wb_exp),
		.l2c_on					(l2c_on),
		.irq					(irq)
	);

	/******** IA ********/
	pu_ia pu_ia(
		.clk					(clk),
		.rst_					(rst_),
		.pid					(pid),
		.tid					(tid),
		.tmode					(tmode),
		.ia_flush				(ia_flush),
		.ia_stall				(ia_stall),
		.ia_busy				(ia_busy),
		.itlb_on				(itlb_on),
		.ic_on					(ic_on),
		.cop_np_pc				(cop_np_pc),
		.cop_pr_pc				(cop_pr_pc),
		.ia_pr_en				(ia_pr_en),
		.ia_pr_pc				(ia_pr_pc),
		.ia_pr_inst				(ia_pr_inst),
		.ia_pr_exp				(ia_pr_exp),
		.inv_en					(inv_ia_en),
		.inv_addr				(inv_ia_addr),
		.cbus_req				(cbus_ia_req),
		.cbus_cmd				(cbus_ia_cmd),
		.cbus_addr				(cbus_ia_addr),
		.cbus_wr_data_be		(cbus_ia_wr_data_be),
		.cbus_wr_data			(cbus_ia_wr_data),
		.cbus_ack				(cbus_ia_ack),
		.cbus_rdy				(cbus_ia_rdy),
		.cbus_rd_data			(cbus_ia_rd_data)
	);

	/******** ID ********/
	pu_id#(
		.PUID					(PUID)
	) pu_id(
		.clk					(clk),
		.rst_					(rst_),
		.pid					(pid),
		.tid					(tid),
		.tmode					(tmode),
		.ne						(ne),
		.id_flush				(id_flush),
		.id_stall				(id_stall),
		.id_busy				(id_busy),
		.id_hazard				(id_hazard),
		.branch_en				(branch_en),
		.branch_pc				(branch_pc),
		.cpr_rd_addr			(cpr_rd_addr),
		.cpr_rd_data			(cpr_rd_data),
		.vcr_rd_addr			(vcr_rd_addr),
		.vcr_rd_data			(vcr_rd_data),
		.cop_rd_addr			(cop_rd_addr),
		.cop_rd_en				(cop_rd_en),
		.cop_rd_data			(cop_rd_data),
		.cop_hi_en				(cop_hi_en),
		.cop_hi_data			(cop_hi_data),
		.cop_lo_en				(cop_lo_en),
		.cop_lo_data			(cop_lo_data),
		.ia_pr_en				(ia_pr_en),
		.ia_pr_pc				(ia_pr_pc),
		.ia_pr_inst				(ia_pr_inst),
		.ia_pr_exp				(ia_pr_exp),
		.fwd_ex_cop_op			(fwd_ex_cop_op),
		.fwd_ex_ls_op			(fwd_ex_ls_op),
		.fwd_ex_rd_addr			(fwd_ex_rd_addr),
		.fwd_ex_rd_en			(fwd_ex_rd_en),
		.fwd_ex_rd_data			(fwd_ex_rd_data),
		.fwd_ex_hi_en			(fwd_ex_hi_en),
		.fwd_ex_hi_data			(fwd_ex_hi_data),
		.fwd_ex_lo_en			(fwd_ex_lo_en),
		.fwd_ex_lo_data			(fwd_ex_lo_data),
		.id_pr_en				(id_pr_en),
		.id_pr_pc				(id_pr_pc),
		.id_pr_cop_op			(id_pr_cop_op),
		.id_pr_ls_op			(id_pr_ls_op),
		.id_pr_ia_op			(id_pr_ia_op),
		.id_pr_in0				(id_pr_in0),
		.id_pr_in1				(id_pr_in1),
		.id_pr_st_data			(id_pr_st_data),
		.id_pr_rd_addr			(id_pr_rd_addr),
		.id_pr_rd_en			(id_pr_rd_en),
		.id_pr_hi_en			(id_pr_hi_en),
		.id_pr_lo_en			(id_pr_lo_en),
		.id_pr_bd				(id_pr_bd),
		.id_pr_exp				(id_pr_exp),
		.fwd_da_cop_op			(fwd_da_cop_op),
		.fwd_da_ls_op			(fwd_da_ls_op),
		.fwd_da_rd_addr			(fwd_da_rd_addr),
		.fwd_da_rd_en			(fwd_da_rd_en),
		.fwd_da_rd_data			(fwd_da_rd_data),
		.fwd_da_hi_en			(fwd_da_hi_en),
		.fwd_da_hi_data			(fwd_da_hi_data),
		.fwd_da_lo_en			(fwd_da_lo_en),
		.fwd_da_lo_data			(fwd_da_lo_data),
		.fwd_wb_cop_op			(fwd_wb_cop_op),
		.fwd_wb_rd_addr			(fwd_wb_rd_addr),
		.fwd_wb_rd_en			(fwd_wb_rd_en),
		.fwd_wb_rd_data			(fwd_wb_rd_data),
		.fwd_wb_hi_en			(fwd_wb_hi_en),
		.fwd_wb_hi_data			(fwd_wb_hi_data),
		.fwd_wb_lo_en			(fwd_wb_lo_en),
		.fwd_wb_lo_data			(fwd_wb_lo_data)
	);

	/******** EX ********/
	pu_ex pu_ex(
		.clk					(clk),
		.rst_					(rst_),
		.pid					(pid),
		.tid					(tid),
		.tmode					(tmode),
		.ex_flush				(ex_flush),
		.ex_stall				(ex_stall),
		.ex_busy				(ex_busy),
		.fwd_ex_cop_op			(fwd_ex_cop_op),
		.fwd_ex_ls_op			(fwd_ex_ls_op),
		.fwd_ex_rd_addr			(fwd_ex_rd_addr),
		.fwd_ex_rd_en			(fwd_ex_rd_en),
		.fwd_ex_rd_data			(fwd_ex_rd_data),
		.fwd_ex_hi_en			(fwd_ex_hi_en),
		.fwd_ex_hi_data			(fwd_ex_hi_data),
		.fwd_ex_lo_en			(fwd_ex_lo_en),
		.fwd_ex_lo_data			(fwd_ex_lo_data),
		.id_pr_en				(id_pr_en),
		.id_pr_pc				(id_pr_pc),
		.id_pr_cop_op			(id_pr_cop_op),
		.id_pr_ls_op			(id_pr_ls_op),
		.id_pr_ia_op			(id_pr_ia_op),
		.id_pr_in0				(id_pr_in0),
		.id_pr_in1				(id_pr_in1),
		.id_pr_st_data			(id_pr_st_data),
		.id_pr_rd_addr			(id_pr_rd_addr),
		.id_pr_rd_en			(id_pr_rd_en),
		.id_pr_hi_en			(id_pr_hi_en),
		.id_pr_lo_en			(id_pr_lo_en),
		.id_pr_bd				(id_pr_bd),
		.id_pr_exp				(id_pr_exp),
		.ex_np_out				(ex_np_out),
		.ex_pr_en				(ex_pr_en),
		.ex_pr_pc				(ex_pr_pc),
		.ex_pr_cop_op			(ex_pr_cop_op),
		.ex_pr_ls_op			(ex_pr_ls_op),
		.ex_pr_out				(ex_pr_out),
		.ex_pr_st_data			(ex_pr_st_data),
		.ex_pr_rd_addr			(ex_pr_rd_addr),
		.ex_pr_rd_en			(ex_pr_rd_en),
		.ex_pr_hi_en			(ex_pr_hi_en),
		.ex_pr_hi_data			(ex_pr_hi_data),
		.ex_pr_lo_en			(ex_pr_lo_en),
		.ex_pr_lo_data			(ex_pr_lo_data),
		.ex_pr_bd				(ex_pr_bd),
		.ex_pr_exp				(ex_pr_exp)
	);

	/******** DA ********/
	pu_da pu_da(
		.clk					(clk),
		.rst_					(rst_),
		.pid					(pid),
		.tid					(tid),
		.tmode					(tmode),
		.da_flush				(da_flush),
		.da_stall				(da_stall),
		.da_busy				(da_busy),
		.dtlb_on				(dtlb_on),
		.dc_on					(dc_on),
		.fwd_da_cop_op			(fwd_da_cop_op),
		.fwd_da_ls_op			(fwd_da_ls_op),
		.fwd_da_rd_addr			(fwd_da_rd_addr),
		.fwd_da_rd_en			(fwd_da_rd_en),
		.fwd_da_rd_data			(fwd_da_rd_data),
		.fwd_da_hi_en			(fwd_da_hi_en),
		.fwd_da_hi_data			(fwd_da_hi_data),
		.fwd_da_lo_en			(fwd_da_lo_en),
		.fwd_da_lo_data			(fwd_da_lo_data),
		.ex_np_out				(ex_np_out),
		.ex_pr_en				(ex_pr_en),
		.ex_pr_pc				(ex_pr_pc),
		.ex_pr_cop_op			(ex_pr_cop_op),
		.ex_pr_ls_op			(ex_pr_ls_op),
		.ex_pr_out				(ex_pr_out),
		.ex_pr_st_data			(ex_pr_st_data),
		.ex_pr_rd_addr			(ex_pr_rd_addr),
		.ex_pr_rd_en			(ex_pr_rd_en),
		.ex_pr_hi_en			(ex_pr_hi_en),
		.ex_pr_hi_data			(ex_pr_hi_data),
		.ex_pr_lo_en			(ex_pr_lo_en),
		.ex_pr_lo_data			(ex_pr_lo_data),
		.ex_pr_bd				(ex_pr_bd),
		.ex_pr_exp				(ex_pr_exp),
		.da_pr_en				(da_pr_en),
		.da_pr_pc				(da_pr_pc),
		.da_pr_cop_op			(da_pr_cop_op),
		.da_pr_cop_data			(da_pr_cop_data),
		.da_pr_rd_addr			(da_pr_rd_addr),
		.da_pr_rd_en			(da_pr_rd_en),
		.da_pr_rd_data			(da_pr_rd_data),
		.da_pr_hi_en			(da_pr_hi_en),
		.da_pr_hi_data			(da_pr_hi_data),
		.da_pr_lo_en			(da_pr_lo_en),
		.da_pr_lo_data			(da_pr_lo_data),
		.da_pr_bd				(da_pr_bd),
		.da_pr_exp				(da_pr_exp),
		.inv_en					(inv_da_en),
		.inv_addr				(inv_da_addr),
		.cbus_req				(cbus_da_req),
		.cbus_cmd				(cbus_da_cmd),
		.cbus_addr				(cbus_da_addr),
		.cbus_wr_data_be		(cbus_da_wr_data_be),
		.cbus_wr_data			(cbus_da_wr_data),
		.cbus_ack				(cbus_da_ack),
		.cbus_rdy				(cbus_da_rdy),
		.cbus_rd_data			(cbus_da_rd_data)
	);

	/******** WB ********/
	pu_wb pu_wb(
		.clk					(clk),
		.rst_					(rst_),
		.pid					(pid),
		.tid					(tid),
		.tmode					(tmode),
		.wb_flush				(wb_flush),
		.wb_stall				(wb_stall),
		.wb_busy				(wb_busy),
		.wb_en					(wb_en),
		.wb_pc					(wb_pc),
		.wb_cop_op				(wb_cop_op),
		.wb_cop_data			(wb_cop_data),
		.wb_rd_addr				(wb_rd_addr),
		.wb_rd_en				(wb_rd_en),
		.wb_rd_data				(wb_rd_data),
		.wb_hi_en				(wb_hi_en),
		.wb_hi_data				(wb_hi_data),
		.wb_lo_en				(wb_lo_en),
		.wb_lo_data				(wb_lo_data),
		.wb_bd					(wb_bd),
		.wb_exp					(wb_exp),
		.fwd_wb_cop_op			(fwd_wb_cop_op),
		.fwd_wb_rd_addr			(fwd_wb_rd_addr),
		.fwd_wb_rd_en			(fwd_wb_rd_en),
		.fwd_wb_rd_data			(fwd_wb_rd_data),
		.fwd_wb_hi_en			(fwd_wb_hi_en),
		.fwd_wb_hi_data			(fwd_wb_hi_data),
		.fwd_wb_lo_en			(fwd_wb_lo_en),
		.fwd_wb_lo_data			(fwd_wb_lo_data),
		.da_pr_en				(da_pr_en),
		.da_pr_pc				(da_pr_pc),
		.da_pr_cop_op			(da_pr_cop_op),
		.da_pr_cop_data			(da_pr_cop_data),
		.da_pr_rd_addr			(da_pr_rd_addr),
		.da_pr_rd_en			(da_pr_rd_en),
		.da_pr_rd_data			(da_pr_rd_data),
		.da_pr_hi_en			(da_pr_hi_en),
		.da_pr_hi_data			(da_pr_hi_data),
		.da_pr_lo_en			(da_pr_lo_en),
		.da_pr_lo_data			(da_pr_lo_data),
		.da_pr_bd				(da_pr_bd),
		.da_pr_exp				(da_pr_exp)
	);

/*----------------------------------------------------------------------------*
 * Debug
 *----------------------------------------------------------------------------*/
`ifdef DEBUG
	/********  ********/
	generate
		for (gi = 0; gi < `PU_PID_NUM; gi = gi + 1) begin : DEBUG_PID

			wire				PID0_EN		=
					(pu_cop.cpr_status_en[gi] == `ENABLE) ? `ENABLE
				:	1'bx;
			wire [`PuTidBus]	PID1_TID	=
					(pu_cop.cpr_status_en[gi] == `ENABLE) ?
					pu_cop.cpr_tid_id[gi]
				:	`PU_TID_W'hx;
			wire [`ByteAddrBus]	PID2_IA		=
					(pu_cop.cpr_pid_id == gi) ?
					{pu_cop.cop_pr_pc, `WORD_BO_W'h0}
				:	`BYTE_ADDR_W'hx;
			wire [`ByteAddrBus]	PID3_ID		=
					((pu_cop.cpr_pid_id == gi) &&
					(pu_id.ia_pr_en == `ENABLE)) ?
					{pu_id.ia_pr_pc, `WORD_BO_W'h0}
				:	`BYTE_ADDR_W'hx;
			wire [`ByteAddrBus]	PID4_EX		=
					((pu_cop.cpr_pid_id == gi) &&
					(pu_ex.id_pr_en == `ENABLE)) ?
					{pu_ex.id_pr_pc, `WORD_BO_W'h0}
				:	`BYTE_ADDR_W'hx;
			wire [`ByteAddrBus]	PID5_DA		=
					((pu_cop.cpr_pid_id == gi) &&
					(pu_da.ex_pr_en == `ENABLE)) ?
					{pu_da.ex_pr_pc, `WORD_BO_W'h0}
				:	`BYTE_ADDR_W'hx;
			wire [`ByteAddrBus]	PID6_WB		=
					((pu_cop.cpr_pid_id == gi) &&
					(pu_wb.da_pr_en == `ENABLE)) ?
					{pu_wb.da_pr_pc, `WORD_BO_W'h0}
				:	`BYTE_ADDR_W'hx;
		end
	endgenerate
`endif

endmodule

