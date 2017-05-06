/*----------------------------------------------------------------------------*
 *	SMIPS
 *
 *	File	: pu_id_gpr_mem.v
 *	Date	: 2012-05-05T11:41:11+9:00
 *	Author	: toshinaga
 *
 *	Description :
 *		***
 *----------------------------------------------------------------------------*/

`include "config.h"

`include "stddef.h"
`include "pu.h"

module pu_id_gpr_mem(
	/******** Clock and Reset ********/
	input wire							clk,
	input wire							rst_,

	/******** Asynchronous Read Port 0 ********/
	input wire [`PuGprAddrBus]			rd0_addr,

	output wire [`WordDataBus]			rd0_data,

	/******** Asynchronous Read Port 1 ********/
	input wire [`PuGprAddrBus]			rd1_addr,

	output wire [`WordDataBus]			rd1_data,

	/******** Synchronous Write Port ********/
	input wire [`PuGprAddrBus]			wr_addr,
	input wire							wr_en,
	input wire [`WordDataBus]			wr_data
);

/*----------------------------------------------------------------------------*
 * Wire and Reg
 *----------------------------------------------------------------------------*/
	/******** Memory ********/
	reg [`WordDataBus]					mem[0:`PU_GPR_NUM-1];

	/******** Iterator ********/
	integer								i;

/*----------------------------------------------------------------------------*
 * Combinational Logic
 *----------------------------------------------------------------------------*/
	/******** Asynchronous Read Port 0 ********/
	assign rd0_data = mem[rd0_addr];

	/******** Asynchronous Read Port 1 ********/
	assign rd1_data = mem[rd1_addr];

/*----------------------------------------------------------------------------*
 * Sequential Logic
 *----------------------------------------------------------------------------*/
	/******** Synchronous Write Port ********/
	always @(posedge clk or negedge rst_) begin
		if (rst_ == `ENABLE_) begin // Reset
			for (i = 0; i < `PU_GPR_NUM; i = i + 1) begin
				mem[i]			<= #1 `WORD_DATA_W'h0;
			end
		end else begin // No Reset
			if (wr_en == `ENABLE) begin
				mem[wr_addr]	<= #1 wr_data;
			end
		end
	end

/*----------------------------------------------------------------------------*
 * Debug
 *----------------------------------------------------------------------------*/
`ifdef DEBUG
	/******** GPR ********/
	wire [`WordDataBus] GPR00_ZERO	= mem[0];
	wire [`WordDataBus] GPR01_AT	= mem[1];
	wire [`WordDataBus] GPR02_V0	= mem[2];
	wire [`WordDataBus] GPR03_V1	= mem[3];
	wire [`WordDataBus] GPR04_A0	= mem[4];
	wire [`WordDataBus] GPR05_A1	= mem[5];
	wire [`WordDataBus] GPR06_A2	= mem[6];
	wire [`WordDataBus] GPR07_A3	= mem[7];
	wire [`WordDataBus] GPR08_T0	= mem[8];
	wire [`WordDataBus] GPR09_T1	= mem[9];
	wire [`WordDataBus] GPR10_T2	= mem[10];
	wire [`WordDataBus] GPR11_T3	= mem[11];
	wire [`WordDataBus] GPR12_T4	= mem[12];
	wire [`WordDataBus] GPR13_T5	= mem[13];
	wire [`WordDataBus] GPR14_T6	= mem[14];
	wire [`WordDataBus] GPR15_T7	= mem[15];
	wire [`WordDataBus] GPR16_S0	= mem[16];
	wire [`WordDataBus] GPR17_S1	= mem[17];
	wire [`WordDataBus] GPR18_S2	= mem[17];
	wire [`WordDataBus] GPR19_S3	= mem[19];
	wire [`WordDataBus] GPR20_S4	= mem[20];
	wire [`WordDataBus] GPR21_S5	= mem[21];
	wire [`WordDataBus] GPR22_S6	= mem[22];
	wire [`WordDataBus] GPR23_S7	= mem[23];
	wire [`WordDataBus] GPR24_T8	= mem[24];
	wire [`WordDataBus] GPR25_T9	= mem[25];
	wire [`WordDataBus] GPR26_K0	= mem[26];
	wire [`WordDataBus] GPR27_K1	= mem[27];
	wire [`WordDataBus] GPR28_GP	= mem[28];
	wire [`WordDataBus] GPR29_SP	= mem[29];
	wire [`WordDataBus] GPR30_FP	= mem[30];
	wire [`WordDataBus] GPR31_RA	= mem[31];
`endif

endmodule

