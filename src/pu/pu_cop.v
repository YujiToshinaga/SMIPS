/*----------------------------------------------------------------------------*
 *	SMIPS
 *
 *	File	: pu_cop.v
 *	Date	: 2012-05-05T11:41:11+9:00
 *	Author	: toshinaga
 *
 *	Description :
 *		***
 *----------------------------------------------------------------------------*/

`include "config.h"

`include "stddef.h"
`include "pu.h"
`include "vu.h"

module pu_cop#(
	parameter							PUID				= 0,
	parameter							VU_EN				= 0
)(
	/******** Clock and Reset ********/
	input wire							clk,
	input wire							rst_,
	/******** Shared Access ********/
	// Pipeline Control
	output wire [`PuPidBus]				pid,
	output wire [`PuTidBus]				tid,
	output wire [`PuTmodeBus]			tmode,
	output wire							ne,
`ifdef IMP_VUS
	output wire [`VusModeBus]			vus_mode,
	output wire [`CpuTileIdBus]			vus_tileid,
`endif
	/******** IA Access ********/
	// Pipeline Control
	output reg							ia_flush,
	output reg							ia_stall,
	input wire							ia_busy,
	// ITLB
	output wire							itlb_on,
	// IC
	output wire							ic_on,
	// COP/IA Non Pipeline
	output reg [`WordAddrBus]			cop_np_pc,
	// COP/IA Pipeline Register
	output reg [`WordAddrBus]			cop_pr_pc,
	/******** ID Access ********/
	// Pipeline Control
	output reg							id_flush,
	output reg							id_stall,
	input wire							id_busy,
	input wire							id_hazard,
	input wire							branch_en,
	input wire [`WordAddrBus]			branch_pc,
	// CPR Read
	input wire [`PuCprAddrBus]			cpr_rd_addr,
	output reg [`WordDataBus]			cpr_rd_data,
	// VCR Read
	input wire [`PuVcrAddrBus]			vcr_rd_addr,
	output reg [`WordDataBus]			vcr_rd_data,
	// Write Back
	output wire [`PuGprAddrBus]			cop_rd_addr,
	output wire							cop_rd_en,
	output reg [`WordDataBus]			cop_rd_data,
	output wire							cop_hi_en,
	output wire [`WordDataBus]			cop_hi_data,
	output wire							cop_lo_en,
	output wire [`WordDataBus]			cop_lo_data,
	/******** EX Access ********/
	// Pipeline Control
	output reg							ex_flush,
	output reg							ex_stall,
	input wire							ex_busy,
	/******** DA Access ********/
	// Pipeline Control
	output reg							da_flush,
	output reg							da_stall,
	input wire							da_busy,
	// DTLB
	output wire							dtlb_on,
	// DC
	output wire							dc_on,
	/******** WB Access ********/
	// Pipeline Control
	output reg							wb_flush,
	output reg							wb_stall,
	input wire							wb_busy,
	// COP Control
	input wire							wb_en,
	input wire [`WordAddrBus]			wb_pc,
	input wire [`PuCopOpBus]			wb_cop_op,
	input wire [`WordDataBus]			wb_cop_data,
	input wire [`PuGprAddrBus]			wb_rd_addr,
	input wire							wb_rd_en,
	input wire [`WordDataBus]			wb_rd_data,
	input wire							wb_hi_en,
	input wire [`WordDataBus]			wb_hi_data,
	input wire							wb_lo_en,
	input wire [`WordDataBus]			wb_lo_data,
	input wire							wb_bd,
	input wire [`PuExpWbBus]			wb_exp,
	/******** Vector Unit Access ********/
	output wire [`PuPidBus]				vu_pid,
	output reg [`WordDataBus]			vu_status,
	/******** L2 Cache Access ********/
	output wire							l2c_on,
	/******** Out Access ********/
	input wire [`PuIrqBus]				irq
);

/*----------------------------------------------------------------------------*
 * Wire and Reg
 *----------------------------------------------------------------------------*/
	/******** Coprocessor Register ********/
	// Processor Unit ID Register
	reg [`PuCprPuidIdBus]				cpr_puid_id;

	// Pipeline ID Register
	reg [`PuCprPidIdBus]				cpr_pid_id;

	// Control Register
	reg [`PuCprCtrlItlbBus]				cpr_ctrl_itlb;
	reg [`PuCprCtrlIcBus]				cpr_ctrl_ic;
	reg [`PuCprCtrlDtlbBus]				cpr_ctrl_dtlb;
	reg [`PuCprCtrlDcBus]				cpr_ctrl_dc;
	reg [`PuCprCtrlL2cBus]				cpr_ctrl_l2c;

	// Status Register
	reg [`PuCprStatusEnBus]				cpr_status_en[0:`PU_PID_NUM-1];
	reg [`PuCprStatusActBus]			cpr_status_act[0:`PU_PID_NUM-1];
	reg [`PuCprStatusNeBus]				cpr_status_ne[0:`PU_PID_NUM-1];
	reg [`PuCprStatusImBus]				cpr_status_im[0:`PU_PID_NUM-1];
	reg [`PuCprStatusKuBus]				cpr_status_ku[0:`PU_PID_NUM-1];
	reg [`PuCprStatusIeBus]				cpr_status_ie[0:`PU_PID_NUM-1];

	// Thread ID Register
	reg [`PuCprTidIdBus]				cpr_tid_id[0:`PU_PID_NUM-1];

	// New PC Register
	reg [`WordAddrBus]					cpr_npc_pc[0:`PU_PID_NUM-1];

	// Cause Register
	reg [`PuCprCauseBdBus]				cpr_cause_bd[0:`PU_PID_NUM-1];
	reg [`PuCprCauseIpBus]				cpr_cause_ip[0:`PU_PID_NUM-1];
	reg [`PuCprCauseSwBus]				cpr_cause_sw[0:`PU_PID_NUM-1];
	reg [`PuCprCauseEcBus]				cpr_cause_ec[0:`PU_PID_NUM-1];

	// EPC Register
	reg [`WordAddrBus]					cpr_epc_pc[0:`PU_PID_NUM-1];

`ifdef IMP_VUS
	// VUS Register
	reg [`PuCprVusModeBus]				cpr_vus_mode[0:`PU_PID_NUM-1];
	reg [`PuCprVusTileidBus]			cpr_vus_tileid[0:`PU_PID_NUM-1];
`endif

	/******** Vector Control Register ********/
	// Status Register
	reg [`PuVcrStatusSwBus]				vcr_status_sw[0:`PU_PID_NUM-1];
	reg [`PuVcrStatusLenBus]			vcr_status_len[0:`PU_PID_NUM-1];
	reg [`PuVcrStatusRfbBus]			vcr_status_rfb[0:`PU_PID_NUM-1];

	/******** Run Thread PID ********/
	reg									run_en;
	reg [`PuPidBus]						run_pid;

	/******** Same Thread PID ********/
	reg									same_en;
	reg [`PuPidBus]						same_pid;

	/******** Next Thread PID ********/
	reg									next_en;
	reg [`PuPidBus]						next_pid;

	/******** Blank Thread PID ********/
	reg									blank_en;
	reg [`PuPidBus]						blank_pid;

	/******** All Flush ********/
	reg									all_flush;

	/******** Pipeline Control ********/
	reg									pc_stall;

	/******** Iterator ********/
	integer								i;

	generate
		genvar								gi;
	endgenerate

/*----------------------------------------------------------------------------*
 * Module Instance
 *----------------------------------------------------------------------------*/
	/********  ********/
//	xxx xxx(
//		.clk				(clk),
//		.rst_				(rst_),
//
//	);

/*----------------------------------------------------------------------------*
 * Combinational Logic
 *----------------------------------------------------------------------------*/
	/******** CPR Read ********/
	always @(*) begin
		cpr_rd_data						= `WORD_DATA_W'h0;

		case (cpr_rd_addr)
		`PU_CPR_ADDR_PUID : begin
			cpr_rd_data[`PuCprPuidIdLoc]	= cpr_puid_id;
		end
		`PU_CPR_ADDR_PID : begin
			cpr_rd_data[`PuCprPidIdLoc]		= cpr_pid_id;
		end
		`PU_CPR_ADDR_CTRL : begin
			cpr_rd_data[`PuCprCtrlItlbLoc]	= cpr_ctrl_itlb;
			cpr_rd_data[`PuCprCtrlIcLoc]	= cpr_ctrl_ic;
			cpr_rd_data[`PuCprCtrlDtlbLoc]	= cpr_ctrl_dtlb;
			cpr_rd_data[`PuCprCtrlDcLoc]	= cpr_ctrl_dc;
			cpr_rd_data[`PuCprCtrlL2cLoc]	= cpr_ctrl_l2c;
		end
		`PU_CPR_ADDR_STATUS : begin
			cpr_rd_data[`PuCprStatusEnLoc]	= cpr_status_en[cpr_pid_id];
			cpr_rd_data[`PuCprStatusActLoc]	= cpr_status_act[cpr_pid_id];
			cpr_rd_data[`PuCprStatusNeLoc]	= cpr_status_ne[cpr_pid_id];
			cpr_rd_data[`PuCprStatusImLoc]	= cpr_status_im[cpr_pid_id];
			cpr_rd_data[`PuCprStatusKuLoc]	= cpr_status_ku[cpr_pid_id];
			cpr_rd_data[`PuCprStatusIeLoc]	= cpr_status_ie[cpr_pid_id];
		end
		`PU_CPR_ADDR_TID : begin
			cpr_rd_data[`PuCprTidIdLoc]		= cpr_tid_id[cpr_pid_id];
		end
		`PU_CPR_ADDR_NPC : begin
			cpr_rd_data[`WordAddrLoc]		= cpr_npc_pc[cpr_pid_id];
		end
		`PU_CPR_ADDR_CAUSE : begin
			cpr_rd_data[`PuCprCauseBdLoc]	= cpr_cause_bd[cpr_pid_id];
			cpr_rd_data[`PuCprCauseIpLoc]	= cpr_cause_ip[cpr_pid_id];
			cpr_rd_data[`PuCprCauseSwLoc]	= cpr_cause_sw[cpr_pid_id];
			cpr_rd_data[`PuCprCauseEcLoc]	= cpr_cause_ec[cpr_pid_id];
		end
		`PU_CPR_ADDR_EPC : begin
			cpr_rd_data[`WordAddrLoc]		= cpr_epc_pc[cpr_pid_id];
		end
`ifdef IMP_VUS
		`PU_CPR_ADDR_VUS : begin
			cpr_rd_data[`PuCprVusModeLoc]	= cpr_vus_mode[cpr_pid_id];
			cpr_rd_data[`PuCprVusTileidLoc]	= cpr_vus_tileid[cpr_pid_id];
		end
`endif
		endcase
	end

	/******** VCR Read ********/
	always @(*) begin
		vcr_rd_data						= `WORD_DATA_W'h0;

		case (vcr_rd_addr)
		`PU_VCR_ADDR_STATUS : begin
			vcr_rd_data[`PuVcrStatusSwLoc]	= vcr_status_sw[cpr_pid_id];
			vcr_rd_data[`PuVcrStatusLenLoc]	= vcr_status_len[cpr_pid_id];
			vcr_rd_data[`PuVcrStatusRfbLoc]	= vcr_status_rfb[cpr_pid_id];
		end
		endcase
	end

	/******** Run Thread PID ********/
	always @(*) begin
		if ((cpr_status_en[cpr_pid_id] == `ENABLE) &&
	   			(cpr_status_act[cpr_pid_id] == `ENABLE)) begin
			run_en	= `ENABLE;
			run_pid	= cpr_pid_id;
		end else begin
			run_en	= `DISABLE;
			run_pid	= `PU_PID_W'h0;
		end
	end

	/******** Same Thread PID ********/
	always @(*) begin
		same_en		= `DISABLE;
		same_pid	= `PU_PID_W'h0;
		for (i = 0; i < `PU_PID_NUM; i = i + 1) begin
			if ((cpr_status_en[i] == `ENABLE) &&
					(cpr_tid_id[i] == wb_rd_data[`PuTidLoc])) begin
				same_en		= `ENABLE;
				same_pid	= i;
			end
		end
	end

	/******** Next Thread PID ********/
	always @(*) begin
		case (cpr_pid_id)
		`PU_PID_W'h0 : begin
			if ((cpr_status_en[1] == `ENABLE) &&
					(cpr_status_act[1] == `ENABLE) &&
					(cpr_status_ne[1] == `ENABLE)) begin
				next_en		= `ENABLE;
				next_pid	= `PU_PID_W'h1;
			end else if ((cpr_status_en[2] == `ENABLE) &&
					(cpr_status_act[2] == `ENABLE) &&
					(cpr_status_ne[2] == `ENABLE)) begin
				next_en		= `ENABLE;
				next_pid	= `PU_PID_W'h2;
			end else if ((cpr_status_en[3] == `ENABLE) &&
					(cpr_status_act[3] == `ENABLE) &&
					(cpr_status_ne[3] == `ENABLE)) begin
				next_en		= `ENABLE;
				next_pid	= `PU_PID_W'h3;
			end else begin
				next_en		= `DISABLE;
				next_pid	= `PU_PID_W'h0;
			end
		end
		`PU_PID_W'h1 : begin
			if ((cpr_status_en[2] == `ENABLE) &&
					(cpr_status_act[2] == `ENABLE) &&
					(cpr_status_ne[2] == `ENABLE)) begin
				next_en		= `ENABLE;
				next_pid	= `PU_PID_W'h2;
			end else if ((cpr_status_en[3] == `ENABLE) &&
					(cpr_status_act[3] == `ENABLE) &&
					(cpr_status_ne[3] == `ENABLE)) begin
				next_en		= `ENABLE;
				next_pid	= `PU_PID_W'h3;
			end else if ((cpr_status_en[0] == `ENABLE) &&
					(cpr_status_act[0] == `ENABLE) &&
					(cpr_status_ne[0] == `ENABLE)) begin
				next_en		= `ENABLE;
				next_pid	= `PU_PID_W'h0;
			end else begin
				next_en		= `DISABLE;
				next_pid	= `PU_PID_W'h1;
			end
		end
		`PU_PID_W'h2 : begin
			if ((cpr_status_en[3] == `ENABLE) &&
					(cpr_status_act[3] == `ENABLE) &&
					(cpr_status_ne[3] == `ENABLE)) begin
				next_en		= `ENABLE;
				next_pid	= `PU_PID_W'h3;
			end else if ((cpr_status_en[0] == `ENABLE) &&
					(cpr_status_act[0] == `ENABLE) &&
					(cpr_status_ne[0] == `ENABLE)) begin
				next_en		= `ENABLE;
				next_pid	= `PU_PID_W'h0;
			end else if ((cpr_status_en[1] == `ENABLE) &&
					(cpr_status_act[1] == `ENABLE) &&
					(cpr_status_ne[1] == `ENABLE)) begin
				next_en		= `ENABLE;
				next_pid	= `PU_PID_W'h1;
			end else begin
				next_en		= `DISABLE;
				next_pid	= `PU_PID_W'h2;
			end
		end
		`PU_PID_W'h3 : begin
			if ((cpr_status_en[0] == `ENABLE) &&
					(cpr_status_act[0] == `ENABLE) &&
					(cpr_status_ne[0] == `ENABLE)) begin
				next_en		= `ENABLE;
				next_pid	= `PU_PID_W'h0;
			end else if ((cpr_status_en[1] == `ENABLE) &&
					(cpr_status_act[1] == `ENABLE) &&
					(cpr_status_ne[1] == `ENABLE)) begin
				next_en		= `ENABLE;
				next_pid	= `PU_PID_W'h1;
			end else if ((cpr_status_en[2] == `ENABLE) &&
					(cpr_status_act[2] == `ENABLE) &&
					(cpr_status_ne[2] == `ENABLE)) begin
				next_en		= `ENABLE;
				next_pid	= `PU_PID_W'h2;
			end else begin
				next_en		= `DISABLE;
				next_pid	= `PU_PID_W'h3;
			end
		end
		endcase
	end

	/******** Blank Thread PID ********/
	always @(*) begin
		blank_en	= `DISABLE;
		blank_pid	= `PU_PID_W'h0;
		for (i = `PU_PID_NUM - 1; i >= 0; i = i - 1) begin
			if (cpr_status_en[i] == `DISABLE) begin
				blank_en		= `ENABLE;
				blank_pid		= i;
			end
		end
	end

	/******** Thread Switch ********/
	always @(*) begin
		all_flush = `DISABLE;

		case (wb_cop_op)
		`PU_COP_OP_DELTH : begin
			if (same_en == `ENABLE) begin
				if (cpr_pid_id == same_pid) begin
					all_flush = `ENABLE;
				end
			end
		end
		`PU_COP_OP_SWTH : begin
			if ((same_en == `ENABLE) && (cpr_pid_id != same_pid)) begin
				all_flush = `ENABLE;
			end
		end
		`PU_COP_OP_NEXTTH : begin
			if (next_en == `ENABLE) begin
				all_flush = `ENABLE;
			end
		end
		`PU_COP_OP_SWITCH : begin
			if (next_en == `ENABLE) begin
				all_flush = `ENABLE;
			end else begin
				all_flush = `ENABLE;
			end
		end
`ifdef IMP_VUS
		`PU_COP_OP_VRSVR : begin
			all_flush = `ENABLE;
		end
		`PU_COP_OP_VRLSR : begin
			all_flush = `ENABLE;
		end
		`PU_COP_OP_VWAKE : begin
			all_flush = `ENABLE;
		end
		`PU_COP_OP_VSLEEP : begin
			all_flush = `ENABLE;
		end
`endif
		endcase
	end

	/******** Pipeline Control ********/
	assign pid		= cpr_pid_id;
	assign tid		= cpr_tid_id[cpr_pid_id];
	assign tmode	= cpr_status_ku[cpr_pid_id];
	assign ne		= next_en;
`ifdef IMP_VUS
	assign vus_mode		= cpr_vus_mode[cpr_pid_id];
	assign vus_tileid	= cpr_vus_tileid[cpr_pid_id];
`endif

	always @ (*) begin
		if (all_flush == `ENABLE) begin
			ia_flush = `ENABLE;
			id_flush = `ENABLE;
			ex_flush = `ENABLE;
			da_flush = `ENABLE;
			wb_flush = `ENABLE;
		end else begin
			ia_flush = `DISABLE;
			id_flush = id_hazard;
			ex_flush = `DISABLE;
			da_flush = `DISABLE;
			wb_flush = `DISABLE;
		end
	end

	always @ (*) begin
		if (all_flush == `ENABLE) begin
			pc_stall = `DISABLE;

			ia_stall = `DISABLE;
			id_stall = `DISABLE;
			ex_stall = `DISABLE;
			da_stall = `DISABLE;
			wb_stall = `DISABLE;
		end else begin
			pc_stall =
				ia_busy | id_busy | ex_busy | da_busy | wb_busy | id_hazard;

			ia_stall = id_busy | ex_busy | da_busy | wb_busy | id_hazard;
			id_stall = ia_busy | ex_busy | da_busy | wb_busy;
			ex_stall = ia_busy | id_busy | da_busy | wb_busy;
			da_stall = ia_busy | id_busy | ex_busy | wb_busy;
			wb_stall = ia_busy | id_busy | ex_busy | da_busy;
		end
	end

	/******** Core Control ********/
	assign itlb_on		= cpr_ctrl_itlb;
	assign ic_on		= cpr_ctrl_ic;
	assign dtlb_on		= cpr_ctrl_dtlb;
	assign dc_on		= cpr_ctrl_dc;
	assign l2c_on		= cpr_ctrl_l2c;

	/******** Vector Unit Control ********/
	assign vu_pid		= cpr_pid_id;
	always @(*) begin
		vu_status						= `WORD_DATA_W'h0;
		vu_status[`PuVcrStatusSwLoc]	= vcr_status_sw[cpr_pid_id];
		vu_status[`PuVcrStatusLenLoc]	= vcr_status_len[cpr_pid_id];
		vu_status[`PuVcrStatusRfbLoc]	= vcr_status_rfb[cpr_pid_id];
	end

	/******** Write Back ********/
	assign cop_rd_addr	= wb_rd_addr;
	assign cop_rd_en	= wb_rd_en;
	always @(*) begin
		cop_rd_data = wb_rd_data;

		case (wb_cop_op)
		`PU_COP_OP_MKTH : begin
			if ((same_en == `DISABLE) && (blank_en == `ENABLE)) begin
				cop_rd_data = `WORD_DATA_W'h1;
			end else begin
				cop_rd_data = `WORD_DATA_W'h0;
			end
		end
		`PU_COP_OP_DELTH : begin
			if (same_en == `ENABLE) begin
				cop_rd_data = `WORD_DATA_W'h1;
			end else begin
				cop_rd_data = `WORD_DATA_W'h0;
			end
		end
		`PU_COP_OP_SWTH : begin
			if ((same_en == `ENABLE) && (cpr_pid_id != same_pid)) begin
				cop_rd_data = `WORD_DATA_W'h1;
			end else begin
				cop_rd_data = `WORD_DATA_W'h0;
			end
		end
		`PU_COP_OP_NEXTTH : begin
			if (next_en == `ENABLE) begin
				cop_rd_data = `WORD_DATA_W'h1;
			end else begin
				cop_rd_data = `WORD_DATA_W'h0;
			end
		end
`ifdef IMP_VUS
		`PU_COP_OP_VRSV : begin // modify
			cop_rd_data = `WORD_DATA_W'h0;
		end
		`PU_COP_OP_VRLS : begin // modify
			cop_rd_data = `WORD_DATA_W'h0;
		end
		`PU_COP_OP_VRSVR : begin // modify
			cop_rd_data = `WORD_DATA_W'h0;
		end
		`PU_COP_OP_VRLSR : begin // modify
			cop_rd_data = `WORD_DATA_W'h0;
		end
`endif
		endcase
	end
	assign cop_hi_en	= wb_hi_en;
	assign cop_hi_data	= wb_hi_data;
	assign cop_lo_en	= wb_lo_en;
	assign cop_lo_data	= wb_lo_data;

	/******** Non Pipeline Signal ********/
	always @(*) begin
		cop_np_pc = cop_pr_pc;

		case (wb_cop_op)
		`PU_COP_OP_DELTH : begin
			if (same_en == `ENABLE) begin
				if (cpr_pid_id == same_pid) begin
					if (next_en == `ENABLE) begin
						cop_np_pc = cpr_npc_pc[next_pid];
					end else begin
						cop_np_pc = `WORD_ADDR_W'h0;
					end
				end
			end
		end
		`PU_COP_OP_SWTH : begin
			if ((same_en == `ENABLE) && (cpr_pid_id != same_pid)) begin
				cop_np_pc = cpr_npc_pc[same_pid];
			end
		end
		`PU_COP_OP_NEXTTH : begin
			if (next_en == `ENABLE) begin
				cop_np_pc = cpr_npc_pc[next_pid];
			end
		end
		`PU_COP_OP_SWITCH : begin
			if (next_en == `ENABLE) begin
				cop_np_pc = cpr_npc_pc[next_pid];
			end else begin
				if (wb_bd == `ENABLE) begin
					cop_np_pc = wb_pc - 1;
				end else begin
					cop_np_pc = wb_pc;
				end
			end
		end
		default : begin
			if (run_en == `ENABLE) begin
				if (branch_en == `ENABLE) begin
					if (pc_stall == `DISABLE) begin
						cop_np_pc = branch_pc;
					end
				end else begin
					if (pc_stall == `DISABLE) begin
						cop_np_pc = cop_pr_pc + 1;
					end
				end
			end else begin
				cop_np_pc = `WORD_ADDR_W'h0;
			end
		end
		endcase
	end

/*----------------------------------------------------------------------------*
 * Sequential Logic
 *----------------------------------------------------------------------------*/
	/********  ********/
	always @(posedge clk or negedge rst_) begin
		if (rst_ == `ENABLE_) begin
			cop_pr_pc			<= #1 `WORD_ADDR_W'h0;

			cpr_puid_id			<= #1 PUID;

			cpr_pid_id			<= #1 `PU_PID_W'h0;

			cpr_ctrl_itlb		<= #1 `DISABLE;
			cpr_ctrl_ic			<= #1 `DISABLE;
			cpr_ctrl_dtlb		<= #1 `DISABLE;
			cpr_ctrl_dc			<= #1 `DISABLE;
			cpr_ctrl_l2c		<= #1 `DISABLE;

			// Thread 0
			cpr_status_en[0]	<= #1 `ENABLE;
			cpr_status_act[0]	<= #1 `ENABLE;
			cpr_status_ne[0]	<= #1 `ENABLE;
			cpr_status_im[0]	<= #1 `PU_CPR_STATUS_IM_W'h0;
			cpr_status_ku[0]	<= #1 `PU_TMODE_KERNEL;
			cpr_status_ie[0]	<= #1 `DISABLE;

			cpr_tid_id[0]		<= #1 {PUID, 2'h0};

			cpr_npc_pc[0]		<= #1 `WORD_ADDR_W'h0;

			cpr_cause_bd[0] 	<= #1 `PU_CPR_CAUSE_BD_W'b0;
			cpr_cause_ip[0] 	<= #1 `PU_CPR_CAUSE_IP_W'b0;
			cpr_cause_sw[0] 	<= #1 `PU_CPR_CAUSE_SW_W'b0;
			cpr_cause_ec[0] 	<= #1 `PU_EXP_NO;

			cpr_epc_pc[0]		<= #1 `WORD_ADDR_W'h0;

`ifdef IMP_VUS
			cpr_vus_mode[0]		<= #1 `VUS_MODE_NO;
			cpr_vus_tileid[0]	<= #1 `CPU_TILE_ID_W'h0;
`endif

			vcr_status_sw[0]	<= #1 `DISABLE;
			vcr_status_len[0]	<= #1 `VU_LENGTH_W'h0;
			vcr_status_rfb[0]	<= #1 `VU_RF_ADDR_W'h0;

			// Thread 1, 2, 3
			for (i = 1; i < `PU_PID_NUM; i = i + 1) begin
				cpr_status_en[i]	<= #1 `DISABLE;
				cpr_status_act[i]	<= #1 `DISABLE;
				cpr_status_ne[i]	<= #1 `DISABLE;
				cpr_status_im[i]	<= #1 `PU_CPR_STATUS_IM_W'h0;
				cpr_status_ku[i]	<= #1 `PU_TMODE_KERNEL;
				cpr_status_ie[i]	<= #1 `DISABLE;

				cpr_tid_id[i]		<= #1 `PU_TID_W'h0;

				cpr_npc_pc[i]		<= #1 `WORD_ADDR_W'h0;

				cpr_cause_bd[i] 	<= #1 `PU_CPR_CAUSE_BD_W'b0;
				cpr_cause_ip[i] 	<= #1 `PU_CPR_CAUSE_IP_W'b0;
				cpr_cause_sw[i] 	<= #1 `PU_CPR_CAUSE_SW_W'b0;
				cpr_cause_ec[i] 	<= #1 `PU_EXP_NO;

				cpr_epc_pc[i]		<= #1 `WORD_ADDR_W'h0;

`ifdef IMP_VUS
				cpr_vus_mode[i]		<= #1 `VUS_MODE_NO;
				cpr_vus_tileid[i]	<= #1 `CPU_TILE_ID_W'h0;
`endif

				vcr_status_sw[i]	<= #1 `DISABLE;
				vcr_status_len[i]	<= #1 `VU_LENGTH_W'h0;
				vcr_status_rfb[i]	<= #1 `VU_RF_ADDR_W'h0;
			end
		end else begin
			/******** Coprocessor Register ********/
			case (wb_cop_op)
			`PU_COP_OP_MT : begin
				case (wb_rd_addr)
				`PU_CPR_ADDR_PUID : begin
					cpr_puid_id			<= #1 wb_rd_data[`PuCprPuidIdLoc];
				end
				`PU_CPR_ADDR_PID : begin
					cpr_pid_id			<= #1 wb_rd_data[`PuCprPidIdLoc];
				end
				`PU_CPR_ADDR_CTRL : begin
					cpr_ctrl_itlb		<= #1 wb_rd_data[`PuCprCtrlItlbLoc];
					cpr_ctrl_ic			<= #1 wb_rd_data[`PuCprCtrlIcLoc];
					cpr_ctrl_dtlb		<= #1 wb_rd_data[`PuCprCtrlDtlbLoc];
					cpr_ctrl_dc			<= #1 wb_rd_data[`PuCprCtrlDcLoc];
					cpr_ctrl_l2c		<= #1 wb_rd_data[`PuCprCtrlL2cLoc];
				end
				`PU_CPR_ADDR_STATUS : begin
					cpr_status_en[cpr_pid_id]
										<= #1 wb_rd_data[`PuCprStatusEnLoc];
					cpr_status_act[cpr_pid_id]
										<= #1 wb_rd_data[`PuCprStatusActLoc];
					cpr_status_ne[cpr_pid_id]
										<= #1 wb_rd_data[`PuCprStatusNeLoc];
					cpr_status_im[cpr_pid_id]
										<= #1 wb_rd_data[`PuCprStatusImLoc];
					cpr_status_ku[cpr_pid_id]
										<= #1 wb_rd_data[`PuCprStatusKuLoc];
					cpr_status_ie[cpr_pid_id]
										<= #1 wb_rd_data[`PuCprStatusIeLoc];
				end
				`PU_CPR_ADDR_TID : begin
					cpr_tid_id[cpr_pid_id]
										<= #1 wb_rd_data[`PuCprTidIdLoc];
				end
				`PU_CPR_ADDR_NPC : begin
					cpr_npc_pc[cpr_pid_id]
										<= #1 wb_rd_data[`WordAddrLoc];
				end
				`PU_CPR_ADDR_CAUSE : begin
					cpr_cause_bd[cpr_pid_id]
										<= #1 wb_rd_data[`PuCprCauseBdLoc];
					cpr_cause_ip[cpr_pid_id]
										<= #1 wb_rd_data[`PuCprCauseIpLoc];
					cpr_cause_sw[cpr_pid_id]
										<= #1 wb_rd_data[`PuCprCauseSwLoc];
					cpr_cause_ec[cpr_pid_id]
										<= #1 wb_rd_data[`PuCprCauseEcLoc];
				end
				`PU_CPR_ADDR_EPC : begin
					cpr_epc_pc[cpr_pid_id]
										<= #1 wb_rd_data[`WordAddrLoc];
				end
`ifdef IMP_VUS
				`PU_CPR_ADDR_VUS : begin
					cpr_vus_mode[cpr_pid_id]
										<= #1 wb_rd_data[`PuCprVusModeLoc];
					cpr_vus_tileid[cpr_pid_id]
										<= #1 wb_rd_data[`PuCprVusTileidLoc];
				end
`endif
				endcase
			end
			`PU_COP_OP_MKTH : begin
				if ((same_en == `DISABLE) && (blank_en == `ENABLE)) begin

					cpr_status_en[blank_pid]
										<= #1 `ENABLE;
					cpr_status_act[blank_pid]
										<= #1 `ENABLE;
					cpr_status_ne[blank_pid]
										<= #1 `ENABLE;
					cpr_tid_id[blank_pid]
										<= #1 wb_rd_data[`PuTidLoc];
					cpr_npc_pc[blank_pid]
										<= #1 wb_cop_data[`WordAddrLoc];
				end
			end
			`PU_COP_OP_DELTH : begin
				if (same_en == `ENABLE) begin
					if (cpr_pid_id == same_pid) begin
						if (next_en == `ENABLE) begin
							cop_pr_pc			<= #1 cpr_npc_pc[next_pid];

							cpr_pid_id			<= #1 next_pid;
						end else begin
							cop_pr_pc			<= #1 `WORD_ADDR_W'h0;

							cpr_pid_id			<= #1 `PU_PID_W'h0;
						end
					end

					cpr_status_en[same_pid]
										<= #1 `DISABLE;
					cpr_status_act[same_pid]
										<= #1 `DISABLE;
					cpr_status_ne[same_pid]
										<= #1 `DISABLE;
					cpr_status_im[same_pid]
										<= #1 `PU_CPR_STATUS_IM_W'h0;
					cpr_status_ku[same_pid]
										<= #1 `PU_TMODE_KERNEL;
					cpr_status_ie[same_pid]
										<= #1 `DISABLE;
					cpr_tid_id[same_pid]
										<= #1 `PU_TID_W'h0;
					cpr_npc_pc[same_pid]
										<= #1 `WORD_ADDR_W'h0;
					cpr_cause_bd[same_pid]
										<= #1 `PU_CPR_CAUSE_BD_W'b0;
					cpr_cause_ip[same_pid]
										<= #1 `PU_CPR_CAUSE_IP_W'b0;
					cpr_cause_sw[same_pid]
										<= #1 `PU_CPR_CAUSE_SW_W'b0;
					cpr_cause_ec[same_pid]
										<= #1 `PU_EXP_NO;
					cpr_epc_pc[same_pid]
										<= #1 `WORD_ADDR_W'h0;
`ifdef IMP_VUS
					cpr_vus_mode[cpr_pid_id]
										<= #1 `VUS_MODE_NO;
					cpr_vus_tileid[cpr_pid_id]
										<= #1 `CPU_TILE_ID_W'h0;
`endif
				end
			end
			`PU_COP_OP_SWTH : begin
				if ((same_en == `ENABLE) && (cpr_pid_id != same_pid)) begin
					cop_pr_pc			<= #1 cpr_npc_pc[same_pid];

					cpr_pid_id			<= #1 same_pid;
					cpr_npc_pc[cpr_pid_id]
										<= #1 wb_pc + 1;
				end
			end
			`PU_COP_OP_NEXTTH : begin
				if (next_en == `ENABLE) begin
					cop_pr_pc			<= #1 cpr_npc_pc[next_pid];

					cpr_pid_id			<= #1 next_pid;
					cpr_npc_pc[cpr_pid_id]
										<= #1 wb_pc + 1;
				end
			end
			`PU_COP_OP_SWITCH : begin
				if (next_en == `ENABLE) begin
					cop_pr_pc			<= #1 cpr_npc_pc[next_pid];

					cpr_pid_id			<= #1 next_pid;
					if (wb_bd == `ENABLE) begin
						cpr_npc_pc[cpr_pid_id]
											<= #1 wb_pc - 1;
					end else begin
						cpr_npc_pc[cpr_pid_id]
											<= #1 wb_pc;
					end
				end else begin
					if (wb_bd == `ENABLE) begin
						cop_pr_pc		<= #1 wb_pc - 1;
					end else begin
						cop_pr_pc		<= #1 wb_pc;
					end
				end
			end
			`PU_COP_OP_VMT : begin
				case (wb_rd_addr)
				`PU_VCR_ADDR_STATUS : begin
					vcr_status_sw[cpr_pid_id]
										<= #1 wb_rd_data[`PuVcrStatusSwLoc];
					vcr_status_len[cpr_pid_id]
										<= #1 wb_rd_data[`PuVcrStatusLenLoc];
					vcr_status_rfb[cpr_pid_id]
										<= #1 wb_rd_data[`PuVcrStatusRfbLoc];
				end
				endcase
			end
`ifdef IMP_VUS
			`PU_COP_OP_VRSV : begin
				if (wb_cop_data[`CpuTileIdBus] == PUID) begin
					cpr_vus_mode[cpr_pid_id]
										<= #1 `VUS_MODE_SELF;
					cpr_vus_tileid[cpr_pid_id]
										<= #1 PUID;
					vcr_status_sw[cpr_pid_id]
										<= #1 wb_rd_data[`PuVcrStatusSwLoc];
					vcr_status_len[cpr_pid_id]
										<= #1 wb_rd_data[`PuVcrStatusLenLoc];
					vcr_status_rfb[cpr_pid_id]
										<= #1 wb_rd_data[`PuVcrStatusRfbLoc];
				end else begin
					cpr_vus_mode[cpr_pid_id]
										<= #1 `VUS_MODE_SEND;
					cpr_vus_tileid[cpr_pid_id]
										<= #1 wb_cop_data[`CpuTileIdBus];
				end
			end
			`PU_COP_OP_VRLS : begin
				cpr_vus_mode[cpr_pid_id]
									<= #1 `VUS_MODE_NO;
				cpr_vus_tileid[cpr_pid_id]
									<= #1 `CPU_TILE_ID_W'h0;
			end
			`PU_COP_OP_VRSVR : begin
				if ((same_en == `DISABLE) && (blank_en == `ENABLE)) begin
					if (wb_bd == `ENABLE) begin
						cop_pr_pc			<= #1 wb_pc - 1;
					end else begin
						cop_pr_pc			<= #1 wb_pc;
					end

					cpr_status_en[blank_pid]
										<= #1 `ENABLE;
					cpr_tid_id[blank_pid]
										<= #1 wb_rd_data[`PuTidLoc];
					cpr_npc_pc[blank_pid]
										<= #1 `WORD_ADDR_W'h0;
					cpr_vus_mode[blank_pid]
										<= #1 `VUS_MODE_RECV;
					cpr_vus_tileid[blank_pid]
										<= #1 wb_rd_addr[`CpuTileIdBus];
					vcr_status_sw[blank_pid]
										<= #1 wb_cop_data[`PuVcrStatusSwLoc];
					vcr_status_len[blank_pid]
										<= #1 wb_cop_data[`PuVcrStatusLenLoc];
					vcr_status_rfb[blank_pid]
										<= #1 wb_cop_data[`PuVcrStatusRfbLoc];
				end
			end
			`PU_COP_OP_VRLSR : begin
				if (same_en == `ENABLE) begin
					if (wb_bd == `ENABLE) begin
						cop_pr_pc			<= #1 wb_pc - 1;
					end else begin
						cop_pr_pc			<= #1 wb_pc;
					end

					cpr_status_en[same_pid]
										<= #1 `DISABLE;
					cpr_status_act[same_pid]
										<= #1 `DISABLE;
					cpr_status_ne[same_pid]
										<= #1 `DISABLE;
					cpr_status_im[same_pid]
										<= #1 `PU_CPR_STATUS_IM_W'h0;
					cpr_status_ku[same_pid]
										<= #1 `PU_TMODE_KERNEL;
					cpr_status_ie[same_pid]
										<= #1 `DISABLE;
					cpr_tid_id[same_pid]
										<= #1 `PU_TID_W'h0;
					cpr_npc_pc[same_pid]
										<= #1 `WORD_ADDR_W'h0;
					cpr_cause_bd[same_pid]
										<= #1 `PU_CPR_CAUSE_BD_W'b0;
					cpr_cause_ip[same_pid]
										<= #1 `PU_CPR_CAUSE_IP_W'b0;
					cpr_cause_sw[same_pid]
										<= #1 `PU_CPR_CAUSE_SW_W'b0;
					cpr_cause_ec[same_pid]
										<= #1 `PU_EXP_NO;
					cpr_epc_pc[same_pid]
										<= #1 `WORD_ADDR_W'h0;
					cpr_vus_mode[same_pid]
										<= #1 `VUS_MODE_NO;
					cpr_vus_tileid[same_pid]
										<= #1 `CPU_TILE_ID_W'h0;
					vcr_status_sw[same_pid]
										<= #1 `DISABLE;
					vcr_status_len[same_pid]
										<= #1 `VU_LENGTH_W'h0;
					vcr_status_rfb[same_pid]
										<= #1 `VU_RF_ADDR_W'h0;
				end
			end
			`PU_COP_OP_VWAKE : begin
				if (same_en == `ENABLE) begin
					cop_pr_pc			<= #1 wb_cop_data[`WordAddrLoc];

					cpr_pid_id			<= #1 same_pid;
					cpr_status_act[same_pid]
										<= #1 `ENABLE;
					cpr_status_ne[same_pid]
										<= #1 `ENABLE;
					if (wb_bd == `ENABLE) begin
						cpr_npc_pc[cpr_pid_id]
											<= #1 wb_pc - 1;
					end else begin
						cpr_npc_pc[cpr_pid_id]
											<= #1 wb_pc;
					end
				end
			end
			`PU_COP_OP_VSLEEP : begin
				if (next_en == `ENABLE) begin
					cop_pr_pc			<= #1 cpr_npc_pc[next_pid];

					cpr_pid_id			<= #1 next_pid;
					cpr_status_act[cpr_pid_id]
										<= #1 `DISABLE;
					cpr_status_ne[cpr_pid_id]
										<= #1 `DISABLE;
					cpr_npc_pc[cpr_pid_id]
										<= #1 wb_pc + 1;
				end else begin
					cop_pr_pc			<= #1 `WORD_ADDR_W'h0;
					cpr_pid_id			<= #1 `PU_PID_W'h0;
					cpr_status_act[cpr_pid_id]
										<= #1 `DISABLE;
					cpr_status_ne[cpr_pid_id]
										<= #1 `DISABLE;
					cpr_npc_pc[cpr_pid_id]
										<= #1 wb_pc + 1;
				end
			end
`else
			`PU_COP_OP_VRSV : begin
				vcr_status_sw[cpr_pid_id]
									<= #1 wb_rd_data[`PuVcrStatusSwLoc];
				vcr_status_len[cpr_pid_id]
									<= #1 wb_rd_data[`PuVcrStatusLenLoc];
				vcr_status_rfb[cpr_pid_id]
									<= #1 wb_rd_data[`PuVcrStatusRfbLoc];
			end
`endif
			default : begin
				if (run_en == `ENABLE) begin
					if (branch_en == `ENABLE) begin
						if (pc_stall == `DISABLE) begin
							cop_pr_pc			<= #1 branch_pc;
						end
					end else begin
						if (pc_stall == `DISABLE) begin
							cop_pr_pc			<= #1 cop_pr_pc + 1;
						end
					end
				end else begin
					cop_pr_pc			<= #1 `WORD_ADDR_W'h0;
				end
			end
			endcase
		end
	end

/*----------------------------------------------------------------------------*
 * Debug
 *----------------------------------------------------------------------------*/
`ifdef DEBUG
	/********  ********/
	wire [`ByteAddrBus] COP_BPC = {wb_pc, `WORD_BO_W'h0};
`endif

endmodule

