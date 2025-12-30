`timescale 1ns / 1ps

/*
 * Module: Snake_Engine
 * Description: 
 * The core logical engine for the game. Responsibilities include:
 * 1. Updates snake positions based on direction inputs and speed tick.
 * 2. Detects collisions (Head vs Wall, Head vs Body, Head vs Bullet).
 * 3. Manages Game Over state, scoring, lives, and immunity periods.
 * 4. Outputs flattened arrays of body coordinates for the renderer.
 */
module Snake_Engine #(
    parameter integer GRID_W   = 40,
    parameter integer GRID_H   = 30,
    parameter integer MAX_LEN  = 64,
    parameter integer INIT_LEN = 3
)(
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire                         game_tick, // Update Strobe
    input  wire [1:0]                   dir_1, dir_2, 
    input  wire [$clog2(GRID_W)-1:0]    food_x,
    input  wire [$clog2(GRID_H)-1:0]    food_y,
    input  wire [9:0]                   bullet1_px, bullet2_px,
    input  wire [9:0]                   bullet1_py, bullet2_py,
    input  wire                         bullet1_active, bullet2_active,

    output reg                          consume_o, // High if apple eaten
    output reg                          game_over,
    output reg  [1:0]                   winner,    // 0=Draw, 1=P1, 2=P2
    output reg  [15:0]                  score_1, score_2,
    output reg  [4:0]                   timer_out, // Game countdown timer
    output reg  [2:0]                   life_1, life_2,
    
    // Flattened arrays for Renderer 
    output wire [($clog2(GRID_W)*MAX_LEN)-1:0] body1_x_flat, body1_y_flat,
    output wire [($clog2(GRID_W)*MAX_LEN)-1:0] body2_x_flat, body2_y_flat,
    output reg [15:0] len_1, len_2
);
    localparam integer XW = $clog2(GRID_W);
    localparam integer YW = $clog2(GRID_H);
    localparam [1:0] UP=2'b00, RIGHT=2'b01, DOWN=2'b10, LEFT=2'b11;

    // Convert Bullet Pixel Coordinates to Grid Coordinates for collision
    wire [XW-1:0] b1_gx = bullet1_px[9:4]; wire [YW-1:0] b1_gy = bullet1_py[9:4];
    wire [XW-1:0] b2_gx = bullet2_px[9:4]; wire [YW-1:0] b2_gy = bullet2_py[9:4];

    // Snake Body Memory (Head is index 0)
    reg [XW-1:0] b1_x [0:MAX_LEN-1]; reg [YW-1:0] b1_y [0:MAX_LEN-1];
    reg [XW-1:0] head1_next_x;       reg [YW-1:0] head1_next_y;
    reg [XW-1:0] b2_x [0:MAX_LEN-1]; reg [YW-1:0] b2_y [0:MAX_LEN-1];
    reg [XW-1:0] head2_next_x;       reg [YW-1:0] head2_next_y;

    integer i, k;
    reg [24:0] sec_cnt;
    reg [3:0] immune_cnt_1, immune_cnt_2; // Counters for temporary invincibility

    // ----------------------------------------
    // 1. Game Countdown Timer
    //    Decrements 'timer_out' every second (~25M cycles).
    // ----------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timer_out <= 30;
            sec_cnt <= 0;
        end else if (!game_over) begin
            if (sec_cnt >= 25175000) begin
                sec_cnt <= 0;
                if (timer_out > 0) timer_out <= timer_out - 1'b1;
            end else sec_cnt <= sec_cnt + 1'b1;
        end
    end

    // ----------------------------------------
    // 2. Movement Logic
    //    Determine the next Head coordinate based on direction.
    //    Prevent 180-degree physical turns by checking body position.
    // ----------------------------------------
    reg [1:0] p1_phys_dir, p2_phys_dir, use_dir_1, use_dir_2;
    always @* begin
        head1_next_x = b1_x[0]; head1_next_y = b1_y[0];
        head2_next_x = b2_x[0]; head2_next_y = b2_y[0];
        
        // P1 Physical Direction Check (cannot move into neck)
        if (len_1 > 1) begin
            if      (b1_x[0] > b1_x[1]) p1_phys_dir = RIGHT;
            else if (b1_x[0] < b1_x[1]) p1_phys_dir = LEFT;
            else if (b1_y[0] > b1_y[1]) p1_phys_dir = DOWN;
            else                        p1_phys_dir = UP;
            if (dir_1 == (p1_phys_dir ^ 2'b10)) use_dir_1 = p1_phys_dir; else use_dir_1 = dir_1;
        end else use_dir_1 = dir_1;

        // P2 Physical Direction Check
        if (len_2 > 1) begin
            if      (b2_x[0] > b2_x[1]) p2_phys_dir = RIGHT;
            else if (b2_x[0] < b2_x[1]) p2_phys_dir = LEFT;
            else if (b2_y[0] > b2_y[1]) p2_phys_dir = DOWN;
            else                        p2_phys_dir = UP;
            if (dir_2 == (p2_phys_dir ^ 2'b10)) use_dir_2 = p2_phys_dir; else use_dir_2 = dir_2;
        end else use_dir_2 = dir_2;

        // Calculate next coordinates (Wrapping logic removed for walls)
        case(use_dir_1)
            UP:    head1_next_y = (b1_y[0] > 0) ? b1_y[0] - 1'b1 : {YW{1'b1}};
            DOWN:  head1_next_y = b1_y[0] + 1'b1;
            LEFT:  head1_next_x = (b1_x[0] > 0) ? b1_x[0] - 1'b1 : {XW{1'b1}};
            RIGHT: head1_next_x = b1_x[0] + 1'b1;
        endcase
        case(use_dir_2)
            UP:    head2_next_y = (b2_y[0] > 0) ? b2_y[0] - 1'b1 : {YW{1'b1}};
            DOWN:  head2_next_y = b2_y[0] + 1'b1;
            LEFT:  head2_next_x = (b2_x[0] > 0) ? b2_x[0] - 1'b1 : {XW{1'b1}};
            RIGHT: head2_next_x = b2_x[0] + 1'b1;
        endcase
    end

    // ----------------------------------------
    // 3. Collision Detection
    // ----------------------------------------
    reg crash_1, crash_2; // Wall/Body crashes (Fatal)
    reg hit_p1, hit_p2;   // Bullet hits (lose life)
    always @* begin
        crash_1 = 0; crash_2 = 0; hit_p1 = 0; hit_p2 = 0;
        
        // Wall crashes
        if (head1_next_x == 0 || head1_next_x >= GRID_W-1 || head1_next_y == 0 || head1_next_y >= GRID_H-1) crash_1 = 1;
        if (head2_next_x == 0 || head2_next_x >= GRID_W-1 || head2_next_y == 0 || head2_next_y >= GRID_H-1) crash_2 = 1;
        
        // Body crashes and Bullet hits loop
        for(i=0; i<MAX_LEN; i=i+1) begin
            // Self/Other collision
            if(i < len_1 && i > 0 && head1_next_x == b1_x[i] && head1_next_y == b1_y[i]) crash_1 = 1;
            if(i < len_2 && i > 0 && head2_next_x == b2_x[i] && head2_next_y == b2_y[i]) crash_2 = 1;
            if(i < len_2 && head1_next_x == b2_x[i] && head1_next_y == b2_y[i]) crash_1 = 1;
            if(i < len_1 && head2_next_x == b1_x[i] && head2_next_y == b1_y[i]) crash_2 = 1;
            
            // Bullet hits (Compare bullet grid pos to body segment)
            if (bullet1_active) begin
                if (i < len_1 && b1_gx == b1_x[i] && b1_gy == b1_y[i]) hit_p1 = 1;
                if (i < len_2 && b1_gx == b2_x[i] && b1_gy == b2_y[i]) hit_p2 = 1;
            end
            if (bullet2_active) begin
                if (i < len_1 && b2_gx == b1_x[i] && b2_gy == b1_y[i]) hit_p1 = 1;
                if (i < len_2 && b2_gx == b2_x[i] && b2_gy == b2_y[i]) hit_p2 = 1;
            end
        end
    end
    
    // ----------------------------------------
    // 4. Immunity Handling
    //    Latch bullet hits so they persist until the game tick, then apply damage 
    //    only if immunity counter is 0.
    // ----------------------------------------
    reg p1_hit_latch, p2_hit_latch;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin p1_hit_latch <= 0; p2_hit_latch <= 0; end
        else begin
            if (game_over) begin p1_hit_latch <= 0; p2_hit_latch <= 0; end
            else begin
                if (hit_p1) p1_hit_latch <= 1;
                if (hit_p2) p2_hit_latch <= 1;
                if (game_tick) begin
                    // Clear latch if damage is taken or processed
                    if (p1_hit_latch && immune_cnt_1 == 0) p1_hit_latch <= 0;
                    if (p2_hit_latch && immune_cnt_2 == 0) p2_hit_latch <= 0;
                end
            end
        end
    end

    // ----------------------------------------
    // 5. Main State Update (Synchronous)
    // ----------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            // Initialization
            len_1 <= INIT_LEN; score_1 <= 0; life_1 <= 3; immune_cnt_1 <= 0;
            for(k=0; k<MAX_LEN; k=k+1) begin b1_x[k] <= (GRID_W/4) - k; b1_y[k] <= (GRID_H/2); end
            
            len_2 <= INIT_LEN; score_2 <= 0; life_2 <= 3; immune_cnt_2 <= 0;
            for(k=0; k<MAX_LEN; k=k+1) begin b2_x[k] <= (GRID_W*3/4) + k; b2_y[k] <= (GRID_H/2); end
            
            game_over <= 0; consume_o <= 0; winner <= 0;
        end else begin
            consume_o <= 0;
            if (!game_over) begin
                // Time Limit Check
                if (timer_out == 0) begin
                    game_over <= 1;
                    if (score_1 > score_2) winner <= 1;
                    else if (score_2 > score_1) winner <= 2;
                    else winner <= 0;
                end 
                else if (game_tick) begin
                    // --- Damage & Lives P1 ---
                    if (crash_1) life_1 <= 0; // Instant death on wall
                    else if (p1_hit_latch && immune_cnt_1 == 0) begin
                        if (life_1 > 0) life_1 <= life_1 - 1;
                        immune_cnt_1 <= 10; // Set immunity frames
                    end
                    if (immune_cnt_1 > 0) immune_cnt_1 <= immune_cnt_1 - 1;

                    // --- Damage & Lives P2 ---
                    if (crash_2) life_2 <= 0;
                    else if (p2_hit_latch && immune_cnt_2 == 0) begin
                        if (life_2 > 0) life_2 <= life_2 - 1;
                        immune_cnt_2 <= 10;
                    end
                    if (immune_cnt_2 > 0) immune_cnt_2 <= immune_cnt_2 - 1;

                    // --- Game Over Trigger ---
                    if (life_1 == 0 || life_2 == 0) begin
                        game_over <= 1;
                        if (life_1 == 0 && life_2 > 0) winner <= 2;
                        else if (life_2 == 0 && life_1 > 0) winner <= 1;
                        else begin 
                            if (score_1 > score_2) winner <= 1;
                            else if (score_2 > score_1) winner <= 2;
                            else winner <= 0;
                        end
                    end 
                    else begin
                        // --- Movement Update P1 ---
                        // Shift body segments: b[k] = b[k-1]
                        for(k=MAX_LEN-1; k>0; k=k-1) if(k <= len_1) begin b1_x[k] <= b1_x[k-1]; b1_y[k] <= b1_y[k-1]; end
                        b1_x[0] <= head1_next_x; b1_y[0] <= head1_next_y;
                        
                        // Food Consumption
                        if(head1_next_x == food_x && head1_next_y == food_y) begin
                            if(len_1 < MAX_LEN) len_1 <= len_1 + 1'b1;
                            score_1 <= score_1 + 1'b1; 
                            if (life_1 < 5) life_1 <= life_1 + 1; // Extra life cap
                            consume_o <= 1;
                        end
                        
                        // --- Movement Update P2 ---
                        for(k=MAX_LEN-1; k>0; k=k-1) if(k <= len_2) begin b2_x[k] <= b2_x[k-1]; b2_y[k] <= b2_y[k-1]; end
                        b2_x[0] <= head2_next_x; b2_y[0] <= head2_next_y;
                        
                        // Food Consumption
                        if(head2_next_x == food_x && head2_next_y == food_y) begin
                            if(len_2 < MAX_LEN) len_2 <= len_2 + 1'b1;
                            score_2 <= score_2 + 1'b1; 
                            if (life_2 < 5) life_2 <= life_2 + 1;
                            consume_o <= 1;
                        end
                    end
                end
            end
        end
    end

    // Flatten arrays for output
    genvar g;
    generate
        for (g=0; g<MAX_LEN; g=g+1) begin : FLATTEN
            assign body1_x_flat[XW*(g+1)-1:XW*g] = b1_x[g];
            assign body1_y_flat[YW*(g+1)-1:YW*g] = b1_y[g];
            assign body2_x_flat[XW*(g+1)-1:XW*g] = b2_x[g];
            assign body2_y_flat[YW*(g+1)-1:YW*g] = b2_y[g];
        end
    endgenerate
endmodule