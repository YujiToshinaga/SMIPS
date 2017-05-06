/*----------------------------------------------------------------------------*
 *	SMIPS
 *
 *	File	: pu_ia_itlb.v
 *	Date	: 2012-05-05T11:41:11+9:00
 *	Author	: toshinaga
 *
 *	Description :
 *		***
 *----------------------------------------------------------------------------*/

`include "config.h"

`include "stddef.h"
`include "pu.h"

module pu_ia_itlb(
	/******** Clock and Reset ********/
	input wire							clk,
	input wire							rst_, 

	/******** Thread Infomation ********/
	input wire [`PuTidBus]				tid,
	input wire [`PuTmodeBus]			tmode,

	/******** ITLB Infomation ********/
	input wire							on,

	/******** ITLB Hardware Control ********/
	input wire [`PuIcTagBus]			vtag,

	output wire [`PuIcTagBus]			ptag,
	output wire							nc,

	/******** ITLB Software Control ********/

	/******** Exception ********/
	output wire							tmp
);

	// Not Implemented
	reg [`PuIcTagBus]					ff_vtag;

	assign ptag		= ff_vtag;
	assign nc		= `DISABLE;
	assign tmp		= `DISABLE;

	always @(posedge clk or negedge rst_) begin
		if (rst_ == `ENABLE_) begin
			ff_vtag <= #1 `PU_IC_TAG_W'h0;
		end else begin
			ff_vtag <= #1 vtag;
		end
	end

/*----------------------------------------------------------------------------*
 * Wire and Reg
 *----------------------------------------------------------------------------*/

/*----------------------------------------------------------------------------*
 * Combinatorial Logic
 *----------------------------------------------------------------------------*/

/*----------------------------------------------------------------------------*
 * Sequential Logic
 *----------------------------------------------------------------------------*/
	/********  ********/

endmodule

