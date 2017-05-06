/*----------------------------------------------------------------------------*
 *	SMIPS
 *
 *	File	: pu_ia.v
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
`include "isa.h"
`include "cbus.h"

module pu_ia(
	/******** Clock and Reset ********/
	input wire							clk,
	input wire							rst_,
	/******** Coprocessor Access ********/
	// Pipeline Control
	input wire [`PuPidBus]				pid,
	input wire [`PuTmodeBus]			tmode,
	input wire							ia_flush,
	input wire							ia_stall,
	output wire							ia_busy,
	// TLB and Cache
	input wire							itlb_on,
	input wire							ic_on,
	// COP/IA Non Pipeline
	input wire							cop_new_en,
	input wire [`WordAddrBus]			cop_new_pc,
	/******** ID Access ********/
	// IA/ID Pipeline Register
	output reg							ia_pr_en,
	output reg [`WordAddrBus]			ia_pr_pc,
	output reg [`WordDataBus]			ia_pr_inst,
	output reg [`PuExpIaBus]			ia_pr_exp,
	/******** L2 Cache Access ********/
	input wire							inv_en,
	input wire [`CoreAddrBus]			inv_addr,
	/******** Cache Bus Access ********/
	output reg							cbus_req,
	output reg [`CbusCmdBus]			cbus_cmd,
	output reg [`CoreAddrBus]			cbus_addr,
	output wire [`CbusDataBeBus]		cbus_wr_data_be,
	output wire [`CbusDataBus]			cbus_wr_data,
	input wire							cbus_ack,
	input wire							cbus_rdy,
	input wire [`CbusDataBus]			cbus_rd_data
);

/*----------------------------------------------------------------------------*
 * Wire and Reg
 *----------------------------------------------------------------------------*/
	/******** Local Parameter ********/
	localparam STATE_W				= 2;
	localparam STATE_READY			= 2'h0;
	localparam STATE_MISS			= 2'h1;
	localparam STATE_STALL			= 2'h2;
	/******** Address Packing and Unpacking ********/
	wire [`ByteAddrBus]					np_vbaddr;
	wire [`PuIcTagBus]					np_vtag;
	wire [`PuIcIndexBus]				np_index;
	wire [`CoreOffsetWaddrBus]			np_offset_waddr;
	wire [`WordBoBus]					np_offset_wbo;
	wire [`ByteAddrBus]					vbaddr;
	wire [`PuIcTagBus]					vtag;
	wire [`PuIcIndexBus]				index;
	wire [`CoreOffsetWaddrBus]			offset_waddr;
	wire [`WordBoBus]					offset_wbo;
	wire [`ByteAddrBus]					pbaddr;
	wire [`WordAddrBus]					pwaddr;
	/******** ITLB ********/
	wire [`PuIcTagBus]					itlb_ptag;
	wire								itlb_nc;
	wire								itlb_tmp;		// TODO:例外
	wire [`PuIcTagBus]					itlb_vtag;
	wire [`PuIcTagBus]					ptag;
	wire								nc;
	/******** IC ********/
	wire [`PuIcTagBus]					ic_rd_ptag;
	wire								ic_rd_valid;
	wire [`CbusDataBus]					ic_rd_data;
	reg									hit;
	reg [`PuIcIndexBus]					ic_rw_index;
	reg									ic_wr_en;
	reg [`PuIcTagBus]					ic_wr_ptag;
	reg									ic_wr_valid;
	reg [`CbusDataBus]					ic_wr_data;
	wire [`PuIcTagBus]					inv_ptag;
	wire [`PuIcIndexBus]				inv_index;
	/******** Cache Bus Interface ********/
	wire								busy;
	/******** Mux ********/
	wire [`WordDataBus]					ic_rd_word;
	wire [`WordDataBus]					cbus_rd_word;
	/******** IA State Transition ********/
	reg [STATE_W-1:0]					state;

