/*----------------------------------------------------------------------------*
 *	***
 *
 *	Author	: toshi
 *	File	: l2c_xu.v
 *	Version	: 1.0
 *	Date	: 2012-10-15T16:04:46+9:00
 *	Update	: 2012-10-15T16:25:39+9:00
 *
 *	Description :
 *		***
 *
 *	Histoy :
 *		2012-10-15 1.0	original
 *----------------------------------------------------------------------------*/

`include "config.h"

`include "stddef.h"
`include "cpu.h"
`include "core.h"
`include "l2c.h"
`include "cbus.h"
`include "xu.h"

module l2c_xu#(
	parameter							L2CID				= 0
)(
	/******** Clock and Reset ********/
	input wire							clk,
	input wire							rst_,

	/******** Internal Cache Bus Access ********/
	input wire							dmp_en,
	input wire [`CoreUidBus]			dmp_uid,
	input wire [`CoreDataBeBus]			dmp_data_be,
	input wire [`CoreDataBus]			dmp_data,

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
	output wire							dl_pot,

	output reg							xu_req,
	output reg [`XuL2cCmdBus]			xu_cmd,
	output reg [`CoreAddrBus]			xu_addr,
	output reg [`CoreUidBus]			xu_uid,
	output reg [`CpuTileIdBus]			xu_src,
	output reg [`CoreDataBeBus]			xu_data_be,
	output reg [`CoreDataBus]			xu_data,

	input wire							xu_ack,

	/******** Processor Unit Access ********/
	output wire							inv_ia_en,
	output wire [`CoreAddrBus]			inv_ia_addr,

	output wire							inv_da_en,
	output wire [`CoreAddrBus]			inv_da_addr,

	/******** Cross Unit Access ********/
	input wire							req,
	input wire [`L2cXuCmdBus]			cmd,
	input wire [`CoreAddrBus]			addr,
	input wire [`CoreUidBus]			uid,
	input wire [`CpuTileIdBus]			src,
	input wire [`CoreDataBus]			data,

	output reg							ack
);

	assign dl_pot = xu_req;

/*----------------------------------------------------------------------------*
 * Wire and Reg
 *----------------------------------------------------------------------------*/
	/******** Local Parameter ********/
	localparam STATE_W					= 5;
	localparam STATE_READY				= 5'h00;
	localparam STATE_RDR_MEM			= 5'h01;
	localparam STATE_RDR_MEM_CH			= 5'h02;
	localparam STATE_RDR_M_VD_XU 		= 5'h03;
	localparam STATE_RDR_M_CBUS 		= 5'h04;
	localparam STATE_UPR_MEM 			= 5'h05;
	localparam STATE_UPR_MEM_CH  		= 5'h06;
	localparam STATE_UPR_H_C_CBUS 		= 5'h07;
	localparam STATE_RXR_MEM 			= 5'h08;
	localparam STATE_RXR_MEM_CH 		= 5'h09;
	localparam STATE_RXR_M_VD_XU 		= 5'h0a;
	localparam STATE_RXR_M_CBUS 		= 5'h0b;
	localparam STATE_RDP_MEM 			= 5'h0c;
	localparam STATE_RDP_MEM_CH  		= 5'h0d;
	localparam STATE_RDP_H_D_XU 		= 5'h0e;
	localparam STATE_RXP_MEM 			= 5'h0f;
	localparam STATE_RXP_MEM_CH  		= 5'h10;
	localparam STATE_RXP_H_D_XU 		= 5'h11;
	localparam STATE_INV_MEM 			= 5'h12;
	localparam STATE_INV_MEM_CH  		= 5'h13;
	localparam STATE_RNR_CBUS 			= 5'h14;
	localparam STATE_WNR_CBUS 			= 5'h15;

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

	/********  ********/
	reg									hit_en;
	reg [`L2cWayBus]					hit_way;
	reg									hit_dirty;

	/********  ********/
	reg [`L2cWayBus]					rep_way;
	reg									rep_dirty;

	/********  ********/
	reg [`CoreDataBus]					dmp_data_mem_marge;
	reg [`CoreDataBus]					dmp_data_xu_marge;

	/******** State Transition ********/
	reg [STATE_W-1:0]					state;

	reg [`L2cWayBus]					rep_way_ff;

	reg [`CoreAddrBus]					addr_ff;
	reg [`CoreUidBus]					uid_ff;
	reg [`CpuTileIdBus]					src_ff;
	reg [`CoreDataBus]					data_ff;

	reg [`L2cTagBus]					mem_rd_tag_ff[0:`L2C_WAY_NUM-1];
	reg									mem_rd_valid_ff[0:`L2C_WAY_NUM-1];
	reg									mem_rd_dirty_ff[0:`L2C_WAY_NUM-1];
	reg [`CoreDataBus]					mem_rd_data_ff[0:`L2C_WAY_NUM-1];

	/******** Dump State Transition ********/
	reg [`CoreDataBeBus]				dmp_data_be_ff[0:`L2C_WAY_NUM-1];
	reg [`CoreDataBus]					dmp_data_ff[0:`L2C_WAY_NUM-1];


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

	/******** Replace ********/
	always @(*) begin
		rep_way	= rand_way;
		for (i = `L2C_WAY_NUM - 1; i >= 0; i = i - 1) begin
			if ((mem_rd_valid_ff[i] == `DISABLE)) begin
				rep_way	= i;
			end
		end
	end

	always @(*) begin
		if ((mem_rd_valid_ff[rep_way] == `ENABLE) &&
				(mem_rd_dirty_ff[rep_way] == `ENABLE)) begin
			rep_dirty = `ENABLE;
		end else begin
			rep_dirty = `DISABLE;
		end
	end

	/******** Marge ********/
	always @(*) begin
		dmp_data_mem_marge = mem_rd_data_ff[hit_way];
		for (i = 0; i < `CORE_DATA_BE_W; i = i + 1) begin
			if (dmp_data_be_ff[uid_ff][i] == `ENABLE) begin
				dmp_data_mem_marge[`BYTE_DATA_W*i+:`BYTE_DATA_W] =
						dmp_data_ff[uid_ff][`BYTE_DATA_W*i+:`BYTE_DATA_W];
			end
		end
	end

	always @(*) begin
		dmp_data_xu_marge = data_ff;
		for (i = 0; i < `CORE_DATA_BE_W; i = i + 1) begin
			if (dmp_data_be_ff[uid_ff][i] == `ENABLE) begin
				dmp_data_xu_marge[`BYTE_DATA_W*i+:`BYTE_DATA_W] =
						dmp_data_ff[uid_ff][`BYTE_DATA_W*i+:`BYTE_DATA_W];
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
		STATE_RDR_MEM : begin
			mem_rw_req				= `ENABLE;
			mem_rw_index			= index_ff;
		end
		STATE_RDR_MEM_CH : begin
			if (hit_en == `ENABLE) begin
			end else begin
				mem_rw_req				= `ENABLE;
				mem_rw_index			= index_ff;
				mem_wr_en[rep_way]		= `ENABLE;
				mem_wr_tag[rep_way]		= tag_ff;
				mem_wr_valid[rep_way]	= `ENABLE;
				mem_wr_dirty[rep_way]	= `DISABLE;
				mem_wr_data[rep_way]	= data_ff;
			end
		end
		STATE_UPR_MEM : begin
			mem_rw_req				= `ENABLE;
			mem_rw_index			= index_ff;
		end
		STATE_UPR_MEM_CH : begin
			if (hit_en == `ENABLE) begin
				if (hit_dirty == `DISABLE) begin
					mem_rw_req				= `ENABLE;
					mem_rw_index			= index_ff;
					mem_wr_en[hit_way]		= `ENABLE;
					mem_wr_tag[hit_way]		= tag_ff;
					mem_wr_valid[hit_way]	= `ENABLE;
					mem_wr_dirty[hit_way]	= `ENABLE;
					mem_wr_data[hit_way]	= dmp_data_mem_marge;
				end
			end
		end
		STATE_RXR_MEM : begin
			mem_rw_req				= `ENABLE;
			mem_rw_index			= index_ff;
		end
		STATE_RXR_MEM_CH : begin
			if (hit_en == `ENABLE) begin
			end else begin
				mem_rw_req				= `ENABLE;
				mem_rw_index			= index_ff;
				mem_wr_en[rep_way]		= `ENABLE;
				mem_wr_tag[rep_way]		= tag_ff;
				mem_wr_valid[rep_way]	= `ENABLE;
				mem_wr_dirty[rep_way]	= `ENABLE;
				mem_wr_data[rep_way]	= dmp_data_xu_marge;
			end
		end
		STATE_RDP_MEM : begin
			mem_rw_req				= `ENABLE;
			mem_rw_index			= index_ff;
		end
		STATE_RDP_MEM_CH : begin
			if (hit_en == `ENABLE) begin
				if (hit_dirty == `DISABLE) begin
				end else begin
					mem_rw_req				= `ENABLE;
					mem_rw_index			= index_ff;
					mem_wr_en[hit_way]		= `ENABLE;
					mem_wr_tag[hit_way]		= tag_ff;
					mem_wr_valid[hit_way]	= `ENABLE;
					mem_wr_dirty[hit_way]	= `DISABLE;
					mem_wr_data[hit_way]	= mem_rd_data_ff[hit_way];
				end
			end
		end
		STATE_RXP_MEM : begin
			mem_rw_req				= `ENABLE;
			mem_rw_index			= index_ff;
		end
		STATE_RXP_MEM_CH : begin
			if (hit_en == `ENABLE) begin
				if (hit_dirty == `DISABLE) begin
				end else begin
					mem_rw_req				= `ENABLE;
					mem_rw_index			= index_ff;
					mem_wr_en[hit_way]		= `ENABLE;
					mem_wr_tag[hit_way]		= `L2C_TAG_W'h0;
					mem_wr_valid[hit_way]	= `DISABLE;
					mem_wr_dirty[hit_way]	= `DISABLE;
					mem_wr_data[hit_way]	= `CORE_DATA_W'h0;
				end
			end
		end
		STATE_INV_MEM : begin
			mem_rw_req				= `ENABLE;
			mem_rw_index			= index_ff;
		end
		STATE_INV_MEM_CH : begin
			if (hit_en == `ENABLE) begin
				if (hit_dirty == `DISABLE) begin
					mem_rw_req				= `ENABLE;
					mem_rw_index			= index_ff;
					mem_wr_en[hit_way]		= `ENABLE;
					mem_wr_tag[hit_way]		= `L2C_TAG_W'h0;
					mem_wr_valid[hit_way]	= `DISABLE;
					mem_wr_dirty[hit_way]	= `DISABLE;
					mem_wr_data[hit_way]	= `CORE_DATA_W'h0;
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
		STATE_RDR_M_CBUS : begin
			cbus_req	= `ENABLE;
			cbus_uid	= uid_ff;
			cbus_data	= data_ff;
		end
		STATE_UPR_H_C_CBUS : begin
			cbus_req	= `ENABLE;
			cbus_uid	= uid_ff;
		end
		STATE_RXR_M_CBUS : begin
			cbus_req	= `ENABLE;
			cbus_uid	= uid_ff;
		end
		STATE_RNR_CBUS : begin
			cbus_req	= `ENABLE;
			cbus_uid	= uid_ff;
			cbus_data	= data_ff;
		end
		STATE_WNR_CBUS : begin
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
		STATE_RDR_M_VD_XU : begin
			xu_req		= `ENABLE;
			xu_cmd		= `XU_L2C_CMD_WB;
			xu_addr		= {mem_rd_tag_ff[rep_way_ff], index_ff};
			xu_data		= mem_rd_data_ff[rep_way_ff];
		end
		STATE_RXR_M_VD_XU : begin
			xu_req		= `ENABLE;
			xu_cmd		= `XU_L2C_CMD_WB;
			xu_addr		= {mem_rd_tag_ff[rep_way_ff], index_ff};
			xu_data		= mem_rd_data_ff[rep_way_ff];
		end
		STATE_RDP_H_D_XU : begin
			xu_req		= `ENABLE;
			xu_cmd		= `XU_L2C_CMD_RDF;
			xu_addr		= {mem_rd_tag_ff[hit_way], index_ff};
			xu_uid		= uid_ff;
			xu_src		= src_ff;
			xu_data		= mem_rd_data_ff[hit_way];
		end
		STATE_RXP_H_D_XU : begin
			xu_req		= `ENABLE;
			xu_cmd		= `XU_L2C_CMD_RXF;
			xu_addr		= {mem_rd_tag_ff[hit_way], index_ff};
			xu_uid		= uid_ff;
			xu_src		= src_ff;
			xu_data		= mem_rd_data_ff[hit_way];
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

			rep_way_ff			<= #1 `L2C_WAY_W'h0;

			addr_ff				<= #1 `CORE_ADDR_W'h0;
			uid_ff				<= #1 `CORE_UID_W'h0;
			src_ff				<= #1 `CPU_TILE_ID_W'h0;
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
					`L2C_XU_CMD_RDR : begin
						state			<= #1 STATE_RDR_MEM;
					end
					`L2C_XU_CMD_UPR : begin
						state			<= #1 STATE_UPR_MEM;
					end
					`L2C_XU_CMD_RXR : begin
						state			<= #1 STATE_RXR_MEM;
					end
					`L2C_XU_CMD_RDP : begin
						state			<= #1 STATE_RDP_MEM;
					end
					`L2C_XU_CMD_RXP : begin
						state			<= #1 STATE_RXP_MEM;
					end
					`L2C_XU_CMD_INV : begin
						state			<= #1 STATE_INV_MEM;
					end
					`L2C_XU_CMD_RNR : begin
						state			<= #1 STATE_RNR_CBUS;
					end
					`L2C_XU_CMD_WNR : begin
						state			<= #1 STATE_WNR_CBUS;
					end
					endcase

					rep_way_ff			<= #1 `L2C_WAY_W'h0;

					addr_ff				<= #1 addr;
					uid_ff				<= #1 uid;
					src_ff				<= #1 src;
					data_ff				<= #1 data;

					for (i = 0; i < `L2C_WAY_NUM; i = i + 1) begin
						mem_rd_tag_ff[i]	<= #1 `L2C_TAG_W'h0;
						mem_rd_valid_ff[i]	<= #1 `DISABLE;
						mem_rd_dirty_ff[i]	<= #1 `DISABLE;
						mem_rd_data_ff[i]	<= #1 `CORE_DATA_W'h0;
					end
				end else begin
					rep_way_ff			<= #1 `L2C_WAY_W'h0;

					addr_ff				<= #1 `CORE_ADDR_W'h0;
					uid_ff				<= #1 `CORE_UID_W'h0;
					src_ff				<= #1 `CPU_TILE_ID_W'h0;
					data_ff				<= #1 `CORE_DATA_W'h0;

					for (i = 0; i < `L2C_WAY_NUM; i = i + 1) begin
						mem_rd_tag_ff[i]	<= #1 `L2C_TAG_W'h0;
						mem_rd_valid_ff[i]	<= #1 `DISABLE;
						mem_rd_dirty_ff[i]	<= #1 `DISABLE;
						mem_rd_data_ff[i]	<= #1 `CORE_DATA_W'h0;
					end
				end
			end

			/******** RDR ********/
			STATE_RDR_MEM : begin
				if (mem_rw_rdy == `ENABLE) begin
					state			<= #1 STATE_RDR_MEM_CH;

					for (i = 0; i < `L2C_WAY_NUM; i = i + 1) begin
						mem_rd_tag_ff[i]	<= #1 mem_rd_tag[i];
						mem_rd_valid_ff[i]	<= #1 mem_rd_valid[i];
						mem_rd_dirty_ff[i]	<= #1 mem_rd_dirty[i];
						mem_rd_data_ff[i]	<= #1 mem_rd_data[i];
					end
				end
			end
			STATE_RDR_MEM_CH : begin
				if (hit_en == `ENABLE) begin
					$display("modify %d", L2CID); $finish(2);
				end else begin
					if (rep_dirty == `DISABLE) begin
						state			<= #1 STATE_RDR_M_CBUS;
					end else begin
						state			<= #1 STATE_RDR_M_VD_XU;

						rep_way_ff		<= #1 rep_way;
					end
				end
			end
			STATE_RDR_M_VD_XU : begin
				if (xu_ack == `ENABLE) begin
					state			<= #1 STATE_RDR_M_CBUS;
				end
			end
			STATE_RDR_M_CBUS : begin
				if (cbus_ack == `ENABLE) begin
					state			<= #1 STATE_READY;
				end
			end

			/******** UPR ********/
			STATE_UPR_MEM : begin
				if (mem_rw_rdy == `ENABLE) begin
					state			<= #1 STATE_UPR_MEM_CH;

					for (i = 0; i < `L2C_WAY_NUM; i = i + 1) begin
						mem_rd_tag_ff[i]	<= #1 mem_rd_tag[i];
						mem_rd_valid_ff[i]	<= #1 mem_rd_valid[i];
						mem_rd_dirty_ff[i]	<= #1 mem_rd_dirty[i];
						mem_rd_data_ff[i]	<= #1 mem_rd_data[i];
					end
				end
			end
			STATE_UPR_MEM_CH : begin
				if (hit_en == `ENABLE) begin
					if (hit_dirty == `DISABLE) begin
						state			<= #1 STATE_UPR_H_C_CBUS;
					end else begin
						$display("modify"); $finish(2);
					end
				end else begin
					$display("modify"); $finish(2);
				end
			end
			STATE_UPR_H_C_CBUS : begin
				if (cbus_ack == `ENABLE) begin
					state			<= #1 STATE_READY;
				end
			end

			/******** RXR ********/
			STATE_RXR_MEM : begin
				if (mem_rw_rdy == `ENABLE) begin
					state			<= #1 STATE_RXR_MEM_CH;

					for (i = 0; i < `L2C_WAY_NUM; i = i + 1) begin
						mem_rd_tag_ff[i]	<= #1 mem_rd_tag[i];
						mem_rd_valid_ff[i]	<= #1 mem_rd_valid[i];
						mem_rd_dirty_ff[i]	<= #1 mem_rd_dirty[i];
						mem_rd_data_ff[i]	<= #1 mem_rd_data[i];
					end
				end
			end
			STATE_RXR_MEM_CH : begin
				if (hit_en == `ENABLE) begin
					$display("modify"); $finish(2);
				end else begin
					if (rep_dirty == `DISABLE) begin
						state			<= #1 STATE_RXR_M_CBUS;
					end else begin
						state			<= #1 STATE_RXR_M_VD_XU;

						rep_way_ff		<= #1 rep_way;
					end
				end
			end
			STATE_RXR_M_VD_XU : begin
				if (xu_ack == `ENABLE) begin
					state			<= #1 STATE_RXR_M_CBUS;
				end
			end
			STATE_RXR_M_CBUS : begin
				if (cbus_ack == `ENABLE) begin
					state			<= #1 STATE_READY;
				end
			end

			/******** RDP ********/
			STATE_RDP_MEM : begin
				if (mem_rw_rdy == `ENABLE) begin
					state			<= #1 STATE_RDP_MEM_CH;

					for (i = 0; i < `L2C_WAY_NUM; i = i + 1) begin
						mem_rd_tag_ff[i]	<= #1 mem_rd_tag[i];
						mem_rd_valid_ff[i]	<= #1 mem_rd_valid[i];
						mem_rd_dirty_ff[i]	<= #1 mem_rd_dirty[i];
						mem_rd_data_ff[i]	<= #1 mem_rd_data[i];
					end
				end
			end
			STATE_RDP_MEM_CH : begin
				if (hit_en == `ENABLE) begin
					if (hit_dirty == `DISABLE) begin
						$display("modify"); $finish(2);
					end else begin
						state			<= #1 STATE_RDP_H_D_XU;
					end
				end else begin
					$display("modify %d", L2CID); $finish(2);
				end
			end
			STATE_RDP_H_D_XU : begin
				if (xu_ack == `ENABLE) begin
					state			<= #1 STATE_READY;
				end
			end


			/******** RXP ********/
			STATE_RXP_MEM : begin
				if (mem_rw_rdy == `ENABLE) begin
					state			<= #1 STATE_RXP_MEM_CH;

					for (i = 0; i < `L2C_WAY_NUM; i = i + 1) begin
						mem_rd_tag_ff[i]	<= #1 mem_rd_tag[i];
						mem_rd_valid_ff[i]	<= #1 mem_rd_valid[i];
						mem_rd_dirty_ff[i]	<= #1 mem_rd_dirty[i];
						mem_rd_data_ff[i]	<= #1 mem_rd_data[i];
					end
				end
			end
			STATE_RXP_MEM_CH : begin
				if (hit_en == `ENABLE) begin
					if (hit_dirty == `DISABLE) begin
						$display("modify"); $finish(2);
					end else begin
						state			<= #1 STATE_RXP_H_D_XU;
					end
				end else begin
					$display("modify"); $finish(2);
				end
			end
			STATE_RXP_H_D_XU : begin
				if (xu_ack == `ENABLE) begin
					state			<= #1 STATE_READY;
				end
			end

			/******** INV ********/
			STATE_INV_MEM : begin
				if (mem_rw_rdy == `ENABLE) begin
					state			<= #1 STATE_INV_MEM_CH;

					for (i = 0; i < `L2C_WAY_NUM; i = i + 1) begin
						mem_rd_tag_ff[i]	<= #1 mem_rd_tag[i];
						mem_rd_valid_ff[i]	<= #1 mem_rd_valid[i];
						mem_rd_dirty_ff[i]	<= #1 mem_rd_dirty[i];
						mem_rd_data_ff[i]	<= #1 mem_rd_data[i];
					end
				end
			end
			STATE_INV_MEM_CH : begin
				if (hit_en == `ENABLE) begin
					if (hit_dirty == `DISABLE) begin
						state			<= #1 STATE_READY;
					end else begin
						$display("modify"); $finish(2);
					end
				end else begin
					$display("modify"); $finish(2);
				end
			end

			/******** RNR ********/
			STATE_RNR_CBUS : begin
				if (cbus_ack == `ENABLE) begin
					state			<= #1 STATE_READY;
				end
			end

			/******** WNR ********/
			STATE_WNR_CBUS : begin
				if (cbus_ack == `ENABLE) begin
					state			<= #1 STATE_READY;
				end
			end

			endcase
		end
	end

	/******** Dump State Transition ********/
	always @(posedge clk or negedge rst_) begin
		if (rst_ == `ENABLE_) begin
			for (i = 0; i < `L2C_WAY_NUM; i = i + 1) begin
				dmp_data_be_ff[i]		<= #1 {`CORE_DATA_BE_W{`DISABLE}};
				dmp_data_ff[i]			<= #1 `CORE_DATA_W'h0;
			end
		end else begin
			if (dmp_en == `ENABLE) begin
				dmp_data_be_ff[dmp_uid]	<= #1 dmp_data_be;
				dmp_data_ff[dmp_uid]	<= #1 dmp_data;
			end
		end
	end

	/******** Random Way Transition ********/
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

