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

`ifndef __L2C_HEADER__
`define __L2C_HEADER__

	/********  ********/
`define L2C_WAY_NUM				4
`define L2C_WAY_W				2
`define L2cWayBus				1:0

	/********  ********/
`define L2C_TAG_W				18
`define L2cTagBus				17:0
`define L2cTagLoc				31:14

`define L2C_INDEX_NUM			512
`define L2C_INDEX_W				9
`define L2cIndexBus				8:0
`define L2cIndexLoc				13:5

`define L2C_XU_CMD_W			4
`define L2cXuCmdBus				3:0
`define L2C_XU_CMD_NO			4'h0
//`define L2C_XU_CMD_RD			4'h1
//`define L2C_XU_CMD_UP			4'h2
//`define L2C_XU_CMD_RX			4'h3
`define L2C_XU_CMD_RDR			4'h4
`define L2C_XU_CMD_UPR			4'h5
`define L2C_XU_CMD_RXR			4'h6
`define L2C_XU_CMD_RDP			4'h7
`define L2C_XU_CMD_RXP			4'h8
`define L2C_XU_CMD_INV			4'h9
//`define L2C_XU_CMD_FLUSH		4'ha
//`define L2C_XU_CMD_RN			4'hb
//`define L2C_XU_CMD_WN			4'hc
`define L2C_XU_CMD_RNR			4'hd
`define L2C_XU_CMD_WNR			4'he

`endif

