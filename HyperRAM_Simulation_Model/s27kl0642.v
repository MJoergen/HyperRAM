///////////////////////////////////////////////////////////////////////////////
//  File name : s27kl0642.v
///////////////////////////////////////////////////////////////////////////////
//  Copyright (C) 2020 Cypress Semiconductor.
//
//  MODIFICATION HISTORY :
//
//  version:  | author:        |   date:    | changes made:
//    V1.0     VINI			     27 Feb 19    Initial release
//    V2.0     VINI              13 Jan 20    updated the AC specs
//											  Fixed latency issues
//											  fixed data mismatch at higher 200MHz
//											  fixed Hybrid sleep and DPD entry &exit 
//											  Added Partial Refresh
//											  Added Refresh Interval and variable latency feature
//											  Added MPN based AC characteristics selection

											  
//
///////////////////////////////////////////////////////////////////////////////
///  PART DESCRIPTION:
//
//  Library:        Cypress
//  Technology:     RAM
//  Part:           S27KL0642
//	spec #:			002-26518
//
//  Description:   Reduced Pin Count Pseudo Static RAM,
//                 64Mb high-speed CMOS 3.0 and 1.8 Volt Core, x8 data bus
//
//
//////////////////////////////////////////////////////////////////////////////
//  Comments :
//      For correct simulation, simulator resolution should be set to 1 ps
//		Model validated using ModelSim (vsim)SE 10.1
//
//////////////////////////////////////////////////////////////////////////////
//  Known Bugs:
//		1. Decars functionality is not implemented
//      2. diferential clock is not used for functionality
//		3. a 1ps of delay on DQ, with respect to RWDS observed for lower frequency access. 
//		4. an additinal 1ps may require for tRP in simulation. 
//		5. Partial refresh uses a 64-bit variable to record the time. partial refresh simulation may not work properly if simulation time exceeds the 64bit value. 
//
//////////////////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////
// MODULE DECLARATION                                                       //
//////////////////////////////////////////////////////////////////////////////
`timescale 1 ps/1 ps

//`define S27KS0642GABHI
//`define S27KS0642DPBHI
//`define S27KL0642GABHI
//`define S27KL0642DPBHI

`ifdef S27KS0642GABHI
	`define FREQ_200MHz_1P8V
	`define INDUSTRIAL
`elsif S27KS0642DPBHI
	`define FREQ_166MHz_1P8V
	`define INDUSTRIAL	
`elsif S27KL0642GABHI
	`define FREQ_200MHz_3P3V 
	`define INDUSTRIAL
`elsif S27KL0642DPBHI
	`define FREQ_166MHz_3P3V
	`define INDUSTRIAL
`else // IS66WVH8M8BLL-100B1LI
	`define INDUSTRIAL
`endif	


module s27kl0642
    (
    DQ7      ,
    DQ6      ,
    DQ5      ,
    DQ4      ,
    DQ3      ,
    DQ2      ,
    DQ1      ,
    DQ0      ,
    RWDS     ,

    CSNeg    ,
    CK       ,
	CKn		 ,
    RESETNeg
    );


`ifdef FREQ_200MHz_1P8V
    `define CONFIG_REG0_DEFAULT 16'h8F2F
	`define tDSV           		5000 //tDSZ,tDSV
	`define tCKDS              	5000 //tCKDS
	`define tCKD               	5000 //tCKD,tCKDS
	`define tCKDI				4200
	`define tCKDSR				5500
			//tsetup values
	`define tCSS          		4000  //tCSS  edge /
	`define tIS            		500  //tIS

			//thold values
	`define tCSH           		0  //tCSH  edge 
	`define tIH             	500  //tIH
	`define tRH    				200000  //tRH

	`define tRWR       			35000  //tRWR

			//tpw values: pulse width
	`define tCL           		2500 //tCL 50% of the min clock period
	`define tCH           		2500 //tCH 50% of the min clock period
	`define tCSHI        		6e3 //tCSHI
	`define tRP     			200e3 //tRP
	`define tACC				35e3
	`define tOZ					5000
	`define tDSZ				5000
	`define tDQLZ				0
	`define tRFH				35e3  //refresh time
			//tperiod values
	`define tCK              	5000//tCK
//-------------------------------------------------------------
`elsif FREQ_166MHz_3P3V
    `define CONFIG_REG0_DEFAULT 16'h8F2F
	`define tDSV           		12000 //tDSV
	`define tCKDS              	7000 //tCKDS
	`define tCKD               	7000 //tCKD,tCKDS
	`define tCKDI				5600
	`define tDSZ				7000
	`define tCKDSR				7000
			//tsetup values
	`define tCSS          		3000  //tCSS  edge /
	`define tIS            		600  //tIS

			//thold values
	`define tCSH           		0  //tCSH  edge 
	`define tIH             	600  //tIH
	`define tRH    				200000  //tRH

	`define tRWR       			36000  //tRWR

			//tpw values: pulse width
	`define tCL           		3000 //tCL 50% of the min clock period
	`define tCH           		3000 //tCH 50% of the min clock period
	`define tCSHI        		6e3 //tCSHI
	`define tRP     			2e5 //tRP
	`define tACC				36e3
	`define tOZ					7000
	`define tDQLZ				0
	`define tRFH				36e3  //refresh time
	
			//tperiod values
	`define tCK              	6000//tCK

`elsif FREQ_200MHz_3P3V
    `define CONFIG_REG0_DEFAULT 16'h8F2F
	`define tDSV           		6500 //tDSZ,tDSV
	`define tCKDS              	6500 //tCKDS
	`define tCKD               	6500 //tCKD,tCKDS
	`define tCKDI				5700
	`define tCKDSR				7000
			//tsetup values
	`define tCSS          		4000  //tCSS  edge /
	`define tIS            		500  //tIS

			//thold values
	`define tCSH           		0  //tCSH  edge 
	`define tIH             	500  //tIH
	`define tRH    				200000  //tRH

	`define tRWR       			35000  //tRWR

			//tpw values: pulse width
	`define tCL           		2500 //tCL 50% of the min clock period
	`define tCH           		2500 //tCH 50% of the min clock period
	`define tCSHI        		6e3 //tCSHI
	`define tRP     			2e5 //tRP
	`define tACC				35e3
	`define tOZ					6500
	`define tDSZ				6500
	`define tDQLZ				0
	`define tRFH				35e3  //refresh time
	
			//tperiod values
	`define tCK              	5000//tCK
//-------------------------------------------------------------
`elsif FREQ_166MHz_1P8V
    `define CONFIG_REG0_DEFAULT 16'h8F2F
	`define tDSV           		12000 //tDSV
	`define tCKDS              	5500 //tCKDS
	`define tCKD               	5500 //tCKD,tCKDS
	`define tCKDI				4600
	`define tDSZ				6000
	`define tCKDSR				5500
			//tsetup values
	`define tCSS          		3000  //tCSS  edge /
	`define tIS            		600  //tIS

			//thold values
	`define tCSH           		0  //tCSH  edge 
	`define tIH             	600  //tIH
	`define tRH    				200000  //tRH

	`define tRWR       			36000  //tRWR	

			//tpw values: pulse width
	`define tCL           		3000 //tCL 50% of the min clock period
	`define tCH           		3000 //tCH 50% of the min clock period
	`define tCSHI        		6e3 //tCSHI
	`define tRP     			2e5 //tRP
	`define tACC				36e3
	`define tOZ					6000
	`define tDQLZ				0
	`define tRFH				36e3  //refresh time
	
			//tperiod values
	`define tCK              	6000//tCK
`else // IS66WVH8M8BLL-100B1LI
    `define CONFIG_REG0_DEFAULT 16'h8F1F
	`define tDSV           		6000 //tDSZ,tDSV
	`define tCKDS              	4000 //tCKDS
	`define tCKD               	4000 //tCKD,tCKDS
	`define tCKDI				2900
	`define tCKDSR				5500
			//tsetup values
	`define tCSS          		3000  //tCSS  edge /
	`define tIS            		1000  //tIS

			//thold values
	`define tCSH           		0  //tCSH  edge 
	`define tIH             	1000  //tIH
	`define tRH    				40000  //tRH

	`define tRWR       			40000  //tRWR

			//tpw values: pulse width
	`define tCL           		5000 //tCL 50% of the min clock period
	`define tCH           		5000 //tCH 50% of the min clock period
	`define tCSHI        		10e3 //tCSHI
	`define tRP     			200e3 //tRP
	`define tACC				40e3
	`define tOZ					3500
	`define tDSZ				3500
	`define tDQLZ				0
	`define tRFH				40e3  //refresh time
			//tperiod values
	`define tCK              	10000//tCK
