/*----------------------------------------------------------------------------*
 *	SMIPS
 *
 *	File	: pu_da_dtlb.v
 *	Date	: 2012-05-05T11:41:11+9:00
 *	Author	: toshinaga
 *
 *	Description :
 *		***
 *----------------------------------------------------------------------------*/

`include "config.h"

`include "stddef.h"
`include "pu.h"

module pu_da_dtlb(
	/******** Clock and Reset ********/
	input wire							clk,
	input wire							rst_, 

	/********  ********/
	input wire [`PuTidBus]				tid,
	input wire [`PuTmodeBus]			tmode,

	/******** DTLB Infomation ********/
	input wire							on,

	/******** DTLB Hardware Control ********/
	input wire [`PuDcTagBus]			vtag,

	output wire [`PuDcTagBus]			ptag,
	output wire							nc,

	/******** DTLB Software Control ********/

	/********  ********/
	output wire							tmp
);

	// Not Implemented
	reg [`PuDcTagBus]					ff_vtag;

	assign ptag		= ff_vtag;
	assign nc		= `DISABLE;
	assign tmp		= `DISABLE;

	always @(posedge clk or negedge rst_) begin
		if (rst_ == `ENABLE_) begin
			ff_vtag <= #1 `PU_DC_TAG_W'h0;
		end else begin
			ff_vtag <= #1 vtag;
		end
	end

/*----------------------------------------------------------------------------*
 * Wire and Reg
 *----------------------------------------------------------------------------*/
	/********  ********/

endmodule

