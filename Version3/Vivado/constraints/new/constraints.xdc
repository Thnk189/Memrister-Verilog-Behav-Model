## Arty S7 configuration bank voltage settings
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

## 12 MHz clock for top-level port clk
set_property -dict { PACKAGE_PIN F14 IOSTANDARD LVCMOS33 } [get_ports { clk }]
create_clock -add -name clk -period 83.333 -waveform {0 41.667} [get_ports { clk }]

## Reset button BTN0 for top-level port rst
set_property -dict { PACKAGE_PIN G15 IOSTANDARD LVCMOS33 } [get_ports { rst }]
