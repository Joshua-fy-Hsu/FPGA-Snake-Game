# Dual-Player Snake Game with Cannon Attack (FPGA)

A fully hardware-accelerated, dual-player implementation of the classic Snake arcade game, featuring autonomous cannon obstacles, real-time physics, and mixed-signal inputs. This project was developed using **Verilog HDL** on the **EGo1 FPGA development board** (Xilinx Artix-7) as a final project for the FPGA System Design course.

## Project Overview

Unlike software-based emulations, this project implements the game logic entirely in digital hardware. It features a custom graphics pipeline, a dedicated physics engine, and mixed-signal processing for game speed control.

* **Course:** FPGA System Design
* **Hardware:** EGo1 Development Board (Xilinx Artix-7)
* **Language:** Verilog HDL
* **Video Output:** VGA (640x480 @ 60Hz)

## Key Features

* **Dual-Player Mode:** Simultaneous gameplay support.
  * **Player 1 (Blue):** Controlled via on-board FPGA push buttons.
  * **Player 2 (Red):** Controlled via an external 4x4 Matrix Keypad.
* **Autonomous Cannons:** Two AI-controlled cannons patrol the screen edges, firing gravity-affected bullets using **22-bit fixed-point arithmetic** for smooth trajectory calculation.
* **Real-Time Rendering:** A custom VGA renderer draws the grid, snakes, UI (hearts/timer), and projectiles at 60 FPS without a frame buffer (on-the-fly pixel generation).
* **Hardware Randomness:** Uses a 16-bit **Linear Feedback Shift Register (LFSR)** to generate random food coordinates and bullet firing velocities.
* **Variable Game Speed:** Integrates with the on-chip **XADC (Analog-to-Digital Converter)** to read a potentiometer, allowing the user to adjust the game simulation speed in real-time.
* **Audio Feedback:** PWM-based sound controller generating distinct tones for eating apples and game-over events.

## How to Play

### Controls

| Action | Player 1 (On-Board Buttons) | Player 2 (Matrix Keypad) |
| :--- | :--- | :--- |
| **Move Up** | `BTN_UP` (Pin R11) | Key `D` |
| **Move Down** | `BTN_DOWN` (Pin R15) | Key `5` |
| **Move Left** | `BTN_LEFT` (Pin V1) | Key `3` |
| **Move Right** | `BTN_RIGHT` (Pin R17) | Key `9` |
| **Reset** | `SYS_RST` (Pin P15) | - |
| **Speed Adj** | Potentiometer | - |

### Rules

1. **Objective:** Eat apples to grow longer, increase your score, and gain extra lives (Max 5).
2. **Hazards:**
   * **Walls/Body:** Hitting the wall or any snake body results in instant death.
   * **Cannons:** Moving cannons fire bullets. Being hit by a bullet costs **1 Life** and grants temporary immunity.
3. **Winning:** The game ends when a player loses all lives or the **30-second timer** runs out. The player with the highest score wins.

## Hardware Architecture

The system is designed with a modular hierarchy, separating the Input, Logic, and Output domains.

### Module Description

#### Top Level

* `Top_SnakeGame.v`: The top-level wrapper connecting all sub-modules and mapping ports to physical I/O pins defined in `EGo1.xdc`.

#### Logic Domain (Physics & Game State)

* `Snake_Engine.v`: The core logic. Handles collision detection, movement updates, scoring, life counting, and the game loop state machine.
* `Cannon_Controller.v`: Manages the vertical movement of the cannons and calculates bullet physics (projectile motion) using fixed-point math.
* `Food_Generator.v`: Uses an LFSR to generate pseudo-random coordinates for apples, ensuring they don't spawn inside walls or snake bodies.

#### Input Domain

* `Input_Controller.v`: Handles Player 1 buttons. Includes `Debounce.v` to filter switch noise and latches inputs to ensure button presses aren't missed between frames.
* `Keypad_Scanner.v`: A finite state machine that actively scans the columns and rows of the external 4x4 matrix keypad for Player 2.
* `UG480.v` & `Clock_Divider.v`: Wraps the Xilinx XADC primitive to read the potentiometer voltage and dynamically adjusts the global `game_tick` frequency.

#### Output Domain (Video & Audio)

* `VGA_Controller.v`: Generates standard HSYNC/VSYNC timing signals for 640x480 resolution.
* `VGA_Renderer.v`: The graphics pipeline. It takes game state (coordinates) and generates RGB colors based on a priority layer system (Text > UI > Objects > Background). It includes sprite logic for the snakes, apples, and cannons.
* `Font_ROM.v`: Stores bitmaps for the text overlay (Score, Timer, "WIN/LOSE").
* `Score_Display.v`: Drives the on-board 7-segment display (multiplexed) to show current scores.
* `Sound_Controller.v`: Generates square waves via PWM for audio effects.

## Build & Usage

1. **Requirements:** Xilinx Vivado Design Suite.
2. **Setup:**
   * Create a new project in Vivado targeting the **EGo1** (Artix-7 XC7A35T).
   * Add all `.v` files from the `src/` directory to the project.
   * Add `EGo1.xdc` as the constraint file.
3. **Synthesis & Implementation:** Run the synthesis and implementation flows to generate the bitstream.
4. **Program:** Connect the EGo1 board via USB and program the device.
5. **Peripherals:**
   * Connect a VGA monitor.
   * Connect the 4x4 Keypad to the GPIO headers (Rows: B16, A15, A13, B18 / Cols: B17, A16, A14, A18).
   * Ensure the potentiometer is ready for speed adjustment.

## File Structure

```text
.
├── src/
│   ├── Top_SnakeGame.v       # Top Level Module
│   ├── Snake_Engine.v        # Game Logic Core
│   ├── VGA_Controller.v      # Video Timing
│   ├── VGA_Renderer.v        # Pixel Rendering
│   ├── Cannon_Controller.v   # Enemy AI & Physics
│   ├── Input_Controller.v    # P1 Button Handling
│   ├── Keypad_Scanner.v      # P2 Keypad Driver
│   ├── Food_Generator.v      # Random Position Generator
│   ├── Sound_Controller.v    # Audio PWM
│   ├── Score_Display.v       # 7-Segment Driver
│   ├── UG480.v               # XADC Wrapper
│   ├── Clock_Divider.v       # Clock Management
│   ├── Debounce.v            # Button Debouncer
│   ├── Font_ROM.v            # Text Bitmaps
│   └── EGo1.xdc              # Constraints / Pinout
└── README.md
"# FPGA-Snake-Game" 
