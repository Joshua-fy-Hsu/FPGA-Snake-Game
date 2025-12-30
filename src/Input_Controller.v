`timescale 1ns / 1ps

/*
 * Module: Input_Controller
 * Description: 
 * Handles player input for 4 discrete buttons (Up, Down, Left, Right).
 * Includes debouncing, input latching to capture quick presses between frames,
 * and logic to prevent invalid 180-degree turns (e.g., moving Left when facing Right).
 */
module Input_Controller(
    input  wire vga_clk,       // 25 MHz clock source
    input  wire rst_n,         // Active-low reset
    input  wire game_tick,     // Game update strobe (defines the frame boundary)
    input  wire [4:0] btn_pin, // Physical button inputs: [4]=Up, [1]=Down, [3]=Left, [0]=Right
    output reg  [1:0] dir_signal // Current direction: 00=UP, 01=RIGHT, 10=DOWN, 11=LEFT
);
    // ----------------------------------------
    // 1. Debounce Logic
    //    Filters out mechanical switch noise. 'btn_pulse' is high for 1 cycle 
    //    only after the input has been stable for ~5ms.
    // ----------------------------------------
    wire btn_u_pulse, btn_d_pulse, btn_l_pulse, btn_r_pulse;
    Debounce u_Debounce_U(.clk(vga_clk), .rst_n(rst_n), .btn_in(btn_pin[4]), .btn_pulse(btn_u_pulse));
    Debounce u_Debounce_D(.clk(vga_clk), .rst_n(rst_n), .btn_in(btn_pin[1]), .btn_pulse(btn_d_pulse));
    Debounce u_Debounce_L(.clk(vga_clk), .rst_n(rst_n), .btn_in(btn_pin[3]), .btn_pulse(btn_l_pulse));
    Debounce u_Debounce_R(.clk(vga_clk), .rst_n(rst_n), .btn_in(btn_pin[0]), .btn_pulse(btn_r_pulse));

    // ----------------------------------------
    // 2. Input Latching
    //    Captures any button press that occurs *between* game ticks.
    //    Ensures that inputs shorter than a game frame are not missed.
    // ----------------------------------------
    reg [3:0] pending;
    always @(posedge vga_clk or negedge rst_n) begin
        if (!rst_n)
            pending <= 4'b0000;
        else begin
            // Accumulate presses into the pending register
            pending[3] <= pending[3] | btn_u_pulse; // Up
            pending[2] <= pending[2] | btn_d_pulse; // Down
            pending[1] <= pending[1] | btn_l_pulse; // Left
            pending[0] <= pending[0] | btn_r_pulse; // Right

            // Clear pending flags immediately after they are processed (on game_tick)
            if (game_tick)
                pending <= 4'b0000;
        end
    end

    // ----------------------------------------
    // 3. Direction State Machine
    //    Updates the direction signal on the game tick based on latched inputs.
    //    Enforces priority and prevents reversing direction directly (180-degree turn).
    // ----------------------------------------
    localparam [1:0] UP=2'b00, RIGHT=2'b01, DOWN=2'b10, LEFT=2'b11;
    always @(posedge vga_clk or negedge rst_n) begin
        if (!rst_n)
            dir_signal <= RIGHT; // Default starting direction
        else if (game_tick) begin
            // Check inputs with priority: Up > Down > Left > Right
            // Condition: Ignore input if it tries to move in the opposite direction
            if (pending[3] && dir_signal != DOWN)
                dir_signal <= UP;
            else if (pending[2] && dir_signal != UP)
                dir_signal <= DOWN;
            else if (pending[1] && dir_signal != RIGHT)
                dir_signal <= LEFT;
            else if (pending[0] && dir_signal != LEFT)
                dir_signal <= RIGHT;
            else
                dir_signal <= dir_signal; // Maintain course if no valid input
        end
    end

endmodule