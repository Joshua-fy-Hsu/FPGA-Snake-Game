`timescale 1ns / 1ps

/*
 * Module: Keypad_Scanner
 * Description: 
 * Interfaces with a 4x4 Matrix Keypad to control Player 2.
 * Cycles through rows to detect key presses on columns.
 * Maps specific matrix keys (D, 5, 3, 9) to direction outputs (Up, Down, Left, Right).
 */
module Keypad_Scanner(
    input  wire clk,            // 25.175 MHz system clock
    input  wire rst_n,
    input  wire [3:0] col_in,   // Inputs from Keypad Columns (pulled high, active low)
    output reg  [3:0] row_out,  // Outputs to Keypad Rows (Active Low scan)
    output reg  [1:0] dir_out   // Decoded direction: 00=UP, 01=RIGHT, 10=DOWN, 11=LEFT
);
    // Timer to slow down scanning. 
    // 25MHz / 25000 = 1kHz scan rate (1ms per row switch).
    reg [15:0] scan_cnt;
    reg [1:0]  curr_row;

    // -----------------------------------------------------
    // Key Mapping (Active Low Logic)
    // -----------------------------------------------------
    // Matrix Physical Layout & Logic Mapping:
    //   Row 0, Col 1 -> 'D' -> Map to UP
    //   Row 1, Col 2 -> '3' -> Map to LEFT
    //   Row 1, Col 0 -> '9' -> Map to RIGHT
    //   Row 2, Col 1 -> '5' -> Map to DOWN
    // -----------------------------------------------------
    wire key_D = (curr_row == 0) && (col_in[1] == 0);
    wire key_3 = (curr_row == 1) && (col_in[2] == 0);
    wire key_9 = (curr_row == 1) && (col_in[0] == 0);
    wire key_5 = (curr_row == 2) && (col_in[1] == 0);

    localparam [1:0] UP=2'b00, RIGHT=2'b01, DOWN=2'b10, LEFT=2'b11;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            scan_cnt <= 0;
            curr_row <= 0;
            row_out  <= 4'b1111; // Inactive (All High)
            dir_out  <= LEFT;    // Default starting direction for P2
        end else begin
            // 1. Scan Interval Timer
            if (scan_cnt >= 25000) begin
                scan_cnt <= 0;
                curr_row <= curr_row + 1'b1; // Move to next row
            end else begin
                scan_cnt <= scan_cnt + 1'b1;
            end

            // 2. Drive Rows (One Low at a time)
            case (curr_row)
                2'd0: row_out <= 4'b1110;
                2'd1: row_out <= 4'b1101;
                2'd2: row_out <= 4'b1011;
                2'd3: row_out <= 4'b0111;
            endcase

            // 3. Register Input & Update Direction
            //    Includes check to prevent 180-degree turns (e.g., can't go UP if currently DOWN).
            if (key_D && dir_out != DOWN)       dir_out <= UP;
            else if (key_5 && dir_out != UP)    dir_out <= DOWN;
            else if (key_3 && dir_out != RIGHT) dir_out <= LEFT;
            else if (key_9 && dir_out != LEFT)  dir_out <= RIGHT; 
        end
    end
endmodule