# Head Soccer FPGA Game

Two-player Head Soccer game implemented on Spartan-7 FPGA with MicroBlaze processor, USB keyboard input, and HDMI output.

## Academic Integrity
Students: Check your course policies before using this code. You are responsible for ensuring compliance with your institution's academic integrity requirements. The author is not responsible for any violations resulting from improper use.

## Features

- Two-player local multiplayer with distinct character sprites
- Realistic ball physics with gravity and collision detection
- Player-to-player collision (stand on opponent's head!)
- Goal detection and scoring system (first to 5 wins)
- CPU AI opponent for single-player mode
- Kick mechanic with directional physics
- Dynamic sprite switching (normal/kick animations)
- Game state management (start screen, gameplay, winner announcement)

## Controls

**Player 1:**
- A/D: Move left/right
- W: Jump
- E: Kick

**Player 2:**
- Arrow Keys: Move left/right
- Up Arrow: Jump
- /?: Kick

**Game:**
- R: Restart game (when game over)

## Hardware Requirements

- Xilinx Spartan-7 FPGA board (Urbana board)
- USB keyboard
- HDMI monitor
- USB cable for programming

## Software Requirements

- Xilinx Vivado (for FPGA synthesis)
- Vitis IDE (for MicroBlaze C code)
- lw_usb library v6.1 (included)

## Setup

1. Clone the repository
2. Open the Vivado project and synthesize the design
3. Export hardware with bitstream
4. Open Vitis IDE and import the software project
5. Program the FPGA and run the application
6. Connect USB keyboard and HDMI monitor
7. Play!

## Technical Details

- **Resolution:** 640×480 @ 60Hz
- **Platform:** MicroBlaze soft processor on Spartan-7
- **Language:** SystemVerilog (hardware), C (software)
- **Graphics:** Sprite-based rendering with palette system
- **Input:** USB HID keyboard via MAX3421E

## Authors

Created by [Anshul Rao](https://github.com/anshulrao) and [Varnith Aleti](https://github.com/varnithaleti) for ECE 385 Final Project, Fall 2025.

## Acknowledgments

Course materials and USB library provided by UIUC ECE Department.
