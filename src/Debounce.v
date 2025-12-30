`timescale 1ns / 1ps

/*
 * Module: Debounce
 * Description: 
 * Filters mechanical switch bounce using a stability counter.
 * Output 'btn_pulse' goes high for exactly one clock cycle when a 
 * button press is detected and remains stable for ~5ms.
 */
module Debounce(
    input  wire clk,
    input  wire rst_n,
    input  wire btn_in,    // Raw asynchronous button input
    output reg  btn_pulse  // Synchronized one-shot pulse
);
    localparam integer STABLE_COUNT = 125_000; // 5ms delay at 25MHz
    reg [16:0] counter;

    reg btn_sync_0, btn_sync_1; // Synchronization flip-flops
    reg btn_state;              // Current stable state

    // 1. Synchronize async input to avoid metastability
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            btn_sync_0 <= 1'b0;
            btn_sync_1 <= 1'b0;
        end else begin
            btn_sync_0 <= btn_in;
            btn_sync_1 <= btn_sync_0;
        end
    end

    // 2. Debounce Counter
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            btn_state <= 0;
            btn_pulse <= 0;
        end else begin
            btn_pulse <= 0; // Default output low
            
            // If input matches state, reset counter (no change)
            if (btn_sync_1 == btn_state) begin
                counter <= 0;
            end else begin
                // Input is different; count stability
                if (counter >= STABLE_COUNT) begin
                    btn_state <= btn_sync_1; // Accept new state
                    counter   <= 0;
                    
                    // Generate pulse only on Rising Edge (Press)
                    if (btn_sync_1) 
                        btn_pulse <= 1;
                    else
                        btn_pulse <= 0;
                end else begin
                    counter <= counter + 1'b1;
                end
            end
        end
    end

endmodule