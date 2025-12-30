`timescale 1ns / 1ps

/*
 * Module: Top_SnakeGame
 * Description: 
 * The top-level hierarchy for the FPGA project. It instantiates and connects
 * sub-modules: Clock gen, Input handling, Game Physics, Video rendering, 
 * Sound generation, and 7-Segment display control.
 * Maps hardware I/O (Buttons, XADC, VGA pins) to internal logic.
 */
module Top_SnakeGame(
    input  wire        sys_clk_in,     // 100 MHz oscillator
    input  wire        sys_rst_n,      // System reset button
    input  wire [4:0]  btn_pin,        // D-Pad buttons (P1 control)
    input  wire [3:0]  column,         // Keypad columns (P2 control input)
    output wire [3:0]  row,            // Keypad rows (P2 control drive)
    // Analog inputs for potentiometer (Speed control)
    input  wire        XADC_AUX_v_p,    
    input  wire        XADC_AUX_v_n,   
    input  wire        XADC_VP_VN_v_p,  
    input  wire        XADC_VP_VN_v_n,  
    // VGA Outputs
    output wire        vga_hs_pin,
    output wire        vga_vs_pin,
    output wire [3:0]  vga_R_Data_pin,
    output wire [3:0]  vga_G_Data_pin,
    output wire [3:0]  vga_B_Data_pin,
    // 7-Segment Outputs
    output wire [7:0]  seg_cs,
    output wire [7:0]  seg_data_0,
    output wire [7:0]  seg_data_1,
    // Audio Output
    output wire        sound
);
    wire vga_clk, game_tick, locked;
    wire [15:0] pot_value;

    // 1. Clock Generation & Speed Control
    Clock_Divider u_Clock_Divider (
        .clk(sys_clk_in), .rst_n(sys_rst_n), .speed_adj(pot_value), 
        .vga_clk(vga_clk), .game_tick(game_tick), .locked(locked)
    );

    // 2. Analog-to-Digital Converter (Read Potentiometer)
    UG480 u_xadc (
        .DCLK(sys_clk_in), .RESET(~sys_rst_n), 
        .VAUXP({2'b00, XADC_AUX_v_p, 1'b0}), .VAUXN({2'b00, XADC_AUX_v_n, 1'b0}), 
        .VP(XADC_VP_VN_v_p), .VN(XADC_VP_VN_v_n), 
        .MEASURED_AUX1(pot_value)
    );
    
    // Create logic reset dependent on clock lock
    wire logic_rst_n = sys_rst_n & locked;
    
    // Game Parameters
    localparam integer GRID_W = 40; localparam integer GRID_H = 30;
    localparam integer MAX_LEN = 64; 
    localparam integer XW = $clog2(GRID_W); localparam integer YW = $clog2(GRID_H);

    // 3. Input Controllers
    wire [1:0] dir_1, dir_2;
    // Player 1: On-board buttons
    Input_Controller u_Input_P1 (
        .vga_clk(vga_clk), .rst_n(logic_rst_n), .game_tick(game_tick), 
        .btn_pin(btn_pin), .dir_signal(dir_1)
    );
    // Player 2: External 4x4 Keypad
    Keypad_Scanner u_Input_P2 (
        .clk(vga_clk), .rst_n(logic_rst_n), 
        .col_in(column), .row_out(row), .dir_out(dir_2)
    );

    // Internal Game Signals
    wire consume_o, game_over;
    wire [1:0] winner;
    wire [15:0] score_1, score_2, len_1, len_2;
    wire [4:0] timer_val;
    wire [XW-1:0] food_x;
    wire [YW-1:0] food_y;
    wire [MAX_LEN*XW-1:0] body1_x, body2_x;
    wire [MAX_LEN*YW-1:0] body1_y, body2_y;
    wire [9:0]    bullet1_px, bullet2_px;
    wire [9:0]    bullet1_py, bullet2_py;
    wire          bullet1_active, bullet2_active;
    wire [YW-1:0] cannon1_y, cannon2_y;
    wire [2:0]    life_1, life_2; 

    // 4. Cannons (Obstacles)
    // Left Cannon targeting Player 1
    Cannon_Controller #(.GRID_W(GRID_W), .GRID_H(GRID_H), .IS_RIGHT_SIDE(0)) u_Cannon_L (
        .clk(vga_clk), .rst_n(logic_rst_n), .game_tick(game_tick), .game_over(game_over),
        .bullet_px(bullet1_px), .bullet_py(bullet1_py), 
        .bullet_active(bullet1_active), .cannon_y(cannon1_y)
    );
    // Right Cannon targeting Player 2
    Cannon_Controller #(.GRID_W(GRID_W), .GRID_H(GRID_H), .IS_RIGHT_SIDE(1)) u_Cannon_R (
        .clk(vga_clk), .rst_n(logic_rst_n), .game_tick(game_tick), .game_over(game_over),
        .bullet_px(bullet2_px), .bullet_py(bullet2_py), 
        .bullet_active(bullet2_active), .cannon_y(cannon2_y)
    );

    // 5. Main Game Physics Engine
    Snake_Engine #(.GRID_W(GRID_W), .GRID_H(GRID_H), .MAX_LEN(MAX_LEN)) u_Snake_Engine (
        .clk(vga_clk), .rst_n(logic_rst_n), .game_tick(game_tick),
        .dir_1(dir_1), .dir_2(dir_2),
        .food_x(food_x), .food_y(food_y),
        .bullet1_px(bullet1_px), .bullet2_px(bullet2_px),
        .bullet1_py(bullet1_py), .bullet2_py(bullet2_py),
        .bullet1_active(bullet1_active), .bullet2_active(bullet2_active),
        .consume_o(consume_o),
        .game_over(game_over), .winner(winner),
        .score_1(score_1), .score_2(score_2),
        .timer_out(timer_val),
        .life_1(life_1), .life_2(life_2), 
        .len_1(len_1), .len_2(len_2),
        .body1_x_flat(body1_x), .body1_y_flat(body1_y),
        .body2_x_flat(body2_x), .body2_y_flat(body2_y)
    );

    // 6. Food Position Generator
    Food_Generator #(.GRID_W(GRID_W), .GRID_H(GRID_H)) u_Food_Generator (
        .clk(vga_clk), .rst_n(logic_rst_n), .consume_i(consume_o), .occ_i(1'b0),
        .food_x(food_x), .food_y(food_y)
    );

    // 7. VGA Display Pipeline
    wire [9:0] pixel_x, pixel_y;
    wire display_active;
    wire [3:0] vga_R, vga_G, vga_B;
    
    // Controller generates H/V sync and pixel counters
    VGA_Controller u_VGA_Controller (
        .vga_clk(vga_clk), .rst_n(logic_rst_n),
        .hsync(vga_hs_pin), .vsync(vga_vs_pin),
        .pixel_x(pixel_x), .pixel_y(pixel_y), .display_active(display_active)
    );

    // Renderer generates pixel colors based on game state
    VGA_Renderer #(.GRID_W(GRID_W), .GRID_H(GRID_H), .MAX_LEN(MAX_LEN)) u_VGA_Renderer (
        .vga_clk(vga_clk), .rst_n(logic_rst_n), .display_active(display_active),
        .pixel_x(pixel_x), .pixel_y(pixel_y),
        .food_x(food_x), .food_y(food_y),
        .body1_x_flat(body1_x), .body1_y_flat(body1_y),
        .body2_x_flat(body2_x), .body2_y_flat(body2_y),
        .len_1(len_1), .len_2(len_2),
        .score_1(score_1), .score_2(score_2),
        .life_1(life_1), .life_2(life_2),
        .timer_val(timer_val),
        .game_over(game_over), .winner(winner),
        .cannon1_y(cannon1_y), .cannon2_y(cannon2_y),
        .bullet1_px(bullet1_px), .bullet2_px(bullet2_px),
        .bullet1_py(bullet1_py), .bullet2_py(bullet2_py),
        .bullet1_active(bullet1_active), .bullet2_active(bullet2_active),
        .vga_R(vga_R), .vga_G(vga_G), .vga_B(vga_B)
    );
    
    assign vga_R_Data_pin = vga_R; 
    assign vga_G_Data_pin = vga_G; 
    assign vga_B_Data_pin = vga_B;

    // 8. 7-Segment Display (Score)
    Score_Display u_Score_Display (
        .clk(vga_clk), .rst_n(logic_rst_n),
        .score_1(score_1), .score_2(score_2),
        .seg_cs(seg_cs), .seg_data_0(seg_data_0), .seg_data_1(seg_data_1)
    );

    // 9. Audio Controller (Buzzer)
    Sound_Controller u_Sound_Controller (
        .clk(vga_clk), .rst_n(logic_rst_n),
        .eat_trigger(consume_o), .game_over(game_over),
        .sound_o(sound)
    );
endmodule