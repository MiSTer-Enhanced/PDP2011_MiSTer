#create_clock -period 20.000ns [get_ports clkin]
#create_clock -period 10.000ns emu|pll|pll_inst|altera_pll_i|general[0].gpll~PLL_OUTPUT_COUNTER|divclk
#create_clock -period 140.000ns emu:emu|mister_top:mister_top|cpuclk
#create_clock -period 80.000ns emu:emu|mister_top:mister_top|unibus:pdp11|rh11:rh0|sdspi:sd1|clk
#create_clock -period 80.000ns emu:emu|mister_top:mister_top|unibus:pdp11|rk11:rk0|sdspi:sd1|clk
#create_clock -period 80.000ns emu:emu|mister_top:mister_top|unibus:pdp11|rl11:rl0|sdspi:sd1|clk

derive_pll_clocks -use_net_name
derive_clock_uncertainty