/*----------------------------------------------------------------------------*
 * Module Instance
 *----------------------------------------------------------------------------*/
	/******** ITLB ********/
	pu_ia_itlb pu_ia_itlb(
		.clk					(clk),
		.rst_					(rst_),
		.tmode					(tmode),
		.on						(itlb_on),
		.vtag					(itlb_vtag),
		.ptag					(itlb_ptag),
		.nc						(itlb_nc),
		.tmp					(itlb_tmp)
	);

	/******** IC ********/
	pu_ia_ic pu_ia_ic(
		.clk					(clk),
		.rst_					(rst_),
		.on						(ic_on),
		.ic_rw_index			(ic_rw_index),
		.ic_wr_en				(ic_wr_en),
		.ic_wr_ptag				(ic_wr_ptag),
		.ic_wr_valid			(ic_wr_valid),
		.ic_wr_data				(ic_wr_data),
		.ic_rd_ptag				(ic_rd_ptag),
		.ic_rd_valid			(ic_rd_valid),
		.ic_rd_data				(ic_rd_data),
	);

	/******** Cache Bus Interface ********/
	pu_ia_cbusif pu_ia_cbusif(
		.clk					(clk),
		.rst_					(rst_),
		.busy					(cbusif_busy),
		.req                    (cbusif_req),
		.nc                     (cbusif_nc),
		.addr                   (cbusif_addr),
		.ack                    (cbusif_ack),
		.rd_data                (cbusif_rd_data),
		.cbus_req				(cbus_req),
		.cbus_grt               (cbus_grt),
		.cbus_cmd               (cbus_cmd),
		.cbus_addr              (cbus_addr),
		.cbus_wr_data_be        (cbus_wr_data_be),
		.cbus_wr_data           (cbus_wr_data),
		.cbus_rdy               (cbus_rdy),
		.cbus_rd_data           (cbus_rd_data)
	);


	/******** Mux : IC Data -> Word ********/
	mux#(
		.DATA_W					(`WORD_DATA_W),
		.ALL_DATA_W				(`CORE_DATA_W),
		.SEL_W					(`CORE_OFFSET_WADDR_W),
		.ENDIAN					(1)
	) pu_ia_memd2w(
		.all_data_in			(ic_rd_data),
		.data_out				(ic_rd_word),
		.sel					(offset_waddr)
	);

	/******** Mux : L2 Cache Data -> Word ********/
	mux#(
		.DATA_W					(`WORD_DATA_W),
		.ALL_DATA_W				(`CORE_DATA_W),
		.SEL_W					(`CORE_OFFSET_WADDR_W),
		.ENDIAN					(1)
	) pu_ia_cbusd2w(
		.all_data_in			(cbus_rd_data),
		.data_out				(cbus_rd_word),
		.sel					(offset_waddr)
	);

