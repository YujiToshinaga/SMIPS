/*----------------------------------------------------------------------------*
 *	SMIPS
 *
 *	File	: stddef.h
 *	Date	: 2012-05-05T11:41:11+9:00
 *	Author	: toshinaga
 *
 *	Description :
 *		***
 *----------------------------------------------------------------------------*/

`ifndef __STDDEF_HEADER__
`define __STDDEF_HEADER__

	/******** Standard Value ********/
`define DISABLE					1'b0	// Disable
`define ENABLE					1'b1	// Enable
`define DISABLE_				1'b1	// Disable (Active Low)
`define ENABLE_					1'b0	// Enable (Active Low)

`define LOW						1'b0	// Low
`define HIGH					1'b1	// High

//`define FALSE					1'b0	// False (Low)
//`define TRUE					1'b1	// True	(High)

//`define READ					1'b0	// Read
//`define WRITE					1'b1	// Write

//`define READ_					1'b1	// Read
//`define WRITE_				1'b0	// Write

//`define FREE					1'b0	// Free
//`define BUSY					1'b1	// Busy

//`define FREE_					1'b1	// Free
//`define BUSY_					1'b0	// Busy

`define NULL					0		// Null

	/******** Address ********/
	// 32 bit Address Space
	// Byte Address
`define BYTE_ADDR_W				32		// Byte Address Width
`define ByteAddrBus				31:0	// Byte Address Bus
`define ByteAddrLoc				31:0	// Byte Address Location

	// Half Word Address
`define HWORD_ADDR_W			31		// Half Word Address Width
`define HwordAddrBus			30:0	// Half Word Address Bus
`define HwordAddrLoc			31:1	// Half Word Address Location

	// Word Address
`define WORD_ADDR_W				30		// Word Address Width
`define WordAddrBus				29:0	// Word Address Bus
`define WordAddrLoc				31:2	// Word Address Location

	// Word Byte Offset
`define WORD_BO_W				2		// Byte Offset Width
`define WordBoBus				1:0		// Byte Offset Bus
`define WordBoLoc				1:0		// Byte Offset Location
`define WORD_BO_BYTE_0			2'b00
`define WORD_BO_BYTE_1			2'b01
`define WORD_BO_BYTE_2			2'b10
`define WORD_BO_BYTE_3			2'b11
`define WORD_BO_HWORD_0			2'b00
`define WORD_BO_HWORD_1			2'b10
`define WORD_BO_WORD			2'b00

	// Word Half Word Offset
`define WORD_HO_W				1		// Half Word Offset Addr Width
`define WordHoBus				0:0		// Half Word Offset Addr Bus
`define WordHoLoc				1:1		// Half Word Offset Addr Location
`define WORD_HO_HWORD_0			1'b0
`define WORD_HO_HWORD_1			1'b1
`define WORD_HO_WORD			1'b0

	/******** Data ********/
	// Big Endian

	// Byte Data
`define BYTE_DATA_W				8		// Byte Data Width
`define ByteDataBus				7:0		// Byte Data Bus
`define BYTE_DATA_MSB			7		// Byte Data MSB
`define BYTE_DATA_LSB			0		// Byte Data LSB

	// Half Word Data
`define HWORD_DATA_W			16		// Half Word Data Width
`define HwordDataBus			15:0	// Half Word Data Bus
`define HWORD_DATA_MSB			15		// Half Word Data MSB
`define HWORD_DATA_LSB			0		// Half Word Data LSB

	// Word Data
`define WORD_DATA_W				32		// Word Data Width
`define WordDataBus				31:0	// Word Data Bus
`define WORD_DATA_MSB			31		// Word Data MSB
`define WORD_DATA_LSB			0		// Word Data LSB

	// Word Data : Byte Location
`define WordDataByte0Loc		31:24	// Byte 0 Location
`define WORD_DATA_BYTE_0_MSB	31		// Byte 0 MSB
`define WORD_DATA_BYTE_0_LSB	24		// Byte 0 LSB
`define WordDataByte1Loc		23:16	// Byte 1 Location
`define WORD_DATA_BYTE_1_MSB	23		// Byte 1 MSB
`define WORD_DATA_BYTE_1_LSB	16		// Byte 1 LSB
`define WordDataByte2Loc		15:8	// Byte 2 Location
`define WORD_DATA_BYTE_2_MSB	15		// Byte 2 MSB
`define WORD_DATA_BYTE_2_LSB	8		// Byte 2 LSB
`define WordDataByte3Loc		7:0		// Byte 3 Location
`define WORD_DATA_BYTE_3_MSB	7		// Byte 3 MSB
`define WORD_DATA_BYTE_3_LSB	0		// Byte 3 LSB

	// Word Data : Half Word Location
