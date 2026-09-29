## =========================================================
## Zybo Z7 Pong
## Compatible with Zybo Z7-10 and Zybo Z7-20
## =========================================================


## =========================================================
## 125 MHz SYSTEM CLOCK
## =========================================================

set_property -dict {
    PACKAGE_PIN K17
    IOSTANDARD LVCMOS33
} [get_ports sysclk]

create_clock -add \
    -name sys_clk_pin \
    -period 8.00 \
    -waveform {0 4} \
    [get_ports sysclk]


## =========================================================
## SWITCHES
## =========================================================

set_property -dict {
    PACKAGE_PIN G15
    IOSTANDARD LVCMOS33
} [get_ports {sw[0]}]

set_property -dict {
    PACKAGE_PIN P15
    IOSTANDARD LVCMOS33
} [get_ports {sw[1]}]

set_property -dict {
    PACKAGE_PIN W13
    IOSTANDARD LVCMOS33
} [get_ports {sw[2]}]

set_property -dict {
    PACKAGE_PIN T16
    IOSTANDARD LVCMOS33
} [get_ports {sw[3]}]


## =========================================================
## BUTTONS
## =========================================================

set_property -dict {
    PACKAGE_PIN K18
    IOSTANDARD LVCMOS33
} [get_ports {btn[0]}]

set_property -dict {
    PACKAGE_PIN P16
    IOSTANDARD LVCMOS33
} [get_ports {btn[1]}]

set_property -dict {
    PACKAGE_PIN K19
    IOSTANDARD LVCMOS33
} [get_ports {btn[2]}]

set_property -dict {
    PACKAGE_PIN Y16
    IOSTANDARD LVCMOS33
} [get_ports {btn[3]}]


## =========================================================
## LEDS
## =========================================================

set_property -dict {
    PACKAGE_PIN M14
    IOSTANDARD LVCMOS33
} [get_ports {led[0]}]

set_property -dict {
    PACKAGE_PIN M15
    IOSTANDARD LVCMOS33
} [get_ports {led[1]}]

set_property -dict {
    PACKAGE_PIN G14
    IOSTANDARD LVCMOS33
} [get_ports {led[2]}]

set_property -dict {
    PACKAGE_PIN D18
    IOSTANDARD LVCMOS33
} [get_ports {led[3]}]


## =========================================================
## HDMI CLOCK
## =========================================================

set_property -dict {
    PACKAGE_PIN H16
    IOSTANDARD TMDS_33
} [get_ports hdmi_tx_clk_p]

set_property -dict {
    PACKAGE_PIN H17
    IOSTANDARD TMDS_33
} [get_ports hdmi_tx_clk_n]


## =========================================================
## HDMI DATA 0 - BLUE
## =========================================================

set_property -dict {
    PACKAGE_PIN D19
    IOSTANDARD TMDS_33
} [get_ports {hdmi_tx_p[0]}]

set_property -dict {
    PACKAGE_PIN D20
    IOSTANDARD TMDS_33
} [get_ports {hdmi_tx_n[0]}]


## =========================================================
## HDMI DATA 1 - GREEN
## =========================================================

set_property -dict {
    PACKAGE_PIN C20
    IOSTANDARD TMDS_33
} [get_ports {hdmi_tx_p[1]}]

set_property -dict {
    PACKAGE_PIN B20
    IOSTANDARD TMDS_33
} [get_ports {hdmi_tx_n[1]}]


## =========================================================
## HDMI DATA 2 - RED
## =========================================================

set_property -dict {
    PACKAGE_PIN B19
    IOSTANDARD TMDS_33
} [get_ports {hdmi_tx_p[2]}]

set_property -dict {
    PACKAGE_PIN A20
    IOSTANDARD TMDS_33
} [get_ports {hdmi_tx_n[2]}]