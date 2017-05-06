/*----------------------------------------------------------------------------*
 *	SMIPS
 *
 *	File	: cbus.h
 *	Date	: 2012-05-05T11:41:11+9:00
 *	Author	: toshinaga
 *
 *	Description :
 *		***
 *----------------------------------------------------------------------------*/

`ifndef __CBUS_HEADER__
`define __CBUS_HEADER__

`define CBUS_CMD_W				3
`define CbusCmdBus				2:0
`define CBUS_CMD_NO				3'h0
`define CBUS_CMD_RD				3'h1
`define CBUS_CMD_WR				3'h2
`define CBUS_CMD_RN				3'h3
`define CBUS_CMD_WN				3'h4

`define CBUS_DATA_W				256
`define CbusDataBus				255:0

`define CBUS_DATA_BE_W			32
`define CbusDataBeBus			31:0


`endif

