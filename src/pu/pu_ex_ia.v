/*----------------------------------------------------------------------------*
 *	SMIPS
 *
 *	File	: pu_ex_ia.v
 *	Date	: 2012-05-05T11:41:11+9:00
 *	Author	: toshinaga
 *
 *	Description :
 *		***
 *----------------------------------------------------------------------------*/

`include "config.h"

`include "stddef.h"
`include "pu.h"

module pu_ex_ia(
	/******** Input Signal ********/
	input wire [`PuIaOpBus]				op,
	input wire [`WordDataBus]			in0,
	input wire [`WordDataBus]			in1,

	/******** Output Signal ********/
	output reg [`WordDataBus]			out,
	output reg [`WordDataBus]			hi,
	output reg [`WordDataBus]			lo,
	output reg							ovf
);

/*----------------------------------------------------------------------------*
 * Wire and Reg
 *----------------------------------------------------------------------------*/
	/********  ********/

/*----------------------------------------------------------------------------*
 * Module Instance
 *----------------------------------------------------------------------------*/
	/********  ********/

/*----------------------------------------------------------------------------*
 * Combinational Logic
 *----------------------------------------------------------------------------*/
	/********  ********/
	always @(*) begin
		/******** Default Value ********/
		out	= `WORD_DATA_W'h0;
		hi	= `WORD_DATA_W'h0;
		lo	= `WORD_DATA_W'h0;
		ovf	= `DISABLE;

		case (op)
		`PU_IA_OP_THA : begin
			out = in0;
		end
		`PU_IA_OP_SLL : begin
			out = in1 << in0;
		end
		`PU_IA_OP_SRL : begin
			out = in1 >> in0;
		end
		`PU_IA_OP_SRA : begin
			out = in1 >>> in0;
		end
		`PU_IA_OP_ADD : begin
			out = in0 + in1;
		end
		`PU_IA_OP_ADDU : begin
			out = in0 + in1;
		end
		`PU_IA_OP_SUB : begin
			out = in0 - in1;
		end
		`PU_IA_OP_SUBU : begin
			out = in0 - in1;
		end
		`PU_IA_OP_AND : begin
			out = in0 & in1;
		end
		`PU_IA_OP_OR : begin
			out = in0 | in1;
		end
		`PU_IA_OP_XOR : begin
			out = in0 ^ in1;
		end
		`PU_IA_OP_NOR : begin
			out = ~(in0 | in1);
		end
		`PU_IA_OP_SLT : begin
			if ($signed(in0) < $signed(in1)) begin
				out = `WORD_DATA_W'h1;
			end else begin
				out = `WORD_DATA_W'h0;
			end
		end
		`PU_IA_OP_SLTU : begin
			if (in0 < in1) begin
				out = `WORD_DATA_W'h1;
			end else begin
				out = `WORD_DATA_W'h0;
			end
		end
		`PU_IA_OP_THHI : begin
			hi = in0;
		end
		`PU_IA_OP_THLO : begin
			lo = in0;
		end
`ifdef IMP_MULT
		`PU_IA_OP_MULT : begin
			{hi, lo} = in0 * in1;
		end
		`PU_IA_OP_MULTU : begin
			{hi, lo} = in0 * in1;
		end
`else
		`PU_IA_OP_MULT : begin
			hi = `WORD_DATA_W'h0;
			lo = `WORD_DATA_W'h0;
		end
		`PU_IA_OP_MULTU : begin
			hi = `WORD_DATA_W'h0;
			lo = `WORD_DATA_W'h0;
		end
`endif
`ifdef IMP_DIV
		`PU_IA_OP_DIV : begin
			hi	= in0 % in1;
			lo	= in0 / in1;
		end
		`PU_IA_OP_DIVU : begin
			hi	= in0 % in1;
			lo	= in0 / in1;
		end
`else
		`PU_IA_OP_DIV : begin
			hi = `WORD_DATA_W'h0;
			lo = `WORD_DATA_W'h0;
		end
		`PU_IA_OP_DIVU : begin
			hi = `WORD_DATA_W'h0;
			lo = `WORD_DATA_W'h0;
		end
`endif
		endcase
	end

endmodule

