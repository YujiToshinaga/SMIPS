/*----------------------------------------------------------------------------*
 *	SMIPS
 *
 *	File	: config.h
 *	Date	: 2012-05-05T11:41:11+9:00
 *	Author	: toshinaga
 *
 *	Description :
 *		***
 *----------------------------------------------------------------------------*/

`ifndef __CONFIG_HEADER__
`define __CONFIG_HEADER__

	/******** Default Nettype ********/
//`default_nettype				none

	/******** Timescale ********/
`timescale						1ns/1ns

	/******** Auto Setupt ********/
`ifdef	IMP_T0_CORE
`define T0_CORE_EN				1
`else
`define T0_CORE_EN				0
`endif
`ifdef	IMP_T0_VU
`define	T0_VU_EN				1
`else
`define	T0_VU_EN				0
`endif
`ifdef	IMP_T0_DIR
`define	T0_DIR_EN				1
`else
`define	T0_DIR_EN				0
`endif
`ifdef	IMP_T0_TMEM
`define	T0_TMEM_EN				1
`else
`define	T0_TMEM_EN				0
`endif
`ifdef	IMP_T0_XU
`define	T0_XU_EN				1
`else
`define	T0_XU_EN				0
`endif
`ifdef	IMP_T0_NI
`define	T0_NI_EN				1
`else
`define	T0_NI_EN				0
`endif

`ifdef	IMP_T1_CORE
`define T1_CORE_EN				1
`else
`define T1_CORE_EN				0
`endif
`ifdef	IMP_T1_VU
`define	T1_VU_EN				1
`else
`define	T1_VU_EN				0
`endif
`ifdef	IMP_T1_DIR
`define	T1_DIR_EN				1
`else
`define	T1_DIR_EN				0
`endif
`ifdef	IMP_T1_TMEM
`define	T1_TMEM_EN				1
`else
`define	T1_TMEM_EN				0
`endif
`ifdef	IMP_T1_XU
`define	T1_XU_EN				1
`else
`define	T1_XU_EN				0
`endif
`ifdef	IMP_T1_NI
`define	T1_NI_EN				1
`else
`define	T1_NI_EN				0
`endif

`ifdef	IMP_T2_CORE
`define T2_CORE_EN				1
`else
`define T2_CORE_EN				0
`endif
`ifdef	IMP_T2_VU
`define	T2_VU_EN				1
`else
`define	T2_VU_EN				0
`endif
`ifdef	IMP_T2_DIR
`define	T2_DIR_EN				1
`else
`define	T2_DIR_EN				0
`endif
`ifdef	IMP_T2_TMEM
`define	T2_TMEM_EN				1
`else
`define	T2_TMEM_EN				0
`endif
`ifdef	IMP_T2_XU
`define	T2_XU_EN				1
`else
`define	T2_XU_EN				0
`endif
`ifdef	IMP_T2_NI
`define	T2_NI_EN				1
`else
`define	T2_NI_EN				0
`endif

`ifdef	IMP_T3_CORE
`define T3_CORE_EN				1
`else
`define T3_CORE_EN				0
`endif
`ifdef	IMP_T3_VU
`define	T3_VU_EN				1
`else
`define	T3_VU_EN				0
`endif
`ifdef	IMP_T3_DIR
`define	T3_DIR_EN				1
`else
`define	T3_DIR_EN				0
`endif
`ifdef	IMP_T3_TMEM
`define	T3_TMEM_EN				1
`else
`define	T3_TMEM_EN				0
`endif
`ifdef	IMP_T3_XU
`define	T3_XU_EN				1
`else
`define	T3_XU_EN				0
`endif
`ifdef	IMP_T3_NI
`define	T3_NI_EN				1
`else
`define	T3_NI_EN				0
`endif

`ifdef	IMP_T4_CORE
`define T4_CORE_EN				1
`else
`define T4_CORE_EN				0
`endif
`ifdef	IMP_T4_VU
`define	T4_VU_EN				1
`else
`define	T4_VU_EN				0
`endif
`ifdef	IMP_T4_DIR
`define	T4_DIR_EN				1
`else
`define	T4_DIR_EN				0
`endif
`ifdef	IMP_T4_TMEM
`define	T4_TMEM_EN				1
`else
`define	T4_TMEM_EN				0
`endif
`ifdef	IMP_T4_XU
`define	T4_XU_EN				1
`else
`define	T4_XU_EN				0
`endif
`ifdef	IMP_T4_NI
`define	T4_NI_EN				1
`else
`define	T4_NI_EN				0
`endif

`ifdef	IMP_T5_CORE
`define T5_CORE_EN				1
`else
`define T5_CORE_EN				0
`endif
`ifdef	IMP_T5_VU
`define	T5_VU_EN				1
`else
`define	T5_VU_EN				0
`endif
`ifdef	IMP_T5_DIR
`define	T5_DIR_EN				1
`else
`define	T5_DIR_EN				0
`endif
`ifdef	IMP_T5_TMEM
`define	T5_TMEM_EN				1
`else
`define	T5_TMEM_EN				0
`endif
`ifdef	IMP_T5_XU
`define	T5_XU_EN				1
`else
`define	T5_XU_EN				0
`endif
`ifdef	IMP_T5_NI
`define	T5_NI_EN				1
`else
`define	T5_NI_EN				0
`endif

`ifdef	IMP_T6_CORE
`define T6_CORE_EN				1
`else
`define T6_CORE_EN				0
`endif
`ifdef	IMP_T6_VU
`define	T6_VU_EN				1
`else
`define	T6_VU_EN				0
`endif
`ifdef	IMP_T6_DIR
`define	T6_DIR_EN				1
`else
`define	T6_DIR_EN				0
`endif
`ifdef	IMP_T6_TMEM
`define	T6_TMEM_EN				1
`else
`define	T6_TMEM_EN				0
`endif
`ifdef	IMP_T6_XU
`define	T6_XU_EN				1
`else
`define	T6_XU_EN				0
`endif
`ifdef	IMP_T6_NI
`define	T6_NI_EN				1
`else
`define	T6_NI_EN				0
`endif

`ifdef	IMP_T7_CORE
`define T7_CORE_EN				1
`else
`define T7_CORE_EN				0
`endif
`ifdef	IMP_T7_VU
`define	T7_VU_EN				1
`else
`define	T7_VU_EN				0
`endif
`ifdef	IMP_T7_DIR
`define	T7_DIR_EN				1
`else
`define	T7_DIR_EN				0
`endif
`ifdef	IMP_T7_TMEM
`define	T7_TMEM_EN				1
`else
`define	T7_TMEM_EN				0
`endif
`ifdef	IMP_T7_XU
`define	T7_XU_EN				1
`else
`define	T7_XU_EN				0
`endif
`ifdef	IMP_T7_NI
`define	T7_NI_EN				1
`else
`define	T7_NI_EN				0
`endif

`ifdef	IMP_T8_CORE
`define T8_CORE_EN				1
`else
`define T8_CORE_EN				0
`endif
`ifdef	IMP_T8_VU
`define	T8_VU_EN				1
`else
`define	T8_VU_EN				0
`endif
`ifdef	IMP_T8_DIR
`define	T8_DIR_EN				1
`else
`define	T8_DIR_EN				0
`endif
`ifdef	IMP_T8_TMEM
`define	T8_TMEM_EN				1
`else
`define	T8_TMEM_EN				0
`endif
`ifdef	IMP_T8_XU
`define	T8_XU_EN				1
`else
`define	T8_XU_EN				0
`endif
`ifdef	IMP_T8_NI
`define	T8_NI_EN				1
`else
`define	T8_NI_EN				0
`endif

`ifdef	IMP_T9_CORE
`define T9_CORE_EN				1
`else
`define T9_CORE_EN				0
`endif
`ifdef	IMP_T9_VU
`define	T9_VU_EN				1
`else
`define	T9_VU_EN				0
`endif
`ifdef	IMP_T9_DIR
`define	T9_DIR_EN				1
`else
`define	T9_DIR_EN				0
`endif
`ifdef	IMP_T9_TMEM
`define	T9_TMEM_EN				1
`else
`define	T9_TMEM_EN				0
`endif
`ifdef	IMP_T9_XU
`define	T9_XU_EN				1
`else
`define	T9_XU_EN				0
`endif
`ifdef	IMP_T9_NI
`define	T9_NI_EN				1
`else
`define	T9_NI_EN				0
`endif

`ifdef	IMP_T10_CORE
`define T10_CORE_EN				1
`else
`define T10_CORE_EN				0
`endif
`ifdef	IMP_T10_VU
`define	T10_VU_EN				1
`else
`define	T10_VU_EN				0
`endif
`ifdef	IMP_T10_DIR
`define	T10_DIR_EN				1
`else
`define	T10_DIR_EN				0
`endif
`ifdef	IMP_T10_TMEM
`define	T10_TMEM_EN				1
`else
`define	T10_TMEM_EN				0
`endif
`ifdef	IMP_T10_XU
`define	T10_XU_EN				1
`else
`define	T10_XU_EN				0
`endif
`ifdef	IMP_T10_NI
`define	T10_NI_EN				1
`else
`define	T10_NI_EN				0
`endif

`ifdef	IMP_T11_CORE
`define T11_CORE_EN				1
`else
`define T11_CORE_EN				0
`endif
`ifdef	IMP_T11_VU
`define	T11_VU_EN				1
`else
`define	T11_VU_EN				0
`endif
`ifdef	IMP_T11_DIR
`define	T11_DIR_EN				1
`else
`define	T11_DIR_EN				0
`endif
`ifdef	IMP_T11_TMEM
`define	T11_TMEM_EN				1
`else
`define	T11_TMEM_EN				0
`endif
`ifdef	IMP_T11_XU
`define	T11_XU_EN				1
`else
`define	T11_XU_EN				0
`endif
`ifdef	IMP_T11_NI
`define	T11_NI_EN				1
`else
`define	T11_NI_EN				0
`endif

`ifdef	IMP_T12_CORE
`define T12_CORE_EN				1
`else
`define T12_CORE_EN				0
`endif
`ifdef	IMP_T12_VU
`define	T12_VU_EN				1
`else
`define	T12_VU_EN				0
`endif
`ifdef	IMP_T12_DIR
`define	T12_DIR_EN				1
`else
`define	T12_DIR_EN				0
`endif
`ifdef	IMP_T12_TMEM
`define	T12_TMEM_EN				1
`else
`define	T12_TMEM_EN				0
`endif
`ifdef	IMP_T12_XU
`define	T12_XU_EN				1
`else
`define	T12_XU_EN				0
`endif
`ifdef	IMP_T12_NI
`define	T12_NI_EN				1
`else
`define	T12_NI_EN				0
`endif

`ifdef	IMP_T13_CORE
`define T13_CORE_EN				1
`else
`define T13_CORE_EN				0
`endif
`ifdef	IMP_T13_VU
`define	T13_VU_EN				1
`else
`define	T13_VU_EN				0
`endif
`ifdef	IMP_T13_DIR
`define	T13_DIR_EN				1
`else
`define	T13_DIR_EN				0
`endif
`ifdef	IMP_T13_TMEM
`define	T13_TMEM_EN				1
`else
`define	T13_TMEM_EN				0
`endif
`ifdef	IMP_T13_XU
`define	T13_XU_EN				1
`else
`define	T13_XU_EN				0
`endif
`ifdef	IMP_T13_NI
`define	T13_NI_EN				1
`else
`define	T13_NI_EN				0
`endif

`ifdef	IMP_T14_CORE
`define T14_CORE_EN				1
`else
`define T14_CORE_EN				0
`endif
`ifdef	IMP_T14_VU
`define	T14_VU_EN				1
`else
`define	T14_VU_EN				0
`endif
`ifdef	IMP_T14_DIR
`define	T14_DIR_EN				1
`else
`define	T14_DIR_EN				0
`endif
`ifdef	IMP_T14_TMEM
`define	T14_TMEM_EN				1
`else
`define	T14_TMEM_EN				0
`endif
`ifdef	IMP_T14_XU
`define	T14_XU_EN				1
`else
`define	T14_XU_EN				0
`endif
`ifdef	IMP_T14_NI
`define	T14_NI_EN				1
`else
`define	T14_NI_EN				0
`endif

`ifdef	IMP_T15_CORE
`define T15_CORE_EN				1
`else
`define T15_CORE_EN				0
`endif
`ifdef	IMP_T15_VU
`define	T15_VU_EN				1
`else
`define	T15_VU_EN				0
`endif
`ifdef	IMP_T15_DIR
`define	T15_DIR_EN				1
`else
`define	T15_DIR_EN				0
`endif
`ifdef	IMP_T15_TMEM
`define	T15_TMEM_EN				1
`else
`define	T15_TMEM_EN				0
`endif
`ifdef	IMP_T15_XU
`define	T15_XU_EN				1
`else
`define	T15_XU_EN				0
`endif
`ifdef	IMP_T15_NI
`define	T15_NI_EN				1
`else
`define	T15_NI_EN				0
`endif

`ifdef IMP_CORE
`define CORE_EN					1
`else
`define CORE_EN					0
`endif

`ifdef IMP_VU
`define VU_EN					1
`else
`define VU_EN					0
`endif

`ifdef IMP_DIR
`define DIR_EN					1
`else
`define DIR_EN					0
`endif

`ifdef IMP_TMEM
`define TMEM_EN					1
`else
`define TMEM_EN					0
`endif

`ifdef IMP_XU
`define XU_EN					1
`else
`define XU_EN					0
`endif

`ifdef IMP_NI
`define NI_EN					1
`else
`define NI_EN					0
`endif

`ifdef IMP_ROUTER
`define ROUTER_EN				1
`else
`define ROUTER_EN				0
`endif

`endif

