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

module l2c_cbus#(
	parameter							L2CID				= 0
)(
	/******** Clock and Reset ********/
	input wire							clk,
	input wire							rst_,

	/******** Internal Cross Unit Access ********/
	output reg							dmp_en,
	output reg [`CoreUidBus]			dmp_uid,
	output reg [`CoreDataBeBus]			dmp_data_be,
	output reg [`CoreDataBus]			dmp_data,

	/******** Memory Out Access ********/
	output reg									mem_rw_req,
	output reg [`L2cIndexBus]					mem_rw_index,
	output wire [1*`L2C_WAY_NUM-1:0]			mem_wr_en_pack,
	output wire [`L2C_TAG_W*`L2C_WAY_NUM-1:0]	mem_wr_tag_pack,
	output wire [1*`L2C_WAY_NUM-1:0]			mem_wr_valid_pack,
	output wire [1*`L2C_WAY_NUM-1:0]			mem_wr_dirty_pack,
	output wire [`CORE_DATA_W*`L2C_WAY_NUM-1:0]	mem_wr_data_pack,

	input wire									mem_rw_rdy,
	input wire [`L2C_TAG_W*`L2C_WAY_NUM-1:0]	mem_rd_tag_pack,
	input wire [1*`L2C_WAY_NUM-1:0]				mem_rd_valid_pack,
	input wire [1*`L2C_WAY_NUM-1:0]				mem_rd_dirty_pack,
	input wire [`CORE_DATA_W*`L2C_WAY_NUM-1:0]	mem_rd_data_pack,

	/******** Cache Bus Out Access ********/
	output reg							cbus_req,
	output reg [`CoreUidBus]			cbus_uid,
	output reg [`CoreDataBus]			cbus_data,

	input wire							cbus_ack,

	/******** Cross Unit Out Access ********/
	output reg							xu_req,
	output reg [`XuL2cCmdBus]			xu_cmd,
	output reg [`CoreAddrBus]			xu_addr,
	output reg [`CoreUidBus]			xu_uid,
	output reg [`CpuTileIdBus]			xu_src,
	output reg [`CoreDataBeBus]			xu_data_be,
	output reg [`CoreDataBus]			xu_data,

	input wire							xu_ack,

	/******** Cache Bus Access ********/
	input wire							req,
	input wire [`L2cCbusCmdBus]			cmd,
	input wire [`CoreAddrBus]			addr,
	input wire [`CoreUidBus]			uid,
	input wire [`CoreDataBeBus]			data_be,
	input wire [`CoreDataBus]			data,

	output reg							ack
);

/*----------------------------------------------------------------------------*
 * Wire and Reg
 *----------------------------------------------------------------------------*/
	/******** Local Parameter ********/
	localparam STATE_W					= 4;
	localparam STATE_READY				= 4'h0;
	localparam STATE_RD_MEM				= 4'h1;
	localparam STATE_RD_MEM_CH			= 4'h2;
	localparam STATE_RD_H_CBUS			= 4'h3;
	localparam STATE_RD_M_XU			= 4'h4;
	localparam STATE_WR_MEM				= 4'h5;
	localparam STATE_WR_MEM_CH			= 4'h6;
	localparam STATE_WR_H_D_CBUS		= 4'h7;
	localparam STATE_WR_H_C_XU			= 4'h8;
	localparam STATE_WR_M_XU			= 4'h9;
	localparam STATE_RN_XU				= 4'ha;
	localparam STATE_WN_XU				= 4'hb;

	/******** Memory ********/
	reg									mem_wr_en[0:`L2C_WAY_NUM-1];
	reg [`L2cTagBus]					mem_wr_tag[0:`L2C_WAY_NUM-1];
	reg									mem_wr_valid[0:`L2C_WAY_NUM-1];
	reg									mem_wr_dirty[0:`L2C_WAY_NUM-1];
	reg [`CoreDataBus]					mem_wr_data[0:`L2C_WAY_NUM-1];

	wire [`L2cTagBus]					mem_rd_tag[0:`L2C_WAY_NUM-1];
	wire								mem_rd_valid[0:`L2C_WAY_NUM-1];
	wire								mem_rd_dirty[0:`L2C_WAY_NUM-1];
	wire [`CoreDataBus]					mem_rd_data[0:`L2C_WAY_NUM-1];

	/******** Address ********/
	wire [`L2cTagBus]					tag_ff;
	wire [`L2cIndexBus]					index_ff;

	/******** Hit ********/
	reg									hit_en;
	reg [`L2cWayBus]					hit_way;
	reg									hit_dirty;

	/******** Marge ********/
	reg [`CoreDataBus]					mem_rd_data_ff_marge;

	/******** State Transition ********/
	reg [STATE_W-1:0]					state;

	reg [`CoreAddrBus]					addr_ff;
	reg [`CoreUidBus]					uid_ff;
	reg [`CoreDataBeBus]				data_be_ff;
	reg [`CoreDataBus]					data_ff;

	reg [`L2cTagBus]					mem_rd_tag_ff[0:`L2C_WAY_NUM-1];
	reg									mem_rd_valid_ff[0:`L2C_WAY_NUM-1];
	reg									mem_rd_dirty_ff[0:`L2C_WAY_NUM-1];
	reg [`CoreDataBus]					mem_rd_data_ff[0:`L2C_WAY_NUM-1];

	/******** Random Way State Transition ********/
	reg [`L2cWayBus]					rand_way;

	/******** Iterator ********/
	integer								i;

	generate
		genvar								gi;
	endgenerate

