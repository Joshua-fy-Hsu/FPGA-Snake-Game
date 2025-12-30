`timescale 1ns / 1ps

/*
 * Module: Clock_Divider
 * Description: 
 * Derives the 25.175 MHz VGA pixel clock from the 100 MHz system clock using an MMCM.
 * Generates a variable-frequency 'game_tick' strobe to control game speed.
 * The game speed is inversely proportional to the 'speed_adj' potentiometer value.
 */
module Clock_Divider(
    input  wire        clk,        // 100 MHz system clock input
    input  wire        rst_n,      // Active-low system reset
    input  wire [15:0] speed_adj,  // 16-bit analog value from XADC (0 to FFFF)
    output wire        vga_clk,    // 25.175 MHz output clock for VGA timing
    output reg         game_tick,  // Single-cycle high strobe for game updates
    output wire        locked      // MMCM locked signal (High when clock is stable)
);
    // Instantiate the Clocking Wizard IP to generate 25.175 MHz from 100 MHz
    clk_wiz_vga u_clk_wiz_vga (
        .clk_in1(clk),
        .reset(~rst_n),    // IP expects active-high reset
        .clk_out1(vga_clk),
        .locked(locked)
    );

    // Synchronize reset with the lock signal to ensure stability
    wire rst_sync = ~rst_n | ~locked;

    // Calculate dynamic counter limit for game speed control.
    // Logic:
    //   - Base limit: 2,000,000 cycles (Fastest speed, ~12 updates/sec)
    //   - Variable offset: speed_adj * 128 (Adds up to ~8.4M cycles)
    //   - Max limit: ~10,400,000 cycles (Slowest speed, ~2.4 updates/sec)
    wire [23:0] dynamic_limit;
    assign dynamic_limit = 24'd2_000_000 + (speed_adj * 128);

    reg [23:0] counter;
    // Counter runs on the slower VGA clock domain (25 MHz)
    always @(posedge vga_clk or posedge rst_sync) begin
        if (rst_sync) begin
            counter   <= 24'd0;
            game_tick <= 1'b0;
        end else begin
            // Reset counter and fire tick when limit is reached
            if (counter >= dynamic_limit) begin
                counter   <= 24'd0;
                game_tick <= 1'b1;
            end else begin
                counter   <= counter + 1'b1;
                game_tick <= 1'b0;
            end
        end
    end

endmodule