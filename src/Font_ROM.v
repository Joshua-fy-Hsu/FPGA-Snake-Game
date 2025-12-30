`timescale 1ns / 1ps

/*
 * Module: Font_ROM
 * Description: 
 * A Read-Only Memory containing 8x8 bitmap data for characters.
 * Used by the VGA Renderer to draw text (Score, WIN/LOSE, Timer).
 * Input: Character Code + Row Index (0-7).
 * Output: 8-bit row pixel data.
 */
module Font_ROM (
    input  wire [3:0] char_code, // Character selector
    input  wire [2:0] row_idx,   // Row of the character (0 top, 7 bottom)
    output reg  [7:0] row_bits   // 8 horizontal pixels
);
    always @(*) begin
        case (char_code)
            // 0: 'G'
            4'd0: case (row_idx)
                3'd0: row_bits = 8'b01111110;
                3'd1: row_bits = 8'b01000000;
                3'd2: row_bits = 8'b01001110;
                3'd3: row_bits = 8'b01000010;
                3'd4: row_bits = 8'b01111110;
                default: row_bits = 8'b00000000;
            endcase
            // 1: 'A'
            4'd1: case (row_idx)
                3'd0: row_bits = 8'b00011000;
                3'd1: row_bits = 8'b00100100;
                3'd2: row_bits = 8'b01000010;
                3'd3: row_bits = 8'b01111110;
                3'd4: row_bits = 8'b01000010;
                default: row_bits = 8'b00000000;
            endcase
            // 2: 'M'
            4'd2: case (row_idx)
                3'd0: row_bits = 8'b01000010;
                3'd1: row_bits = 8'b01100110;
                3'd2: row_bits = 8'b01011010;
                3'd3: row_bits = 8'b01000010;
                3'd4: row_bits = 8'b01000010;
                default: row_bits = 8'b00000000;
            endcase
            // 3: 'E'
            4'd3: case (row_idx)
                3'd0: row_bits = 8'b01111110;
                3'd1: row_bits = 8'b01000000;
                3'd2: row_bits = 8'b01111100;
                3'd3: row_bits = 8'b01000000;
                3'd4: row_bits = 8'b01111110;
                default: row_bits = 8'b00000000;
            endcase
            // 4: ' ' (space)
            4'd4: row_bits = 8'b00000000;
            // 5: 'O'
            4'd5: case (row_idx)
                3'd0: row_bits = 8'b00111100;
                3'd1: row_bits = 8'b01000010;
                3'd2: row_bits = 8'b01000010;
                3'd3: row_bits = 8'b01000010;
                3'd4: row_bits = 8'b00111100;
                default: row_bits = 8'b00000000;
            endcase
            // 6: 'V'
            4'd6: case (row_idx)
                3'd0: row_bits = 8'b01000010;
                3'd1: row_bits = 8'b01000010;
                3'd2: row_bits = 8'b00100100;
                3'd3: row_bits = 8'b00100100;
                3'd4: row_bits = 8'b00011000;
                default: row_bits = 8'b00000000;
            endcase
            // 7: 'R'
            4'd7: case (row_idx)
                3'd0: row_bits = 8'b01111100;
                3'd1: row_bits = 8'b01000010;
                3'd2: row_bits = 8'b01111100;
                3'd3: row_bits = 8'b01000100;
                3'd4: row_bits = 8'b01000010;
                default: row_bits = 8'b00000000;
            endcase
            // 8: 'B'
            4'd8: case (row_idx)
                3'd0: row_bits = 8'b01111100;
                3'd1: row_bits = 8'b01000010;
                3'd2: row_bits = 8'b01111100;
                3'd3: row_bits = 8'b01000010;
                3'd4: row_bits = 8'b01111100;
                default: row_bits = 8'b00000000;
            endcase
            // 9: 'L'
            4'd9: case (row_idx)
                3'd0: row_bits = 8'b01000000;
                3'd1: row_bits = 8'b01000000;
                3'd2: row_bits = 8'b01000000;
                3'd3: row_bits = 8'b01000000;
                3'd4: row_bits = 8'b01111110;
                default: row_bits = 8'b00000000;
            endcase
            // 10: 'U'
            4'd10: case (row_idx)
                3'd0: row_bits = 8'b01000010;
                3'd1: row_bits = 8'b01000010;
                3'd2: row_bits = 8'b01000010;
                3'd3: row_bits = 8'b01000010;
                3'd4: row_bits = 8'b00111100;
                default: row_bits = 8'b00000000;
            endcase
            // 11: 'W'
            4'd11: case (row_idx)
                3'd0: row_bits = 8'b10000010;
                3'd1: row_bits = 8'b10000010;
                3'd2: row_bits = 8'b10010010;
                3'd3: row_bits = 8'b10101010;
                3'd4: row_bits = 8'b01000100;
                default: row_bits = 8'b00000000;
            endcase
            // 12: 'I'
            4'd12: case (row_idx)
                3'd0: row_bits = 8'b01111110;
                3'd1: row_bits = 8'b00011000;
                3'd2: row_bits = 8'b00011000;
                3'd3: row_bits = 8'b00011000;
                3'd4: row_bits = 8'b01111110;
                default: row_bits = 8'b00000000;
            endcase
            // 13: 'N'
            4'd13: case (row_idx)
                3'd0: row_bits = 8'b10000010;
                3'd1: row_bits = 8'b11000010;
                3'd2: row_bits = 8'b10100010;
                3'd3: row_bits = 8'b10010010;
                3'd4: row_bits = 8'b10001110;
                default: row_bits = 8'b00000000;
            endcase
             // 14: 'D'
            4'd14: case (row_idx)
                3'd0: row_bits = 8'b01111000;
                3'd1: row_bits = 8'b01000100;
                3'd2: row_bits = 8'b01000100;
                3'd3: row_bits = 8'b01000100;
                3'd4: row_bits = 8'b01111000;
                default: row_bits = 8'b00000000;
            endcase
            // 15: 'T'
            4'd15: case (row_idx)
                3'd0: row_bits = 8'b01111110;
                3'd1: row_bits = 8'b00011000;
                3'd2: row_bits = 8'b00011000;
                3'd3: row_bits = 8'b00011000;
                3'd4: row_bits = 8'b00011000;
                default: row_bits = 8'b00000000;
            endcase

            default: row_bits = 8'b00000000;
        endcase
    end
endmodule