`endif

`ifdef INDUSTRIAL
	`define DRI					2'h1
	`define tCSM        		4e6  //tCSM
`elsif INDUSTRIAL_PLUS
	`define DRI					2'h2
	`define tCSM        		1e6  //tCSM
`endif
////////////////////////////////////////////////////////////////////////
// Port / Part Pin Declarations
////////////////////////////////////////////////////////////////////////
    inout  DQ7;
    inout  DQ6;
    inout  DQ5;
    inout  DQ4;
    inout  DQ3;
    inout  DQ2;
    inout  DQ1;
    inout  DQ0;
    inout  RWDS;

    input  CSNeg;
    input  CK;
	input  CKn;
    input  RESETNeg;

    // interconnect path delay signals
    wire CSNeg_ipd;
    wire CK_ipd;
    wire RESETNeg_ipd;
    wire DQ7_ipd;
    wire DQ6_ipd;
    wire DQ5_ipd;
    wire DQ4_ipd;
    wire DQ3_ipd;
    wire DQ2_ipd;
    wire DQ1_ipd;
    wire DQ0_ipd;
    wire RWDS_ipd;

    wire [7:0] Din;
    assign Din = { DQ7_ipd,
                   DQ6_ipd,
                   DQ5_ipd,
                   DQ4_ipd,
                   DQ3_ipd,
                   DQ2_ipd,
                   DQ1_ipd,
                   DQ0_ipd};

    wire [7:0] Dout;
    assign Dout = { DQ7,
                    DQ6,
                    DQ5,
                    DQ4,
                    DQ3,
                    DQ2,
                    DQ1,
                    DQ0 };
    wire RWDSin;
    assign RWDSin = RWDS_ipd;

    //  internal delays
    reg HS_in           = 0;
    reg HS_out          = 0;
    reg DPD_in          = 0;
    reg DPD_out         = 0;
    reg RPH_in          = 0;
    reg RPH_out         = 0;
    reg REF_in          = 0;
    reg REF_out         = 0;
    reg PO_in           = 0;
    reg PO_out          = 0;

    wire   DPDExt_in;       // DPD Exit event
    reg    DPDExt_out  = 0; // DPD Exit event confirmed
    reg    DPDExt      = 0; // DPD Exit event detected

    // event control registers
    reg rising_edge_PoweredUp  = 0;
    reg rising_edge_CKDiff     = 0;
    reg falling_edge_CKDiff    = 0;
    reg rising_edge_CSNeg      = 0;
    reg falling_edge_CSNeg     = 0;
    reg rising_edge_REF_out    = 0;
    reg rising_edge_PO_out     = 0;
    reg rising_edge_RPH_out    = 0;
    reg rising_edge_DPD_in     = 0;
    reg rising_edge_DPD_out    = 0;
    reg rising_edge_HS_in     = 0;
    reg rising_edge_HS_out    = 0;
    reg rising_edge_RESETNeg   = 0;
    reg falling_edge_RESETNeg  = 0;
    reg rising_edge_glitch_rwds= 0;

	integer tACC_delay = 0;
    integer DQt_01;
    integer RWDSt_01;
    integer RWDSRt_01;
    time CK_cycle = 0;
    time prev_CK;
	reg tacc_start = 1'b0;
    reg glitch_dq = 1'b0;
    reg glitch_rwds = 1'b0;
    reg glitch_rwdsR = 1'b0;
    reg Viol = 1'b0;

    reg [7:0] Dout_zd = 8'bzzzzzzzz;
    reg [7:0] Dout_zdp = 8'bzzzzzzzz;
    reg [7:0] Dout_zdn = 8'bzzzzzzzz;
    reg RWDSout_zd = 1'bz;
    reg RWDS_zdp = 1'bz;
    reg RWDS_zdn = 1'bz;

	reg DQp_latch = 1'b0;
	reg DQn_latch = 1'b0;
	
    wire  DQ7_zd   ;
    wire  DQ6_zd   ;
    wire  DQ5_zd   ;
    wire  DQ4_zd   ;
    wire  DQ3_zd   ;
    wire  DQ2_zd   ;
    wire  DQ1_zd   ;
    wire  DQ0_zd   ;

    assign {DQ7_zd,
            DQ6_zd,
            DQ5_zd,
            DQ4_zd,
            DQ3_zd,
            DQ2_zd,
            DQ1_zd,
            DQ0_zd  } = Dout_zd;

    wire RWDS_zd;
    assign RWDS_zd = RWDSout_zd;

    reg [7:0] Dout_zd_tmp = 8'bzzzzzzzz;
    reg RWDSout_zd_tmp = 1'bz;

    reg [7:0] Dout_zd_latchH ;
    reg [7:0] Dout_zd_latchL ;
    reg RWDS_zd_latchH ;
    reg RWDS_zd_latchL ;

    wire RESETNeg_pullup;
    assign RESETNeg_pullup = (RESETNeg === 1'bZ) ? 1 : RESETNeg;

    wire CKDiff;
    reg RW     = 0;

    reg REFCOLL = 0;
    reg REFCOLL_ACTIV = 0; // = 1 : refresh collision occured

    reg t_RWR_CHK = 1'b0;

    parameter UserPreload     = 1;
    parameter mem_file_name   = "none";

    parameter TimingModel = "S27KS0642GAXXXXXX";//do not change. identical for all device options

    parameter PartID   = "S27KL0642";//do not change. identical for all device options
    parameter MaxData  = 16'hFFFF;
    parameter MemSize  = 25'h3FFFFF;
	parameter no_of_rows = 8192;
    parameter HiAddrBit = 34;
    parameter AddrRANGE = 25'h3FFFFF;

	integer PartialRefresh_Array[0:7][1:0];
	wire temp;
///////////////////////////////////////////////////////////////////////////////
//Interconnect Path Delay Section
///////////////////////////////////////////////////////////////////////////////
    buf   (DQ7_ipd , DQ7 );
    buf   (DQ6_ipd , DQ6 );
    buf   (DQ5_ipd , DQ5 );
    buf   (DQ4_ipd , DQ4 );
    buf   (DQ3_ipd , DQ3 );
    buf   (DQ2_ipd , DQ2 );
    buf   (DQ1_ipd , DQ1 );
    buf   (DQ0_ipd , DQ0 );
    buf   (RWDS_ipd , RWDS );

    buf   (CK_ipd       , CK      );
    buf   (RESETNeg_ipd , RESETNeg);
    buf   (CSNeg_ipd    , CSNeg   );


///////////////////////////////////////////////////////////////////////////////
// Propagation  delay Section
///////////////////////////////////////////////////////////////////////////////
    nmos   (DQ7 ,   DQ7_zd  , 1);
    nmos   (DQ6 ,   DQ6_zd  , 1);
    nmos   (DQ5 ,   DQ5_zd  , 1);
    nmos   (DQ4 ,   DQ4_zd  , 1);
    nmos   (DQ3 ,   DQ3_zd  , 1);
    nmos   (DQ2 ,   DQ2_zd  , 1);
    nmos   (DQ1 ,   DQ1_zd  , 1);
    nmos   (DQ0 ,   DQ0_zd  , 1);
    nmos   (RWDS ,  RWDS_zd , 1);

    wire Dout_Z;
    assign Dout_Z = Dout_zd==8'bzzzzzzzz;

    wire RWDSout_Z;
    assign RWDSout_Z = RWDSout_zd==1'bz & RW == 0;
    //assign RWDS_zd = RWDSout_Z;

    wire tRWR_CHK;
    assign tRWR_CHK = t_RWR_CHK;

	real REFinterval;
    specify

        // tpd delays
    specparam  tpd_CSNeg_RWDSn          = `tDSV; //tDSZ,tDSV
	specparam  tpd_CSNeg_RWDSp			= `tDSZ;
    specparam  tpd_CK_RWDS              = `tCKDS; //tCKDS
    specparam  tpd_CSNeg_DQ0            = `tOZ;//(`tCSS - `tIS); //(tCSS - tIS)
    specparam  tpd_CK_DQ0               = `tCKD; //tCKD,tCKDS

        //tsetup values
    specparam  tsetup_CSNeg_CK          = `tCSS;  //tCSS  edge /
    specparam  tsetup_DQ0_CK            = `tIS;  //tIS

        //thold values
    specparam  thold_CSNeg_CK           = `tCSH;  //tCSH  edge 
    specparam  thold_DQ0_CK             = `tIH;  //tIH
    specparam  thold_CSNeg_RESETNeg     = `tRH;  //tRH

    specparam  trecovery_CSNeg_CK       = `tRWR;  //tRWR
    specparam  tskew_CSNeg_CSNeg        = `tCSM;  //tCSM	

        //tpw values: pulse width
    specparam  tpw_CK_negedge           = `tCL; //tCL
    specparam  tpw_CK_posedge           = `tCH; //tCH
    specparam  tpw_CSNeg_posedge        = `tCSHI; //tCSHI
    specparam  tpw_RESETNeg_negedge     = `tRP; //tRP
	specparam  tACC_device				= `tACC;	
        //tperiod values
    specparam  tperiod_CK               = `tCK; //tCK

     //tdevice values: values for internal delays
     // power-on reset
    specparam tdevice_VCS    = 150e6;
    // Deep Power Down to Idle wake up time
    specparam tdevice_DPD    = 150e6;
    // Exit Event from Deep Power Down
    specparam tdevice_DPDCSL = 150e6;
	// Exit from Hybrid sleep
	specparam tdevice_HSCSL  = 100e6;
    // Warm HW reset
    specparam tdevice_RPH    = 200e3;
    // Refresh time
    specparam tdevice_REF100 = `tRFH;
    // Page Open Time
    specparam tdevice_PO100 = 0;
	//Hybrid Sleep Enter Time
	specparam tHSIN = 3e6;
	//DPD Enter Time
	specparam tDPDIN = 3e6;
	//CS pulse to exit HS
	specparam tCSHS = 60e3;
	//CS pulse to exit DPD
	specparam tCSDPD = 200e3;
///////////////////////////////////////////////////////////////////////////////
// Input Port  Delays  don't require Verilog description
///////////////////////////////////////////////////////////////////////////////
// Path delays                                                               //
///////////////////////////////////////////////////////////////////////////////

    // Data output paths
    (CSNeg => DQ0) = tpd_CSNeg_DQ0;
    (CSNeg => DQ1) = tpd_CSNeg_DQ0;
    (CSNeg => DQ2) = tpd_CSNeg_DQ0;
    (CSNeg => DQ3) = tpd_CSNeg_DQ0;
    (CSNeg => DQ4) = tpd_CSNeg_DQ0;
    (CSNeg => DQ5) = tpd_CSNeg_DQ0;
    (CSNeg => DQ6) = tpd_CSNeg_DQ0;
    (CSNeg => DQ7) = tpd_CSNeg_DQ0;

    if (falling_edge_CSNeg) (CSNeg => RWDS) = tpd_CSNeg_RWDSn;
    if (rising_edge_CSNeg) (CSNeg => RWDS) = tpd_CSNeg_RWDSp;

    ///////////////////////////////////////////////////////////////////////////
    // Timing Violation                                                      //
    ///////////////////////////////////////////////////////////////////////////
    $setup (CSNeg, posedge CK,   tsetup_CSNeg_CK);

    $setup (DQ0 &&& Dout_Z, CK, tsetup_DQ0_CK);
    $setup (DQ1 &&& Dout_Z, CK, tsetup_DQ0_CK);
    $setup (DQ2 &&& Dout_Z, CK, tsetup_DQ0_CK);
    $setup (DQ3 &&& Dout_Z, CK, tsetup_DQ0_CK);
    $setup (DQ4 &&& Dout_Z, CK, tsetup_DQ0_CK);
    $setup (DQ5 &&& Dout_Z, CK, tsetup_DQ0_CK);
    $setup (DQ6 &&& Dout_Z, CK, tsetup_DQ0_CK);
    $setup (DQ7 &&& Dout_Z, CK, tsetup_DQ0_CK);

    $setup (RWDS &&& RWDSout_Z, CK, tsetup_DQ0_CK);

    $hold (negedge CK, CSNeg, thold_CSNeg_CK);

    $hold (CK, DQ0 &&& Dout_Z, thold_DQ0_CK, Viol);
    $hold (CK, DQ1 &&& Dout_Z, thold_DQ0_CK, Viol);
    $hold (CK, DQ2 &&& Dout_Z, thold_DQ0_CK, Viol);
    $hold (CK, DQ3 &&& Dout_Z, thold_DQ0_CK, Viol);
    $hold (CK, DQ4 &&& Dout_Z, thold_DQ0_CK, Viol);
    $hold (CK, DQ5 &&& Dout_Z, thold_DQ0_CK, Viol);
    $hold (CK, DQ6 &&& Dout_Z, thold_DQ0_CK, Viol);
    $hold (CK, DQ7 &&& Dout_Z, thold_DQ0_CK, Viol);

    $hold (CK, RWDS &&& RWDSout_Z, thold_DQ0_CK, Viol);

    $hold (posedge RESETNeg, CSNeg, thold_CSNeg_RESETNeg);

    $recovery (posedge CSNeg, negedge CK &&& tRWR_CHK, trecovery_CSNeg_CK, Viol);

    $skew (negedge CSNeg, posedge CSNeg, tskew_CSNeg_CSNeg, Viol);

    $width (posedge CK                 , tpw_CK_posedge);
    $width (negedge CK                 , tpw_CK_negedge);
    $width (posedge CSNeg              , tpw_CSNeg_posedge);
    $width (negedge RESETNeg           , tpw_RESETNeg_negedge);

    $period(posedge CK  ,tperiod_CK);

    endspecify

///////////////////////////////////////////////////////////////////////////////
// Main Behavior Block                                                       //
///////////////////////////////////////////////////////////////////////////////

    // FSM states
    parameter POWER_ON     = 3'd0;
    parameter ACT          = 3'd1;
    parameter RESET_STATE  = 3'd2;
    parameter DPD_STATE    = 3'd3;
	parameter HSLEEP_STATE = 3'd4;
    reg [2:0] current_state = POWER_ON;
    reg [2:0] next_state    = POWER_ON;

    //Bus cycle state
    parameter STAND_BY        = 2'd0;
    parameter CA_BITS         = 2'd1;
    parameter DATA_BITS       = 2'd2;
    reg [1:0] bus_cycle_state;

    // Parameters that define read mode, burst or continuous
    parameter LINEAR     = 4'd0;
    parameter CONTINUOUS = 4'd1;
    reg [1:0] RD_MODE = CONTINUOUS;

    integer Mem [0:MemSize];
	real Mem_time[0:MemSize];

    reg PoweredUp = 0;

    reg DPD_ACT        = 0;
	reg HS_ACT		   = 0;
    integer Address; // entire address

    reg [15:0] Config_reg0 = `CONFIG_REG0_DEFAULT;
	reg [15:0] Config_reg1 = {14'h3FF0,`DRI};
	reg [15:0] Identification_reg0 = 16'h0C81;
	reg [15:0] Identification_reg1 = 16'h0001;
	
    reg UByteMask             = 0;
    reg LByteMask             = 0;
    reg Target                = 0;
    integer BurstDelay;
    integer RefreshDelay = 4;
    integer BurstLength;

    //varaibles to resolve architecture used
    reg [24*8-1:0] tmp_timing;//stores copy of TimingModel
    reg [7:0] tmp_char1; //Identify Speed option
	reg [7:0] tmp_char2;
    integer found = 1'b0;

    reg SPEED100 = 0;
	
	reg refresh_pulse = 1'b0;
	
	always
	begin
		#`tCSM refresh_pulse = 1'b1;
		#`tRFH refresh_pulse = 1'b0;
	end
    //Power Up time;
    initial
    begin
        # tdevice_VCS PoweredUp = 1'b1;
    end

    initial
    begin: InitTimingModel
    integer i;
    integer j;
        //assumptions:
        //1. TimingModel has format as S27KL0642XXXXXXXX
        //it is important that 10-th character from first one is "GA" or "DP"
        //2. TimingModel does not have more than 24 characters
        tmp_timing = TimingModel;//copy of TimingModel

        i = 23;
        while ((i >= 0) && (found != 1'b1))//search for first non null character
        begin        //i keeps position of first non null character
            j = 7;
            while ((j >= 0) && (found != 1'b1))
            begin
                if (tmp_timing[i*8+j] != 1'd0)
                    found = 1'b1;
                else
                    j = j-1;
            end
            i = i - 1;
        end
        i = i +1;
        if (found)//if non null character is found
        begin
            for (j=0;j<=7;j=j+1)
            begin
            //Speed is 11.
                tmp_char1[j] = TimingModel[(i-10)*8+j];
                tmp_char2[j] = TimingModel[(i-9)*8+j];
            end
        end
        if (tmp_char1 == "A" && tmp_char2 == "G")begin
            SPEED100 = 1;
		end else if(tmp_char1 == "P" && tmp_char2 == "D")begin
            SPEED100 = 1;
		end else begin
			$error ("No speed grade found\n");
		end
		
		PartialRefresh_Array[0][0] = 0;
		PartialRefresh_Array[0][1] = MemSize;
		PartialRefresh_Array[1][0] = 0;
		PartialRefresh_Array[1][1] = MemSize/2;
		PartialRefresh_Array[2][0] = 0;
		PartialRefresh_Array[2][1] = MemSize/4;
		PartialRefresh_Array[3][0] = 0;
		PartialRefresh_Array[3][1] = MemSize/8;
		PartialRefresh_Array[4][0] = 0;
		PartialRefresh_Array[4][1] = 0;
		PartialRefresh_Array[5][1] = MemSize;
		PartialRefresh_Array[5][0] = MemSize/2;
		PartialRefresh_Array[6][1] = MemSize;
		PartialRefresh_Array[6][0] = 3*MemSize/4;
		PartialRefresh_Array[7][1] = MemSize;
		PartialRefresh_Array[7][0] = 7*MemSize/8;
    end

	    // ------------------------------------------------------------------------
    // Hybrid Sleep time
    // ------------------------------------------------------------------------
    // HSExit_in is any write or read access for which CSNeg_ipd is asserted
    // more than tHSCSL time
	reg HSExit_in = 1'b1;
	reg HSExt_out = 1'b0;
	reg HSExt;
    assign HSExt_in = ((falling_edge_CSNeg == 1'b1) && (HS_in == 1'b1)) ?
                         1'b1 : 1'b0;

	always @(posedge HSExt_in or posedge HS_in)
	begin
		if(HS_in && !HSExit_in)begin
			HSExit_in = 1'b1;
		end else begin
			#tCSHS HSExit_in = CSNeg_ipd;
		end
	end
	
    always @(negedge HSExit_in)
    begin : HSExtEvent
			#(tdevice_HSCSL - 1 - tCSHS) HSExt_out = 1'b1;
			#1 HSExt_out = 1'b0;
    end
    // Generate event to trigger exiting from HS mode
    always @(posedge HSExt_out or CSNeg_ipd or RESETNeg or falling_edge_RESETNeg or
             HS_in)
    begin : HSExtDetected
      if ((HSExt_out == 1'b1) ||
          (!RESETNeg && falling_edge_RESETNeg && HS_in))
      begin
        HSExt = 1'b1;
        #1 HSExt = 1'b0;
      end
    end
    // HS exit event, generated after tHSOUT time (maximal: 150 us)
    always @(posedge HSExt)
    begin : HSTime
        HS_out = 1'b0;
        #1 HS_out = 1'b1;
    end
	
	
	reg DPDExit_in = 1'b1;
    // ------------------------------------------------------------------------
    // Deep Power Down time
    // ------------------------------------------------------------------------
    // DPDExit_in is any write or read access for which CSNeg_ipd is asserted
    // more than tCSDPD time
    assign DPDExt_in = ((falling_edge_CSNeg == 1'b1) && (DPD_in == 1'b1)) ?
                         1'b1 : 1'b0;

	always @(posedge DPDExt_in or posedge DPD_in)
	begin
		if(DPD_in && !DPDExit_in)begin
			DPDExit_in = 1'b1;
		end else if(DPDExt_in)begin
			#tCSDPD DPDExit_in = CSNeg_ipd;
		end
	end
	
    always @(negedge DPDExit_in)
    begin : DPDExtEvent
		#(tdevice_DPDCSL - 1 - tCSDPD) DPDExt_out = 1'b1;
		#1 DPDExt_out = 1'b0;
    end
    // Generate event to trigger exiting from DPD mode
    always @(posedge DPDExt_out or CSNeg_ipd or RESETNeg or falling_edge_RESETNeg or
             DPD_in)
    begin : DPDExtDetected
      if ((DPDExt_out == 1'b1) ||
          (!RESETNeg && falling_edge_RESETNeg && DPD_in))
      begin
        DPDExt = 1'b1;
        #1 DPDExt = 1'b0;
      end
    end
    // DPD exit event, generated after tDPDEXIT time (maximal: 150 us)
    always @(posedge DPDExt)
    begin : DPDTime
        DPD_out = 1'b0;
        #1 DPD_out = 1'b1;
    end

    // Timing control

    // Warm HW reset
    always @(posedge RPH_in)
    begin:RPHr
        #tdevice_RPH RPH_out = RPH_in;
    end
    always @(negedge RPH_in)
    begin:RPHf
        #1 RPH_out = RPH_in;
    end

    //  Refresh Collision Time
    always @(posedge REF_in)
    begin:REFr
        if (SPEED100)
            #(tdevice_REF100 * REFinterval) REF_out = REF_in;
    end
    always @(negedge REF_in)
    begin:REFf
        #1 REF_out = REF_in;
    end

    //  Page Open Time
    always @(posedge PO_in)
    begin:POr
        if (SPEED100)
            #tdevice_PO100 PO_out = PO_in;
    end
    always @(negedge PO_in)
    begin:POf
        #1 PO_out = PO_in;
    end

    // initialize memory and load preoload files if any
    initial
    begin: InitMemory
    integer i;
        for (i=0;i<=MemSize;i=i+1)begin
           Mem[i]=MaxData;
		   Mem_time[i] = $time;
		end

        if (UserPreload && !(mem_file_name == "none"))
            $readmemh(mem_file_name,Mem);
    end
    ///////////////////////////////////////////////////////////////////////////
    // CKDiff is not actualy diferential clock. 
    ///////////////////////////////////////////////////////////////////////////
    assign CKDiff = CK;

    ///////////////////////////////////////////////////////////////////////////
    // Process for clock frequency determination
    ///////////////////////////////////////////////////////////////////////////
    always @(posedge CK)
    begin : clk_period
        CK_cycle = $time - prev_CK;
        prev_CK = $time;
    end
    ///////////////////////////////////////////////////////////////////////////
    // Check if device is selected during power up
    ///////////////////////////////////////////////////////////////////////////
    always @(negedge CSNeg_ipd)
    begin:CheckCSOnPowerUP
        if (~PoweredUp)
            $display ("Device is selected during Power Up");
    end

    always @(rising_edge_CKDiff or falling_edge_CKDiff)
    begin : clock_period
        if (CSNeg_ipd == 1'b0)
        begin
            if (DQt_01 > CK_cycle/2)
                glitch_dq = 1'b1;
        end
    end

	integer tACC_start_time = 0;
	
	always @(posedge tacc_start)begin
		tACC_start_time = $time;
	end
	
	always @(rising_edge_CKDiff or falling_edge_CKDiff)
    begin : tacc
		if(!CSNeg_ipd && tacc_start)begin
			tACC_delay = $time - tACC_start_time;
		end
    end
    ///////////////////////////////////////////////////////////////////////////
    // Bus Cycle Decode
    ///////////////////////////////////////////////////////////////////////////
    integer data_cycle  =  0;
    integer ca_cnt      = 48;
    reg [47:0] ca_in        ;
    reg [15:0] Data_in      ;
    reg RD_WRAP;
    integer Start_BurstAddr;
    reg RdWrStart        = 1'b0;
    reg ALTERNATE_64     = 1'b0;
    reg HYBRID           = 1'b0;
	reg po_out_flag			 = 1'b0;
	reg flag = 1'b0;
    always @(rising_edge_CSNeg or falling_edge_CSNeg or
           rising_edge_CKDiff or falling_edge_CKDiff or falling_edge_RESETNeg
            or rising_edge_REF_out or rising_edge_PO_out)
    begin: BusCycle
    integer i;

    if (current_state == ACT)
    begin
        case (bus_cycle_state)

        STAND_BY:
        begin
            if (falling_edge_CSNeg)
            begin
                ca_cnt        = 48;
                data_cycle    = 0;
                RW            = 1'b0;
                RD_WRAP       = 1'b0;
                RdWrStart     = 1'b0;
                REFCOLL       = 1'b0;
                REFCOLL_ACTIV = 1'b0;
                ALTERNATE_64  = 1'b0;
                HYBRID        = 1'b0;
		RWDSout_zd_tmp = Config_reg0[3];
                bus_cycle_state = CA_BITS;
				po_out_flag   = 1'b0;
				tacc_start   = 1'b0;
				flag  =1'b0;
            end
        end

        CA_BITS:
        begin
            if (!CSNeg &&
            (rising_edge_CKDiff || falling_edge_CKDiff) && !po_out_flag)
            begin
                for(i=1;i<=8;i=i+1)
                    ca_in[ca_cnt-i] = Din[8-i];
                ca_cnt = ca_cnt - 8;
				po_out_flag = 1'b1;
				po_out_flag = #2 1'b0;	
				
                if (ca_cnt == 40)
                begin
                    REFCOLL = 1'b1;
                    if (Config_reg0[3] == 1'b1)// fixed latency
                    begin
                        REFCOLL_ACTIV = 1'b1;
                        RWDSout_zd_tmp = 1'b1;
                    end
                    else if (Config_reg0[3] == 1'b0) begin// variable latency
						if(refresh_pulse)begin
							REFCOLL_ACTIV = 1'b1;
							RWDSout_zd_tmp = 1'b1;
						end else begin
							REFCOLL_ACTIV = 1'b0;
							RWDSout_zd_tmp = 1'b0;
						end
					end
                end

                else if (ca_cnt == 24)
                    t_RWR_CHK = 1'b1;

                else if (ca_cnt == 16)
                begin
                    RW = ca_in[47];
                    Target = ca_in[46];
                    if (Target==1'b0 || (Target==1'b1 && RW==1'b1))
                    begin
                        if (REFCOLL_ACTIV)
                            REF_in = 1'b1;
                        else begin	
							tacc_start = 1'b1;
                            PO_in = 1'b1;
						end
                    end

                    if (Config_reg0[2] == 1'b0)
                        HYBRID = 1'b1;

                    if (Config_reg0[1:0] == 2'b00)
                    begin
                        BurstLength = 64;
					end else if (Config_reg0[1:0] == 2'b01) begin
						ALTERNATE_64 = 1'b1;
						BurstLength = 32;
                    end
                    else if (Config_reg0[1:0] == 2'b10)
                        BurstLength = 8;
                    else if (Config_reg0[1:0] == 2'b11)
                        BurstLength = 16;

                    if (Config_reg0[7:4] == 4'b0000)
                        BurstDelay = 5;
                    else if (Config_reg0[7:4] == 4'b0001)
                        BurstDelay = 6;
                    else if (Config_reg0[7:4] == 4'b0010)
                        BurstDelay = 7;
                    else if (Config_reg0[7:4] == 4'b1111)
                        BurstDelay = 4;
                    else if (Config_reg0[7:4] == 4'b1110)
                        BurstDelay = 3;

                    RefreshDelay = BurstDelay;
                end

                else if (ca_cnt == 8)
                begin
                    if (RW == 1'b1) // read
                        RWDSout_zd_tmp = 1'b0;
                    else  // write
                        RWDSout_zd_tmp = 1'bz;
                    t_RWR_CHK = 1'b0;
                end

                else if (ca_cnt == 0)
                begin
                    REFCOLL = 1'b0;
                    if (ca_in[45])
                        RD_MODE = CONTINUOUS;
                    else
                        RD_MODE = LINEAR;

                    Address   = {ca_in[HiAddrBit:16], ca_in[2:0]};
                    Start_BurstAddr = Address;

                    if (REFCOLL_ACTIV)
                        RefreshDelay = RefreshDelay - 1;
                    else begin
                        BurstDelay = BurstDelay - 1;
					end
                    bus_cycle_state = DATA_BITS;
                end
            end
        end

        DATA_BITS:
        begin
            if (rising_edge_CKDiff && !CSNeg)
            begin
                if (Target==1'b1 && RW==1'b0)
                begin
                    Data_in[15:8] = Din;
                    data_cycle = data_cycle + 1;
                end
                else
                if (BurstDelay==0 && !PO_in)
                begin
                    RdWrStart = 1'b0;
                    if (RW == 1 && tACC_delay >= tACC_device) // read
                    begin
                        glitch_rwds = 1'b0;
                        glitch_rwdsR = 1'b1;
                        RWDSout_zd_tmp = 1'b1;
                        if (Target == 0) // mem
                        begin
                            if (Mem[Address][15:8]==-1)
                                Dout_zd_tmp = 8'bxxxxxxxx;
                            else if(Address >= PartialRefresh_Array[Config_reg1[4:2]][0] && Address <= PartialRefresh_Array[Config_reg1[4:2]][1])
                                Dout_zd_tmp=Mem[Address][15:8];
							else begin
								if(($time - Mem_time[Address]) > `tCSM*no_of_rows)
									Dout_zd_tmp = 8'bxxxxxxxx;
								else
									Dout_zd_tmp=Mem[Address][15:8];
							end
                        end
                        else // reg
							if(ca_in[44:16] == 29'h0000 && ca_in[7:1] == 7'h00)
							begin
								if(ca_in[0] == 1'b0)
								begin
									Dout_zd_tmp = Identification_reg0[15:8]; //Identification Register 0
								end else
								begin
									Dout_zd_tmp = Identification_reg1[15:8]; //Identification Register 1
								end
							end else if(ca_in[44:16] == 29'h0100 && ca_in[7:1] == 7'h00)
							begin
								if(ca_in[0] == 1'b0)
								begin
									Dout_zd_tmp = Config_reg0[15:8]; //Configuration register 0 Read
								end else
								begin
									Dout_zd_tmp = Config_reg1[15:8]; //Configuration register 1 Read
								end
							end
                    end
                    else if(tACC_delay >= tACC_device) // (RW == 0) write
                    begin
			glitch_rwds = 1'b1;
                        Data_in[15:8] = Din;
                        data_cycle = data_cycle + 1;
                        UByteMask = RWDS;
                    end
                end else if(BurstDelay == 1 && RW)begin
					Dout_zd_tmp = #(`tDQLZ) 8'hxx;
				end
            end

            else if (falling_edge_CKDiff && !CSNeg)
            begin
                if (Target==1'b1 && RW==1'b0)
                begin
                    Data_in[7:0] = Din;
                    data_cycle = data_cycle + 1;
                    if (data_cycle == 2 && ca_in[24] == 1'b1 && ca_in[0] == 1'b0)
                    begin
                        if (!Data_in[15] && Config_reg0[15])
                        begin
                            DPD_ACT = 1'b1;
                        end
                        Config_reg0=Data_in;
                    end else if (data_cycle == 2 && ca_in[24] == 1'b1 && ca_in[0] == 1'b1)
                    begin
                        if (Data_in[5] && !Config_reg1[5])//CR1[5]==0 normal operation, CR1[5]==1 Enable H Sleep
                        begin
                            HS_ACT = 1'b1;
                        end

						REFinterval=1;
                        Config_reg1[15:2]=Data_in[15:2];
                    end
                end
                else
                if (REFCOLL_ACTIV)
                begin
                    if (RefreshDelay > 0)
                        RefreshDelay = RefreshDelay - 1;
                    else if (RefreshDelay == 0)
                    begin
                        if (!REF_in)
                        begin
                            PO_in = 1'b1;
                            REFCOLL_ACTIV = 1'b0;
                        end
                    end
					if(RefreshDelay == 0)
						tacc_start = 1'b1;
                end
                else
                begin
                    if (BurstDelay>0 || tACC_delay < tACC_device)begin
						if(BurstDelay == 0 && tACC_delay < tACC_device)begin
							BurstDelay = 0;
						end else begin
							BurstDelay = BurstDelay - 1;
						end
                    end else 
                    begin
                        if (!PO_in)
                        begin
                            if (RdWrStart == 1'b1)
                                RdWrStart =1'b0;
                            else
                            begin
                                if (RW == 1) // read
                                begin
                                    RWDSout_zd_tmp = 1'b0;
                                    if (Target == 0) // mem
                                    begin
										if (Mem[Address][7:0]==-1)
											Dout_zd_tmp = 8'bxxxxxxxx;
										else if(Address >= PartialRefresh_Array[Config_reg1[4:2]][0] && Address <= PartialRefresh_Array[Config_reg1[4:2]][1])
											Dout_zd_tmp=Mem[Address][7:0];
										else begin
											if(($time - Mem_time[Address]) > `tCSM*no_of_rows)
												Dout_zd_tmp = 8'bxxxxxxxx;
											else
												Dout_zd_tmp=Mem[Address][7:0];
										end
                                    end
                                    else // reg
										if(ca_in[44:16] == 29'h0000 && ca_in[7:1] == 7'h00)
										begin
											if(ca_in[0] == 1'b0)
											begin
												Dout_zd_tmp = Identification_reg0[7:0]; //Identification Register 0
											end else
											begin
												Dout_zd_tmp = Identification_reg1[7:0]; //Identification Register 1
											end
										end else if(ca_in[44:16] == 29'h0100 && ca_in[7:1] == 7'h00)
										begin
											if(ca_in[0] == 1'b0)
											begin
												Dout_zd_tmp = Config_reg0[7:0]; //Configuration register 0 Read
											end else
											begin
												Dout_zd_tmp = Config_reg1[7:0]; //Configuration register 1 Read
											end
										end
                                end
                                else // write
                                begin
                                    if (Target == 0)  // mem
                                    begin
                                        if (data_cycle >= 1)
                                        begin
                                            Data_in[7:0] = Din;
                                            data_cycle = data_cycle + 1;
                                            LByteMask = RWDS;
                                            if (data_cycle % 2 == 0)
                                            begin
                                                if (!LByteMask)
                                                    Mem[Address][7:0]=Data_in[7:0];
                                                if (!UByteMask)
                                                    Mem[Address][15:8]=Data_in[15:8];
												Mem_time[Address] = $time;
                                            end
                                        end
                                    end
                                end

                                if (RD_MODE == CONTINUOUS)
                                begin
                                    if (Address == AddrRANGE)
                                        Address = 0;
                                    else
                                        Address = Address + 1;
                                end
                                else // wrapped burst
                                begin
                                    if (!HYBRID)//legacy wrapped burst
                                    begin
                                        if ((BurstLength==8) ||
                                        (BurstLength==16) ||
                                        (BurstLength==32) || (BurstLength==64))
                                        begin
                                            Address = Address + 1;
                                            if (Address % BurstLength == 0)
                                                Address= Address - BurstLength;
                                        end
                                        else if (BurstLength==32 && ALTERNATE_64)
                                        begin
                                            Address = Address + 1;
                                            if (Address % (BurstLength/2)== 0)
                                            begin
                                                if (!RD_WRAP)
                                                begin
                                                    Address= Address-(BurstLength/2);
                                                    RD_WRAP = 1'b1;
                                                end
                                                else
                                                begin
                                                    ALTERNATE_64 = 0;
                                                    if (Address[4] == 1'b0)
                                                        Address=Address-BurstLength;
                                                end
                                            end
                                            if ((Address == Start_BurstAddr) &&
                                            ALTERNATE_64)
                                            begin
                                                if (Address[4] == 1'b0)
                                                begin
                                                    Address =
                                                    (Start_BurstAddr/
                                                    BurstLength)*BurstLength
                                                        + BurstLength/2;
                                                end
                                                else if (Address[4] == 1'b1)
                                                    Address =
                                                    (Start_BurstAddr/
                                                    BurstLength)*BurstLength;
                                            end
                                        end
                                    end
                                    else // Hybrid burst sequencing
                                    begin
                                        if ((BurstLength==8) ||
                                        (BurstLength==16) ||
                                        (BurstLength==32) || (BurstLength==64))
                                        begin
                                            Address = Address + 1;
                                            if (Address % BurstLength == 0)
                                                Address= Address - BurstLength;
                                            if (Address == Start_BurstAddr)
                                            begin
                                                Address=
                                        (Start_BurstAddr/BurstLength)*BurstLength
                                                + BurstLength;
                                                if (Address==AddrRANGE + 1)
                                                    Address = 0;
                                                RD_MODE = CONTINUOUS;
                                            end
                                        end

                                        else if (BurstLength==32 && ALTERNATE_64)
                                        begin
                                            Address = Address + 1;
                                            if (Address % (BurstLength/2)== 0)
                                            begin
                                                if (!RD_WRAP)
                                                begin
                                                    Address= Address-(BurstLength/2);
                                                    RD_WRAP = 1'b1;
                                                end
                                                else
                                                begin
                                                    Address =
                                                    (Start_BurstAddr/
                                                    BurstLength)*BurstLength
                                                        + BurstLength;
                                                    if (Address==AddrRANGE + 1)
                                                        Address = 0;
                                                    RD_MODE = CONTINUOUS;
                                                end
                                            end
                                            if (Address == Start_BurstAddr)
                                            begin
                                                if (Address[4] == 1'b0)
                                                    Address =
                                                    (Start_BurstAddr/
                                                    BurstLength)*BurstLength
                                                    + BurstLength/2;
                                                else if (Address[4] == 1'b1)
                                                    Address =
                                                    (Start_BurstAddr/
                                                    BurstLength)*BurstLength;
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end 
                end
            end
        end
        endcase

        if (falling_edge_CSNeg)
        begin
            if (Config_reg0[3] == 1'b1)// fixed latency
                RWDSout_zd = 1'b1;
            else
                RWDSout_zd = 1'b0;
        end

        if (rising_edge_CSNeg || falling_edge_RESETNeg)
        begin
            bus_cycle_state = STAND_BY;
            Dout_zd_tmp = 8'bzzzzzzzz;
            RWDSout_zd_tmp = 1'bz;
            Dout_zd = 8'bzzzzzzzz;
            RWDSout_zd = 1'bz;
            glitch_rwds = 1'b0;
            glitch_rwdsR = 1'b0;
            if (falling_edge_RESETNeg) begin
                Config_reg0 = `CONFIG_REG0_DEFAULT;
                Config_reg1 = {14'h3FF0,`DRI};// default value 11 1111 1111 0000 01
				Identification_reg0 = 16'h0C81;//default value
				Identification_reg1 = 16'h0001;//default value
			end
        end
        if (rising_edge_PO_out)
        begin
            PO_in = 1'b0;
            RdWrStart = 1'b1;
        end
        if (rising_edge_REF_out)
            REF_in = 1'b0;
    end

    else
      begin
        bus_cycle_state = STAND_BY;
        if (falling_edge_RESETNeg) begin
            Config_reg0 = `CONFIG_REG0_DEFAULT;
            Config_reg1 = {14'h3FF0,`DRI};// default value
			Identification_reg0 = 16'h0C81;//default value
			Identification_reg1 = 16'h0001;//default value
		end
      end
    end

    always @(next_state)
    begin:CurrentStatGen
        current_state = next_state;
    end

    always @(rising_edge_PoweredUp or
            rising_edge_DPD_in or rising_edge_RPH_out or
            rising_edge_RESETNeg or rising_edge_DPD_out or
            falling_edge_RESETNeg or rising_edge_HS_in or rising_edge_HS_out)
    begin: StateGen
        case (current_state)

            POWER_ON:
            begin
                if (rising_edge_PoweredUp)
                    next_state <= ACT;
            end

            ACT:
            begin
                if (falling_edge_RESETNeg)
                    next_state <= RESET_STATE;
                else if (rising_edge_DPD_in)
                    next_state <= DPD_STATE;
                else if (rising_edge_HS_in)
                    next_state <= HSLEEP_STATE;
            end

            RESET_STATE:
            begin
                if ((rising_edge_RPH_out && RESETNeg_pullup) ||
                (rising_edge_RESETNeg && !RPH_in))
                    next_state <= ACT;
            end

            DPD_STATE:
            begin
                if (falling_edge_RESETNeg)
                    next_state <= RESET_STATE;
                else if (rising_edge_DPD_out) begin
                    next_state <= ACT;
					Config_reg0[15] <= 1'b1;
				end
            end
			
            HSLEEP_STATE:
            begin
                if (falling_edge_RESETNeg)
                    next_state <= RESET_STATE;
                else if (rising_edge_HS_out) begin
                    next_state <= ACT;
					Config_reg1[5] <= 1'b0;
				end
            end

        endcase
    end

	always @(falling_edge_CSNeg)
	begin
		if(DPD_ACT && !DPD_in)begin
			Config_reg0[15] = 1'b1;
			DPD_ACT = 1'b0;
		end
		
		if(HS_ACT && !HS_in)begin
			Config_reg1[5] = 1'b0;
			HS_ACT = 1'b0;
		end
	end
	
    always @(falling_edge_RESETNeg or
            DPD_ACT or rising_edge_RPH_out or
            rising_edge_DPD_out or rising_edge_HS_out or HS_ACT)
    begin:Functional
        case (current_state)

            POWER_ON:
            begin
            end

            ACT:
            begin
                if (falling_edge_RESETNeg)
                    RPH_in = 1'b1;
                if (DPD_ACT)begin
                    #tDPDIN DPD_in = DPD_ACT;
					DPD_ACT = 1'b0;
				end
				if(HS_ACT)begin
					#tHSIN HS_in = HS_ACT;
					HS_ACT = 1'b0;
				end
            end

            RESET_STATE:
            begin
                if (rising_edge_RPH_out)
                    RPH_in = 1'b0;
            end

            DPD_STATE:
            begin
                if (rising_edge_DPD_out)
                    DPD_in = 1'b0;
                if (falling_edge_RESETNeg)
                begin
                    RPH_in = 1'b1;
                    DPD_in = 1'b0;
                end
            end

            HSLEEP_STATE:
            begin
                if (rising_edge_HS_out)
                    HS_in = 1'b0;
                if (falling_edge_RESETNeg)
                begin
                    RPH_in = 1'b1;
                    HS_in = 1'b0;
                end
            end
        endcase
    end

 always @(posedge PoweredUp)
    begin
        rising_edge_PoweredUp = 1;
        #1 rising_edge_PoweredUp = 0;
    end

    always @(negedge CKDiff)
    begin
        falling_edge_CKDiff = 1;
        #1 falling_edge_CKDiff = 0;
    end

    always @(posedge CKDiff)
    begin
        rising_edge_CKDiff = 1;
        #1 rising_edge_CKDiff = 0;
    end

 always @(posedge CSNeg)
    begin
        rising_edge_CSNeg = 1;
        #1 rising_edge_CSNeg = 0;
    end
 always @(negedge CSNeg)
    begin
        falling_edge_CSNeg = 1;
        #1 falling_edge_CSNeg = 0;
    end

 always @(posedge REF_out)
    begin
        rising_edge_REF_out = 1;
        #1 rising_edge_REF_out = 0;
    end

 always @(posedge PO_out)
    begin
        rising_edge_PO_out = 1;
        #1 rising_edge_PO_out = 0;
    end

 always @(posedge RPH_out)
    begin
        rising_edge_RPH_out = 1;
        #1 rising_edge_RPH_out = 0;
    end

 always @(posedge DPD_in)
    begin
        rising_edge_DPD_in = 1;
        #1 rising_edge_DPD_in = 0;
    end

 always @(posedge DPD_out)
    begin
        rising_edge_DPD_out = 1;
        #1 rising_edge_DPD_out = 0;
    end

 always @(posedge HS_in)
    begin
        rising_edge_HS_in = 1;
        #1 rising_edge_HS_in = 0;
    end

 always @(posedge HS_out)
    begin
        rising_edge_HS_out = 1;
        #1 rising_edge_HS_out = 0;
    end
	
 always @(posedge RESETNeg)
    begin
        rising_edge_RESETNeg = 1;
        #1 rising_edge_RESETNeg = 0;
    end

 always @(negedge RESETNeg)
    begin
        #(`tRP) falling_edge_RESETNeg = !RESETNeg;
        #1 falling_edge_RESETNeg = 0;
    end

 always @(posedge glitch_rwds or posedge CSNeg or negedge RESETNeg)
    begin
		if(~RESETNeg)begin
			rising_edge_glitch_rwds <= 1'b0;
		end else if(CSNeg) begin
			rising_edge_glitch_rwds <= 1'b0;
		end else begin
			rising_edge_glitch_rwds = 1;
		end
    end

    always @(rising_edge_CSNeg)
    begin
        disable read_process_dq1;
        disable read_process_dq2;
        disable read_process_rwds1;
        disable read_process_rwds2;
        disable read_process_rwdsR1;
        disable read_process_rwdsR2;
    end

 always @(rising_edge_CKDiff)
    begin: read_process_dq1
        if (~CSNeg_ipd)
        begin
            if (glitch_dq)
            begin
                #1 Dout_zd_latchH = Dout_zd_tmp;
                #DQt_01 Dout_zd = Dout_zd_latchH;
            end
            else
            begin
                Dout_zdp = #1100 Dout_zd_tmp;
            end
        end
    end

 always @(falling_edge_CKDiff)
    begin: read_process_dq2
        if (~CSNeg_ipd)
        begin
            if (glitch_dq)
            begin
                #1 Dout_zd_latchL = Dout_zd_tmp;
                #DQt_01 Dout_zd = Dout_zd_latchL;
            end
            else
            begin
				Dout_zdn = #1100 Dout_zd_tmp;
            end
        end
    end

    always @(rising_edge_CKDiff)
    begin: read_process_rwds1
        if (~CSNeg_ipd)
        begin
            if (glitch_rwds && !REFCOLL)
            begin
                #1 RWDS_zd_latchH = RWDSout_zd_tmp;
                #RWDSt_01 RWDS_zdp = RWDS_zd_latchH;
            end
            else if (!REFCOLL)
            begin
				if(BurstDelay>0 && RW)begin
					RWDSout_zd = #`tCKDSR RWDSout_zd_tmp;
				end else begin
					RWDSout_zd = #`tCKDS RWDSout_zd_tmp;
				end
            end
        end
    end

    always @(falling_edge_CKDiff)
    begin: read_process_rwds2
        if (~CSNeg_ipd)
        begin
            if (glitch_rwds && !REFCOLL)
            begin
                #1 RWDS_zd_latchL = RWDSout_zd_tmp;
                #RWDSt_01 RWDS_zdn = RWDS_zd_latchL;
            end
            else if (!REFCOLL)
            begin
				if(BurstDelay>0 && RW)begin
					RWDSout_zd = #`tCKDSR RWDSout_zd_tmp;
				end else begin
					RWDSout_zd = #`tCKDS RWDSout_zd_tmp;
				end
            end
        end
    end

    always @(rising_edge_CKDiff)
    begin: read_process_rwdsR1
        if (~CSNeg_ipd)
        begin
            if (glitch_rwdsR && !REFCOLL)
            begin
                #1 RWDS_zd_latchH = RWDSout_zd_tmp;
                #RWDSRt_01 RWDS_zdp = RWDS_zd_latchH;
            end
            else if (REFCOLL)
            begin
				if(BurstDelay>0 && RW)begin
					RWDSout_zd = #`tCKDSR RWDSout_zd_tmp;
				end else begin
					RWDSout_zd = #`tCKDS RWDSout_zd_tmp;
				end                         
            end
        end
    end

	
    always @(falling_edge_CKDiff)
    begin: read_process_rwdsR2
        if (~CSNeg_ipd)
        begin
            if (glitch_rwdsR && !REFCOLL)
            begin
                #1 RWDS_zd_latchL = RWDSout_zd_tmp;
                #RWDSRt_01 RWDS_zdn = RWDS_zd_latchL;
            end
            else if (REFCOLL)
            begin
				if(BurstDelay>0 && RW)begin
					RWDSout_zd = #`tCKDSR RWDSout_zd_tmp;
				end else begin
					RWDSout_zd = #`tCKDS RWDSout_zd_tmp;
				end
            end
        end
    end

    reg  BuffInDQ;
    wire BuffOutDQ;

    reg  BuffInRWDS;
    wire BuffOutRWDS;

    reg  BuffInRWDSR;
    wire BuffOutRWDSR;

	reg rwds_enable = 1'b0;
	
    BUFFERs27kl0641    BUF_DOut    (BuffOutDQ, BuffInDQ);
    BUFFERs27kl0641    BUF_RWDS    (BuffOutRWDS, BuffInRWDS);
    BUFFERs27kl0641    BUF_RWDSR   (BuffOutRWDSR, BuffInRWDSR);

    initial
    begin
        BuffInDQ    = 1'b1;
        BuffInRWDS  = 1'b1;
        BuffInRWDSR = 1'b1;
		rwds_enable = 1'b0;
    end

    always @(posedge BuffOutDQ)
    begin
        DQt_01 = $time;
    end

    always @(posedge BuffOutRWDS)
    begin
        RWDSt_01 = $time;
    end

    always @(posedge BuffOutRWDSR)
    begin
        RWDSRt_01 = $time;
    end

	reg DQp_z = 1'b0;
	reg DQn_z = 1'b0;
	always @(rising_edge_CKDiff)
	begin
		if((bus_cycle_state == DATA_BITS) && (BurstDelay == 0))
		begin
			DQp_latch <= #`tCKDS rwds_enable;
			DQp_latch <= #(`tCKDS+1) 1'b0;
			
			DQp_z <= #(`tCKDI) 1'b1;
			DQp_z <= #(`tCKDI + 1) 1'b0;
		end
	end
	
	always @(falling_edge_CKDiff)
	begin
		if((bus_cycle_state == DATA_BITS) && (BurstDelay == 0))
		begin
			DQn_latch <= #`tCKDS rwds_enable;
			DQn_latch <= #(`tCKDS+1) 1'b0;
			
			DQn_z <= #(`tCKDI) 1'b1;
			DQn_z <= #(`tCKDI + 1) 1'b0;
		end
	end
	
	always @(posedge rising_edge_CSNeg or posedge DQn_latch or posedge DQp_latch or posedge DQn_z or posedge DQp_z)
	begin
		if(CSNeg)begin
			Dout_zd <= 8'hzz;
			RWDSout_zd <= 1'bz;
		end else begin
			if(DQn_latch)begin
				Dout_zd <= Dout_zdn;
				RWDSout_zd <= RWDS_zdn;
			end
		
			if(DQp_latch)begin
				Dout_zd <= Dout_zdp;
				RWDSout_zd <= RWDS_zdp;
			end 
			
			if(DQp_z)begin
				Dout_zd <= 8'hz;
			end
			
			if(DQn_z)begin
				Dout_zd <= 8'hz;
			end
		end
	end
	
	always @(CSNeg or rising_edge_CKDiff)
	begin
		if(CSNeg)begin
			rwds_enable <= 1'b0;
		end else if((bus_cycle_state == DATA_BITS) && (BurstDelay == 0) && tACC_delay >= tACC_device)begin
			rwds_enable <= 1'b1;
		end
	end
endmodule

module BUFFERs27kl0641 (OUT,IN);
    input IN;
    output OUT;
    buf   ( OUT, IN);
endmodule
