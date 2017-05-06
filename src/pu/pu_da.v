/*----------------------------------------------------------------------------*
 *	SMIPS
 *
 *	File	: pu_da.v
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
`include "l2c.h"
`include "cbus.h"

module pu_da(
	/******** Clock and Reset ********/
	input wire							clk,
	input wire							rst_,
	/******** Coprocessor Access ********/
	// Thread Control
	input wire [`PuPidBus]				pid,
	input wire [`PuTidBus]				tid,
	input wire [`PuTmodeBus]			tmode,
	// Pipeline Control
	input wire							da_flush,
	input wire							da_stall,
	output reg							da_busy,
	// DTLB
	input wire							dtlb_on,
	// DC
	input wire							dc_on,
	/******** ID Access ********/
	// DA Forwarding
	output wire [`PuCopOpBus]			fwd_da_cop_op,
	output wire [`PuLsOpBus]			fwd_da_ls_op,
	output wire [`PuGprAddrBus]			fwd_da_rd_addr,
	output wire							fwd_da_rd_en,
	output wire [`WordDataBus]			fwd_da_rd_data,
	output wire							fwd_da_hi_en,
	output wire [`WordDataBus]			fwd_da_hi_data,
	output wire							fwd_da_lo_en,
	output wire [`WordDataBus]			fwd_da_lo_data,
	/******** EX Access ********/
	// EX/DA Non Pipeline
	input wire [`WordDataBus]			ex_np_out,
	// EX/DA Pipeline Register
	input wire							ex_pr_en,
	input wire [`WordAddrBus]			ex_pr_pc,
	input wire [`PuCopOpBus]			ex_pr_cop_op,
	input wire [`PuLsOpBus]				ex_pr_ls_op,
	input wire [`WordDataBus]			ex_pr_out,
	input wire [`WordDataBus]			ex_pr_st_data,
	input wire [`PuGprAddrBus]			ex_pr_rd_addr,
	input wire							ex_pr_rd_en,
	input wire							ex_pr_hi_en,
	input wire [`WordDataBus]			ex_pr_hi_data,
	input wire							ex_pr_lo_en,
	input wire [`WordDataBus]			ex_pr_lo_data,
	input wire							ex_pr_bd,
	input wire [`PuExpExBus]			ex_pr_exp,
	/******** WB Access ********/
	// DA/WB Pipeline Register
	output reg							da_pr_en,
	output reg [`WordAddrBus]			da_pr_pc,
	output reg [`PuCopOpBus]			da_pr_cop_op,
	output reg [`WordDataBus]			da_pr_cop_data,
	output reg [`PuGprAddrBus]			da_pr_rd_addr,
	output reg							da_pr_rd_en,
	output reg [`WordDataBus]			da_pr_rd_data,
	output reg							da_pr_hi_en,
	output reg [`WordDataBus]			da_pr_hi_data,
	output reg							da_pr_lo_en,
	output reg [`WordDataBus]			da_pr_lo_data,
	output reg							da_pr_bd,
	output reg [`PuExpDaBus]			da_pr_exp,
	/******** L2 Cache Access ********/
	input wire							inv_en,
	input wire [`CoreAddrBus]			inv_addr,
	/******** Cache Bus Access ********/
	output reg							cbus_req,
	output reg [`L2cCbusCmdBus]			cbus_cmd,
	output reg [`CoreAddrBus]			cbus_addr,
	output reg [`CoreDataBeBus]			cbus_wr_data_be,
	output reg [`CoreDataBus]			cbus_wr_data,
	input wire							cbus_ack,
	input wire							cbus_rdy,
	input wire [`CoreDataBus]			cbus_rd_data
);

/*----------------------------------------------------------------------------*
 * Wire and Reg
 *----------------------------------------------------------------------------*/
	/******** Local Parameter ********/
	localparam STATE_W				= 4;
	localparam STATE_READY			= 4'h0;
	localparam STATE_RD_M_CBUS		= 4'h1;
	localparam STATE_RD_M_CBUS_WAIT	= 4'h2;
	localparam STATE_RD_PIPE		= 4'h3;
	localparam STATE_WR_H_CBUS		= 4'h4;
	localparam STATE_WR_H_CBUS_WAIT	= 4'h5;
	localparam STATE_WR_M_CBUS		= 4'h6;
	localparam STATE_WR_M_CBUS_WAIT	= 4'h7;
	localparam STATE_WR_PIPE		= 4'h8;

	/******** DTLB ********/
	wire [`PuDcTagBus]					dtlb_ptag;
	wire								dtlb_nc;
	wire								dtlb_tmp;

	/******** Memory ********/
	wire [`PuDcTagBus]					mem_rd_ptag;
	wire								mem_rd_valid;
	wire [`CoreDataBus]					mem_rd_data;

	wire [`PuDcTagBus]					inv_rd_ptag;
	wire								inv_rd_valid;

	/******** Mux ********/
	wire [`WordDataBus]					mem_rd_word;
	wire [`WordDataBus]					cbus_rd_word;

	wire [`CoreDataBus]					mem_wr_data_align;
	wire [`CoreDataBeBus]				cbus_wr_data_be_align;
	wire [`CoreDataBus]					cbus_wr_data_align;

	/******** Address ********/
	wire [`ByteAddrBus]					np_vbaddr;
	wire [`PuDcTagBus]					np_vtag;
	wire [`PuDcIndexBus]				np_index;
	wire [`CoreOffsetWaddrBus]			np_offset_waddr;
	wire [`WordBoBus]					np_offset_wbo;

	wire [`ByteAddrBus]					vbaddr;
	wire [`PuDcTagBus]					vtag;
	wire [`PuDcIndexBus]				index;
	wire [`CoreOffsetWaddrBus]			offset_waddr;
	wire [`WordBoBus]					offset_wbo;

	wire [`ByteAddrBus]					pbaddr;

	/******** Address Translation ********/
	wire [`PuDcTagBus]					dtlb_vtag;
	wire [`PuDcTagBus]					ptag;
	wire								nc;

	/********  ********/
	reg									hit;

	/********  ********/
	reg [`PuDcIndexBus]					mem_rw_index;
	reg									mem_wr_en;
	reg [`PuDcTagBus]					mem_wr_ptag;
	reg									mem_wr_valid;
	reg [`CoreDataBus]					mem_wr_data;

	/******** Align Data ********/
	// logic
	reg [`WordDataBus]					mem_rd_word_align;
	reg [`WordDataBus]					cbus_rd_word_align;

	reg [`WordDataBus]					mem_wr_word_align;
	reg [`WordDataBeBus]				cbus_wr_word_be_align;
	reg [`WordDataBus]					cbus_wr_word_align;

	reg									miss_align;

	/******** Invalidate ********/
	wire [`PuIcTagBus]					inv_ptag;
	wire [`PuIcIndexBus]				inv_index;
	wire [`PuIcTagBus]					inv_ptag_ff;
	wire [`PuIcIndexBus]				inv_index_ff;

	reg [`PuIcIndexBus]					inv_rw_index;
	reg									inv_wr_en;
	reg [`PuIcTagBus]					inv_wr_ptag;
	reg									inv_wr_valid;

	/******** DA State Transition ********/
	reg [STATE_W-1:0]					state;
	reg [`WordDataBus]					word_dmp;

	/******** Invalidate State Transition ********/
	reg									inv_en_ff;
	reg [`CoreAddrBus]					inv_addr_ff;

/*----------------------------------------------------------------------------*
 * Module Instance
 *----------------------------------------------------------------------------*/
	/******** DTLB ********/
	pu_da_dtlb pu_da_dtlb(
		.clk					(clk),
		.rst_					(rst_),

		.tid					(tid),
		.tmode					(tmode),

		.on						(dtlb_on),

		.vtag					(dtlb_vtag),

		.ptag					(dtlb_ptag),
		.nc						(dtlb_nc),

		.tmp					(dtlb_tmp)
	);

	/******** Memory ********/
	pu_da_mem pu_da_mem(
		.clk					(clk),
		.rst_					(rst_),

		.mem_rw_index			(mem_rw_index),

		.mem_wr_en				(mem_wr_en),
		.mem_wr_ptag			(mem_wr_ptag),
		.mem_wr_valid			(mem_wr_valid),
		.mem_wr_data			(mem_wr_data),

		.mem_rd_ptag			(mem_rd_ptag),
		.mem_rd_valid			(mem_rd_valid),
		.mem_rd_data			(mem_rd_data),

		.inv_rw_index			(inv_rw_index),

		.inv_wr_en				(inv_wr_en),
		.inv_wr_ptag			(inv_wr_ptag),
		.inv_wr_valid			(inv_wr_valid),

		.inv_rd_ptag			(inv_rd_ptag),
		.inv_rd_valid			(inv_rd_valid)
	);

	/******** Mux : Memory Data -> Word ********/
	mux#(
		.DATA_W					(`WORD_DATA_W),
		.ALL_DATA_W				(`CORE_DATA_W),
		.SEL_W					(`CORE_OFFSET_WADDR_W),
		.ENDIAN					(1)
	) pu_da_memd2w(
		.all_data_in			(mem_rd_data),
		.data_out				(mem_rd_word),
		.sel					(offset_waddr)
	);

	/******** Mux : L2 Cache Data -> Word ********/
	mux#(
		.DATA_W					(`WORD_DATA_W),
		.ALL_DATA_W				(`CORE_DATA_W),
		.SEL_W					(`CORE_OFFSET_WADDR_W),
		.ENDIAN					(1)
	) pu_da_cbusd2w(
		.all_data_in			(cbus_rd_data),
		.data_out				(cbus_rd_word),
		.sel					(offset_waddr)
	);

	/******** Demux : Memory Word -> Data ********/
	demux#(
		.DATA_W					(`WORD_DATA_W),
		.ALL_DATA_W				(`CORE_DATA_W),
		.SEL_W					(`CORE_OFFSET_WADDR_W),
		.ENDIAN					(1)
	) pu_da_memw2d(
		.data_in				(mem_wr_word_align),
		.all_data_out			(mem_wr_data_align),
		.sel					(offset_waddr),
		.all_data_default		(mem_rd_data)
	);

	/******** Demux : L2 Cache BE Word -> Data ********/
	demux#(
		.DATA_W					(`WORD_DATA_BE_W),
		.ALL_DATA_W				(`CORE_DATA_BE_W),
		.SEL_W					(`CORE_OFFSET_WADDR_W),
		.ENDIAN					(1)
	) pu_da_cbusbew2l(
		.data_in				(cbus_wr_word_be_align),
		.all_data_out			(cbus_wr_data_be_align),
		.sel					(offset_waddr),
		.all_data_default		({`CORE_DATA_BE_W{`DISABLE}})
	);

	/******** Demux : L2 Cache Word -> Data ********/
	demux#(
		.DATA_W					(`WORD_DATA_W),
		.ALL_DATA_W				(`CORE_DATA_W),
		.SEL_W					(`CORE_OFFSET_WADDR_W),
		.ENDIAN					(1)
	) pu_da_cbusw2d(
		.data_in				(cbus_wr_word_align),
		.all_data_out			(cbus_wr_data_align),
		.sel					(offset_waddr),
		.all_data_default		(`CORE_DATA_W'h0)
	);

/*----------------------------------------------------------------------------*
 * Combinational Logic
 *----------------------------------------------------------------------------*/
	/******** Forwarding ********/
	assign fwd_da_cop_op	= ex_pr_cop_op;
	assign fwd_da_ls_op		= ex_pr_ls_op;
	assign fwd_da_rd_addr	= ex_pr_rd_addr;
	assign fwd_da_rd_en		= ex_pr_rd_en;
	assign fwd_da_rd_data	= ex_pr_out;
	assign fwd_da_hi_en		= ex_pr_hi_en;
	assign fwd_da_hi_data	= ex_pr_hi_data;
	assign fwd_da_lo_en		= ex_pr_lo_en;
	assign fwd_da_lo_data	= ex_pr_lo_data;

	/******** Address ********/
	assign np_vbaddr = ex_np_out;
	assign {np_vtag, np_index, np_offset_waddr, np_offset_wbo} = np_vbaddr;

	assign vbaddr = ex_pr_out;
	assign {vtag, index, offset_waddr, offset_wbo} = vbaddr;

	assign pbaddr = {ptag, index, offset_waddr, offset_wbo};

	/******** Address Translation ********/
	assign dtlb_vtag = np_vtag;
	assign ptag = dtlb_ptag;
	assign nc = dtlb_nc;

	/********  ********/
	always @(*) begin
		if ((mem_rd_ptag == ptag) && (mem_rd_valid == `ENABLE)) begin
			hit = `ENABLE;
		end else begin
			hit = `DISABLE;
		end
	end

	/********  ********/
	always @(*) begin
		mem_rw_index	= np_index;
		mem_wr_en		= `DISABLE;
		mem_wr_ptag		= `PU_DC_TAG_W'h0;
		mem_wr_valid 	= `DISABLE;
		mem_wr_data		= `CORE_DATA_W'h0;

		case (state)
		STATE_RD_M_CBUS_WAIT : begin
			if ((dc_on == `ENABLE) && (nc == `DISABLE)) begin // Cache
				if (cbus_rdy == `ENABLE) begin
					mem_rw_index	= index;
					mem_wr_en		= `ENABLE;
					mem_wr_ptag		= ptag;
					mem_wr_valid	= `ENABLE;
					mem_wr_data		= cbus_rd_data; // Same Width
				end
			end
		end
		STATE_WR_H_CBUS_WAIT : begin
			if ((dc_on == `ENABLE) && (nc == `DISABLE)) begin // Cache
				if (cbus_rdy == `ENABLE) begin
					mem_rw_index	= index;
					mem_wr_en		= `ENABLE;
					mem_wr_ptag		= ptag;
					mem_wr_valid	= `ENABLE;
					mem_wr_data		= mem_wr_data_align;
				end
			end
		end
		endcase
	end

	/********  ********/
	always @(*) begin
		cbus_req		= `DISABLE;
		cbus_cmd		= `L2C_CBUS_CMD_NO;
		cbus_addr		= `CORE_ADDR_W'h0;
		cbus_wr_data_be	= {`CORE_DATA_BE_W{`DISABLE}};
		cbus_wr_data	= `CORE_DATA_W'h0;

		case (state)
		STATE_RD_M_CBUS : begin
			if ((dc_on == `ENABLE) && (nc == `DISABLE)) begin // Cache
				cbus_req		= `ENABLE;
				cbus_cmd		= `L2C_CBUS_CMD_RD;
				cbus_addr		= pbaddr[`CoreAddrLoc];
			end else begin // Non Cache
				cbus_req		= `ENABLE;
				cbus_cmd		= `L2C_CBUS_CMD_RN;
				cbus_addr		= pbaddr[`CoreAddrLoc];
			end
		end
		STATE_WR_H_CBUS : begin
			if ((dc_on == `ENABLE) && (nc == `DISABLE)) begin // Cache
				cbus_req		= `ENABLE;
				cbus_cmd		= `L2C_CBUS_CMD_WR;
				cbus_addr		= pbaddr[`CoreAddrLoc];
//				cbus_wr_data_be	= {`CORE_DATA_BE_W{`ENABLE}};
//				cbus_wr_data	= mem_wr_data_align;
				cbus_wr_data_be	= cbus_wr_data_be_align;
				cbus_wr_data	= cbus_wr_data_align;
			end else begin // Non Cache
				cbus_req		= `ENABLE;
				cbus_cmd		= `L2C_CBUS_CMD_WN;
				cbus_addr		= pbaddr[`CoreAddrLoc];
				cbus_wr_data_be	= cbus_wr_data_be_align;
				cbus_wr_data	= cbus_wr_data_align;
			end
		end
		STATE_WR_M_CBUS : begin
			if ((dc_on == `ENABLE) && (nc == `DISABLE)) begin // Cache
				cbus_req		= `ENABLE;
				cbus_cmd		= `L2C_CBUS_CMD_WR;
				cbus_addr		= pbaddr[`CoreAddrLoc];
				cbus_wr_data_be	= cbus_wr_data_be_align;
				cbus_wr_data	= cbus_wr_data_align;
			end else begin // Non Cache
				cbus_req		= `ENABLE;
				cbus_cmd		= `L2C_CBUS_CMD_WN;
				cbus_addr		= pbaddr[`CoreAddrLoc];
				cbus_wr_data_be	= cbus_wr_data_be_align;
				cbus_wr_data	= cbus_wr_data_align;
			end
		end
		endcase
	end

	/******** Align Data ********/
	always @(*) begin
		mem_rd_word_align		= `WORD_DATA_W'h0;
		cbus_rd_word_align		= `WORD_DATA_W'h0;

		mem_wr_word_align		= `WORD_DATA_W'h0;
		cbus_wr_word_be_align	= `WORD_DATA_BE_DISABLE;
		cbus_wr_word_align		= `WORD_DATA_W'h0;

		miss_align				= `DISABLE;

		case (ex_pr_ls_op)
		`PU_LS_OP_LB : begin
			case (offset_wbo)
			`WORD_BO_BYTE_0 : begin
				mem_rd_word_align		=
						{{(`BYTE_DATA_W * 3)
						{mem_rd_word[`WORD_DATA_BYTE_0_MSB]}},
						mem_rd_word[`WordDataByte0Loc]};
				cbus_rd_word_align		=
						{{(`BYTE_DATA_W * 3)
						{cbus_rd_word[`WORD_DATA_BYTE_0_MSB]}},
						cbus_rd_word[`WordDataByte0Loc]};
			end
			`WORD_BO_BYTE_1 : begin
				mem_rd_word_align		=
						{{(`BYTE_DATA_W * 3)
						{mem_rd_word[`WORD_DATA_BYTE_1_MSB]}},
						mem_rd_word[`WordDataByte1Loc]};
				cbus_rd_word_align		=
						{{(`BYTE_DATA_W * 3)
						{cbus_rd_word[`WORD_DATA_BYTE_1_MSB]}},
						cbus_rd_word[`WordDataByte1Loc]};
			end
			`WORD_BO_BYTE_2 : begin
				mem_rd_word_align		=
						{{(`BYTE_DATA_W * 3)
						{mem_rd_word[`WORD_DATA_BYTE_2_MSB]}},
						mem_rd_word[`WordDataByte2Loc]};
				cbus_rd_word_align		=
						{{(`BYTE_DATA_W * 3)
						{cbus_rd_word[`WORD_DATA_BYTE_2_MSB]}},
						cbus_rd_word[`WordDataByte2Loc]};
			end
			`WORD_BO_BYTE_3 : begin
				mem_rd_word_align		=
						{{(`BYTE_DATA_W * 3)
						{mem_rd_word[`WORD_DATA_BYTE_3_MSB]}},
						mem_rd_word[`WordDataByte3Loc]};
				cbus_rd_word_align		=
						{{(`BYTE_DATA_W * 3)
						{cbus_rd_word[`WORD_DATA_BYTE_3_MSB]}},
						cbus_rd_word[`WordDataByte3Loc]};
			end
			endcase
		end
		`PU_LS_OP_LH : begin
			case (offset_wbo)
			`WORD_BO_BYTE_0 : begin
				mem_rd_word_align		=
						{{`HWORD_DATA_W{mem_rd_word[`WORD_DATA_HWORD_0_MSB]}},
						mem_rd_word[`WordDataHword0Loc]};
				cbus_rd_word_align		=
						{{`HWORD_DATA_W{cbus_rd_word[`WORD_DATA_HWORD_0_MSB]}},
						cbus_rd_word[`WordDataHword0Loc]};
			end
			`WORD_BO_BYTE_1 : begin
				miss_align				= `ENABLE;
			end
			`WORD_BO_BYTE_2 : begin
				mem_rd_word_align		=
						{{`HWORD_DATA_W{mem_rd_word[`WORD_DATA_HWORD_1_MSB]}},
				mem_rd_word[`WordDataHword1Loc]};
				cbus_rd_word_align		=
						{{`HWORD_DATA_W{cbus_rd_word[`WORD_DATA_HWORD_1_MSB]}},
						cbus_rd_word[`WordDataHword1Loc]};
			end
			`WORD_BO_BYTE_3 : begin
				miss_align				= `ENABLE;
			end
			endcase
		end
		`PU_LS_OP_LW : begin
			case (offset_wbo)
			`WORD_BO_BYTE_0 : begin
				mem_rd_word_align		= mem_rd_word;
				cbus_rd_word_align		= cbus_rd_word;
			end
			`WORD_BO_BYTE_1 : begin
				miss_align				= `ENABLE;
			end
			`WORD_BO_BYTE_2 : begin
				miss_align				= `ENABLE;
			end
			`WORD_BO_BYTE_3 : begin
				miss_align				= `ENABLE;
			end
			endcase
		end
		`PU_LS_OP_LBU : begin
			case (offset_wbo)
			`WORD_BO_BYTE_0 : begin
				mem_rd_word_align		=
						{{(`BYTE_DATA_W * 3){1'b0}},
						mem_rd_word[`WordDataByte0Loc]};
				cbus_rd_word_align		=
						{{(`BYTE_DATA_W * 3){1'b0}},
						cbus_rd_word[`WordDataByte0Loc]};
			end
			`WORD_BO_BYTE_1 : begin
				mem_rd_word_align		=
						{{(`BYTE_DATA_W * 3){1'b0}},
						mem_rd_word[`WordDataByte1Loc]};
				cbus_rd_word_align		=
						{{(`BYTE_DATA_W * 3){1'b0}},
						cbus_rd_word[`WordDataByte1Loc]};
			end
			`WORD_BO_BYTE_2 : begin
				mem_rd_word_align		=
						{{(`BYTE_DATA_W * 3){1'b0}},
						mem_rd_word[`WordDataByte2Loc]};
				cbus_rd_word_align		=
						{{(`BYTE_DATA_W * 3){1'b0}},
						cbus_rd_word[`WordDataByte2Loc]};
			end
			`WORD_BO_BYTE_3 : begin
				mem_rd_word_align		=
						{{(`BYTE_DATA_W * 3){1'b0}},
						mem_rd_word[`WordDataByte3Loc]};
				cbus_rd_word_align		=
						{{(`BYTE_DATA_W * 3){1'b0}},
						cbus_rd_word[`WordDataByte3Loc]};
			end
			endcase
		end
		`PU_LS_OP_LHU : begin
			case (offset_wbo)
			`WORD_BO_BYTE_0 : begin
				mem_rd_word_align		=
						{{`HWORD_DATA_W{1'b0}},
						mem_rd_word[`WordDataHword0Loc]};
				cbus_rd_word_align		=
						{{`HWORD_DATA_W{1'b0}},
						cbus_rd_word[`WordDataHword0Loc]};
			end
			`WORD_BO_BYTE_1 : begin
				miss_align				= `ENABLE;
			end
			`WORD_BO_BYTE_2 : begin
				mem_rd_word_align		=
						{{`HWORD_DATA_W{1'b0}},
						mem_rd_word[`WordDataHword1Loc]};
				cbus_rd_word_align		=
						{{`HWORD_DATA_W{1'b0}},
						cbus_rd_word[`WordDataHword1Loc]};
			end
			`WORD_BO_BYTE_3 : begin
				miss_align				= `ENABLE;
			end
			endcase
		end
		`PU_LS_OP_SB : begin // modify
			case (offset_wbo)
			`WORD_BO_BYTE_0 : begin
				mem_wr_word_align		=
						{ex_pr_st_data[`WordDataByte3Loc],
						mem_rd_word[`WordDataByte1Loc],
						mem_rd_word[`WordDataByte2Loc],
						mem_rd_word[`WordDataByte3Loc]};
				cbus_wr_word_be_align	= `WORD_DATA_BE_BYTE_0;
				cbus_wr_word_align		=
						{ex_pr_st_data[`WordDataByte3Loc],
						{(`BYTE_DATA_W * 3){1'b0}}};
			end
			`WORD_BO_BYTE_1 : begin
				mem_wr_word_align		=
						{mem_rd_word[`WordDataByte0Loc],
						ex_pr_st_data[`WordDataByte3Loc],
						mem_rd_word[`WordDataByte2Loc],
						mem_rd_word[`WordDataByte3Loc]};
				cbus_wr_word_be_align	= `WORD_DATA_BE_BYTE_1;
				cbus_wr_word_align		=
						{{(`BYTE_DATA_W){1'b0}},
						ex_pr_st_data[`WordDataByte3Loc],
						{(`BYTE_DATA_W * 2){1'b0}}};
			end
			`WORD_BO_BYTE_2 : begin
				mem_wr_word_align		=
						{mem_rd_word[`WordDataByte0Loc],
						mem_rd_word[`WordDataByte1Loc],
						ex_pr_st_data[`WordDataByte3Loc],
						mem_rd_word[`WordDataByte3Loc]};
				cbus_wr_word_be_align	= `WORD_DATA_BE_BYTE_2;
				cbus_wr_word_align		=
						{{(`BYTE_DATA_W * 2){1'b0}},
						ex_pr_st_data[`WordDataByte3Loc],
						{(`BYTE_DATA_W){1'b0}}};
			end
			`WORD_BO_BYTE_3 : begin
				mem_wr_word_align		=
						{mem_rd_word[`WordDataByte0Loc],
						mem_rd_word[`WordDataByte1Loc],
						mem_rd_word[`WordDataByte2Loc],
						ex_pr_st_data[`WordDataByte3Loc]};
				cbus_wr_word_be_align	= `WORD_DATA_BE_BYTE_3;
				cbus_wr_word_align		=
						{{(`BYTE_DATA_W * 3){1'b0}},
						ex_pr_st_data[`WordDataByte3Loc]};
			end
			endcase
		end
		`PU_LS_OP_SH : begin
			case (offset_wbo)
			`WORD_BO_BYTE_0 : begin
				mem_wr_word_align		=
						{ex_pr_st_data[`WordDataHword1Loc], 
						mem_rd_word[`WordDataHword1Loc]};
				cbus_wr_word_be_align	= `WORD_DATA_BE_HWORD_0;
				cbus_wr_word_align		=
						{{(`BYTE_DATA_W * 3){1'b0}},
						ex_pr_st_data[`WordDataHword0Loc]};
			end
			`WORD_BO_BYTE_1 : begin
				miss_align				= `ENABLE;
			end
			`WORD_BO_BYTE_2 : begin
				mem_wr_word_align		=
						{mem_rd_word[`WordDataHword0Loc],
						ex_pr_st_data[`WordDataHword1Loc]};
				cbus_wr_word_be_align	= `WORD_DATA_BE_HWORD_1;
				cbus_wr_word_align		=
						{{(`BYTE_DATA_W * 3){1'b0}},
						ex_pr_st_data[`WordDataHword1Loc]};
			end
			`WORD_BO_BYTE_3 : begin
				miss_align				= `ENABLE;
			end
			endcase
		end
		`PU_LS_OP_SW : begin
			case (offset_wbo)
			`WORD_BO_BYTE_0 : begin
				mem_wr_word_align		= ex_pr_st_data;
				cbus_wr_word_be_align	= `WORD_DATA_BE_WORD;
				cbus_wr_word_align		= ex_pr_st_data;
			end
			`WORD_BO_BYTE_1 : begin
				miss_align				= `ENABLE;
			end
			`WORD_BO_BYTE_2 : begin
				miss_align				= `ENABLE;
			end
			`WORD_BO_BYTE_3 : begin
				miss_align				= `ENABLE;
			end
			endcase
		end
		endcase
	end

	/******** Busy ********/
	always @(*) begin
		da_busy = `DISABLE;

		case (state)
		STATE_READY : begin
			if (da_flush == `ENABLE) begin
			end else if (ex_pr_en == `DISABLE) begin
			end else if (ex_pr_exp != `PU_EXP_EX_NO) begin
			end else if (miss_align == `ENABLE) begin
			end else begin
				if (ex_pr_ls_op == `PU_LS_OP_NO) begin // No Load Store
				end else if ((ex_pr_ls_op == `PU_LS_OP_LB) ||
						(ex_pr_ls_op == `PU_LS_OP_LH) ||
						(ex_pr_ls_op == `PU_LS_OP_LW) ||
						(ex_pr_ls_op == `PU_LS_OP_LBU) ||
						(ex_pr_ls_op == `PU_LS_OP_LHU)) begin // Load
					if ((dc_on == `ENABLE) && (nc == `DISABLE)) begin // Cache
						if (hit == `ENABLE) begin // Hit
						end else begin // Miss
							da_busy = `ENABLE;
						end
					end else begin // Non Cache
						da_busy = `ENABLE;
					end
				end else begin // Store
					da_busy = `ENABLE;
				end
			end
		end
		STATE_RD_M_CBUS : begin
			da_busy = `ENABLE;
		end
		STATE_RD_M_CBUS_WAIT : begin
			da_busy = `ENABLE;
		end
		STATE_WR_H_CBUS : begin
			da_busy = `ENABLE;
		end
		STATE_WR_H_CBUS_WAIT : begin
			da_busy = `ENABLE;
		end
		STATE_WR_M_CBUS : begin
			da_busy = `ENABLE;
		end
		STATE_WR_M_CBUS_WAIT : begin
			da_busy = `ENABLE;
		end
		endcase
	end

	/******** Invalidate ********/
	assign {inv_ptag, inv_index} = inv_addr;
	assign {inv_ptag_ff, inv_index_ff} = inv_addr_ff;

	always @(*) begin
		inv_rw_index	= inv_index;
		inv_wr_en		= `DISABLE;
		inv_wr_ptag		= `PU_DC_TAG_W'h0;
		inv_wr_valid	= `DISABLE;

		if ((inv_en_ff == `ENABLE) &&
				(inv_rd_ptag == inv_ptag_ff) &&
				(inv_rd_valid == `ENABLE)) begin
			inv_rw_index	= inv_index_ff;
			inv_wr_en		= `ENABLE;
			inv_wr_ptag		= `PU_DC_TAG_W'h0;
			inv_wr_valid	= `DISABLE;
		end
	end

/*----------------------------------------------------------------------------*
 * Sequential Logic
 *----------------------------------------------------------------------------*/
	/******** DA State Transition ********/
	always @(posedge clk or negedge rst_) begin
		if (rst_ == `ENABLE_) begin
			state			<= #1 STATE_READY;
			word_dmp		<= #1 `WORD_DATA_W'h0;

			da_pr_en		<= #1 `DISABLE;
			da_pr_pc		<= #1 `WORD_ADDR_W'h0;
			da_pr_cop_op	<= #1 `PU_COP_OP_NO;
			da_pr_cop_data	<= #1 `WORD_DATA_W'h0;
			da_pr_rd_addr	<= #1 `PU_GPR_ADDR_W'h0;
			da_pr_rd_en		<= #1 `DISABLE;
			da_pr_rd_data	<= #1 `WORD_DATA_W'h0;
			da_pr_hi_en		<= #1 `DISABLE;
			da_pr_hi_data	<= #1 `WORD_DATA_W'h0;
			da_pr_lo_en		<= #1 `DISABLE;
			da_pr_lo_data	<= #1 `WORD_DATA_W'h0;
			da_pr_bd		<= #1 `DISABLE;
			da_pr_exp		<= #1 `PU_EXP_DA_NO;
		end else begin
			case (state)
			STATE_READY : begin
				if (da_flush == `ENABLE) begin
					if (da_stall == `DISABLE) begin
						da_pr_en		<= #1 `DISABLE;
						da_pr_pc		<= #1 `WORD_ADDR_W'h0;
						da_pr_cop_op	<= #1 `PU_COP_OP_NO;
						da_pr_cop_data	<= #1 `WORD_DATA_W'h0;
						da_pr_rd_addr	<= #1 `PU_GPR_ADDR_W'h0;
						da_pr_rd_en		<= #1 `DISABLE;
						da_pr_rd_data	<= #1 `WORD_DATA_W'h0;
						da_pr_hi_en		<= #1 `DISABLE;
						da_pr_hi_data	<= #1 `WORD_DATA_W'h0;
						da_pr_lo_en		<= #1 `DISABLE;
						da_pr_lo_data	<= #1 `WORD_DATA_W'h0;
						da_pr_bd		<= #1 `DISABLE;
						da_pr_exp		<= #1 `PU_EXP_DA_NO;
					end
				end else if (ex_pr_en == `DISABLE) begin
					if (da_stall == `DISABLE) begin
						da_pr_en		<= #1 `DISABLE;
						da_pr_pc		<= #1 `WORD_ADDR_W'h0;
						da_pr_cop_op	<= #1 `PU_COP_OP_NO;
						da_pr_cop_data	<= #1 `WORD_DATA_W'h0;
						da_pr_rd_addr	<= #1 `PU_GPR_ADDR_W'h0;
						da_pr_rd_en		<= #1 `DISABLE;
						da_pr_rd_data	<= #1 `WORD_DATA_W'h0;
						da_pr_hi_en		<= #1 `DISABLE;
						da_pr_hi_data	<= #1 `WORD_DATA_W'h0;
						da_pr_lo_en		<= #1 `DISABLE;
						da_pr_lo_data	<= #1 `WORD_DATA_W'h0;
						da_pr_bd		<= #1 `DISABLE;
						da_pr_exp		<= #1 `PU_EXP_DA_NO;
					end
				end else if (ex_pr_exp != `PU_EXP_EX_NO) begin
					if (da_stall == `DISABLE) begin
						da_pr_en		<= #1 `ENABLE;
						da_pr_pc		<= #1 ex_pr_pc;
						da_pr_cop_op	<= #1 `PU_COP_OP_NO;
						da_pr_cop_data	<= #1 `WORD_DATA_W'h0;
						da_pr_rd_addr	<= #1 `PU_GPR_ADDR_W'h0;
						da_pr_rd_en		<= #1 `DISABLE;
						da_pr_rd_data	<= #1 `WORD_DATA_W'h0;
						da_pr_hi_en		<= #1 `DISABLE;
						da_pr_hi_data	<= #1 `WORD_DATA_W'h0;
						da_pr_lo_en		<= #1 `DISABLE;
						da_pr_lo_data	<= #1 `WORD_DATA_W'h0;
						da_pr_bd		<= #1 ex_pr_bd;
						da_pr_exp		<= #1 ex_pr_exp;
					end
				end else if (miss_align == `ENABLE) begin
					if (da_stall == `DISABLE) begin
						da_pr_en		<= #1 `ENABLE;
						da_pr_pc		<= #1 ex_pr_pc;
						da_pr_cop_op	<= #1 `PU_COP_OP_NO;
						da_pr_cop_data	<= #1 `WORD_DATA_W'h0;
						da_pr_rd_addr	<= #1 `PU_GPR_ADDR_W'h0;
						da_pr_rd_en		<= #1 `DISABLE;
						da_pr_rd_data	<= #1 `WORD_DATA_W'h0;
						da_pr_hi_en		<= #1 `DISABLE;
						da_pr_hi_data	<= #1 `WORD_DATA_W'h0;
						da_pr_lo_en		<= #1 `DISABLE;
						da_pr_lo_data	<= #1 `WORD_DATA_W'h0;
						da_pr_bd		<= #1 ex_pr_bd;
						da_pr_exp		<= #1 `PU_EXP_DA_NO; // modify
					end
				end else begin
					if (ex_pr_ls_op == `PU_LS_OP_NO) begin // No LS
						if (da_stall == `DISABLE) begin
							da_pr_en		<= #1 `ENABLE;
							da_pr_pc		<= #1 ex_pr_pc;
							da_pr_cop_op	<= #1 ex_pr_cop_op;
							da_pr_cop_data	<= #1 ex_pr_st_data;
							da_pr_rd_addr	<= #1 ex_pr_rd_addr;
							da_pr_rd_en		<= #1 ex_pr_rd_en;
							da_pr_rd_data	<= #1 ex_pr_out;
							da_pr_hi_en		<= #1 ex_pr_hi_en;
							da_pr_hi_data	<= #1 ex_pr_hi_data;
							da_pr_lo_en		<= #1 ex_pr_lo_en;
							da_pr_lo_data	<= #1 ex_pr_lo_data;
							da_pr_bd		<= #1 ex_pr_bd;
							da_pr_exp		<= #1 `PU_EXP_DA_NO;
						end
					end else if ((ex_pr_ls_op == `PU_LS_OP_LB) ||
							(ex_pr_ls_op == `PU_LS_OP_LH) ||
							(ex_pr_ls_op == `PU_LS_OP_LW) ||
							(ex_pr_ls_op == `PU_LS_OP_LBU) ||
							(ex_pr_ls_op == `PU_LS_OP_LHU)) begin // Load
						if ((dc_on == `ENABLE) && (nc == `DISABLE)) begin // Cache
							if (hit == `ENABLE) begin // Hit
								if (da_stall == `DISABLE) begin
									da_pr_en		<= #1 `ENABLE;
									da_pr_pc		<= #1 ex_pr_pc;
									da_pr_cop_op	<= #1 `PU_COP_OP_NO;
									da_pr_cop_data	<= #1 `WORD_DATA_W'h0;
									da_pr_rd_addr	<= #1 ex_pr_rd_addr;
									da_pr_rd_en		<= #1 ex_pr_rd_en;
									da_pr_rd_data	<= #1 mem_rd_word_align;
									da_pr_hi_en		<= #1 `DISABLE;
									da_pr_hi_data	<= #1 `WORD_DATA_W'h0;
									da_pr_lo_en		<= #1 `DISABLE;
									da_pr_lo_data	<= #1 `WORD_DATA_W'h0;
									da_pr_bd		<= #1 ex_pr_bd;
									da_pr_exp		<= #1 `PU_EXP_DA_NO;
								end
							end else begin // Miss
								state			<= #1 STATE_RD_M_CBUS;
							end
						end else begin // Non Cache
							state			<= #1 STATE_RD_M_CBUS;
						end
					end else begin // Store
						if ((dc_on == `ENABLE) && (nc == `DISABLE)) begin // Cache
							if (hit == `ENABLE) begin // Hit
								state			<= #1 STATE_WR_H_CBUS;
							end else begin // Miss
								state			<= #1 STATE_WR_M_CBUS;
							end
						end else begin // Non Cache
							state			<= #1 STATE_WR_M_CBUS;
						end
					end
				end
			end
			STATE_RD_M_CBUS : begin
				if (cbus_ack == `ENABLE) begin
					state			<= #1 STATE_RD_M_CBUS_WAIT;
				end
			end
			STATE_RD_M_CBUS_WAIT : begin
				if (cbus_rdy == `ENABLE) begin
					state			<= #1 STATE_RD_PIPE;
					word_dmp		<= #1 cbus_rd_word_align;
				end 
			end
			STATE_RD_PIPE : begin
				if (da_flush == `ENABLE) begin
					if (da_stall == `DISABLE) begin
						state			<= #1 STATE_READY;
						word_dmp		<= #1 `WORD_DATA_W'h0;

						da_pr_en		<= #1 `DISABLE;
						da_pr_pc		<= #1 `WORD_ADDR_W'h0;
						da_pr_cop_op	<= #1 `PU_COP_OP_NO;
						da_pr_cop_data	<= #1 `WORD_DATA_W'h0;
						da_pr_rd_addr	<= #1 `PU_GPR_ADDR_W'h0;
						da_pr_rd_en		<= #1 `DISABLE;
						da_pr_rd_data	<= #1 `WORD_DATA_W'h0;
						da_pr_hi_en		<= #1 `DISABLE;
						da_pr_hi_data	<= #1 `WORD_DATA_W'h0;
						da_pr_lo_en		<= #1 `DISABLE;
						da_pr_lo_data	<= #1 `WORD_DATA_W'h0;
						da_pr_bd		<= #1 `DISABLE;
						da_pr_exp		<= #1 `PU_EXP_DA_NO;
					end
				end else begin
					if (da_stall == `DISABLE) begin
						state			<= #1 STATE_READY;
						word_dmp		<= #1 `WORD_DATA_W'h0;

						da_pr_en		<= #1 `ENABLE;
						da_pr_pc		<= #1 ex_pr_pc;
						da_pr_cop_op	<= #1 `PU_COP_OP_NO;
						da_pr_cop_data	<= #1 `WORD_DATA_W'h0;
						da_pr_rd_addr	<= #1 ex_pr_rd_addr;
						da_pr_rd_en		<= #1 ex_pr_rd_en;
						da_pr_rd_data	<= #1 word_dmp;
						da_pr_hi_en		<= #1 `DISABLE;
						da_pr_hi_data	<= #1 `WORD_DATA_W'h0;
						da_pr_lo_en		<= #1 `DISABLE;
						da_pr_lo_data	<= #1 `WORD_DATA_W'h0;
						da_pr_bd		<= #1 ex_pr_bd;
						da_pr_exp		<= #1 `PU_EXP_DA_NO;
					end
				end 
			end
			STATE_WR_H_CBUS : begin
				if (cbus_ack == `ENABLE) begin
					state			<= #1 STATE_WR_H_CBUS_WAIT;
				end
			end
			STATE_WR_H_CBUS_WAIT : begin
				if (cbus_rdy == `ENABLE) begin
					state			<= #1 STATE_WR_PIPE;
				end
			end
			STATE_WR_M_CBUS : begin
				if (cbus_ack == `ENABLE) begin
					state			<= #1 STATE_WR_M_CBUS_WAIT;
				end
			end
			STATE_WR_M_CBUS_WAIT : begin
				if (cbus_rdy == `ENABLE) begin
					state			<= #1 STATE_WR_PIPE;
				end
			end
			STATE_WR_PIPE : begin
				if (da_flush == `ENABLE) begin
					if (da_stall == `DISABLE) begin
						state			<= #1 STATE_READY;

						da_pr_en		<= #1 `DISABLE;
						da_pr_pc		<= #1 `WORD_ADDR_W'h0;
						da_pr_cop_op	<= #1 `PU_COP_OP_NO;
						da_pr_cop_data	<= #1 `WORD_DATA_W'h0;
						da_pr_rd_addr	<= #1 `PU_GPR_ADDR_W'h0;
						da_pr_rd_en		<= #1 `DISABLE;
						da_pr_rd_data	<= #1 `WORD_DATA_W'h0;
						da_pr_hi_en		<= #1 `DISABLE;
						da_pr_hi_data	<= #1 `WORD_DATA_W'h0;
						da_pr_lo_en		<= #1 `DISABLE;
						da_pr_lo_data	<= #1 `WORD_DATA_W'h0;
						da_pr_bd		<= #1 `DISABLE;
						da_pr_exp		<= #1 `PU_EXP_DA_NO;
					end
				end else begin
					if (da_stall == `DISABLE) begin
						state			<= #1 STATE_READY;

						da_pr_en		<= #1 `ENABLE;
						da_pr_pc		<= #1 ex_pr_pc;
						da_pr_cop_op	<= #1 `PU_COP_OP_NO;
						da_pr_cop_data	<= #1 `WORD_DATA_W'h0;
						da_pr_rd_addr	<= #1 `WORD_ADDR_W'h0;
						da_pr_rd_en		<= #1 `DISABLE;
						da_pr_rd_data	<= #1 `WORD_DATA_W'h0;
						da_pr_hi_en		<= #1 `DISABLE;
						da_pr_hi_data	<= #1 `WORD_DATA_W'h0;
						da_pr_lo_en		<= #1 `DISABLE;
						da_pr_lo_data	<= #1 `WORD_DATA_W'h0;
						da_pr_bd		<= #1 ex_pr_bd;
						da_pr_exp		<= #1 `PU_EXP_DA_NO;
					end
				end 
			end
			endcase
		end
	end

	/******** Invalidate State Transition ********/
	always @(posedge clk or negedge rst_) begin
		if (rst_ == `ENABLE_) begin
			inv_en_ff		<= #1 `DISABLE;
			inv_addr_ff		<= #1 `CORE_ADDR_W'h0;
		end else begin
			inv_en_ff		<= #1 inv_en;
			inv_addr_ff		<= #1 inv_addr;
		end
	end

/*----------------------------------------------------------------------------*
 * Debug
 *----------------------------------------------------------------------------*/
`ifdef DEBUG
	/********  ********/
	wire [`ByteAddrBus] DA_BPC = {ex_pr_pc, `WORD_BO_W'h0};
`endif

endmodule