`define WordDataHword0Loc		31:16	// Half Word 1 Location
`define WORD_DATA_HWORD_0_MSB	31		// Half Word 1 MSB
`define WORD_DATA_HWORD_0_LSB	16		// Half Word 1 LSB
`define WordDataHword1Loc		15:0	// Half Word 0 Location
`define WORD_DATA_HWORD_1_MSB	15		// Half Word 0 MSB
`define WORD_DATA_HWORD_1_LSB	0		// Half Word 0 LSB

	// Word Data : Byte Enable
`define WORD_DATA_BE_W			4		// Byte Enable Width
`define WordDataBeBus			3:0		// Byte Enable Bus

`define WORD_DATA_BE_DISABLE	4'b0000	// Byte Enable Disable
`define WORD_DATA_BE_BYTE_0		4'b1000	// Byte Enable Byte 0
`define WORD_DATA_BE_BYTE_1		4'b0100	// Byte Enable Byte 1
`define WORD_DATA_BE_BYTE_2		4'b0010	// Byte Enable Byte 2
`define WORD_DATA_BE_BYTE_3		4'b0001	// Byte Enable Byte 3
`define WORD_DATA_BE_HWORD_0	4'b1100	// Byte Enable Half Word 0
`define WORD_DATA_BE_HWORD_1	4'b0011	// Byte Enable Half Word 1
`define WORD_DATA_BE_WORD		4'b1111	// Byte Enable Word

`define WORD_DATA_BE_DISABLE_	4'b1111	// Byte Enable Disable
`define WORD_DATA_BE_BYTE_0_	4'b0111	// Byte Enable Byte 0
`define WORD_DATA_BE_BYTE_1_	4'b1011	// Byte Enable Byte 1
`define WORD_DATA_BE_BYTE_2_	4'b1101	// Byte Enable Byte 2
`define WORD_DATA_BE_BYTE_3_	4'b1110	// Byte Enable Byte 3
`define WORD_DATA_BE_HWORD_0_	4'b0011	// Byte Enable Half Word 0
`define WORD_DATA_BE_HWORD_1_	4'b1100	// Byte Enable Half Word 1
`define WORD_DATA_BE_WORD_		4'b0000	// Byte Enable Word

	// Word Data : Half Word Enable
`define WORD_DATA_HE_W			2		// Half Word Enable Width
`define WordDataHeBus			1:0		// Half Word Enable Bus

`define WORD_DATA_HE_DISABLE	2'b00	// Half Word Enable Disable
`define WORD_DATA_HE_HWORD_0	2'b10	// Half Word Enable Half Word 0
`define WORD_DATA_HE_HWORD_1	2'b01	// Half Word Enable Half Word 1
`define WORD_DATA_HE_WORD		2'b11	// Half Word Enable Word

`define WORD_DATA_HE_DISABLE_	2'b11	// Half Word Enable Disable
`define WORD_DATA_HE_HWORD_0_	2'b01	// Half Word Enable Half Word 0
`define WORD_DATA_HE_HWORD_1_	2'b10	// Half Word Enable Half Word 1
`define WORD_DATA_HE_WORD_		2'b00	// Half Word Enable Word

	// Double Word Data
`define DWORD_DATA_W			64		// Double Word Data Width
`define DwordDataBus			63:0	// Double Word Data Bus
`define DWORD_DATA_MSB			63		// Double Word Data MSB
`define DWORD_DATA_LSB			0		// Double Word Data LSB

	// Quadruple Word Data
`define QWORD_DATA_W			128		// Quadruple Word Data Width
`define QwordDataBus			127:0	// Quadruple Word Data Bus
`define QWORD_DATA_MSB			127		// Quadruple Word Data MSB
`define QWORD_DATA_LSB			0		// Quadruple Word Data LSB

`endif

