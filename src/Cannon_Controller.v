`timescale 1ns / 1ps

/*
 * Module: Cannon_Controller
 * Description: 
 * Controls an automated cannon bullets.
 * - Moves the cannon vertically (Up/Down) within bounds.
 * - Fires bullets at random intervals with random vertical velocity.
 * - Updates bullet physics using fixed-point arithmetic (Speed, Gravity).
 * - Disables firing when the game ends.
 */
module Cannon_Controller #(
    parameter integer GRID_W = 40,
    parameter integer GRID_H = 30,
    parameter integer IS_RIGHT_SIDE = 0  // 0 = Left Cannon, 1 = Right Cannon
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        game_tick,   // Game physics tick (used for cannon movement)
    input  wire        game_over,   // Stop signal
    
    output reg [9:0]   bullet_px,   // Bullet X pixel
    output reg [9:0]   bullet_py,   // Bullet Y pixel
    output reg         bullet_active,
    output reg [$clog2(GRID_H)-1:0] cannon_y // Cannon vertical grid position
);
    // ----------------------------------------
    // 1. Animation Timer
    //    Controls bullet physics update rate (independent of game_tick).
    // ----------------------------------------
    reg [18:0] anim_cnt;
    wire anim_tick = (anim_cnt == 419_000); 
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) anim_cnt <= 0;
        else if (anim_tick) anim_cnt <= 0;
        else anim_cnt <= anim_cnt + 1;
    end

    // Physics Constants
    localparam signed [15:0] GRAVITY = 16'd10;
    localparam signed [21:0] SPEED_X = 22'd256; // Fixed point X speed
    localparam integer SHOOT_DELAY = 50_350_000; // ~2 seconds

    // ----------------------------------------
    // 2. Cannon Movement Logic
    //    Patrols up and down between Y=1 and Y=28.
    // ----------------------------------------
    reg cannon_dir; // 0=Down, 1=Up
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            cannon_y <= (IS_RIGHT_SIDE) ? (GRID_H/3) : (GRID_H*2/3); 
            cannon_dir <= 0;
        end else if (game_tick && !game_over) begin
            if (cannon_dir == 0) begin 
                if (cannon_y >= GRID_H-2) cannon_dir <= 1;
                else cannon_y <= cannon_y + 1;
            end else begin 
                if (cannon_y <= 1) cannon_dir <= 0;
                else cannon_y <= cannon_y - 1;
            end
        end
    end

    // ----------------------------------------
    // 3. Random Number Generator (LFSR)
    //    Used to randomize the bullet's vertical launch velocity.
    // ----------------------------------------
    reg [15:0] lfsr;
    wire feedback = lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10];
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) lfsr <= (IS_RIGHT_SIDE ? 16'h5AA5 : 16'hACE1);
        else lfsr <= {lfsr[14:0], feedback};
    end

    // ----------------------------------------
    // 4. Bullet Physics & State
    //    Uses fixed-point math for smooth arcs.
    // ----------------------------------------
    reg signed [21:0] pos_x_fixed;
    reg signed [21:0] pos_y_fixed;
    reg signed [15:0] vel_y_fixed;
    reg [31:0] shoot_timer;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            bullet_active <= 0;
            bullet_px <= 0; bullet_py <= 0;
            shoot_timer <= 0; pos_x_fixed <= 0; pos_y_fixed <= 0; vel_y_fixed <= 0;
        end else begin
            // Reload Timer
            if (shoot_timer < SHOOT_DELAY && !game_over) 
                shoot_timer <= shoot_timer + 1;
            
            if (bullet_active) begin
                // Update position on animation tick
                if (anim_tick) begin
                    if (IS_RIGHT_SIDE == 0) pos_x_fixed <= pos_x_fixed + SPEED_X;
                    else                    pos_x_fixed <= pos_x_fixed - SPEED_X;
                    
                    pos_y_fixed <= pos_y_fixed + {{6{vel_y_fixed[15]}}, vel_y_fixed};
                    vel_y_fixed <= vel_y_fixed + GRAVITY; 

                    // Update Integer Outputs (Upper bits)
                    bullet_px <= pos_x_fixed[15:6];
                    bullet_py <= pos_y_fixed[15:6];
                    
                    // Boundary Check: Deactivate if off-screen
                    if (pos_y_fixed[21] || pos_y_fixed[15:6] >= 480 || 
                        pos_x_fixed[21] || pos_x_fixed[15:6] >= 640) begin
                        bullet_active <= 0;
                    end
                end
            end else begin
                // Firing Logic
                if (shoot_timer >= SHOOT_DELAY && !game_over) begin
                    shoot_timer <= 0;
                    bullet_active <= 1;
                    // Initial Position
                    if (IS_RIGHT_SIDE == 0) pos_x_fixed <= {10'd16, 6'd0} + 64;
                    else                    pos_x_fixed <= {10'd624, 6'd0} - 64;
                    pos_y_fixed <= {6'd0, cannon_y, 4'd0, 6'd0} + 22'd512; 
                    // Random Initial Velocity
                    vel_y_fixed <= ({11'b0, lfsr[4:0]} * 12) - 16'd220;
                end
            end
        end
    end
endmodule