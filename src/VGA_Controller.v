`timescale 1ns / 1ps

/*
 * Module: VGA_Controller
 * Description: 
 * Generates industry-standard VGA timing signals for 640x480 resolution at 60 Hz.
 * Outputs synchronization pulses (HSYNC, VSYNC) and pixel coordinates (X, Y).
 * 'display_active' indicates the visible region where pixels should be drawn.
 */
module VGA_Controller(
    input  wire        vga_clk,        // 25.175 MHz pixel clock
    input  wire        rst_n,

    output reg         hsync,          // Active-low Horizontal Sync
    output reg         vsync,          // Active-low Vertical Sync
    output reg  [9:0]  pixel_x,        // 0 to 639 (Visible Horizontal)
    output reg  [9:0]  pixel_y,        // 0 to 479 (Visible Vertical)
    output reg         display_active  // High during the visible display area
);
    // -----------------------------------------------------
    // Timing Parameters (640x480 @ 60Hz)
    // -----------------------------------------------------
    localparam integer H_VISIBLE   = 640;
    localparam integer H_FRONT     = 16;  // Front Porch
    localparam integer H_SYNC      = 96;  // Sync Pulse
    localparam integer H_BACK      = 48;  // Back Porch
    localparam integer H_TOTAL     = 800; // Total Line Clocks

    localparam integer V_VISIBLE   = 480;
    localparam integer V_FRONT     = 10;
    localparam integer V_SYNC      = 2;
    localparam integer V_BACK      = 33;
    localparam integer V_TOTAL     = 525; // Total Lines

    // Calculate start points for Sync pulses (Active Low logic)
    localparam integer H_SYNC_START = H_VISIBLE + H_FRONT;
    localparam integer V_SYNC_START = V_VISIBLE + V_FRONT;

    // -----------------------------------------------------
    // Counters
    // -----------------------------------------------------
    reg [9:0] h_count; // Horizontal line counter
    reg [9:0] v_count; // Vertical line counter

    always @(posedge vga_clk or negedge rst_n) begin
        if (!rst_n) begin
            h_count <= 10'd0;
            v_count <= 10'd0;
        end else begin
            if (h_count == H_TOTAL-1) begin
                h_count <= 10'd0;
                // Increment vertical counter at end of line
                if (v_count == V_TOTAL-1)
                    v_count <= 10'd0;
                else
                    v_count <= v_count + 10'd1;
            end else begin
                h_count <= h_count + 10'd1;
            end
        end
    end

    // -----------------------------------------------------
    // Signal Generation
    // -----------------------------------------------------
    // Sync windows: High when counter is within the sync pulse definition
    wire hsync_window = (h_count >= H_SYNC_START) && (h_count < H_SYNC_START + H_SYNC);
    wire vsync_window = (v_count >= V_SYNC_START) && (v_count < V_SYNC_START + V_SYNC);
    
    // Active area: True only when within the visible 640x480 region
    wire active_area  = (h_count < H_VISIBLE) && (v_count < V_VISIBLE);

    // Register outputs to align timing
    always @(posedge vga_clk or negedge rst_n) begin
        if (!rst_n) begin
            hsync          <= 1'b1;
            vsync          <= 1'b1;
            display_active <= 1'b0;
            pixel_x        <= 10'd0;
            pixel_y        <= 10'd0;
        end else begin
            hsync          <= ~hsync_window; // Invert for Active Low
            vsync          <= ~vsync_window; // Invert for Active Low
            display_active <= active_area;
            // Only output coordinates if valid, else 0
            pixel_x        <= active_area ? h_count : 10'd0;
            pixel_y        <= active_area ? v_count : 10'd0;
        end
    end

endmodule