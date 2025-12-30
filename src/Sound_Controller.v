`timescale 1ns / 1ps

/*
 * Module: Sound_Controller
 * Description: 
 * Generates audio feedback using a passive buzzer.
 * Uses Pulse Width Modulation (PWM) to create a square wave tone.
 * Implements a state machine to handle sound effects for "Eating" and "Game Over"
 * with different beep patterns.
 */
module Sound_Controller(
    input  wire clk,          // 25.175 MHz system clock
    input  wire rst_n,        // Active-low reset
    input  wire eat_trigger,  // Pulse input: Play single beep (Apple eaten)
    input  wire game_over,    // Level input: Play triple beep sequence on rising edge
    output reg  sound_o       // PWM output pin driving the buzzer
);
    // Duration constants (calculated for 25.175 MHz)
    localparam integer TIME_100MS = 2_517_500;
    localparam integer TIME_200MS = 5_035_000;
    
    // Frequency configuration: 
    // 4 kHz Tone -> Period = 250us. Toggle pin every 125us.
    // 25,175,000 / 4000 = ~6294 cycles period / 2 = 3147 cycles toggle.
    localparam integer TONE_TOGGLE = 3147;

    // State Machine States
    localparam [1:0] S_IDLE = 0;
    localparam [1:0] S_PLAY = 1; // Actively driving the buzzer
    localparam [1:0] S_WAIT = 2; // Silent pause between multiple beeps

    reg [1:0]  state;
    reg [31:0] timer;
    reg [2:0]  beep_count;    // Number of remaining beeps in sequence
    reg [15:0] tone_cnt;      // Counter for square wave generation

    // Edge Detection for the game_over signal
    reg game_over_last;
    wire go_edge = (game_over && !game_over_last);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state          <= S_PLAY; // Play a beep on startup reset
            timer          <= TIME_200MS;
            beep_count     <= 0;
            sound_o        <= 0;
            tone_cnt       <= 0;
            game_over_last <= 0;
        end else begin
            game_over_last <= game_over;
            
            case (state)
                S_IDLE: begin
                    sound_o <= 0;
                    tone_cnt <= 0;
                    
                    // Priority 1: Game Over (Sequence of 3 beeps)
                    if (go_edge) begin
                        state      <= S_PLAY;
                        timer      <= TIME_100MS;
                        beep_count <= 2; // Play 1 + 2 repeats = 3 total
                    end 
                    // Priority 2: Eat Trigger (Single beep)
                    else if (eat_trigger) begin
                        state      <= S_PLAY;
                        timer      <= TIME_100MS;
                        beep_count <= 0;
                    end
                end

                S_PLAY: begin
                    // Duration Timer
                    if (timer > 0) begin
                        timer <= timer - 1'b1;
                        
                        // Square Wave Generation
                        if (tone_cnt >= TONE_TOGGLE) begin
                            tone_cnt <= 0;
                            sound_o  <= ~sound_o; // Toggle output
                        end else begin
                            tone_cnt <= tone_cnt + 1'b1;
                        end
                    end else begin
                        // Beep duration finished
                        sound_o <= 0;
                        tone_cnt <= 0;
                        
                        // Check if more beeps are queued
                        if (beep_count > 0) begin
                            state <= S_WAIT;
                            timer <= TIME_100MS; // Silence duration
                        end else begin
                            state <= S_IDLE;
                        end
                    end
                end

                S_WAIT: begin
                    // Silence between beeps
                    sound_o <= 0;
                    if (timer > 0) begin
                        timer <= timer - 1'b1;
                    end else begin
                        beep_count <= beep_count - 1'b1;
                        state      <= S_PLAY;
                        timer      <= TIME_100MS;
                    end
                end
            endcase
        end
    end

endmodule