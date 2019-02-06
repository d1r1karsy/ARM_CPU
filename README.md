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
    - [ ] implement 12 instructions (complete single cycle ARM32):
        - [x] unconditional branch
        - [ ] conditional flags and execution: conditional branch (cmp)
        - [x] branch link
        - [ ] arithmetic instruction like: add `add r1, r2, r3`, addi `add r1, r2, #1`
        - [ ] load a word from memory: up/down bit, data_addr (5-bits)
        - [ ] store a word to memory:  up/down bit, data_addr (5-bits)
+ **Lab 3**:
    - [ ] pipelining will be implemented


To run this cpu design on the TinyFPGA Bx follow [this tutorial](https://tinyfpga.com/bx/guide.html)

Once the setup tutorial is complete you can upload the design using `apio clean` then `apio build` and finally `apio build`.

To run the debugger enter `python ./debug_console.py` in the folder the script is in.
