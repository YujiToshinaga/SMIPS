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
`include "core.h"
`include "l2c.h"

module l2c_mem(
	/******** Clock and Reset ********/
	input wire							clk,
	input wire							rst_,

	/******** Memory ********/
	input wire									rw_req,
	input wire [`L2cIndexBus]					rw_index,
	input wire [1*`L2C_WAY_NUM-1:0]				wr_en_pack,
	input wire [`L2C_TAG_W*`L2C_WAY_NUM-1:0]	wr_tag_pack,
	input wire [1*`L2C_WAY_NUM-1:0]				wr_valid_pack,
	input wire [1*`L2C_WAY_NUM-1:0]				wr_dirty_pack,
	input wire [`CORE_DATA_W*`L2C_WAY_NUM-1:0]	wr_data_pack,

	output reg									rw_rdy,
	output wire [`L2C_TAG_W*`L2C_WAY_NUM-1:0]	rd_tag_pack,
	output wire [1*`L2C_WAY_NUM-1:0]			rd_valid_pack,
	output wire [1*`L2C_WAY_NUM-1:0]			rd_dirty_pack,
	output wire [`CORE_DATA_W*`L2C_WAY_NUM-1:0]	rd_data_pack
);

/*----------------------------------------------------------------------------*
 * Wire and Reg
 *----------------------------------------------------------------------------*/
	/******** Local Parameter ********/
	localparam STATE_W					= 1;
	localparam STATE_READY				= 1'h0;
	localparam STATE_RD					= 1'h1;

	/******** Unpack ********/
	wire								wr_en[0:`L2C_WAY_NUM-1];
	wire [`L2cTagBus]					wr_tag[0:`L2C_WAY_NUM-1];
	wire								wr_valid[0:`L2C_WAY_NUM-1];
	wire								wr_dirty[0:`L2C_WAY_NUM-1];
	wire [`CoreDataBus]					wr_data[0:`L2C_WAY_NUM-1];

	wire [`L2cTagBus]					rd_tag[0:`L2C_WAY_NUM-1];
	wire								rd_valid[0:`L2C_WAY_NUM-1];
	wire								rd_dirty[0:`L2C_WAY_NUM-1];
	wire [`CoreDataBus]					rd_data[0:`L2C_WAY_NUM-1];

	/******** State Transition ********/
	reg [STATE_W-1:0]					state;

	/******** Iterator ********/
	integer								i;

	generate
		genvar								gi;
	endgenerate

/*----------------------------------------------------------------------------*
 * Module Instance
 *----------------------------------------------------------------------------*/

`ifdef LIB_TSMC130


`elsif LIB_TSMC65

	wire [127:0]						rd_data_high[0:`L2C_WAY_NUM];
	wire [127:0]						rd_data_low[0:`L2C_WAY_NUM];
	generate
		for (gi = 0; gi < `L2C_WAY_NUM; gi = gi + 1) begin : L2C_MEM_MEM
			/******** Tag nad Valid and Dirty ********/
			sram_sp_512x20 l2c_mem_tagvaliddirty(
				.Q			({rd_tag[gi], rd_valid[gi], rd_dirty[gi]}),
				.CLK		(clk),
				.CEN		(`ENABLE_),
				.WEN		(~wr_en[gi]),
				.A			(rw_index),
				.D			({wr_tag[gi], wr_valid[gi], wr_dirty[gi]}),
				.EMA		(3'h0),
				.RETN		(`DISABLE_)
			);

			/******** Data ********/
			assign rd_data[gi] = {rd_data_high[gi], rd_data_low[gi]};
			sram_sp_512x128 l2c_mem_data_high(
				.Q			(rd_data_high[gi]),
				.CLK		(clk),
				.CEN		(`ENABLE_),
				.WEN		(~wr_en[gi]),
				.A			(rw_index),
				.D			(wr_data[gi][255:128]),
				.EMA		(3'h0),
				.RETN		(`DISABLE_)
			);
			sram_sp_512x128 l2c_mem_data_low(
				.Q			(rd_data_low[gi]),
				.CLK		(clk),
				.CEN		(`ENABLE_),
				.WEN		(~wr_en[gi]),
				.A			(rw_index),
				.D			(wr_data[gi][127:0]),
				.EMA		(3'h0),
				.RETN		(`DISABLE_)
			);
		end
	endgenerate

