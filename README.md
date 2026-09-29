# Zybo Z7 FPGA Pong

A hardware-based implementation of the classic Pong game developed in SystemVerilog and deployed on a Digilent Zybo Z7 FPGA development board.

The project demonstrates digital design, real-time video generation, hardware-based game logic, and FPGA interfacing. The game runs entirely in programmable logic, with player input handled through the Zybo Z7's onboard buttons and video output generated for an external display.

## Project Overview

This project recreates Pong as a fully hardware-implemented system. Rather than running the game as software on a processor, the game logic, graphics generation, collision detection, and video timing are implemented using SystemVerilog and synthesized onto the FPGA.

The project was designed to explore practical FPGA development concepts including:

- SystemVerilog RTL design
- Synchronous digital logic
- Finite-state and control logic
- VGA/HDMI video timing
- Real-time graphics generation
- Button input synchronization
- Collision detection
- Hardware-based game state management
- FPGA synthesis and implementation

## Features

- Two-player Pong gameplay
- Real-time ball and paddle movement
- Paddle collision detection
- Ball boundary detection
- Player scoring
- Hardware-generated video output
- Push-button player controls
- Fully synthesizable SystemVerilog design

## Hardware

- **FPGA Board:** Digilent Zybo Z7
- **FPGA:** Xilinx Zynq-7000 SoC
- **Video Output:** HDMI
- **Input:** Zybo Z7 push buttons
- **Development Environment:** AMD/Xilinx Vivado

## System Architecture

The design is divided into several hardware modules, each responsible for a specific part of the system.

```text
                    ┌─────────────────────┐
                    │      Zybo Z7        │
                    │                     │
 Buttons ──────────►│   Input Handling    │
                    │          │          │
                    │          ▼          │
                    │   ┌──────────────┐  │
                    │   │  Game Logic  │  │
                    │   │              │  │
                    │   │ Ball/Paddles │  │
                    │   │ Collision    │  │
                    │   │ Score        │  │
                    │   └──────┬───────┘  │
                    │          │          │
                    │          ▼          │
                    │   ┌──────────────┐  │
                    │   │ Video Timing │  │
                    │   └──────┬───────┘  │
                    │          │          │
                    │          ▼          │
                    │   ┌──────────────┐  │
                    │   │ Video Output │  │
                    │   └──────┬───────┘  │
                    └──────────┼──────────┘
                               │
                               ▼
                            HDMI
                               │
                               ▼
                            Display
