# Pipelined ARM CPU
32-Bit ARM design for a 5 state pipelined cpu on the TinyFPGA Bx board.
Class project for UW CSE/EE 469: Computer Architecture I with Mark Oskin.
This cpu design is implemented by Doruk Arisoy and Ben Eastin.

The Verilog code for the CPU design is at <code>cpu.v</code> and the top level module for the project is <code>top.v</code>.

**To Do list:**
+ **Lab 1**:
    - [x] register file
    - [x] read a register
    - [x] program counter
    - [x] compare code with solution, perform fixes
+ **Lab 2**:
    - [ ] memory
    - [ ] write to a register
    - [ ] implement ALU
    - [ ] implement 12 instructions:
        - [ ] 3 branches: unconditional, some kind of conditional, branch link
        - [ ] add <code>add r1, r2, r3</code>, addi <code>add r1, r2, #1</code>
+ **Lab 3**:
    - [ ] pipelining will be implemented


To run this cpu design on the TinyFPGA Bx follow [this tutorial](https://tinyfpga.com/bx/guide.html)

Once the setup tutorial is complete you can upload the design using <code>apio clean</code>, then <code>apio build</code> and finally <code>apio build</code>.

To run the debugger enter <code>python ./debug_console.py</code> in the folder the script is in.
