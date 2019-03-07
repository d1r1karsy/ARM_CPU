onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /cpu_testbench/clk
add wave -noupdate /cpu_testbench/nreset
add wave -noupdate /cpu_testbench/dut/cond_go
add wave -noupdate /cpu_testbench/dut/branch_target
add wave -noupdate -divider {FETCH PIPE}
add wave -noupdate -radix unsigned /cpu_testbench/dut/pc_fetch
add wave -noupdate /cpu_testbench/dut/inst_fetch
add wave -noupdate -divider {DECODE PIPE}
add wave -noupdate -radix unsigned /cpu_testbench/dut/pc_dec
add wave -noupdate /cpu_testbench/dut/inst_dec
add wave -noupdate -radix unsigned /cpu_testbench/dut/rf_rs1
add wave -noupdate -radix unsigned /cpu_testbench/dut/rf_rs2
add wave -noupdate -radix unsigned /cpu_testbench/dut/rf_d1_dec
add wave -noupdate -radix unsigned /cpu_testbench/dut/rf_d2_dec
add wave -noupdate -radix decimal /cpu_testbench/dut/rf_ws_dec
add wave -noupdate /cpu_testbench/dut/stall
add wave -noupdate -divider {EXEC PIPE}
add wave -noupdate -radix unsigned /cpu_testbench/dut/pc_exec
add wave -noupdate /cpu_testbench/dut/inst_exec
add wave -noupdate -radix unsigned /cpu_testbench/dut/rf_d1_exec
add wave -noupdate -radix unsigned /cpu_testbench/dut/rf_d2_exec
add wave -noupdate -radix decimal /cpu_testbench/dut/rf_ws_exec
add wave -noupdate -radix unsigned /cpu_testbench/dut/alu_result_exec
add wave -noupdate -radix unsigned /cpu_testbench/dut/operand2
add wave -noupdate -label cpsr_n {/cpu_testbench/dut/cpsr[31]}
add wave -noupdate -label cpsr_z {/cpu_testbench/dut/cpsr[30]}
add wave -noupdate -label cpsr_c {/cpu_testbench/dut/cpsr[29]}
add wave -noupdate -label cpsr_v {/cpu_testbench/dut/cpsr[28]}
add wave -noupdate /cpu_testbench/dut/cond_go_exec
add wave -noupdate -radix unsigned /cpu_testbench/dut/branch_target_exec
add wave -noupdate /cpu_testbench/dut/stall_exec
add wave -noupdate -divider {MEM PIPE}
add wave -noupdate -radix unsigned /cpu_testbench/dut/pc_mem
add wave -noupdate /cpu_testbench/dut/inst_mem
add wave -noupdate -radix decimal /cpu_testbench/dut/rf_d1_mem
add wave -noupdate -radix unsigned /cpu_testbench/dut/rf_ws_mem
add wave -noupdate -radix unsigned /cpu_testbench/dut/alu_result_mem
add wave -noupdate -radix decimal /cpu_testbench/dut/data_mem_rd_mem
add wave -noupdate -radix unsigned /cpu_testbench/dut/branch_target_mem
add wave -noupdate /cpu_testbench/dut/cond_go_mem
add wave -noupdate -divider {WB PIPE}
add wave -noupdate -radix decimal /cpu_testbench/dut/pc_wb
add wave -noupdate /cpu_testbench/dut/inst_wb
add wave -noupdate /cpu_testbench/dut/rf_we
add wave -noupdate -radix decimal /cpu_testbench/dut/rf_ws_wb
add wave -noupdate -radix unsigned /cpu_testbench/dut/rf_wd
add wave -noupdate -radix decimal /cpu_testbench/dut/data_mem_rd_wb
add wave -noupdate -divider REGISTERS
add wave -noupdate -radix unsigned {/cpu_testbench/dut/rf[0]}
add wave -noupdate -radix unsigned {/cpu_testbench/dut/rf[1]}
add wave -noupdate -radix unsigned {/cpu_testbench/dut/rf[2]}
add wave -noupdate -radix unsigned {/cpu_testbench/dut/rf[3]}
add wave -noupdate -radix unsigned {/cpu_testbench/dut/rf[14]}
add wave -noupdate -radix decimal {/cpu_testbench/dut/data_mem[1]}
add wave -noupdate -radix decimal {/cpu_testbench/dut/data_mem[6]}
add wave -noupdate -divider OUTPUTS
add wave -noupdate /cpu_testbench/led
add wave -noupdate -radix hexadecimal /cpu_testbench/debug_port1
add wave -noupdate -radix hexadecimal /cpu_testbench/debug_port2
add wave -noupdate -radix hexadecimal /cpu_testbench/debug_port3
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {698 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 45
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 50
configure wave -gridperiod 100
configure wave -griddelta 5
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ps} {1963 ps}
