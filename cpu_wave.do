onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /cpu_testbench/clk
add wave -noupdate /cpu_testbench/resetn
add wave -noupdate /cpu_testbench/led
add wave -noupdate /cpu_testbench/debug_port1
add wave -noupdate /cpu_testbench/debug_port2
add wave -noupdate /cpu_testbench/debug_port3
add wave -noupdate -radix decimal /cpu_testbench/dut/pc
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {3078 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {3007 ps} {4316 ps}
