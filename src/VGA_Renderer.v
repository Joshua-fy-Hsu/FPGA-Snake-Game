`timescale 1ns / 1ps

/*
 * Module: VGA_Renderer
 * Description: 
 * Implements the pixel-processing pipeline for the VGA output.
 * - Maps game state (coordinates, lives) to pixel colors.
 * - Renders sprites for Snake, Apple, Cannon, and Bullet.
 * - Renders UI: Hearts for lives (using bitmaps) and a countdown timer.
 */
module VGA_Renderer #(
    parameter integer GRID_W     = 40,
    parameter integer GRID_H     = 30,
    parameter integer MAX_LEN    = 64,
    parameter integer CELL_SIZE  = 16
)(
    input  wire                   vga_clk,        // 25.175 MHz pixel clock
    input  wire                   rst_n,          // Active-low reset
    input  wire [9:0]             pixel_x,        // Current pixel X (0-639)
    input  wire [9:0]             pixel_y,        // Current pixel Y (0-479)
    input  wire                   display_active, // High when inside visible screen area

    // --- Game State Inputs ---
    input  wire [$clog2(GRID_W)-1:0] food_x,
    input  wire [$clog2(GRID_H)-1:0] food_y,
    input  wire [($clog2(GRID_W)*MAX_LEN)-1:0] body1_x_flat, // Flattened array of P1 X coords
    input  wire [($clog2(GRID_H)*MAX_LEN)-1:0] body1_y_flat, // Flattened array of P1 Y coords
    input  wire [($clog2(GRID_W)*MAX_LEN)-1:0] body2_x_flat, // Flattened array of P2 X coords
    input  wire [($clog2(GRID_H)*MAX_LEN)-1:0] body2_y_flat, // Flattened array of P2 Y coords
    input  wire [15:0]             len_1, len_2,   // Current lengths of snakes
    input  wire [15:0]             score_1, score_2, 
    input  wire [4:0]              timer_val,      // Game countdown (seconds)
    input  wire                    game_over,      // High if game ended
    input  wire [1:0]              winner,         // 0=Draw, 1=P1, 2=P2
    input  wire [2:0]              life_1, life_2, // Player lives (0-5)
    input  wire [$clog2(GRID_H)-1:0] cannon1_y, cannon2_y, // Cannon vertical positions
    input  wire [9:0]                bullet1_px, bullet2_px, // Bullet X pixel coords
    input  wire [9:0]                bullet1_py, bullet2_py, // Bullet Y pixel coords
    input  wire                      bullet1_active, bullet2_active, // Bullet visibility flags
    
    // --- VGA Color Output (RGB 4:4:4) ---
    output reg  [3:0]              vga_R,
    output reg  [3:0]              vga_G,
    output reg  [3:0]              vga_B
);
    localparam XW = $clog2(GRID_W);
    localparam YW = $clog2(GRID_H);

    // ---------------------------------------------------------
    // 1. Array Unpacking
    // Reshapes the flat input vectors back into accessible 2D arrays
    // for easier indexing (e.g., b1_x[segment_index]).
    // ---------------------------------------------------------
    wire [XW-1:0] b1_x [0:MAX_LEN-1]; wire [YW-1:0] b1_y [0:MAX_LEN-1];
    wire [XW-1:0] b2_x [0:MAX_LEN-1]; wire [YW-1:0] b2_y [0:MAX_LEN-1];
    genvar i;
    generate
        for (i = 0; i < MAX_LEN; i = i + 1) begin : UNPACK
            assign b1_x[i] = body1_x_flat[XW*(i+1)-1 : XW*i];
            assign b1_y[i] = body1_y_flat[YW*(i+1)-1 : YW*i];
            assign b2_x[i] = body2_x_flat[XW*(i+1)-1 : XW*i];
            assign b2_y[i] = body2_y_flat[YW*(i+1)-1 : YW*i];
        end
    endgenerate

    // ---------------------------------------------------------
    // 2. Coordinate Transformation
    // Converts absolute pixel coordinates to Game Grid coordinates.
    // 'cell_px/py' provide the sub-pixel offset (0-15) within a specific grid cell.
    // ---------------------------------------------------------
    wire [XW-1:0] grid_x = pixel_x / CELL_SIZE;
    wire [YW-1:0] grid_y = pixel_y / CELL_SIZE;
    wire [3:0]    cell_px = pixel_x[3:0];
    wire [3:0]    cell_py = pixel_y[3:0];
    
    // Boundary check for the game board walls
    wire is_wall = (grid_x == 0) || (grid_x == GRID_W[XW-1:0]-1) ||
                   (grid_y == 0) || (grid_y == GRID_H[YW-1:0]-1);

    // ---------------------------------------------------------
    // 3. Sprite Logic: Cannons
    // Uses hardcoded pixel checks to draw the cannon's wheel, wood body,
    // metal barrel, and fuse based on relative position.
    // ---------------------------------------------------------
    reg is_c_wheel, is_c_wood, is_c_metal, is_c_fuse;
    wire [3:0] rel_px = (grid_x == 0) ? cell_px : (15 - cell_px); // Mirror sprite for Right Cannon
    always @* begin
        is_c_wheel = 0; is_c_wood = 0; is_c_metal = 0; is_c_fuse = 0;
        if ((grid_x == 0 && grid_y == cannon1_y) || (grid_x == GRID_W[XW-1:0]-1 && grid_y == cannon2_y)) begin
            // Wheel: Circle approximation
            if (rel_px >= 3 && rel_px <= 9 && cell_py >= 8 && cell_py <= 14) begin
                 if (!((rel_px==3 && cell_py==8) || (rel_px==9 && cell_py==8) || (rel_px==3 && cell_py==14) || (rel_px==9 && cell_py==14)))
                     is_c_wheel = 1;
            end
            // Body: Rectangular block
            if (rel_px >= 1 && rel_px <= 8 && cell_py >= 8 && cell_py <= 12 && !is_c_wheel) is_c_wood = 1;
            // Barrel: Grey cylinder
            if (rel_px >= 4 && rel_px <= 14 && cell_py >= 2 && cell_py <= 8) begin
                if (!(rel_px == 4 && cell_py == 2)) is_c_metal = 1;
            end
            // Fuse: Orange tip
            if (rel_px == 5 && cell_py < 2) is_c_fuse = 1;
        end
    end

    // ---------------------------------------------------------
    // 4. Object Logic: Bullets
    // Checks Manhattan distance (|dx| + |dy|) to draw a diamond-shaped bullet.
    // ---------------------------------------------------------
    reg is_bullet;
    reg [10:0] diff_x, diff_y;
    always @* begin
        is_bullet = 0;
        if (bullet1_active) begin
            diff_x = (pixel_x > bullet1_px) ? (pixel_x - bullet1_px) : (bullet1_px - pixel_x);
            diff_y = (pixel_y > bullet1_py) ? (pixel_y - bullet1_py) : (bullet1_py - pixel_y);
            if (diff_x + diff_y < 7) is_bullet = 1; // Bullet Size = 7px radius
        end
        if (bullet2_active) begin
            diff_x = (pixel_x > bullet2_px) ? (pixel_x - bullet2_px) : (bullet2_px - pixel_x);
            diff_y = (pixel_y > bullet2_py) ? (pixel_y - bullet2_py) : (bullet2_py - pixel_y);
            if (diff_x + diff_y < 7) is_bullet = 1;
        end
    end
    
    // ---------------------------------------------------------
    // 5. Snake Logic
    // Iterates through body segments to check if current grid cell contains a snake part.
    // Calculates head orientation to draw eyes in the correct direction.
    // ---------------------------------------------------------
    reg s1_head, s1_body, s2_head, s2_body, is_snake_highlight;
    reg [7:0] s1_seg_id, s2_seg_id; 
    reg is_corner_cut;
    integer j;
    
    // Determine Head Orientation (Up/Right/Down/Left) for Eye rendering
    reg [1:0] p1_dir, p2_dir;
    always @* begin
        if (len_1 > 1) begin
             if (b1_y[0] < b1_y[1]) p1_dir=0;      // UP
             else if (b1_x[0] > b1_x[1]) p1_dir=1; // RIGHT
             else if (b1_y[0] > b1_y[1]) p1_dir=2; // DOWN
             else p1_dir=3;                        // LEFT
        end else p1_dir=1;
        // Repeat for Snake 2
        if (len_2 > 1) begin
             if (b2_y[0] < b2_y[1]) p2_dir=0;
             else if (b2_x[0] > b2_x[1]) p2_dir=1; else if (b2_y[0] > b2_y[1]) p2_dir=2; else p2_dir=3;
        end else p2_dir=3;
    end

    // Eye/Pupil pixel checks
    reg is_eye_1, is_pupil_1, is_eye_2, is_pupil_2;
    always @* begin
        is_eye_1 = 0; is_pupil_1 = 0;
        if (s1_head) begin
            case(p1_dir)
                0: begin is_eye_1=(cell_py<6 && (cell_px<6 || cell_px>9));
                   is_pupil_1=(cell_py<4 && (cell_px==4 || cell_px==11)); end 
                // ... (Cases 1, 2, 3 omitted for brevity but follow same logic)
                1: begin is_eye_1=(cell_px>9 && (cell_py<6 || cell_py>9));
                   is_pupil_1=(cell_px>11 && (cell_py==4 || cell_py==11)); end 
                2: begin is_eye_1=(cell_py>9 && (cell_px<6 || cell_px>9));
                   is_pupil_1=(cell_py>11 && (cell_px==4 || cell_px==11)); end 
                3: begin is_eye_1=(cell_px<6 && (cell_py<6 || cell_py>9));
                   is_pupil_1=(cell_px<4 && (cell_py==4 || cell_py==11)); end 
            endcase
        end
        // Repeat for Snake 2
        is_eye_2 = 0; is_pupil_2 = 0;
        if (s2_head) begin
            case(p2_dir)
                0: begin is_eye_2=(cell_py<6 && (cell_px<6 || cell_px>9));
                   is_pupil_2=(cell_py<4 && (cell_px==4 || cell_px==11)); end
                1: begin is_eye_2=(cell_px>9 && (cell_py<6 || cell_py>9));
                   is_pupil_2=(cell_px>11 && (cell_py==4 || cell_py==11)); end
                2: begin is_eye_2=(cell_py>9 && (cell_px<6 || cell_px>9));
                   is_pupil_2=(cell_py>11 && (cell_px==4 || cell_py==11)); end
                3: begin is_eye_2=(cell_px<6 && (cell_py<6 || cell_py>9));
                   is_pupil_2=(cell_px<4 && (cell_py==4 || cell_py==11)); end
            endcase
        end
    end

    // Body Segment Rendering Loop
    always @* begin
        // Corner cutting creates "rounded" look for segments
        is_corner_cut = (cell_px < 2 && cell_py < 2) || (cell_px > 13 && cell_py < 2) || 
                        (cell_px < 2 && cell_py > 13) || (cell_px > 13 && cell_py > 13);
        s1_head = 0; s1_body = 0; s1_seg_id = 0; 
        s2_head = 0; s2_body = 0; s2_seg_id = 0; 
        is_snake_highlight = 0;
        
        if (!is_wall && !is_corner_cut) begin
            // Lighting highlight on top-left of segment
            if ((cell_px >= 3 && cell_px <= 5 && cell_py >= 3 && cell_py <= 5)) is_snake_highlight = 1;
            
            // Check Snake 1 Body
            if ((grid_x == b1_x[0]) && (grid_y == b1_y[0])) s1_head = 1;
            for (j = 1; j < MAX_LEN; j = j + 1) begin
                if (j < len_1) begin
                    if ((grid_x == b1_x[j]) && (grid_y == b1_y[j])) begin s1_body = 1; s1_seg_id = j; end
                end
            end
            
            // Check Snake 2 Body
            if ((grid_x == b2_x[0]) && (grid_y == b2_y[0])) s2_head = 1;
            for (j = 1; j < MAX_LEN; j = j + 1) begin
                if (j < len_2) begin
                    if ((grid_x == b2_x[j]) && (grid_y == b2_y[j])) begin s2_body = 1; s2_seg_id = j; end
                end
            end
        end
    end

    // ---------------------------------------------------------
    // 6. Food Logic (Apple)
    // ---------------------------------------------------------
    wire food_pixel = (grid_x == food_x) && (grid_y == food_y) && !is_wall;
    reg is_apple_body, is_apple_highlight, is_apple_stem, is_apple_leaf;
    always @* begin
        is_apple_body = 0; is_apple_highlight = 0; is_apple_stem = 0; is_apple_leaf = 0;
        if (food_pixel) begin
            if (!((cell_px < 4 && cell_py < 4) || (cell_px > 11 && cell_py < 4) || 
                  (cell_px < 4 && cell_py > 11) || (cell_px > 11 && cell_py > 11))) is_apple_body = 1;
            if (cell_px == 5 && cell_py == 6) is_apple_highlight = 1;
            if (cell_px == 7 && cell_py >= 1 && cell_py <= 3) is_apple_stem = 1;
            if ((cell_px >= 8 && cell_px <= 10) && (cell_py >= 1 && cell_py <= 2)) is_apple_leaf = 1;
        end
    end

    // Checkerboard Background Pattern
    reg [11:0] bg_color;
    always @* begin
        // XOR grid bits to create checker pattern
        if ((grid_x[0] ^ grid_y[0]) == 1'b0) bg_color = {4'h8, 4'hD, 4'h4}; // Light Green
        else                                 bg_color = {4'h7, 4'hC, 4'h3}; // Dark Green
    end

    // ---------------------------------------------------------
    // 7. UI Rendering Helpers (Text, Numbers, Hearts)
    // ---------------------------------------------------------
    // ... [get_text_char and get_digit_row functions omitted for brevity] ...
    function [3:0] get_text_char; input [1:0] win_code;
    input [3:0] c_idx; begin case(win_code) 0:case(c_idx) 0:get_text_char=14; 1:get_text_char=7; 2:get_text_char=1; 3:get_text_char=11; default:get_text_char=4; endcase 1:case(c_idx) 0:get_text_char=8; 1:get_text_char=9; 2:get_text_char=10; 3:get_text_char=3; 4:get_text_char=4; 5:get_text_char=11; 6:get_text_char=12;
    7:get_text_char=13; 8:get_text_char=4; default:get_text_char=4; endcase 2:case(c_idx) 0:get_text_char=7; 1:get_text_char=3; 2:get_text_char=14; 3:get_text_char=4; 4:get_text_char=4; 5:get_text_char=11; 6:get_text_char=12; 7:get_text_char=13; 8:get_text_char=4; default:get_text_char=4; endcase default: get_text_char=4;
    endcase end endfunction
    function [7:0] get_digit_row; input [3:0] num; input [2:0] row;
    begin case (num) 0:case(row)0:get_digit_row=8'b00111100;1:get_digit_row=8'b01100110;2:get_digit_row=8'b01101110;3:get_digit_row=8'b01110110;4:get_digit_row=8'b01100110;5:get_digit_row=8'b01100110;6:get_digit_row=8'b00111100;default:get_digit_row=8'b0;endcase 1:case(row)0:get_digit_row=8'b00011000;1:get_digit_row=8'b00111000;2:get_digit_row=8'b00011000;3:get_digit_row=8'b00011000;4:get_digit_row=8'b00011000;5:get_digit_row=8'b00011000;6:get_digit_row=8'b01111110;default:get_digit_row=8'b0;endcase 2:case(row)0:get_digit_row=8'b00111100;1:get_digit_row=8'b01100110;2:get_digit_row=8'b00000110;3:get_digit_row=8'b00011100;4:get_digit_row=8'b01100000;5:get_digit_row=8'b01100110;6:get_digit_row=8'b01111110;default:get_digit_row=8'b0;endcase 3:case(row)0:get_digit_row=8'b01111100;1:get_digit_row=8'b01100110;2:get_digit_row=8'b00000110;3:get_digit_row=8'b00111100;4:get_digit_row=8'b00000110;5:get_digit_row=8'b01100110;6:get_digit_row=8'b01111100;default:get_digit_row=8'b0;endcase 4:case(row)0:get_digit_row=8'b00001100;1:get_digit_row=8'b00011100;2:get_digit_row=8'b00101100;3:get_digit_row=8'b01001100;4:get_digit_row=8'b01111110;5:get_digit_row=8'b00001100;6:get_digit_row=8'b00011110;default:get_digit_row=8'b0;endcase 5:case(row)0:get_digit_row=8'b01111110;1:get_digit_row=8'b01100000;2:get_digit_row=8'b01111100;3:get_digit_row=8'b00000110;4:get_digit_row=8'b00000110;5:get_digit_row=8'b01100110;6:get_digit_row=8'b00111100;default:get_digit_row=8'b0;endcase 6:case(row)0:get_digit_row=8'b00111100;1:get_digit_row=8'b01100110;2:get_digit_row=8'b01100000;3:get_digit_row=8'b01111100;4:get_digit_row=8'b01100110;5:get_digit_row=8'b01100110;6:get_digit_row=8'b00111100;default:get_digit_row=8'b0;endcase 7:case(row)0:get_digit_row=8'b01111110;1:get_digit_row=8'b01100110;2:get_digit_row=8'b00000110;3:get_digit_row=8'b00001100;4:get_digit_row=8'b00011000;5:get_digit_row=8'b00011000;6:get_digit_row=8'b00011000;default:get_digit_row=8'b0;endcase 8:case(row)0:get_digit_row=8'b00111100;1:get_digit_row=8'b01100110;2:get_digit_row=8'b01101110;3:get_digit_row=8'b00111100;4:get_digit_row=8'b01100110;5:get_digit_row=8'b01100110;6:get_digit_row=8'b00111100;default:get_digit_row=8'b0;endcase 9:case(row)0:get_digit_row=8'b00111100;1:get_digit_row=8'b01100110;2:get_digit_row=8'b01100110;3:get_digit_row=8'b00111110;4:get_digit_row=8'b00000110;5:get_digit_row=8'b01100110;6:get_digit_row=8'b00111100;default:get_digit_row=8'b0;endcase default: get_digit_row = 8'b0;
    endcase end endfunction

    // Custom Heart Bitmap (8x7 pixel)
    function [7:0] get_heart_row; input [2:0] row;
    begin
        case (row)
            3'd0: get_heart_row = 8'b01100110; //  ** **
            3'd1: get_heart_row = 8'b11111111; // ********
            3'd2: get_heart_row = 8'b11111111; // ********
            3'd3: get_heart_row = 8'b11111111; // ********
            3'd4: get_heart_row = 8'b01111110; //  ******
            3'd5: get_heart_row = 8'b00111100; //   ****
            3'd6: get_heart_row = 8'b00011000; //    **
            default: get_heart_row = 8'b00000000;
        endcase
    end
    endfunction

    // UI State & Positioning
    wire [7:0] char_bitmap; reg [3:0] char_code_rom; reg [2:0] row_idx; 
    reg [3:0] col_idx; // 4-bit column index needed for heart stride (9px)
    
    Font_ROM u_Font_ROM (.char_code(char_code_rom), .row_idx(row_idx), .row_bits(char_bitmap));

    localparam TEXT_X=(640-9*8*8)/2, TEXT_Y=(480-8*8)/2, TIME_X=270, TIME_Y=24, S1_X=32, S2_X=544, S_Y=24;
    localparam LIFE1_X = 32, LIFE1_Y = 40, LIFE2_X = 544, LIFE2_Y = 40; 

    // Extract digits for Score/Time
    integer d1_1, d1_0, d2_1, d2_0, t_1, t_0;
    always @* begin d1_1=(score_1/10)%10; d1_0=score_1%10; d2_1=(score_2/10)%10; d2_0=score_2%10; t_1=(timer_val/10)%10; t_0=timer_val%10; end

    reg win_px, time_px, s1_px, s2_px, life1_px, life2_px;
    reg [7:0] bit_row;
    always @* begin
        win_px=0; time_px=0; s1_px=0; s2_px=0; life1_px=0; life2_px=0; char_code_rom=0;
        row_idx=0; col_idx=0; bit_row=0;
        
        // Game Over Screen (Winner Text)
        if (game_over && pixel_x >= TEXT_X && pixel_x < TEXT_X + 9*8*8 && pixel_y >= TEXT_Y && pixel_y < TEXT_Y + 8*8) begin
            row_idx = (pixel_y - TEXT_Y) / 8;
            col_idx = 7 - (((pixel_x - TEXT_X) / 8) % 8);
            char_code_rom = get_text_char(winner, (pixel_x - TEXT_X) / (64));
            win_px = char_bitmap[col_idx];
        end 
        
        else if (display_active) begin
            // 1. Timer Display (Middle Top)
            if (pixel_y >= TIME_Y && pixel_y < TIME_Y + 8 && pixel_x >= TIME_X && pixel_x < TIME_X + 56) begin
                 row_idx = pixel_y - TIME_Y;
                 col_idx = 7 - ((pixel_x - TIME_X) % 8);
                 case ((pixel_x - TIME_X)/8) 0:char_code_rom=15; 1:char_code_rom=12; 2:char_code_rom=2; 3:char_code_rom=3; 4:char_code_rom=4; 5:bit_row=get_digit_row(t_1, row_idx);
                 6:bit_row=get_digit_row(t_0, row_idx); endcase
                 time_px = ((pixel_x - TIME_X)/8 < 5) ? char_bitmap[col_idx] : bit_row[col_idx];
            end
            
            // 2. Heart Display (Mapped to Lives for Visibility)
            // Left Player Hearts (Life 1)
            if (pixel_y >= LIFE1_Y && pixel_y < LIFE1_Y+8 && pixel_x >= LIFE1_X && pixel_x < LIFE1_X + (16*9)) begin
                // Render hearts based on 'life_1' count so they appear at game start
                if (((pixel_x - LIFE1_X) / 9) < life_1) begin
                    col_idx = (pixel_x - LIFE1_X) % 9;
                    if (col_idx < 8) begin // Leave 1px gap
                        bit_row = get_heart_row(pixel_y - LIFE1_Y);
                        life1_px = bit_row[7 - col_idx];
                    end
                end
            end
            // Right Player Hearts (Life 2)
            if (pixel_y >= LIFE2_Y && pixel_y < LIFE2_Y+8 && pixel_x >= LIFE2_X && pixel_x < LIFE2_X + (16*9)) begin
                if (((pixel_x - LIFE2_X) / 9) < life_2) begin
                    col_idx = (pixel_x - LIFE2_X) % 9;
                    if (col_idx < 8) begin
                        bit_row = get_heart_row(pixel_y - LIFE2_Y);
                        life2_px = bit_row[7 - col_idx];
                    end
                end
            end
        end
    end

    // ---------------------------------------------------------
    // 8. Final Color Priority Encoder
    // Determines final RGB color based on overlapping flags.
    // Priority: Text > UI > Objects > Background
    // ---------------------------------------------------------
    reg [3:0] seg_color_R, seg_color_G, seg_color_B;
    always @(posedge vga_clk or negedge rst_n) begin
        if (!rst_n) {vga_R, vga_G, vga_B} <= 0;
        else if (display_active) begin
            // Layer 1: Text & UI
            if (win_px) begin case(winner) 1:{vga_R,vga_G,vga_B}<={4'h3,4'h6,4'hF}; // Blue
                2:{vga_R,vga_G,vga_B}<={4'hF,4'h3,4'h3}; default:{vga_R,vga_G,vga_B}<={4'hF,4'hF,4'hF}; endcase end
            else if (time_px) {vga_R, vga_G, vga_B} <= {4'hF, 4'hF, 4'h0}; // Yellow
            else if (s1_px || life1_px)   {vga_R, vga_G, vga_B} <= {4'h3, 4'h6, 4'hF}; // Blue UI
            else if (s2_px || life2_px)   {vga_R, vga_G, vga_B} <= {4'hF, 4'h3, 4'h3}; // Red UI
            
            // Layer 2: Projectiles & Obstacles
            else if (is_bullet)          {vga_R, vga_G, vga_B} <= {4'h0, 4'h0, 4'h0};
            else if (is_c_fuse)          {vga_R, vga_G, vga_B} <= {4'hF, 4'h8, 4'h0};
            else if (is_c_wheel)         {vga_R, vga_G, vga_B} <= {4'h8, 4'h5, 4'h2};
            else if (is_c_metal)         {vga_R, vga_G, vga_B} <= {4'h3, 4'h3, 4'h4};
            else if (is_c_wood)          {vga_R, vga_G, vga_B} <= {4'h8, 4'h4, 4'h1};
            else if (is_wall)            {vga_R, vga_G, vga_B} <= {4'hB, 4'hB, 4'hB};
            
            // Layer 3: Snake 1 (Blue Gradient)
            else if (s1_head) begin
                if (is_pupil_1)      {vga_R, vga_G, vga_B} <= {4'h0, 4'h0, 4'h0};
                else if (is_eye_1)   {vga_R, vga_G, vga_B} <= {4'hF, 4'hF, 4'hF};
                else                 {vga_R, vga_G, vga_B} <= {4'h4, 4'hA, 4'hF};
            end
            else if (s1_body) begin
                if (is_snake_highlight) {vga_R, vga_G, vga_B} <= {4'h8, 4'hD, 4'hF};
                else begin
                    seg_color_G = (s1_seg_id > 20) ? 4'h4 : (14 - (s1_seg_id >> 1));
                    {vga_R, vga_G, vga_B} <= {4'h2, seg_color_G, 4'hF};
                end
            end
            
            // Layer 4: Snake 2 (Red Gradient)
            else if (s2_head) begin
                if (is_pupil_2)      {vga_R, vga_G, vga_B} <= {4'h0, 4'h0, 4'h0};
                else if (is_eye_2)   {vga_R, vga_G, vga_B} <= {4'hF, 4'hF, 4'hF};
                else                 {vga_R, vga_G, vga_B} <= {4'hF, 4'h8, 4'h8};
            end
            else if (s2_body) begin
                if (is_snake_highlight) {vga_R, vga_G, vga_B} <= {4'hF, 4'hB, 4'hB};
                else begin
                    seg_color_G = (s2_seg_id > 14) ? 4'h1 : (8 - (s2_seg_id >> 1));
                    {vga_R, vga_G, vga_B} <= {4'hF, seg_color_G, 4'h2};
                end
            end
            
            // Layer 5: Food & Background
            else if (food_pixel) begin
                if (is_apple_highlight)      {vga_R, vga_G, vga_B} <= {4'hF, 4'hF, 4'hF};
                else if (is_apple_leaf)      {vga_R, vga_G, vga_B} <= {4'h4, 4'hF, 4'h0};
                else if (is_apple_stem)      {vga_R, vga_G, vga_B} <= {4'h8, 4'h4, 4'h0};
                else if (is_apple_body)      {vga_R, vga_G, vga_B} <= {4'hE, 4'h1, 4'h1};
                else                         {vga_R, vga_G, vga_B} <= bg_color;
            end
            else {vga_R, vga_G, vga_B} <= bg_color;
        end else {vga_R, vga_G, vga_B} <= 0;
    end
endmodule