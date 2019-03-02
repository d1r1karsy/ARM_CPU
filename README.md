# Pipelined ARM CPU
32-Bit ARM design for a 5 state pipelined cpu on the TinyFPGA Bx board.
Class project for UW CSE/EE 469: Computer Architecture I with Mark Oskin.
This cpu design is implemented by Doruk Arisoy and Ben Eastin.

The Verilog code for the CPU design is at <code>cpu.v</code> and the top level module for the project is <code>top.v</code>.

## To Do List:
+ **Lab 1**:
    - [x] register file
    - [x] read a register
    - [x] program counter
    - [x] compare code with solution, perform fixes
+ **Lab 2**:
    - [x] implement 12 instructions (complete single cycle ARM32):
        - [x] unconditional branch
        - [x] conditional branch
        - [x] branch link
        - [x] arithmetic instructions
        - [x] load a word from memory
        - [x] store a word to memory
+ **Lab 3**:
    - [ ] 5-stage pipeline
        - [x] 4 physical pipelines
        - [x] R-type instructions
        - [x] Hazard detection
        - [ ] Branching
            - [ ] Conditional branching w/ cpsr tags
        - [ ] Stalling

## Set Up
To run this cpu design on the TinyFPGA Bx follow [this tutorial](https://tinyfpga.com/bx/guide.html).

Once the setup tutorial is complete you can upload the design using `apio clean` then `apio build` and finally `apio build`.

To run the debugger enter `python ./debug_console.py` in the folder the script is in.

## Simulation for Windows
This cpu design and its waveforms can be simulated using ModelSim. All necessary files to run this simulation are provided in this repo. Following steps will walk through how to run the simulation:
1. Edit the `Launch_ModelSim.bat` file to point to your local ModelSim executable file.

    Example ModelSim path: `C:\intelFPGA\17.0\modelsim_ase\win32aloem\modelsim.exe`
    
2. Double click on `Launch_ModelSim.bat` file to launch the ModelSim application.
3. Once ModelSim is running, enter `do runcpu.do` command to run the simulation.
