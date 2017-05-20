/*----------------------------------------------------------------------------*
 *	SMIPS
 *
 *	File	: cpu.h
 *	Date	: 2012-05-05T11:41:11+9:00
 *	Author	: toshinaga
 *
 *	Description :
 *		***
 *----------------------------------------------------------------------------*/

`ifndef __CORE_HEADER__
	`define __CORE_HEADER__

	/********  ********/
`define CORE_UID_W				2
`define CoreUidBus				1:0

	/********  ********/
`define CORE_ADDR_W				27
`define CoreAddrBus				26:0
`define CoreAddrLoc				31:5

`define CORE_OFFSET_W			5
`define CoreOffsetBus			4:0
`define CoreOffsetLoc			4:0

`define CORE_OFFSET_BADDR_W		4
`define CoreOffsetBaddrBus		4:0
`define CoreOffsetBaddrLoc		4:0

`define CORE_OFFSET_HADDR_W		4
`define CoreOffsetHaddrBus		3:0
`define CoreOffsetHaddrLoc		4:1

`define CORE_OFFSET_WADDR_W		3
`define CoreOffsetWaddrBus		2:0
`define CoreOffsetWaddrLoc		4:2

`define CoreTileIdLoc			26:23

`endif