/*----------------------------------------------------------------------------*
 * Combinational Logic
 *----------------------------------------------------------------------------*/
	/******** Memory ********/
	generate
		for (gi = 0; gi < `L2C_WAY_NUM; gi = gi + 1) begin
			assign mem_wr_en_pack[1*gi+:1]
					= mem_wr_en[gi];
			assign mem_wr_tag_pack[`L2C_TAG_W*gi+:`L2C_TAG_W]
					= mem_wr_tag[gi];
			assign mem_wr_valid_pack[1*gi+:1]
					= mem_wr_valid[gi];
			assign mem_wr_dirty_pack[1*gi+:1]
					= mem_wr_dirty[gi];
			assign mem_wr_data_pack[`CORE_DATA_W*gi+:`CORE_DATA_W]
					= mem_wr_data[gi];

			assign mem_rd_tag[gi]
					= mem_rd_tag_pack[`L2C_TAG_W*gi+:`L2C_TAG_W];
			assign mem_rd_valid[gi]
					= mem_rd_valid_pack[1*gi+:1];
			assign mem_rd_dirty[gi]
					= mem_rd_dirty_pack[1*gi+:1];
			assign mem_rd_data[gi]
					= mem_rd_data_pack[`CORE_DATA_W*gi+:`CORE_DATA_W];
		end
	endgenerate

	/******** Address ********/
	assign {tag_ff, index_ff} = addr_ff;

	/******** Hit ********/
	always @(*) begin
		hit_en		= `DISABLE;
		hit_way		= `L2C_WAY_W'h0;
		hit_dirty 	= `DISABLE;
		for (i = 0; i < `L2C_WAY_NUM; i = i + 1) begin
			if ((mem_rd_tag_ff[i] == tag_ff) &&
					(mem_rd_valid_ff[i] == `ENABLE)) begin
				hit_en		= `ENABLE;
				hit_way		= i;
				hit_dirty	= mem_rd_dirty_ff[i];
			end
		end
	end

	/******** Marge ********/
	always @(*) begin
		mem_rd_data_ff_marge = mem_rd_data_ff[hit_way];
		for (i = 0; i < `CORE_DATA_BE_W; i = i + 1) begin
			if (data_be_ff[i] == `ENABLE) begin
				mem_rd_data_ff_marge[`BYTE_DATA_W*i+:`BYTE_DATA_W]
						= data_ff[`BYTE_DATA_W*i+:`BYTE_DATA_W];
			end
		end
	end

	/********  ********/
	always @(*) begin
		ack = `DISABLE;

		case (state)
		STATE_READY : begin
			if (req == `ENABLE) begin
				ack = `ENABLE;
			end
		end
		endcase
	end

	/********  ********/
	always @(*) begin
		dmp_en			= `DISABLE;
		dmp_uid			= `CORE_UID_W'h0;
		dmp_data_be		= {`CORE_DATA_BE_W{`DISABLE}};
		dmp_data		= `CORE_DATA_W'h0;

		case (state)
		STATE_WR_MEM_CH : begin
			dmp_en			= `ENABLE;
			dmp_uid			= uid_ff;
			dmp_data_be		= data_be_ff;
			dmp_data		= data_ff;
		end
		endcase
	end

	/******** Memory ********/
	always @(*) begin
		mem_rw_req				= `DISABLE;
		mem_rw_index			= `L2C_INDEX_W'h0;
		for (i = 0; i < `L2C_WAY_NUM; i = i + 1) begin
			mem_wr_en[i]			= `DISABLE;
			mem_wr_tag[i]			= `L2C_TAG_W'h0;
			mem_wr_valid[i]			= `DISABLE;
			mem_wr_dirty[i]			= `DISABLE;
			mem_wr_data[i]			= `CORE_DATA_W'h0;
		end

		case (state)
		STATE_RD_MEM : begin
			mem_rw_req				= `ENABLE;
			mem_rw_index			= index_ff;
		end
		STATE_WR_MEM : begin
			mem_rw_req				= `ENABLE;
			mem_rw_index			= index_ff;
		end
		STATE_WR_MEM_CH : begin
			mem_rw_req				= `ENABLE;
			if (hit_en == `ENABLE) begin
				if (hit_dirty == `DISABLE) begin
				end else begin
					mem_rw_index			= index_ff;
					mem_wr_en[hit_way]		= `ENABLE;
					mem_wr_tag[hit_way]		= tag_ff;
					mem_wr_valid[hit_way]	= `ENABLE;
					mem_wr_dirty[hit_way]	= `ENABLE;
					mem_wr_data[hit_way]	= mem_rd_data_ff_marge;
				end
			end
		end
		endcase
	end

	/******** Cache Bus ********/
	always @(*) begin
		cbus_req	= `DISABLE;
		cbus_uid	= `CORE_UID_W'h0;
		cbus_data	= `CORE_DATA_W'h0;

		case (state)
		STATE_RD_H_CBUS : begin
			cbus_req	= `ENABLE;
			cbus_uid	= uid_ff;
			cbus_data	= mem_rd_data_ff[hit_way];
		end
		STATE_WR_H_D_CBUS : begin
			cbus_req	= `ENABLE;
			cbus_uid	= uid_ff;
		end
		endcase
	end

	/******** Cross Unit ********/
	always @(*) begin
		xu_req		= `DISABLE;
		xu_cmd		= `XU_L2C_CMD_NO;
		xu_addr		= `CORE_ADDR_W'h0;
		xu_uid		= `CORE_UID_W'h0;
		xu_src		= `CPU_TILE_ID_W'h0;
		xu_data_be	= {`CORE_DATA_BE_W{`DISABLE}};
		xu_data		= `CORE_DATA_W'h0;

		case (state)
		STATE_RD_M_XU : begin
			xu_req		= `ENABLE;
			xu_cmd		= `XU_L2C_CMD_RD;
			xu_addr		= addr_ff;
			xu_uid		= uid_ff;
		end
		STATE_WR_H_C_XU : begin
			xu_req		= `ENABLE;
			xu_cmd		= `XU_L2C_CMD_UP;
			xu_addr		= addr_ff;
			xu_uid		= uid_ff;
		end
		STATE_WR_M_XU : begin
			xu_req		= `ENABLE;
			xu_cmd		= `XU_L2C_CMD_RX;
			xu_addr		= addr_ff;
			xu_uid		= uid_ff;
		end
		STATE_RN_XU : begin
			xu_req		= `ENABLE;
			xu_cmd		= `XU_L2C_CMD_RN;
			xu_addr		= addr_ff;
			xu_uid		= uid_ff;
		end
		STATE_WN_XU : begin
			xu_req		= `ENABLE;
			xu_cmd		= `XU_L2C_CMD_WN;
			xu_addr		= addr_ff;
			xu_uid		= uid_ff;
			xu_data_be	= data_be_ff;
			xu_data		= data_ff;
		end
		endcase
	end

/*----------------------------------------------------------------------------*
 * Sequential Logic
 *----------------------------------------------------------------------------*/
	/******** State Transition ********/
	always @(posedge clk or negedge rst_) begin
		if (rst_ == `ENABLE_) begin
			state				<= #1 STATE_READY;

			addr_ff				<= #1 `CORE_ADDR_W'h0;
			uid_ff				<= #1 `CORE_UID_W'h0;
			data_be_ff			<= #1 {`CORE_DATA_BE_W{`DISABLE}};
			data_ff				<= #1 `CORE_DATA_W'h0;

			for (i = 0; i < `L2C_WAY_NUM; i = i + 1) begin
				mem_rd_tag_ff[i]	<= #1 `L2C_TAG_W'h0;
				mem_rd_valid_ff[i]	<= #1 `DISABLE;
				mem_rd_dirty_ff[i]	<= #1 `DISABLE;
				mem_rd_data_ff[i]	<= #1 `CORE_DATA_W'h0;
			end
		end else begin
			case (state)
			STATE_READY : begin
				if (req == `ENABLE) begin
					case (cmd)
					`L2C_CBUS_CMD_RD : begin
						state				<= #1 STATE_RD_MEM;
					end
					`L2C_CBUS_CMD_WR : begin
						state				<= #1 STATE_WR_MEM;
					end
					`L2C_CBUS_CMD_RN : begin // (RN)
						state				<= #1 STATE_RN_XU;
					end
					`L2C_CBUS_CMD_WN : begin // (WN)
						state				<= #1 STATE_WN_XU;
					end
					endcase

					addr_ff				<= #1 addr;
					uid_ff				<= #1 uid;
					data_be_ff			<= #1 data_be;
					data_ff				<= #1 data;

					for (i = 0; i < `L2C_WAY_NUM; i = i + 1) begin
						mem_rd_tag_ff[i]	<= #1 `L2C_TAG_W'h0;
						mem_rd_valid_ff[i]	<= #1 `DISABLE;
						mem_rd_dirty_ff[i]	<= #1 `DISABLE;
						mem_rd_data_ff[i]	<= #1 `CORE_DATA_W'h0;
					end
				end else begin
					addr_ff				<= #1 `CORE_ADDR_W'h0;
					uid_ff				<= #1 `CORE_UID_W'h0;
					data_be_ff			<= #1 {`CORE_DATA_BE_W{`DISABLE}};
					data_ff				<= #1 `CORE_DATA_W'h0;

					for (i = 0; i < `L2C_WAY_NUM; i = i + 1) begin
						mem_rd_tag_ff[i]	<= #1 `L2C_TAG_W'h0;
						mem_rd_valid_ff[i]	<= #1 `DISABLE;
						mem_rd_dirty_ff[i]	<= #1 `DISABLE;
						mem_rd_data_ff[i]	<= #1 `CORE_DATA_W'h0;
					end
				end
			end

			/******** RD ********/
			STATE_RD_MEM : begin
				if (mem_rw_rdy == `ENABLE) begin
					state				<= #1 STATE_RD_MEM_CH;

					for (i = 0; i < `L2C_WAY_NUM; i = i + 1) begin
						mem_rd_tag_ff[i]	<= #1 mem_rd_tag[i];
						mem_rd_valid_ff[i]	<= #1 mem_rd_valid[i];
						mem_rd_dirty_ff[i]	<= #1 mem_rd_dirty[i];
						mem_rd_data_ff[i]	<= #1 mem_rd_data[i];
					end
				end
			end
			STATE_RD_MEM_CH : begin
				if (hit_en == `ENABLE) begin // Hit (RDYD)
					state				<= #1 STATE_RD_H_CBUS;
				end else begin // Miss (RD)
					state				<= #1 STATE_RD_M_XU;
				end
			end
			STATE_RD_H_CBUS : begin
				if (cbus_ack == `ENABLE) begin
					state				<= #1 STATE_READY;
				end
			end
			STATE_RD_M_XU : begin
				if (xu_ack == `ENABLE) begin
					state				<= #1 STATE_READY;
				end
			end

			/******** WR ********/
			STATE_WR_MEM : begin
				if (mem_rw_rdy == `ENABLE) begin
					state				<= #1 STATE_WR_MEM_CH;

					for (i = 0; i < `L2C_WAY_NUM; i = i + 1) begin
						mem_rd_tag_ff[i]	<= #1 mem_rd_tag[i];
						mem_rd_valid_ff[i]	<= #1 mem_rd_valid[i];
						mem_rd_dirty_ff[i]	<= #1 mem_rd_dirty[i];
						mem_rd_data_ff[i]	<= #1 mem_rd_data[i];
					end
				end
			end
			STATE_WR_MEM_CH : begin
				if (hit_en == `ENABLE) begin // Hit
					if (hit_dirty == `DISABLE) begin // Clean (UP)
						state				<= #1 STATE_WR_H_C_XU;
					end else begin // Dirty (RDY)
						state				<= #1 STATE_WR_H_D_CBUS;
					end
				end else begin // Miss (RX)
					state				<= #1 STATE_WR_M_XU;
				end
			end
			STATE_WR_H_C_XU : begin
				if (xu_ack == `ENABLE) begin
					state				<= #1 STATE_READY;
				end
			end
			STATE_WR_H_D_CBUS : begin
				if (cbus_ack == `ENABLE) begin
					state				<= #1 STATE_READY;
				end
			end
			STATE_WR_M_XU : begin
				if (xu_ack == `ENABLE) begin
					state				<= #1 STATE_READY;
				end
			end

			/******** RN ********/
			STATE_RN_XU : begin
				if (xu_ack == `ENABLE) begin
					state				<= #1 STATE_READY;
				end
			end

			/******** WN ********/
			STATE_WN_XU : begin
				if (xu_ack == `ENABLE) begin
					state				<= #1 STATE_READY;
				end
			end
			endcase
		end
	end

	/******** Random Way State Transition ********/
	always @(posedge clk or negedge rst_) begin
		if (rst_ == `ENABLE_) begin
			rand_way			<= #1 `L2C_WAY_W'h0;
		end else begin
			rand_way			<= #1 rand_way + 1;
		end
	end

/*----------------------------------------------------------------------------*
 * Debug
 *----------------------------------------------------------------------------*/
`ifdef DEBUG
	/********  ********/
`endif

endmodule