/*----------------------------------------------------------------------------*
 * Combinational Logic
 *----------------------------------------------------------------------------*/
	/******** Address Packing and Unpacking ********/
	assign np_vbaddr = {cop_np_pc, `WORD_BO_W'h0};
	assign {np_vtag, np_index, np_offset_waddr, np_offset_wbo} = np_vbaddr;

	assign vbaddr = {cop_pr_pc, `WORD_BO_W'h0};
	assign {vtag, index, offset_waddr, offset_wbo} = vbaddr;

	assign pbaddr = {ptag, index, offset_waddr, offset_wbo};
	assign pwaddr = {ptag, index, offset_waddr};

	/******** ITLB ********/
	assign itlb_vtag = np_vtag;
	assign ptag = itlb_ptag;
	assign nc = itlb_nc;

	/******** IC ********/
	always @(*) begin
		if ((nc == `DISABLE) && (ic_rd_ptag == ptag) &&
				(ic_rd_valid == `ENABLE)) begin
			hit = `ENABLE;
		end else begin
			hit = `DISABLE;
		end
	end

	always @(*) begin
		if ((nc == `DISABLE) && (cbus_rdy == `ENABLE)) begin
			ic_rw_index	= index;
			ic_wr_en	= `ENABLE;
			ic_wr_ptag	= ptag;
			ic_wr_valid	= `ENABLE;
			ic_wr_data	= cbus_rd_data;
		end else begin
			ic_rw_index	= np_index;
			ic_wr_en	= `DISABLE;
			ic_wr_ptag	= `PU_IC_TAG_W'h0;
			ic_wr_valid	= `DISABLE;
			ic_wr_data	= `CBUS_DATA_W'h0;
		end
	end

	assign {inv_ptag, inv_index} = inv_addr;

	/******** Pipeline Control ********/
	assign ia_busy = busy;

	/******** Next PC ********/
	always @(*) begin
		if (cop_new_en == `ENABLE) begin
			next_pc = cop_new_pc;
		end else begin
			next_pc = ia_pr_pc + 1;
		end
	end

/*----------------------------------------------------------------------------*
 * Sequential Logic
 *----------------------------------------------------------------------------*/
	/******** IA State Transition ********/
	always @(posedge clk or negedge rst_) begin
		if (rst_ == `ENABLE_) begin
			state		<= STATE_READY;
			ia_pr_en	<= `DISABLE;
			ia_pr_pc	<= `WORD_ADDR_W'h0;
			ia_pr_inst	<= `IR_NOP;
			ia_pr_exp	<= `PU_EXP_IA_NO;
		end else begin
			case (state)
			STATE_READY : begin
				if (ia_flush == `ENABLE) begin
					if (ia_stall == `DISABLE) begin
//						state		<= STATE_READY;
						ia_pr_en	<= `DISABLE;
						ia_pr_pc	<= `WORD_ADDR_W'h0;
						ia_pr_inst	<= `IR_NOP;
						ia_pr_exp	<= `PU_EXP_IA_NO;
					end
				end else if (itlb_tmp == `ENABLE) begin
					if (ia_stall == `DISABLE) begin
//						state		<= STATE_READY;
						ia_pr_en	<= `DISABLE;
						ia_pr_pc	<= `WORD_ADDR_W'h0;
						ia_pr_inst	<= `IR_NOP;
						ia_pr_exp	<= `PU_EXP_IA_NO;
					end
				end else if (hit == `ENABLE) begin // Hit
					if (ia_stall == `DISABLE) begin
//						state		<= STATE_READY;
						ia_pr_en	<= `ENABLE;
						ia_pr_pc	<= next_pc;
						ia_pr_inst	<= ic_rd_word;
						ia_pr_exp	<= `PU_EXP_IA_NO;
					end
				end else begin // Miss
						state		<= STATE_MISS;
//						ia_pr_en	<= `DISABLE;
//						ia_pr_pc	<= `WORD_ADDR_W'h0;
//						ia_pr_inst	<= `IR_NOP;
//						ia_pr_exp	<= `PU_EXP_IA_NO;
				end
				STATE_MISS : begin
					if (ack == `ENABLE) begin
						state		<= STATE_STALL;
//						ia_pr_en	<= `DISABLE;
//						ia_pr_pc	<= ia_pr_pc;
						ia_pr_inst	<= cbus_rd_word;
//						ia_pr_exp	<= `PU_EXP_IA_NO;
					end
				end
				STATE_STALL : begin
					if (ia_stall == `DISABLE) begin
						state		<= STATE_READY;
						ia_pr_en	<= `ENABLE;
						ia_pr_pc	<= next_pc;
//						ia_pr_inst	<= ia_pr_inst;
						ia_pr_exp	<= `PU_EXP_IA_NO;
					end
				end
				endcase
			end
		end
	end

/*----------------------------------------------------------------------------*
 * Debug
 *----------------------------------------------------------------------------*/
`ifdef DEBUG
	/********  ********/
	wire [`ByteAddrBus] IA_BPC = {cop_pr_pc, `WORD_BO_W'h0};

//	wire [`StringBus] STATE =
//			(state == STATE_READY)			? "STATE_READY"
//		:	(state == STATE_RD_M_CBUS)		? "STATE_RD_M_CBUS"
//		:	(state == STATE_RD_M_CBUS_WAIT)	? "STATE_RD_M_CBUS_WAIT"
//		:	(state == STATE_RD_PIPE)		? "STATE_RD_PIPE"
//		:	"XXX";
`endif

endmodule

