`timescale 1ns / 1ps

/*
 * Module: UG480
 * Description: 
 * Wrapper for the Xilinx XADC primitive. Configures the ADC to read
 * auxiliary analog channels and exposes the DRP (Dynamic Reconfiguration Port) interface.
 * Specifically reads 'MEASURED_AUX1' to control game speed via potentiometer.
 */
module UG480 (
    input DCLK, // Clock for the DRP interface
    input RESET,
    input [3:0] VAUXP, VAUXN,  // Auxiliary analog inputs
    input VP, VN,              // Dedicated analog pair
    output reg [15:0] MEASURED_TEMP, MEASURED_VCCINT, 
    output reg [15:0] MEASURED_VCCAUX, MEASURED_VCCBRAM,
    output reg [15:0] MEASURED_AUX0, MEASURED_AUX1, 
    output reg [15:0] MEASURED_AUX2, MEASURED_AUX3,
    output wire [7:0] ALM,     // Alarm outputs
    output wire [4:0] CHANNEL, // Channel selection status
    output wire       OT,      // Over-Temperature alarm
    output wire       EOC,     // End of Conversion
    output wire       EOS      // End of Sequence
);
    // DRP Interface signals
    wire busy;
    wire [5:0] channel;
    wire drdy; // Data Ready
    wire eoc, eos;
    wire dclk_bufg;
    reg [6:0] daddr;
    reg [15:0] di_drp;
    wire [15:0] do_drp;
    wire [15:0] vauxp_active, vauxn_active;
    reg [1:0]  den_reg;
    reg [1:0]  dwe_reg;
    
    // DRP Read/Write State Machine
    reg [7:0]   state = init_read;
    parameter	init_read       = 8'h00,
                read_waitdrdy   = 8'h01,
                write_waitdrdy  = 8'h03,
                read_reg00      = 8'h04,
                reg00_waitdrdy  = 8'h05,
                read_reg11      = 8'h0e, // Register for AUX1 data
                reg11_waitdrdy  = 8'h0f;

    // Buffer the clock for DRP
    BUFG i_bufg (.I(DCLK), .O(dclk_bufg));
	
	// DRP Access Logic
	always @(posedge dclk_bufg)
	if (RESET) 
		begin
			state   <= init_read;
			den_reg <= 2'h0;
			dwe_reg <= 2'h0;
			di_drp  <= 16'h0000;
		end
	else
		case (state)
		init_read : 
			begin
				daddr <= 7'h40;  // Config Register 0
				den_reg <= 2'h2; // Assert Enable
				if (busy == 0 ) 
					state <= read_waitdrdy;
			end

		read_waitdrdy : 
			if (eos ==1)  	
				begin
					// Modify Config Reg 0: Clear averaging bits
					di_drp <= do_drp  & 16'h03_FF; 
					daddr <= 7'h40;
					den_reg <= 2'h2;
					dwe_reg <= 2'h2; // Assert Write Enable
					state <= write_waitdrdy;
				end
			else 
				begin
					// Shift registers to generate pulses
					den_reg <= { 1'b0, den_reg[1] } ;
					dwe_reg <= { 1'b0, dwe_reg[1] } ;
					state <= state;                
				end

		write_waitdrdy : 
			if (drdy ==1) 
				state <= read_reg11; // Move to read AUX1
			else 
				begin
					den_reg <= { 1'b0, den_reg[1] } ;
					dwe_reg <= { 1'b0, dwe_reg[1] } ;      
					state <= state;
				end

		read_reg11 : 
			begin
				daddr   <= 7'h11; // Address of AUX1 measurement
				den_reg <= 2'h2;  // Assert Enable
				state   <= reg11_waitdrdy;
			end
			
		reg11_waitdrdy : 
			if (drdy ==1)  	
				begin
					MEASURED_AUX1 <= do_drp; // Capture data
					state <= read_reg11;     // Loop back to continuous read
				end
			else 
				begin
					den_reg <= { 1'b0, den_reg[1] } ;
					dwe_reg <= { 1'b0, dwe_reg[1] } ;      
					state <= state;          
				end
			
		default : 
			begin
				daddr <= 7'h40;
				den_reg <= 2'h2;
				state <= init_read;
			end
		endcase

    // XADC Hard Macro Instantiation
	XADC #(
		.INIT_40(16'h9000), // Averaging of 16 for external channels
		.INIT_41(16'h2ef0), // Continuous Sequence Mode, Calibration Enabled
		.INIT_42(16'h0400), // DCLK Divider
		.INIT_48(16'h4701), // CHSEL1: Enable Temp, VCC, Cal
		.INIT_49(16'h000f), // CHSEL2: Enable Aux Channels 0-3
		.SIM_MONITOR_FILE("design.txt")
	)
	XADC_INST (
		.CONVST (1'b0),
		.CONVSTCLK  (1'b0),
		.DADDR  (daddr),
		.DCLK   (dclk_bufg),
		.DEN    (den_reg[0]),
		.DI     (di_drp),
		.DWE    (dwe_reg[0]),
		.RESET  (RESET),
		.VAUXN  (vauxn_active ),
		.VAUXP  (vauxp_active ),
		.ALM    (ALM),
		.BUSY   (busy),
		.CHANNEL(CHANNEL),
		.DO     (do_drp),
		.DRDY   (drdy),
		.EOC    (eoc),
		.EOS    (eos),
		.OT     (OT),
		.VP     (VP),
		.VN     (VN)
	);

    // Map auxiliary inputs to the macro ports
    assign vauxp_active = {12'h00, VAUXP[3:0]};
    assign vauxn_active = {12'h00, VAUXN[3:0]};
    assign EOC = eoc;
    assign EOS = eos;

endmodule