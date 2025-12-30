`timescale 1ns/1ps

/*
 * Module: Food_Generator
 * Description: 
 * Generates random X/Y coordinates for the food item using a 16-bit Linear Feedback Shift Register (LFSR).
 * Implements a state machine to verify that the generated coordinate is valid 
 * (not on the snake body, not on a wall) before committing it.
 */
module Food_Generator #(
    parameter integer GRID_W       = 40,
    parameter integer GRID_H       = 30,
    parameter integer ATTEMPT_MAX  = 1024,
    parameter [15:0]  SEED_DEFAULT = 16'hACE1
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   consume_i,   // Pulse high when food is eaten to trigger regeneration
    input  wire                   occ_i,       // Input from Engine: High if candidate coord is occupied
    output reg  [$clog2(GRID_W)-1:0] food_x,
    output reg  [$clog2(GRID_H)-1:0] food_y,
    output reg                    busy_o,      // High while searching for a valid position
    output reg                    new_valid_o  // Pulse high when a new valid position is found
);
    localparam integer XW = $clog2(GRID_W);
    localparam integer YW = $clog2(GRID_H);

    // ----------------------------------------
    // 1. Pseudo-Random Number Generator (LFSR)
    //    Polynomial: x^16 + x^14 + x^13 + x^11 + 1 (taps at 15, 13, 12, 10)
    // ----------------------------------------
    reg  [15:0] lfsr_q;
    wire        lfsr_fb = lfsr_q[15] ^ lfsr_q[13] ^ lfsr_q[12] ^ lfsr_q[10];
    wire [15:0] lfsr_next = {lfsr_q[14:0], lfsr_fb};
    
    // Create a rotated version for the Y-coordinate to decorrelate X and Y
    wire [15:0] lfsr_rot = {lfsr_q[10:0], lfsr_q[15:11]};

    // ----------------------------------------
    // 2. Coordinate Mapping
    //    Scale 16-bit random value to grid dimensions using multiplication (Fixed-point approach)
    //    Take the upper 16 bits of the 32-bit result.
    // ----------------------------------------
    wire [31:0] prod_x = lfsr_q   * GRID_W;
    wire [31:0] prod_y = lfsr_rot * GRID_H;
    wire [XW-1:0] cand_x_w = prod_x[31:16];
    wire [YW-1:0] cand_y_w = prod_y[31:16];
    
    // Registers to hold the candidate coordinates during verification
    reg  [XW-1:0] cand_x_q;
    reg  [YW-1:0] cand_y_q;

    // ----------------------------------------
    // 3. Validation State Machine
    // ----------------------------------------
    localparam [1:0] S_HOLD=0, S_FIND=1, S_CHECK=2, S_COMMIT=3;
    reg [1:0] state_q, state_d;
    reg [$clog2(ATTEMPT_MAX)-1:0] attempt_q, attempt_d;

    // Collision check: Determine if candidate is on the border walls
    wire on_wall;
    assign on_wall = (cand_x_q == 0) || (cand_x_q == GRID_W[XW-1:0]-1) ||
                     (cand_y_q == 0) || (cand_y_q == GRID_H[YW-1:0]-1);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_q    <= S_FIND; // Start by generating first food
            lfsr_q     <= SEED_DEFAULT;
            food_x     <= {XW{1'b0}};
            food_y     <= {YW{1'b0}};
            cand_x_q   <= {XW{1'b0}};
            cand_y_q   <= {YW{1'b0}};
            busy_o     <= 1'b0;
            new_valid_o<= 1'b0;
            attempt_q  <= 0;
        end else begin
            lfsr_q <= lfsr_next;  // Always cycle LFSR
            new_valid_o <= 1'b0;  // Default low
            state_q   <= state_d;
            attempt_q <= attempt_d;

            case (state_q)
                S_HOLD: busy_o <= 1'b0;
                
                S_FIND: begin
                    busy_o   <= 1'b1;
                    // Latch new random coordinates
                    cand_x_q <= cand_x_w;
                    cand_y_q <= cand_y_w;
                end
                
                S_CHECK: busy_o <= 1'b1; // Waiting for external 'occ_i' check
                
                S_COMMIT: begin
                    busy_o      <= 1'b0;
                    new_valid_o <= 1'b1; // Signal valid coordinate ready
                    food_x      <= cand_x_q;
                    food_y      <= cand_y_q;
                end
                
                default: busy_o <= 1'b0;
            endcase
        end
    end

    // Next State Logic
    always @* begin
        state_d   = state_q;
        attempt_d = attempt_q;

        case (state_q)
            S_HOLD: begin
                attempt_d = 1'b0;
                // Wait for external trigger to start generation
                if (consume_i) state_d = S_FIND;
            end
            
            S_FIND: begin
                // Move to check state immediately after latching
                state_d = S_CHECK;
            end
            
            S_CHECK: begin
                // Give up if too many attempts failed to prevent infinite loops
                if (attempt_q == ATTEMPT_MAX-1) begin
                    state_d   = S_COMMIT;
                    attempt_d = 1'b0;
                end 
                // Retry if location is occupied by snake or is a wall
                else if (occ_i || on_wall) begin 
                    state_d   = S_FIND;
                    attempt_d = attempt_q + 1'b1;
                end 
                // Location is free
                else begin
                    state_d   = S_COMMIT;
                    attempt_d = 1'b0;
                end
            end
            
            S_COMMIT: state_d = S_HOLD;
            
            default:  state_d = S_HOLD;
        endcase
    end
endmodule