`else

	generate
		for (gi = 0; gi < `L2C_WAY_NUM; gi = gi + 1) begin : L2C_MEM_MEM
			/******** Tag ********/
			ram_srw#(
				.ADDR_W					(`L2C_INDEX_W),
				.DATA_W					(`L2C_TAG_W),
				.MASK_W					(1)
			) l2c_mem_tag(
				.rst_					(rst_),

				.cs						(`ENABLE),

				.rw_clk					(clk),
				.rw_addr				(rw_index),
				.rw_as					(`ENABLE),
				.rw_rw					(wr_en[gi]),
				.wr_mask				(wr_en[gi]),
				.wr_data				(wr_tag[gi]),

				.rw_rdy					(),
				.rd_data				(rd_tag[gi])
			);

			/******** Valid ********/
			ram_srw#(
				.ADDR_W					(`L2C_INDEX_W),
				.DATA_W					(1),
				.MASK_W					(1)
			) l2c_mem_valid(
				.rst_					(rst_),

				.cs						(`ENABLE),

				.rw_clk					(clk),
				.rw_addr				(rw_index),
				.rw_as					(`ENABLE),
				.rw_rw					(wr_en[gi]),
				.wr_mask				(wr_en[gi]),
				.wr_data				(wr_valid[gi]),

				.rw_rdy					(),
				.rd_data				(rd_valid[gi])
			);

			/******** Dirty ********/
			ram_srw#(
				.ADDR_W					(`L2C_INDEX_W),
				.DATA_W					(1),
				.MASK_W					(1)
			) l2c_mem_dirty(
				.rst_					(rst_),

				.cs						(`ENABLE),

				.rw_clk					(clk),
				.rw_addr				(rw_index),
				.rw_as					(`ENABLE),
				.rw_rw					(wr_en[gi]),
				.wr_mask				(wr_en[gi]),
				.wr_data				(wr_dirty[gi]),

				.rw_rdy					(),
				.rd_data				(rd_dirty[gi])
			);

			/******** Data ********/
			ram_srw#(
				.ADDR_W					(`L2C_INDEX_W),
				.DATA_W					(`CORE_DATA_W),
				.MASK_W					(1)
			) l2c_mem_data(
				.rst_					(rst_),

				.cs						(`ENABLE),

				.rw_clk					(clk),
				.rw_addr				(rw_index),
				.rw_as					(`ENABLE),
				.rw_rw					(wr_en[gi]),
				.wr_mask				(wr_en[gi]),
				.wr_data				(wr_data[gi]),

				.rw_rdy					(),
				.rd_data				(rd_data[gi])
			);
		end
	endgenerate

`endif

/*----------------------------------------------------------------------------*
 * Combinational Logic
 *----------------------------------------------------------------------------*/
	/******** Unpack ********/
	generate
		for (gi = 0; gi < `L2C_WAY_NUM; gi = gi + 1) begin
			assign wr_en[gi]
					= wr_en_pack[1*gi+:1];
			assign wr_tag[gi]
					= wr_tag_pack[`L2C_TAG_W*gi+:`L2C_TAG_W];
			assign wr_valid[gi]
					= wr_valid_pack[1*gi+:1];
			assign wr_dirty[gi]
					= wr_dirty_pack[1*gi+:1];
			assign wr_data[gi]
					= wr_data_pack[`CORE_DATA_W*gi+:`CORE_DATA_W];

			assign rd_tag_pack[`L2C_TAG_W*gi+:`L2C_TAG_W]
					= rd_tag[gi];
			assign rd_valid_pack[1*gi+:1]
					= rd_valid[gi];
			assign rd_dirty_pack[1*gi+:1]
					= rd_dirty[gi];
			assign rd_data_pack[`CORE_DATA_W*gi+:`CORE_DATA_W]
					= rd_data[gi];
		end
	endgenerate

	/******** Ready ********/
	always @(*) begin
		rw_rdy = `DISABLE;

		case (state)
		STATE_READY : begin
			if (rw_req == `ENABLE) begin
				if (|wr_en_pack == `ENABLE) begin
					rw_rdy = `ENABLE;
				end
			end
		end
		STATE_RD : begin
			rw_rdy = `ENABLE;
		end
		endcase
	end

/*----------------------------------------------------------------------------*
 * Sequential Logic
 *----------------------------------------------------------------------------*/
	/********  ********/
	always @(posedge clk or negedge rst_) begin
		if (rst_ == `ENABLE_) begin
			state <= #1 STATE_READY;
		end else begin
			case (state)
			STATE_READY : begin
				if (rw_req == `ENABLE) begin
					if (|wr_en_pack == `ENABLE) begin
						state <= #1 STATE_READY;
					end else begin
						state <= #1 STATE_RD;
					end
				end
			end
			STATE_RD : begin
				state <= #1 STATE_READY;
			end
			endcase
		end
	end

endmodule

