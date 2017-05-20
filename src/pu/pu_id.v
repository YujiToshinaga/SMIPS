/*----------------------------------------------------------------------------*
 *	SMIPS
 *
 *	File	: pu_id.v
 *	Date	: 2012-05-05T11:41:11+9:00
 *	Author	: toshinaga
 *
 *	Description :
 *		***
 *----------------------------------------------------------------------------*/

`include "config.h"

`include "stddef.h"
`include "pu.h"
`include "isa.h"
`include "vu.h"
`include "vus.h"

module pu_id#(
	parameter							PUID				= 0,
	parameter							VU_EN				= 0
)(
	/******** Clock and Reset ********/
	input wire							clk,
	input wire							rst_,

	/******** Coprocessor Access ********/
	// Pipeline Control
	input wire [`PuPidBus]				pid,
	input wire [`PuTidBus]				tid,
	input wire [`PuTmodeBus]			tmode,
	input wire							ne,
`ifdef IMP_VUS
	input wire [`VusModeBus]			vus_mode,
	input wire [`CpuTileIdBus]			vus_tileid,
`endif
	input wire							id_flush,
	input wire							id_stall,
	output reg							id_busy,
	output reg							id_hazard,
	output wire							branch_en,
	output wire [`WordAddrBus]			branch_pc,
	// CPR Read
	output wire [`PuCprAddrBus]			cpr_rd_addr,
	input wire [`WordDataBus]			cpr_rd_data,
	// VCR Read
	output wire [`PuVcrAddrBus]			vcr_rd_addr,
	input wire [`WordDataBus]			vcr_rd_data,
	// Write Back
	input wire [`PuGprAddrBus]			cop_rd_addr,
	input wire							cop_rd_en,
	input wire [`WordDataBus]			cop_rd_data,
	input wire							cop_hi_en,
	input wire [`WordDataBus]			cop_hi_data,
	input wire							cop_lo_en,
	input wire [`WordDataBus]			cop_lo_data,
	/******** IA Access ********/
	// IA/ID Pipeline Register
	input wire							ia_pr_en,
	input wire [`WordAddrBus]			ia_pr_pc,
	input wire [`WordDataBus]			ia_pr_inst,
	input wire [`PuExpIaBus]			ia_pr_exp,
	/******** EX Access ********/
	// EX Forwarding
	input wire [`PuCopOpBus]			fwd_ex_cop_op,
	input wire [`PuLsOpBus]				fwd_ex_ls_op,
	input wire [`PuGprAddrBus]			fwd_ex_rd_addr,
	input wire							fwd_ex_rd_en,
	input wire [`WordDataBus]			fwd_ex_rd_data,
	input wire							fwd_ex_hi_en,
	input wire [`WordDataBus]			fwd_ex_hi_data,
	input wire							fwd_ex_lo_en,
	input wire [`WordDataBus]			fwd_ex_lo_data,
	// ID/EX Pipeline Register
	output reg							id_pr_en,
	output reg [`WordAddrBus]			id_pr_pc,
	output reg [`PuCopOpBus]			id_pr_cop_op,
	output reg [`PuLsOpBus]				id_pr_ls_op,
	output reg [`PuIaOpBus]				id_pr_ia_op,
	output reg [`WordDataBus]			id_pr_in0,
	output reg [`WordDataBus]			id_pr_in1,
	output reg [`WordDataBus]			id_pr_st_data,
	output reg [`PuGprAddrBus]			id_pr_rd_addr,
	output reg							id_pr_rd_en,
	output reg							id_pr_hi_en,
	output reg							id_pr_lo_en,
	output reg							id_pr_bd,		// Branch Delay
	output reg [`PuExpIdBus]			id_pr_exp,
	/******** DA Access ********/
	// DA Forwarding
	input wire [`PuCopOpBus]			fwd_da_cop_op,
	input wire [`PuLsOpBus]				fwd_da_ls_op,
	input wire [`PuGprAddrBus]			fwd_da_rd_addr,
	input wire							fwd_da_rd_en,
	input wire [`WordDataBus]			fwd_da_rd_data,
	input wire							fwd_da_hi_en,
	input wire [`WordDataBus]			fwd_da_hi_data,
	input wire							fwd_da_lo_en,
	input wire [`WordDataBus]			fwd_da_lo_data,
	/******** WB Access ********/
	// WB Forwarding
	input wire [`PuCopOpBus]			fwd_wb_cop_op,
	input wire [`PuGprAddrBus]			fwd_wb_rd_addr,
	input wire							fwd_wb_rd_en,
	input wire [`WordDataBus]			fwd_wb_rd_data,
	input wire							fwd_wb_hi_en,
	input wire [`WordDataBus]			fwd_wb_hi_data,
	input wire							fwd_wb_lo_en,
	input wire [`WordDataBus]			fwd_wb_lo_data,
	/******** VU Access ********/
	input wire							vu_busy,
	input wire							vu_active,
	input wire							vu_switch,
	output wire [`VuRfAddrBus]			vu_sr_rd_addr,
	input wire [`DwordDataBus]			vu_sr_rd_data,
	output wire							vu_dd_enq,
	output wire [`VuDdBus]				vu_dd
`ifdef IMP_VUS
	/******** Network Interface Access ********/
	// Master
	,output reg							vus_m_req,
	output reg [`RouterCmdBus]			vus_m_cmd,
	output reg [`CoreAddrBus]			vus_m_addr,
	output reg [`CoreUidBus]			vus_m_uid,
	output reg [`CpuTileIdBus]			vus_m_src,
	output reg [`CpuTileIdBus]			vus_m_dst,
	output reg [`CoreDataBeBus]			vus_m_data_be,
	output reg [`CoreDataBus]			vus_m_data,
	input wire							vus_m_ack,
	// Slave
	input wire							vus_s_req,
	input wire [`RouterCmdBus]			vus_s_cmd,
	input wire [`CpuTileIdBus]			vus_s_src,
	input wire [`CoreDataBus]			vus_s_data,
	output reg							vus_s_ack
`endif
);

/*----------------------------------------------------------------------------*
 * Wire and Reg
 *----------------------------------------------------------------------------*/
