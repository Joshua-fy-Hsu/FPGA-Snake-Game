`timescale 1ns / 1ps

/*
 * Module: Score_Display
 * Description: 
 * Drives an 8-digit 7-segment display using Time-Division Multiplexing (TDM).
 * Displays scores in the format: "1. XX - 2. XX"
 * (Player 1 label, P1 Score, Dash, Player 2 label, P2 Score)
 */
module Score_Display(
    input  wire        clk,        // System Clock
    input  wire        rst_n,
    input  wire [15:0] score_1,
    input  wire [15:0] score_2,
    output reg  [7:0]  seg_cs,     // Chip Select (Active High for each digit)
    output reg  [7:0]  seg_data_0, // Segment Data (Common Anode/Cathode)
    output reg  [7:0]  seg_data_1  // Duplicate output
);
    // ----------------------------------------
    // 1. Multiplexing Timer
    //    Switches the active digit every 25,000 cycles (1kHz refresh rate).
    // ----------------------------------------
    reg [15:0] scan_cnt;
    reg [2:0]  scan_idx;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin scan_cnt <= 0; scan_idx <= 0; end
        else if (scan_cnt >= 25000) begin scan_cnt <= 0; scan_idx <= scan_idx + 1'b1; end
        else scan_cnt <= scan_cnt + 1'b1;
    end

    // ----------------------------------------
    // 2. Data Preparation
    //    Extract Tens and Ones digits for both scores.
    // ----------------------------------------
    reg [3:0] p1_t, p1_o, p2_t, p2_o;
    always @* begin
        p1_t = (score_1 / 10) % 10;
        p1_o = score_1 % 10;
        p2_t = (score_2 / 10) % 10;
        p2_o = score_2 % 10;
    end

    // ----------------------------------------
    // 3. Digit Multiplexer
    //    Selects content based on current scan index.
    //    Special Codes: 10='-', 12='1.', 13='2.'
    // ----------------------------------------
    reg [4:0] char_code; 
    always @* begin
        case(scan_idx)
            3'd0: char_code = 5'd12;         // '1.' (Player 1 Label)
            3'd1: char_code = {1'b0, p1_t};  // P1 Tens
            3'd2: char_code = {1'b0, p1_o};  // P1 Ones
            3'd3: char_code = 5'd10;         // '-' Separator
            3'd4: char_code = 5'd13;         // '2.' (Player 2 Label)
            3'd5: char_code = {1'b0, p2_t};  // P2 Tens
            3'd6: char_code = {1'b0, p2_o};  // P2 Ones
            3'd7: char_code = 5'd11;         // Blank
        endcase
    end

    // ----------------------------------------
    // 4. Segment Decoder (Look-up Table)
    //    Maps 5-bit values to 7-segment patterns (abcdefg + dot).
    // ----------------------------------------
    function [7:0] get_segs;
    input [4:0] val;
        begin
            case (val)
                5'd0: get_segs = 8'b00111111;
                5'd1: get_segs = 8'b00000110;
                5'd2: get_segs = 8'b01011011; 5'd3: get_segs = 8'b01001111;
                5'd4: get_segs = 8'b01100110; 5'd5: get_segs = 8'b01101101;
                5'd6: get_segs = 8'b01111101; 5'd7: get_segs = 8'b00000111;
                5'd8: get_segs = 8'b01111111; 5'd9: get_segs = 8'b01101111;
                5'd10: get_segs = 8'b01000000; // '-'
                5'd11: get_segs = 8'b00000000; // Blank
                5'd12: get_segs = 8'b10000110; // '1.' (Digit 1 with DP)
                5'd13: get_segs = 8'b11011011; // '2.' (Digit 2 with DP)
                default: get_segs = 8'b00000000;
            endcase
        end
    endfunction

    // ----------------------------------------
    // 5. Output Logic
    //    Drives Chip Select (Active High) one at a time.
    // ----------------------------------------
    always @* begin
        seg_data_0 = get_segs(char_code);
        seg_data_1 = seg_data_0;
        case (scan_idx)
            3'd0: seg_cs = 8'b00000001;
            3'd1: seg_cs = 8'b00000010;
            3'd2: seg_cs = 8'b00000100; 3'd3: seg_cs = 8'b00001000;
            3'd4: seg_cs = 8'b00010000; 3'd5: seg_cs = 8'b00100000;
            3'd6: seg_cs = 8'b01000000; 3'd7: seg_cs = 8'b10000000;
        endcase
    end
endmodule