`ifdef IMP_VUS
	/******** Local Parameter ********/
	localparam STATE_W					= 3;
	localparam STATE_READY				= 3'h0;
	localparam STATE_RSV_NI				= 3'h1;
	localparam STATE_RLS_NI				= 3'h2;
	localparam STATE_START_NI			= 3'h3;
	localparam STATE_END_NI				= 3'h4;
	localparam STATE_PIPE				= 3'h5;
	localparam STATE_NI					= 3'h6;
`endif
	/******** Instrution Decoder ********/
	wire [`PuGprAddrBus]				rs_addr;
	wire [`PuGprAddrBus]				rt_addr;
	wire [`PuCopOpBus]					dec_cop_op;
	wire [`PuLsOpBus]					dec_ls_op;
	wire [`PuIaOpBus]					dec_ia_op;
	wire [`WordDataBus]					dec_in0;
	wire [`WordDataBus]					dec_in1;
	wire [`WordDataBus]					dec_st_data;
	wire [`PuGprAddrBus]				dec_rd_addr;
	wire								dec_rd_en;
	wire								dec_hi_en;
	wire								dec_lo_en;
	wire								dec_bi;
	wire								dec_sync;
	wire								dec_sc;
	wire								dec_bp;
	wire								dec_pif;
	wire								dec_vu_dd_enq;
	wire [`VuDdBus]						dec_vu_dd;
`ifdef IMP_VUS
	wire [`VusOpBus]					dec_vus_op;
	wire [`VuStatusBus]					dec_vus_status;
	wire [`CpuTileIdBus]				dec_vus_tileid;
	wire [`WordAddrLoc]					dec_vus_pc;
`endif
	/******** GPR ********/
	wire [`WordDataBus]					gpr_rd0_data;
	wire [`WordDataBus]					gpr_rd1_data;
	/******** HLR ********/
	wire [`WordDataBus]					hlr_hi_rd_data;
	wire [`WordDataBus]					hlr_lo_rd_data;
	/******** Read and Write GPR ********/
	wire [`PuGprAddrBus]				gpr_rd0_addr;
	wire [`PuGprAddrBus]				gpr_rd1_addr;
	wire [`PuGprAddrBus]				gpr_wr_addr;
	wire								gpr_wr_en;
	wire [`WordDataBus]					gpr_wr_data;
	/******** Write HLR ********/
	wire								hlr_hi_wr_en;
	wire [`WordDataBus]					hlr_hi_wr_data;
	wire								hlr_lo_wr_en;
	wire [`WordDataBus]					hlr_lo_wr_data;
	/******** Busy ********/
`ifdef IMP_VUS
	reg									vus_busy;
`endif
	/******** Coprocessor Hazard ********/
	reg									cop_hazard;
	/******** RS Hazard and Forwarding ********/
	reg									rs_hazard;
	reg [`WordDataBus]					rs_data;
	/******** RT Hazard and Forwarding ********/
	reg									rt_hazard;
	reg [`WordDataBus]					rt_data;
	/******** HI Forwarding ********/
	reg [`WordDataBus]					hi_data;
	/******** LO Forwarding ********/
	reg [`WordDataBus]					lo_data;
	/******** Switch Operation ********/
	wire								switch;
	/******** ID State Transition ********/
`ifdef IMP_VUS
	reg [STATE_W-1:0]					state;
	reg									bd;
	reg [`RouterCmdBus]					vus_s_cmd_ff;
	reg [`CpuTileIdBus]					vus_s_src_ff;
	reg [`PuTidBus]						vus_s_tid_ff;
	reg [`WordAddrBus]					vus_s_pc_ff;
	reg [`VuStatusBus]					vus_s_status_ff;
`else
	reg									bd;
`endif
	/******** Iterator ********/
	integer								i;
	generate
		genvar								gi;
	endgenerate

/*----------------------------------------------------------------------------*
 * Module Instance
 *----------------------------------------------------------------------------*/
	/******** Instrution Decoder ********/
	pu_id_dec#(
		.PUID					(PUID),
		.VU_EN					(VU_EN)
	) pu_id_dec(
		.tmode					(tmode),
		.inst					(ia_pr_inst),
		.pc						(ia_pr_pc),
`ifdef IMP_VUS
		.vus_mode				(vus_mode),
		.vus_tileid				(vus_tileid),
`endif
		.rs_addr				(rs_addr),
		.rt_addr				(rt_addr),
		.rs_data				(rs_data),
		.rt_data				(rt_data),
		.hi_data				(hi_data),
		.lo_data				(lo_data),
		.cpr_rd_addr			(cpr_rd_addr),
		.cpr_rd_data			(cpr_rd_data),
		.vcr_rd_addr			(vcr_rd_addr),
		.vcr_rd_data			(vcr_rd_data),
		.branch_en				(branch_en),
		.branch_pc				(branch_pc),
		.vu_sr_rd_addr			(vu_sr_rd_addr),
		.vu_sr_rd_data			(vu_sr_rd_data),
		.dec_cop_op				(dec_cop_op),
		.dec_ls_op				(dec_ls_op),
		.dec_ia_op				(dec_ia_op),
		.dec_in0				(dec_in0),
		.dec_in1				(dec_in1),
		.dec_st_data			(dec_st_data),
		.dec_rd_addr			(dec_rd_addr),
		.dec_rd_en				(dec_rd_en),
		.dec_hi_en				(dec_hi_en),
		.dec_lo_en				(dec_lo_en),
		.dec_bi					(dec_bi),
		.dec_sync				(dec_sync),
		.dec_sc					(dec_sc),
		.dec_bp					(dec_bp),
		.dec_pif				(dec_pif),
		.dec_vu_dd_enq			(dec_vu_dd_enq),
		.dec_vu_dd				(dec_vu_dd)
`ifdef IMP_VUS
		,.dec_vus_op			(dec_vus_op),
		.dec_vus_status			(dec_vus_status),
		.dec_vus_tileid			(dec_vus_tileid),
		.dec_vus_pc				(dec_vus_pc)
`endif
	);

	/******** GPR ********/
	pu_id_gpr pu_id_gpr(
		.clk					(clk),
		.rst_					(rst_),
		.pid					(pid),
		.rd0_addr				(gpr_rd0_addr),
		.rd0_data				(gpr_rd0_data),
		.rd1_addr				(gpr_rd1_addr),
		.rd1_data				(gpr_rd1_data),
		.wr_addr				(gpr_wr_addr),
		.wr_en					(gpr_wr_en),
		.wr_data				(gpr_wr_data)
	);

	/******** HLR ********/
	pu_id_hlr pu_id_hlr(
		.clk					(clk),
		.rst_					(rst_),
		.pid					(pid),
		.hi_rd_data				(hlr_hi_rd_data),
		.lo_rd_data				(hlr_lo_rd_data),
		.hi_wr_en				(hlr_hi_wr_en),
		.hi_wr_data				(hlr_hi_wr_data),
		.lo_wr_en				(hlr_lo_wr_en),
		.lo_wr_data				(hlr_lo_wr_data)
	);

/*----------------------------------------------------------------------------*
 * Combinational Logic
 *----------------------------------------------------------------------------*/
	/******** Read and Write GPR ********/
	assign gpr_rd0_addr = rs_addr;
	assign gpr_rd1_addr = rt_addr;
	assign gpr_wr_addr	= cop_rd_addr;
	assign gpr_wr_en	= cop_rd_en;
	assign gpr_wr_data	= cop_rd_data;
	/******** Write HLR ********/
	assign hlr_hi_wr_en		= cop_hi_en;
	assign hlr_hi_wr_data	= cop_hi_data;
	assign hlr_lo_wr_en		= cop_lo_en;
	assign hlr_lo_wr_data	= cop_lo_data;
	/******** Busy ********/
`ifdef IMP_VUS
	always @(*) begin
		id_busy = `DISABLE;

		case (state)
		STATE_READY : begin
			if (id_flush == `ENABLE) begin
			end else if (ia_pr_en == `DISABLE) begin
			end else if (vus_s_req == `ENABLE) begin
				id_busy = `ENABLE;
			end else if (switch == `ENABLE) begin
			end else if (ia_pr_exp != `PU_EXP_IA_NO) begin
			end else begin
				case (dec_vus_op)
				`VUS_OP_RSV : begin
					id_busy = `ENABLE;
				end
				`VUS_OP_RLS : begin
					id_busy = `ENABLE;
				end
				`VUS_OP_START : begin
					id_busy = `ENABLE;
				end
				`VUS_OP_END : begin
					id_busy = `ENABLE;
				end
				default : begin
					if ((vu_busy == `ENABLE) && (dec_vu_dd_enq == `ENABLE)) begin
						id_busy = `ENABLE;
					end
				end
				endcase
			end
		end
		STATE_RSV_NI : begin
			id_busy = `ENABLE;
		end
		STATE_RLS_NI : begin
			id_busy = `ENABLE;
		end
		STATE_START_NI : begin
			id_busy = `ENABLE;
		end
		STATE_END_NI : begin
			id_busy = `ENABLE;
		end
		endcase
	end
`else
	always @(*) begin
		id_busy = `DISABLE;

		if (id_flush == `ENABLE) begin
		end else if (ia_pr_en == `DISABLE) begin
		end else if (switch == `ENABLE) begin
		end else if (ia_pr_exp != `PU_EXP_IA_NO) begin
		end else begin
			if ((vu_busy == `ENABLE) && (dec_vu_dd_enq == `ENABLE)) begin
				id_busy = `ENABLE;
			end
		end
	end
`endif

	/******** Coprocessor Hazard ********/
	always @(*) begin
		if ((fwd_ex_cop_op != `PU_COP_OP_NO) ||
				(fwd_da_cop_op != `PU_COP_OP_NO) ||
				(fwd_wb_cop_op != `PU_COP_OP_NO)) begin
			cop_hazard = `ENABLE;
		end else begin
			cop_hazard = `DISABLE;
		end
	end

	/******** RS Hazard and Forwarding ********/
	always @(*) begin
		if ((fwd_ex_rd_addr == rs_addr) &&
				(fwd_ex_rd_en == `ENABLE)) begin
			if ((fwd_ex_ls_op == `PU_LS_OP_LB) ||
					(fwd_ex_ls_op == `PU_LS_OP_LH) ||
					(fwd_ex_ls_op == `PU_LS_OP_LW) ||
					(fwd_ex_ls_op == `PU_LS_OP_LBU) ||
					(fwd_ex_ls_op == `PU_LS_OP_LHU)) begin
				rs_hazard	= `ENABLE;
				rs_data		= `WORD_DATA_W'h0;
			end else begin
				rs_hazard	= `DISABLE;
				rs_data		= fwd_ex_rd_data;
			end
		end else if ((fwd_da_rd_addr == rs_addr) &&
				(fwd_da_rd_en == `ENABLE)) begin
			if ((fwd_da_ls_op == `PU_LS_OP_LB) ||
					(fwd_da_ls_op == `PU_LS_OP_LH) ||
					(fwd_da_ls_op == `PU_LS_OP_LW) ||
					(fwd_da_ls_op == `PU_LS_OP_LBU) ||
					(fwd_da_ls_op == `PU_LS_OP_LHU)) begin
				rs_hazard	= `ENABLE;
				rs_data		= `WORD_DATA_W'h0;
			end else begin
				rs_hazard	= `DISABLE;
				rs_data		= fwd_da_rd_data;
			end
		end else if ((fwd_wb_rd_addr == rs_addr) &&
				(fwd_wb_rd_en == `ENABLE)) begin
			rs_hazard	= `DISABLE;
			rs_data		= fwd_wb_rd_data;
		end else begin
			rs_hazard	= `DISABLE;
			rs_data		= gpr_rd0_data;
		end
	end

	/******** RT Hazard and Forwarding ********/
	always @(*) begin
		if ((fwd_ex_rd_addr == rt_addr) &&
				(fwd_ex_rd_en == `ENABLE)) begin
			if ((fwd_ex_ls_op == `PU_LS_OP_LB) ||
					(fwd_ex_ls_op == `PU_LS_OP_LH) ||
					(fwd_ex_ls_op == `PU_LS_OP_LW) ||
					(fwd_ex_ls_op == `PU_LS_OP_LBU) ||
					(fwd_ex_ls_op == `PU_LS_OP_LHU)) begin
				rt_hazard	= `ENABLE;
				rt_data		= `WORD_DATA_W'h0;
			end else begin
				rt_hazard	= `DISABLE;
				rt_data		= fwd_ex_rd_data;
			end
		end else if ((fwd_da_rd_addr == rt_addr) &&
				(fwd_da_rd_en == `ENABLE)) begin
			if ((fwd_da_ls_op == `PU_LS_OP_LB) ||
					(fwd_da_ls_op == `PU_LS_OP_LH) ||
					(fwd_da_ls_op == `PU_LS_OP_LW) ||
					(fwd_da_ls_op == `PU_LS_OP_LBU) ||
					(fwd_da_ls_op == `PU_LS_OP_LHU)) begin
				rt_hazard	= `ENABLE;
				rt_data		= `WORD_DATA_W'h0;
			end else begin
				rt_hazard	= `DISABLE;
				rt_data		= fwd_da_rd_data;
			end
		end else if ((fwd_wb_rd_addr == rt_addr) &&
				(fwd_wb_rd_en == `ENABLE)) begin
			rt_hazard	= `DISABLE;
			rt_data		= fwd_wb_rd_data;
		end else begin
			rt_hazard	= `DISABLE;
			rt_data		= gpr_rd1_data;
		end
	end

	/******** HI Forwarding ********/
	always @(*) begin
		if (fwd_ex_hi_en == `ENABLE) begin
			hi_data = fwd_ex_hi_data;
		end else if (fwd_da_hi_en == `ENABLE) begin
			hi_data = fwd_da_hi_data;
		end else if (fwd_wb_hi_en == `ENABLE) begin
			hi_data = fwd_wb_hi_data;
		end else begin
			hi_data = hlr_hi_rd_data;
		end
	end

	/******** LO Forwarding ********/
	always @(*) begin
		if (fwd_ex_lo_en == `ENABLE) begin
			lo_data = fwd_ex_lo_data;
		end else if (fwd_da_lo_en == `ENABLE) begin
			lo_data = fwd_da_lo_data;
		end else if (fwd_wb_lo_en == `ENABLE) begin
			lo_data = fwd_wb_lo_data;
		end else begin
			lo_data = hlr_lo_rd_data;
		end
	end

	/******** Output Hazard ********/
	generate
		if (VU_EN == 1) begin
			always @(*) begin
				if (cop_hazard == `ENABLE) begin
					id_hazard = `ENABLE;
				end else if (rs_hazard == `ENABLE) begin
					id_hazard = `ENABLE;
				end else if (rt_hazard == `ENABLE) begin
					id_hazard = `ENABLE;
				end else if ((dec_sync == `ENABLE) &&
						(vu_active == `ENABLE)) begin
					id_hazard = `ENABLE;
				end else begin
					id_hazard = `DISABLE;
				end
			end
		end else begin
			always @(*) begin
				if (cop_hazard == `ENABLE) begin
					id_hazard = `ENABLE;
				end else if (rs_hazard == `ENABLE) begin
					id_hazard = `ENABLE;
				end else if (rt_hazard == `ENABLE) begin
					id_hazard = `ENABLE;
				end else begin
					id_hazard = `DISABLE;
				end
			end
		end
	endgenerate

	/******** Switch Operation ********/
	generate
		if (VU_EN == 1) begin
			assign switch =
					((vu_switch == `ENABLE) &&
					(ne == `ENABLE)) ? `ENABLE : `DISABLE;
		end else begin
			assign switch = `DISABLE;
		end
	endgenerate

	/******** Vector Unit Access ********/
	generate
		if (VU_EN == 1) begin
`ifdef IMP_VUS
			assign vu_dd_enq	=
					((state == STATE_READY) &&
					(vus_s_req == `DISABLE) &&
					(switch == `DISABLE) &&
					(vu_busy == `DISABLE) &&
					(id_flush == `DISABLE) && (id_stall == `DISABLE)) ?
						dec_vu_dd_enq
				:	`DISABLE;
			assign vu_dd		= dec_vu_dd;
`else
			assign vu_dd_enq	=
					((switch == `DISABLE) &&
					(vu_busy == `DISABLE) &&
					(id_flush == `DISABLE) && (id_stall == `DISABLE)) ?
						dec_vu_dd_enq
				:	`DISABLE;
			assign vu_dd		= dec_vu_dd;
`endif
		end else begin
`ifdef IMP_VUS
			assign vu_dd_enq	= `DISABLE;
			assign vu_dd		= `VU_DD_W'h0;
`else
			assign vu_dd_enq	= `DISABLE;
			assign vu_dd		= `VU_DD_W'h0;
`endif
		end
	endgenerate

`ifdef IMP_VUS
	/********  ********/
	always @(*) begin
		vus_m_req		= `DISABLE;
		vus_m_cmd		= `ROUTER_CMD_NO;
		vus_m_addr		= `CORE_ADDR_W'h0;
		vus_m_uid		= `CORE_UID_W'h0;
		vus_m_src		= `CPU_TILE_ID_W'h0;
		vus_m_dst		= `CPU_TILE_ID_W'h0;
		vus_m_data_be	= {`CORE_DATA_BE_W{`DISABLE}};
		vus_m_data		= `CORE_DATA_W'h0;

		vus_s_ack		= `DISABLE;

		case (state)
		STATE_READY : begin
			if (id_flush == `ENABLE) begin
			end else if (ia_pr_en == `DISABLE) begin
			end else if (vus_s_req == `ENABLE) begin
				vus_s_ack		= `ENABLE;
			end
		end
		STATE_RSV_NI : begin
			vus_m_req		= `ENABLE;
			vus_m_cmd		= `ROUTER_CMD_VRSV;
			vus_m_src		= PUID;
			vus_m_dst		= dec_vus_tileid;
			vus_m_data_be	= {`CORE_DATA_BE_W{`ENABLE}};
			vus_m_data[`CoreDataTidLoc]
							= tid;
			vus_m_data[`CoreDataStatusLoc]
							= dec_vus_status;
		end
		STATE_RLS_NI : begin
			vus_m_req		= `ENABLE;
			vus_m_cmd		= `ROUTER_CMD_VRLS;
			vus_m_src		= PUID;
			vus_m_dst		= dec_vus_tileid;
			vus_m_data_be	= {`CORE_DATA_BE_W{`ENABLE}};
			vus_m_data[`CoreDataTidLoc]
							= tid;
		end
		STATE_START_NI : begin
			vus_m_req		= `ENABLE;
			vus_m_cmd		= `ROUTER_CMD_VSTART;
			vus_m_src		= PUID;
			vus_m_dst		= dec_vus_tileid;
			vus_m_data_be	= {`CORE_DATA_BE_W{`ENABLE}};
			vus_m_data[`CoreDataTidLoc]
							= tid;
			vus_m_data[`CoreDataPcLoc]
							= dec_vus_pc;
		end
		STATE_END_NI : begin
			vus_m_req		= `ENABLE;
			vus_m_cmd		= `ROUTER_CMD_VEND;
			vus_m_src		= PUID;
			vus_m_dst		= dec_vus_tileid;
			vus_m_data_be	= {`CORE_DATA_BE_W{`ENABLE}};
			vus_m_data[`CoreDataTidLoc]
							= tid;
			vus_m_data[`CoreDataPcLoc]
							= dec_vus_pc;
		end
		endcase
	end
`endif

/*----------------------------------------------------------------------------*
 * Sequential Logic
 *----------------------------------------------------------------------------*/
	/******** ID State Transition ********/
`ifdef IMP_VUS
	always @(posedge clk or negedge rst_) begin
		if (rst_ == `ENABLE_) begin // Reset
			state			<= #1 STATE_READY;
			bd				<= #1 `DISABLE;

			id_pr_en		<= #1 `DISABLE;
			id_pr_pc		<= #1 `WORD_ADDR_W'h0;
			id_pr_cop_op	<= #1 `PU_COP_OP_NO;
			id_pr_ls_op		<= #1 `PU_LS_OP_NO;
			id_pr_ia_op		<= #1 `PU_IA_OP_NO;
			id_pr_in0		<= #1 `WORD_DATA_W'h0;
			id_pr_in1		<= #1 `WORD_DATA_W'h0;
			id_pr_st_data	<= #1 `WORD_DATA_W'h0;
			id_pr_rd_addr	<= #1 `PU_GPR_ADDR_W'h0;
			id_pr_rd_en		<= #1 `DISABLE;
			id_pr_hi_en		<= #1 `DISABLE;
			id_pr_lo_en		<= #1 `DISABLE;
			id_pr_bd		<= #1 `DISABLE;
			id_pr_exp		<= #1 `PU_EXP_ID_NO;

			vus_s_cmd_ff	<= #1 `ROUTER_CMD_NO;
			vus_s_src_ff	<= #1 `CPU_TILE_ID_W'h0;
			vus_s_tid_ff	<= #1 `PU_TID_W'h0;
			vus_s_pc_ff		<= #1 `WORD_ADDR_W'h0;
			vus_s_status_ff	<= #1 `VU_STATUS_W'h0;
		end else begin
			case (state)
			STATE_READY : begin
				if (id_flush == `ENABLE) begin
					if (id_stall == `DISABLE) begin
						bd				<= #1 `DISABLE;

						id_pr_en		<= #1 `DISABLE;
						id_pr_pc		<= #1 `WORD_ADDR_W'h0;
						id_pr_cop_op	<= #1 `PU_COP_OP_NO;
						id_pr_ls_op		<= #1 `PU_LS_OP_NO;
						id_pr_ia_op		<= #1 `PU_IA_OP_NO;
						id_pr_in0		<= #1 `WORD_DATA_W'h0;
						id_pr_in1		<= #1 `WORD_DATA_W'h0;
						id_pr_st_data	<= #1 `WORD_DATA_W'h0;
						id_pr_rd_addr	<= #1 `PU_GPR_ADDR_W'h0;
						id_pr_rd_en		<= #1 `DISABLE;
						id_pr_hi_en		<= #1 `DISABLE;
						id_pr_lo_en		<= #1 `DISABLE;
						id_pr_bd		<= #1 `DISABLE;
						id_pr_exp		<= #1 `PU_EXP_ID_NO;
					end
				end else if (ia_pr_en == `DISABLE) begin
					if (id_stall == `DISABLE) begin
						bd				<= #1
								(dec_bi == `ENABLE) ? `ENABLE : bd;

						id_pr_en		<= #1 `DISABLE;
						id_pr_pc		<= #1 `WORD_ADDR_W'h0;
						id_pr_cop_op	<= #1 `PU_COP_OP_NO;
						id_pr_ls_op		<= #1 `PU_LS_OP_NO;
						id_pr_ia_op		<= #1 `PU_IA_OP_NO;
						id_pr_in0		<= #1 `WORD_DATA_W'h0;
						id_pr_in1		<= #1 `WORD_DATA_W'h0;
						id_pr_st_data	<= #1 `WORD_DATA_W'h0;
						id_pr_rd_addr	<= #1 `PU_GPR_ADDR_W'h0;
						id_pr_rd_en		<= #1 `DISABLE;
						id_pr_hi_en		<= #1 `DISABLE;
						id_pr_lo_en		<= #1 `DISABLE;
						id_pr_bd		<= #1 `DISABLE;
						id_pr_exp		<= #1 `PU_EXP_ID_NO;
					end
				end else if (vus_s_req == `ENABLE) begin
					state			<= #1 STATE_NI;

					vus_s_cmd_ff	<= #1 vus_s_cmd;
					vus_s_src_ff	<= #1 vus_s_src;
					vus_s_tid_ff	<= #1 vus_s_data[`CoreDataTidLoc];
					vus_s_pc_ff		<= #1 vus_s_data[`CoreDataPcLoc];
					vus_s_status_ff	<= #1 vus_s_data[`CoreDataStatusLoc];
				end else if (switch == `ENABLE) begin
					if (id_stall == `DISABLE) begin
						bd				<= #1 dec_bi;

						id_pr_en		<= #1 `ENABLE;
						id_pr_pc		<= #1 ia_pr_pc;
						id_pr_cop_op	<= #1 `PU_COP_OP_SWITCH;
						id_pr_ls_op		<= #1 `PU_LS_OP_NO;
						id_pr_ia_op		<= #1 `PU_IA_OP_NO;
						id_pr_in0		<= #1 `WORD_DATA_W'h0;
						id_pr_in1		<= #1 `WORD_DATA_W'h0;
						id_pr_st_data	<= #1 `WORD_DATA_W'h0;
						id_pr_rd_addr	<= #1 `PU_GPR_ADDR_W'h0;
						id_pr_rd_en		<= #1 `DISABLE;
						id_pr_hi_en		<= #1 `DISABLE;
						id_pr_lo_en		<= #1 `DISABLE;
						id_pr_bd		<= #1 bd;
						id_pr_exp		<= #1 `PU_EXP_ID_NO;
					end
				end else if (ia_pr_exp != `PU_EXP_IA_NO) begin
					if (id_stall == `DISABLE) begin
						bd				<= #1 dec_bi;

						id_pr_en		<= #1 `ENABLE;
						id_pr_pc		<= #1 ia_pr_pc;
						id_pr_cop_op	<= #1 `PU_COP_OP_NO;
						id_pr_ls_op		<= #1 `PU_LS_OP_NO;
						id_pr_ia_op		<= #1 `PU_IA_OP_NO;
						id_pr_in0		<= #1 `WORD_DATA_W'h0;
						id_pr_in1		<= #1 `WORD_DATA_W'h0;
						id_pr_st_data	<= #1 `WORD_DATA_W'h0;
						id_pr_rd_addr	<= #1 `PU_GPR_ADDR_W'h0;
						id_pr_rd_en		<= #1 `DISABLE;
						id_pr_hi_en		<= #1 `DISABLE;
						id_pr_lo_en		<= #1 `DISABLE;
						id_pr_bd		<= #1 bd;
						id_pr_exp		<= #1 ia_pr_exp;
					end
				end else begin
					case (dec_vus_op)
					`VUS_OP_RSV : begin
						state			<= #1 STATE_RSV_NI;
					end
					`VUS_OP_RLS : begin
						state			<= #1 STATE_RLS_NI;
					end
					`VUS_OP_START : begin
						state			<= #1 STATE_START_NI;
					end
					`VUS_OP_END : begin
						state			<= #1 STATE_END_NI;
					end
					default : begin
						if ((vu_busy == `ENABLE) && (dec_vu_dd_enq == `ENABLE)) begin
						end else begin
							if (id_stall == `DISABLE) begin
								bd				<= #1 dec_bi;

								id_pr_en		<= #1 `ENABLE;
								id_pr_pc		<= #1 ia_pr_pc;
								id_pr_cop_op	<= #1 dec_cop_op;
								id_pr_ls_op		<= #1 dec_ls_op;
								id_pr_ia_op		<= #1 dec_ia_op;
								id_pr_in0		<= #1 dec_in0;
								id_pr_in1		<= #1 dec_in1;
								id_pr_st_data	<= #1 dec_st_data;
								id_pr_rd_addr	<= #1 dec_rd_addr;
								id_pr_rd_en		<= #1 dec_rd_en;
								id_pr_hi_en		<= #1 dec_hi_en;
								id_pr_lo_en		<= #1 dec_lo_en;
								id_pr_bd		<= #1 bd;
								id_pr_exp		<= #1 `PU_EXP_ID_NO;
							end
						end
					end
					endcase
				end
			end
			STATE_RSV_NI : begin
				if (vus_m_ack == `ENABLE) begin
					state			<= #1 STATE_PIPE;
				end
			end
			STATE_RLS_NI : begin
				if (vus_m_ack == `ENABLE) begin
					state			<= #1 STATE_PIPE;
				end
			end
			STATE_START_NI : begin
				if (vus_m_ack == `ENABLE) begin
					state			<= #1 STATE_PIPE;
				end
			end
			STATE_END_NI : begin
				if (vus_m_ack == `ENABLE) begin
					state			<= #1 STATE_PIPE;
				end
			end
			STATE_PIPE : begin
				if (id_flush == `ENABLE) begin
					if (id_stall == `DISABLE) begin
						state			<= #1 STATE_READY;
						bd				<= #1 `DISABLE;

						id_pr_en		<= #1 `DISABLE;
						id_pr_pc		<= #1 `WORD_ADDR_W'h0;
						id_pr_cop_op	<= #1 `PU_COP_OP_NO;
						id_pr_ls_op		<= #1 `PU_LS_OP_NO;
						id_pr_ia_op		<= #1 `PU_IA_OP_NO;
						id_pr_in0		<= #1 `WORD_DATA_W'h0;
						id_pr_in1		<= #1 `WORD_DATA_W'h0;
						id_pr_st_data	<= #1 `WORD_DATA_W'h0;
						id_pr_rd_addr	<= #1 `PU_GPR_ADDR_W'h0;
						id_pr_rd_en		<= #1 `DISABLE;
						id_pr_hi_en		<= #1 `DISABLE;
						id_pr_lo_en		<= #1 `DISABLE;
						id_pr_bd		<= #1 `DISABLE;
						id_pr_exp		<= #1 `PU_EXP_ID_NO;
					end
				end else begin
					if (id_stall == `DISABLE) begin
						state			<= #1 STATE_READY;
						bd				<= #1 dec_bi;

						id_pr_en		<= #1 `ENABLE;
						id_pr_pc		<= #1 ia_pr_pc;
						id_pr_cop_op	<= #1 dec_cop_op;
						id_pr_ls_op		<= #1 dec_ls_op;
						id_pr_ia_op		<= #1 dec_ia_op;
						id_pr_in0		<= #1 dec_in0;
						id_pr_in1		<= #1 dec_in1;
						id_pr_st_data	<= #1 dec_st_data;
						id_pr_rd_addr	<= #1 dec_rd_addr;
						id_pr_rd_en		<= #1 dec_rd_en;
						id_pr_hi_en		<= #1 dec_hi_en;
						id_pr_lo_en		<= #1 dec_lo_en;
						id_pr_bd		<= #1 bd;
						id_pr_exp		<= #1 `PU_EXP_ID_NO;
					end
				end
			end
			STATE_NI : begin
				if (id_flush == `ENABLE) begin
					if (id_stall == `DISABLE) begin
						state			<= #1 STATE_READY;
						bd				<= #1 `DISABLE;

						id_pr_en		<= #1 `DISABLE;
						id_pr_pc		<= #1 `WORD_ADDR_W'h0;
						id_pr_cop_op	<= #1 `PU_COP_OP_NO;
						id_pr_ls_op		<= #1 `PU_LS_OP_NO;
						id_pr_ia_op		<= #1 `PU_IA_OP_NO;
						id_pr_in0		<= #1 `WORD_DATA_W'h0;
						id_pr_in1		<= #1 `WORD_DATA_W'h0;
						id_pr_st_data	<= #1 `WORD_DATA_W'h0;
						id_pr_rd_addr	<= #1 `PU_GPR_ADDR_W'h0;
						id_pr_rd_en		<= #1 `DISABLE;
						id_pr_hi_en		<= #1 `DISABLE;
						id_pr_lo_en		<= #1 `DISABLE;
						id_pr_bd		<= #1 `DISABLE;
						id_pr_exp		<= #1 `PU_EXP_ID_NO;
					end
				end else begin
					if (id_stall == `DISABLE) begin
						case (vus_s_cmd_ff)
						`ROUTER_CMD_VRSV : begin
							state			<= #1 STATE_READY;
							bd				<= #1 dec_bi;

							id_pr_en		<= #1 `ENABLE;
							id_pr_pc		<= #1 ia_pr_pc;
							id_pr_cop_op	<= #1 `PU_COP_OP_VRSVR;
							id_pr_ls_op		<= #1 `PU_LS_OP_NO;
							id_pr_ia_op		<= #1 `PU_IA_OP_THA;
							id_pr_in0		<= #1 vus_s_tid_ff;
							id_pr_in1		<= #1 `WORD_DATA_W'h0;
							id_pr_st_data	<= #1 vus_s_status_ff;
							id_pr_rd_addr	<= #1 vus_s_src_ff;
							id_pr_rd_en		<= #1 `DISABLE;
							id_pr_hi_en		<= #1 `DISABLE;
							id_pr_lo_en		<= #1 `DISABLE;
							id_pr_bd		<= #1 bd;
							id_pr_exp		<= #1 `PU_EXP_ID_NO;
						end
						`ROUTER_CMD_VRLS : begin
							state			<= #1 STATE_READY;
							bd				<= #1 dec_bi;

							id_pr_en		<= #1 `ENABLE;
							id_pr_pc		<= #1 ia_pr_pc;
							id_pr_cop_op	<= #1 `PU_COP_OP_VRLSR;
							id_pr_ls_op		<= #1 `PU_LS_OP_NO;
							id_pr_ia_op		<= #1 `PU_IA_OP_THA;
							id_pr_in0		<= #1 vus_s_tid_ff;
							id_pr_in1		<= #1 `WORD_DATA_W'h0;
							id_pr_st_data	<= #1 `WORD_DATA_W'h0;
							id_pr_rd_addr	<= #1 `PU_GPR_ADDR_W'h0;
							id_pr_rd_en		<= #1 `DISABLE;
							id_pr_hi_en		<= #1 `DISABLE;
							id_pr_lo_en		<= #1 `DISABLE;
							id_pr_bd		<= #1 bd;
							id_pr_exp		<= #1 `PU_EXP_ID_NO;
						end
						`ROUTER_CMD_VSTART : begin
							state			<= #1 STATE_READY;
							bd				<= #1 dec_bi;

							id_pr_en		<= #1 `ENABLE;
							id_pr_pc		<= #1 ia_pr_pc;
							id_pr_cop_op	<= #1 `PU_COP_OP_VWAKE;
							id_pr_ls_op		<= #1 `PU_LS_OP_NO;
							id_pr_ia_op		<= #1 `PU_IA_OP_THA;
							id_pr_in0		<= #1 vus_s_tid_ff;
							id_pr_in1		<= #1 `WORD_DATA_W'h0;
							id_pr_st_data	<= #1 {vus_s_pc_ff, `WORD_BO_W'h0};
							id_pr_rd_addr	<= #1 `PU_GPR_ADDR_W'h0;
							id_pr_rd_en		<= #1 `DISABLE;
							id_pr_hi_en		<= #1 `DISABLE;
							id_pr_lo_en		<= #1 `DISABLE;
							id_pr_bd		<= #1 bd;
							id_pr_exp		<= #1 `PU_EXP_ID_NO;
						end
						`ROUTER_CMD_VEND : begin
							state			<= #1 STATE_READY;
							bd				<= #1 dec_bi;

							id_pr_en		<= #1 `ENABLE;
							id_pr_pc		<= #1 ia_pr_pc;
							id_pr_cop_op	<= #1 `PU_COP_OP_VWAKE;
							id_pr_ls_op		<= #1 `PU_LS_OP_NO;
							id_pr_ia_op		<= #1 `PU_IA_OP_THA;
							id_pr_in0		<= #1 vus_s_tid_ff;
							id_pr_in1		<= #1 `WORD_DATA_W'h0;
							id_pr_st_data	<= #1 {vus_s_pc_ff, `WORD_BO_W'h0};
							id_pr_rd_addr	<= #1 `PU_GPR_ADDR_W'h0;
							id_pr_rd_en		<= #1 `DISABLE;
							id_pr_hi_en		<= #1 `DISABLE;
							id_pr_lo_en		<= #1 `DISABLE;
							id_pr_bd		<= #1 bd;
							id_pr_exp		<= #1 `PU_EXP_ID_NO;
						end
						endcase
						vus_s_cmd_ff	<= #1 `VUS_OP_NO;
						vus_s_src_ff	<= #1 `CPU_TILE_ID_W'h0;
						vus_s_tid_ff	<= #1 `PU_TID_W'h0;
						vus_s_pc_ff		<= #1 `WORD_ADDR_W'h0;
						vus_s_status_ff	<= #1 `VU_STATUS_W'h0;
					end
				end
			end
			endcase
		end
	end
`else
	always @(posedge clk or negedge rst_) begin
		if (rst_ == `ENABLE_) begin // Reset
			bd				<= #1 `DISABLE;

			id_pr_en		<= #1 `DISABLE;
			id_pr_pc		<= #1 `WORD_ADDR_W'h0;
			id_pr_cop_op	<= #1 `PU_COP_OP_NO;
			id_pr_ls_op		<= #1 `PU_LS_OP_NO;
			id_pr_ia_op		<= #1 `PU_IA_OP_NO;
			id_pr_in0		<= #1 `WORD_DATA_W'h0;
			id_pr_in1		<= #1 `WORD_DATA_W'h0;
			id_pr_st_data	<= #1 `WORD_DATA_W'h0;
			id_pr_rd_addr	<= #1 `PU_GPR_ADDR_W'h0;
			id_pr_rd_en		<= #1 `DISABLE;
			id_pr_hi_en		<= #1 `DISABLE;
			id_pr_lo_en		<= #1 `DISABLE;
			id_pr_bd		<= #1 `DISABLE;
			id_pr_exp		<= #1 `PU_EXP_ID_NO;
		end else begin
			if (id_flush == `ENABLE) begin
				if (id_stall == `DISABLE) begin
					bd				<= #1 `DISABLE;

					id_pr_en		<= #1 `DISABLE;
					id_pr_pc		<= #1 `WORD_ADDR_W'h0;
					id_pr_cop_op	<= #1 `PU_COP_OP_NO;
					id_pr_ls_op		<= #1 `PU_LS_OP_NO;
					id_pr_ia_op		<= #1 `PU_IA_OP_NO;
					id_pr_in0		<= #1 `WORD_DATA_W'h0;
					id_pr_in1		<= #1 `WORD_DATA_W'h0;
					id_pr_st_data	<= #1 `WORD_DATA_W'h0;
					id_pr_rd_addr	<= #1 `PU_GPR_ADDR_W'h0;
					id_pr_rd_en		<= #1 `DISABLE;
					id_pr_hi_en		<= #1 `DISABLE;
					id_pr_lo_en		<= #1 `DISABLE;
					id_pr_bd		<= #1 `DISABLE;
					id_pr_exp		<= #1 `PU_EXP_ID_NO;
				end
			end else if (ia_pr_en == `DISABLE) begin
				if (id_stall == `DISABLE) begin
					bd				<= #1
							(dec_bi == `ENABLE) ? `ENABLE : bd;

					id_pr_en		<= #1 `DISABLE;
					id_pr_pc		<= #1 `WORD_ADDR_W'h0;
					id_pr_cop_op	<= #1 `PU_COP_OP_NO;
					id_pr_ls_op		<= #1 `PU_LS_OP_NO;
					id_pr_ia_op		<= #1 `PU_IA_OP_NO;
					id_pr_in0		<= #1 `WORD_DATA_W'h0;
					id_pr_in1		<= #1 `WORD_DATA_W'h0;
					id_pr_st_data	<= #1 `WORD_DATA_W'h0;
					id_pr_rd_addr	<= #1 `PU_GPR_ADDR_W'h0;
					id_pr_rd_en		<= #1 `DISABLE;
					id_pr_hi_en		<= #1 `DISABLE;
					id_pr_lo_en		<= #1 `DISABLE;
					id_pr_bd		<= #1 `DISABLE;
					id_pr_exp		<= #1 `PU_EXP_ID_NO;
				end
			end else if (switch == `ENABLE) begin
				if (id_stall == `DISABLE) begin
					bd				<= #1 dec_bi;

					id_pr_en		<= #1 `ENABLE;
					id_pr_pc		<= #1 ia_pr_pc;
					id_pr_cop_op	<= #1 `PU_COP_OP_SWITCH;
					id_pr_ls_op		<= #1 `PU_LS_OP_NO;
					id_pr_ia_op		<= #1 `PU_IA_OP_NO;
					id_pr_in0		<= #1 `WORD_DATA_W'h0;
					id_pr_in1		<= #1 `WORD_DATA_W'h0;
					id_pr_st_data	<= #1 `WORD_DATA_W'h0;
					id_pr_rd_addr	<= #1 `PU_GPR_ADDR_W'h0;
					id_pr_rd_en		<= #1 `DISABLE;
					id_pr_hi_en		<= #1 `DISABLE;
					id_pr_lo_en		<= #1 `DISABLE;
					id_pr_bd		<= #1 bd;
					id_pr_exp		<= #1 `PU_EXP_ID_NO;
				end
			end else if (ia_pr_exp != `PU_EXP_IA_NO) begin
				if (id_stall == `DISABLE) begin
					bd				<= #1 dec_bi;

					id_pr_en		<= #1 `ENABLE;
					id_pr_pc		<= #1 ia_pr_pc;
					id_pr_cop_op	<= #1 `PU_COP_OP_NO;
					id_pr_ls_op		<= #1 `PU_LS_OP_NO;
					id_pr_ia_op		<= #1 `PU_IA_OP_NO;
					id_pr_in0		<= #1 `WORD_DATA_W'h0;
					id_pr_in1		<= #1 `WORD_DATA_W'h0;
					id_pr_st_data	<= #1 `WORD_DATA_W'h0;
					id_pr_rd_addr	<= #1 `PU_GPR_ADDR_W'h0;
					id_pr_rd_en		<= #1 `DISABLE;
					id_pr_hi_en		<= #1 `DISABLE;
					id_pr_lo_en		<= #1 `DISABLE;
					id_pr_bd		<= #1 bd;
					id_pr_exp		<= #1 ia_pr_exp;
				end
			end else begin
				if ((vu_busy == `ENABLE) && (dec_vu_dd_enq == `ENABLE)) begin
				end else begin
					if (id_stall == `DISABLE) begin
						bd				<= #1 dec_bi;

						id_pr_en		<= #1 `ENABLE;
						id_pr_pc		<= #1 ia_pr_pc;
						id_pr_cop_op	<= #1 dec_cop_op;
						id_pr_ls_op		<= #1 dec_ls_op;
						id_pr_ia_op		<= #1 dec_ia_op;
						id_pr_in0		<= #1 dec_in0;
						id_pr_in1		<= #1 dec_in1;
						id_pr_st_data	<= #1 dec_st_data;
						id_pr_rd_addr	<= #1 dec_rd_addr;
						id_pr_rd_en		<= #1 dec_rd_en;
						id_pr_hi_en		<= #1 dec_hi_en;
						id_pr_lo_en		<= #1 dec_lo_en;
						id_pr_bd		<= #1 bd;
						id_pr_exp		<= #1 `PU_EXP_ID_NO;
					end
				end
			end
		end
	end
`endif

/*----------------------------------------------------------------------------*
 * Debug
 *----------------------------------------------------------------------------*/
`ifdef DEBUG
	/********  ********/
	wire [`ByteAddrBus] ID_BPC		= {ia_pr_pc, `WORD_BO_W'h0};
	wire [`ByteAddrBus] BRANCH_BPC	= {branch_pc, `WORD_BO_W'h0};
`endif

endmodule

