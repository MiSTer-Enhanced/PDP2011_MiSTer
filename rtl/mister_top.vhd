--
-- Copyright (c) 2008-2021 Sytse van Slooten
--
-- Permission is hereby granted to any person obtaining a copy of these VHDL source files and
-- other language source files and associated documentation files ("the materials") to use
-- these materials solely for personal, non-commercial purposes.
-- You are also granted permission to make changes to the materials, on the condition that this
-- copyright notice is retained unchanged.
--
-- The materials are distributed in the hope that they will be useful, but WITHOUT ANY WARRANTY;
-- without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
--

-- $Revision$

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity mister_top is
   port(
	   --clocks
		clk_100        : in std_logic;
		clk_50         : in std_logic;
		
		--reset
		reset          : in std_logic;
		
		-- PDP settings
		modelcode      : in integer;
		serial_console : in std_logic;
		have_rk        : in integer;
		have_rl        : in integer;
		have_rh        : in integer;
		have_xu        : in integer;
		
		-- VT settings
		vttype         : in integer;
		have_act       : in integer;
		vga_cursor_block : in std_logic;
		vga_cursor_blink : in std_logic;
		teste          : in std_logic;
		testf          : in std_logic;
		
      -- second serial port
      rx1: in std_logic;
      tx1: out std_logic;
		rts1:out std_logic;
		cts1:in std_logic;

      -- sd card
      rk_sdcard_cs   : out std_logic;
      rk_sdcard_mosi : out std_logic;
      rk_sdcard_sclk : out std_logic;
      rk_sdcard_miso : in std_logic;
		rk_sdcard_debug: out std_logic_vector (3 downto 0);

      rl_sdcard_cs   : out std_logic;
      rl_sdcard_mosi : out std_logic;
      rl_sdcard_sclk : out std_logic;
      rl_sdcard_miso : in std_logic;
		rl_sdcard_debug: out std_logic_vector (3 downto 0);

      rh_sdcard_cs   : out std_logic;
      rh_sdcard_mosi : out std_logic;
      rh_sdcard_sclk : out std_logic;
      rh_sdcard_miso : in std_logic;
		rh_sdcard_debug: out std_logic_vector (3 downto 0);

      -- Ethernet
      xu_cs   : out std_logic;
      xu_mosi : out std_logic;
      xu_sclk : out std_logic;
      xu_miso : in std_logic;
		
		-- vga and ps2
      vga_hsync      : out std_logic;
      vga_vsync      : out std_logic;
      vga_hblank     : out std_logic;
      vga_vblank     : out std_logic;
		ce_pix         : out std_logic;
      vga_fb         : out std_logic;
      vga_ht         : out std_logic;
      ps2k_c         : in std_logic;
      ps2k_d         : in std_logic;
		
      -- dram
      dram_addr      : buffer std_logic_vector(12 downto 0);
      dram_dq        : inout std_logic_vector(15 downto 0);
      dram_ba_1      : out std_logic;
      dram_ba_0      : out std_logic;
      dram_udqm      : out std_logic;
      dram_ldqm      : out std_logic;
      dram_ras_n     : out std_logic;
      dram_cas_n     : out std_logic;
      dram_cke       : out std_logic;
      dram_clk       : out std_logic;
      dram_we_n      : out std_logic;
      dram_cs_n      : out std_logic;

      -- board peripherals
      greenled       : out std_logic
  );
end mister_top;

architecture implementation of mister_top is

component unibus is
   port(
-- bus interface
      addr : out std_logic_vector(21 downto 0);                      -- physical address driven out to the bus by cpu or busmaster peripherals
      dati : in std_logic_vector(15 downto 0);                       -- data input to cpu or busmaster peripherals
      dato : out std_logic_vector(15 downto 0);                      -- data output from cpu or busmaster peripherals
      control_dati : out std_logic;                                  -- if '1', this is an input cycle
      control_dato : out std_logic;                                  -- if '1', this is an output cycle
      control_datob : out std_logic;                                 -- if '1', the current output cycle is for a byte
      addr_match : in std_logic;                                     -- '1' if the address is recognized

-- debug & blinkenlights
      ifetch : out std_logic;                                        -- '1' if this cycle is an ifetch cycle
      iwait : out std_logic;                                         -- '1' if the cpu is in wait state
      cpu_addr_v : out std_logic_vector(15 downto 0);                -- virtual address from cpu, for debug and general interest

-- rl controller
      have_rl : in integer range 0 to 1 := 0;                        -- enable conditional compilation
      rl_sdcard_cs : out std_logic;
      rl_sdcard_mosi : out std_logic;
      rl_sdcard_sclk : out std_logic;
      rl_sdcard_miso : in std_logic := '0';
      rl_sdcard_debug : out std_logic_vector(3 downto 0);            -- debug/blinkenlights

-- rk controller
      have_rk : in integer range 0 to 1 := 0;                        -- enable conditional compilation
      have_rk_num : in integer range 1 to 8 := 8;                    -- active number of drives on the controller; set to < 8 to save core
      rk_sdcard_cs : out std_logic;
      rk_sdcard_mosi : out std_logic;
      rk_sdcard_sclk : out std_logic;
      rk_sdcard_miso : in std_logic := '0';
      rk_sdcard_debug : out std_logic_vector(3 downto 0);            -- debug/blinkenlights

-- rh controller
      have_rh : in integer range 0 to 1 := 0;                        -- enable conditional compilation
      rh_sdcard_cs : out std_logic;
      rh_sdcard_mosi : out std_logic;
      rh_sdcard_sclk : out std_logic;
      rh_sdcard_miso : in std_logic := '0';
      rh_sdcard_debug : out std_logic_vector(3 downto 0);            -- debug/blinkenlights
      rh_type : in integer range 1 to 7 := 6;

-- xu enc424j600 controller interface
      have_xu : in integer range 0 to 1 := 0;                        -- enable conditional compilation
      have_xu_debug : in integer range 0 to 1 := 1;                  -- enable debug core
      xu_cs : out std_logic;
      xu_mosi : out std_logic;
      xu_sclk : out std_logic;
      xu_miso : in std_logic := '0';
      xu_debug_tx : out std_logic;                                   -- rs232, 115200/8/n/1 debug output from microcode

-- kl11, console ports
      have_kl11 : in integer range 0 to 4 := 1;                      -- conditional compilation - number of kl11 controllers to include. Should normally be at least 1

      tx0 : out std_logic;
      rx0 : in std_logic := '1';
      rts0 : out std_logic;
      cts0 : in std_logic := '0';
      kl0_bps : in integer range 1200 to 230400 := 9600;             -- bps rate - don't set over 38400 for interrupt control applications
      kl0_force7bit : in integer range 0 to 1 := 0;                  -- zero out high order bit on transmission and reception
      kl0_rtscts : in integer range 0 to 1 := 0;                     -- conditional compilation switch for rts and cts signals; also implies to include core that implements a silo buffer

      tx1 : out std_logic;
      rx1 : in std_logic := '1';
      rts1 : out std_logic;
      cts1 : in std_logic := '0';
      kl1_bps : in integer range 1200 to 230400 := 9600;
      kl1_force7bit : in integer range 0 to 1 := 0;
      kl1_rtscts : in integer range 0 to 1 := 0;

      tx2 : out std_logic;
      rx2 : in std_logic := '1';
      rts2 : out std_logic;
      cts2 : in std_logic := '0';
      kl2_bps : in integer range 1200 to 230400 := 9600;
      kl2_force7bit : in integer range 0 to 1 := 0;
      kl2_rtscts : in integer range 0 to 1 := 0;

      tx3 : out std_logic;
      rx3 : in std_logic := '1';
      rts3 : out std_logic;
      cts3 : in std_logic := '0';
      kl3_bps : in integer range 1200 to 230400 := 9600;
      kl3_force7bit : in integer range 0 to 1 := 0;
      kl3_rtscts : in integer range 0 to 1 := 0;

-- dr11c, universal interface

      have_dr11c : in integer range 0 to 1 := 0;                     -- conditional compilation
      have_dr11c_loopback : in integer range 0 to 1 := 0;            -- for testing only - zdrc
      have_dr11c_signal_stretch : in integer range 0 to 127 := 7;    -- the signals ndr*, dxm, init will be stretched to this many cpu cycles

      dr11c_in : in std_logic_vector(15 downto 0) := (others => '0');
      dr11c_out : out std_logic_vector(15 downto 0);
      dr11c_reqa : in std_logic := '0';
      dr11c_reqb : in std_logic := '0';
      dr11c_csr0 : out std_logic;
      dr11c_csr1 : out std_logic;
      dr11c_ndr : out std_logic;                                     -- new data ready : dr11c_out has new data
      dr11c_ndrlo : out std_logic;                                   -- new data ready : dr11c_out(7 downto 0) has new data
      dr11c_ndrhi : out std_logic;                                   -- new data ready : dr11c_out(15 downto 8) has new data
      dr11c_dxm : out std_logic;                                     -- data transmitted : dr11c_in data has been read by the cpu
      dr11c_init : out std_logic;                                    -- unibus reset propagated out to the user device

-- minc-11

      have_mncad : in integer range 0 to 1 := 0;                     -- mncad: a/d, max one card in a system
      have_mnckw : in integer range 0 to 2 := 0;                     -- mnckw: clock, either one or two
      have_mncaa : in integer range 0 to 4 := 0;                     -- mncaa: d/a
      have_mncdi : in integer range 0 to 4 := 0;                     -- mncdi: digital in
      have_mncdo : in integer range 0 to 4 := 0;                     -- mncdo: digital out
      ad_start : out std_logic;                                      -- interface from mncad to a/d hardware : '1' signals to start converting
      ad_done : in std_logic := '1';                                 -- interface from mncad to a/d hardware : '1' signals to the mncad that the a/d has completed a conversion
      ad_channel : out std_logic_vector(5 downto 0);                 -- interface from mncad to a/d hardware : the channel number for the current command
      ad_nxc : in std_logic := '1';                                  -- interface from mncad to a/d hardware : '1' signals to the mncad that the required channel does not exist
      ad_sample : in std_logic_vector(11 downto 0) := "000000000000";-- interface from mncad to a/d hardware : the value of the last sample
      kw_st1in : in std_logic := '0';                                -- mnckw0 st1 signal input, active on rising edge
      kw_st2in : in std_logic := '0';                                -- mnckw0 st2 signal input, active on rising edge
      kw_st1out : out std_logic;                                     -- mnckw0 st1 output pulse - actually : copy of the st1flag in the csr
      kw_st2out : out std_logic;                                     -- mnckw0 st2 output pulse
      kw_clkov : out std_logic;                                      -- mnckw0 clkovf output pulse
      da_dac0 : out std_logic_vector(11 downto 0);                   -- da channel 0 - 1st mncaa unit
      da_dac1 : out std_logic_vector(11 downto 0);                   -- da channel 1
      da_dac2 : out std_logic_vector(11 downto 0);                   -- da channel 2
      da_dac3 : out std_logic_vector(11 downto 0);                   -- da channel 3
      da_dac4 : out std_logic_vector(11 downto 0);                   -- da channel 4 - 2nd mncaa unit
      da_dac5 : out std_logic_vector(11 downto 0);                   -- da channel 5
      da_dac6 : out std_logic_vector(11 downto 0);                   -- da channel 6
      da_dac7 : out std_logic_vector(11 downto 0);                   -- da channel 7
      da_dac8 : out std_logic_vector(11 downto 0);                   -- da channel 8 - 3rd mncaa unit
      da_dac9 : out std_logic_vector(11 downto 0);                   -- da channel 9
      da_dac10 : out std_logic_vector(11 downto 0);                  -- da channel 10
      da_dac11 : out std_logic_vector(11 downto 0);                  -- da channel 11
      da_dac12 : out std_logic_vector(11 downto 0);                  -- da channel 12 - 4th mncaa unit
      da_dac13 : out std_logic_vector(11 downto 0);                  -- da channel 13
      da_dac14 : out std_logic_vector(11 downto 0);                  -- da channel 14
      da_dac15 : out std_logic_vector(11 downto 0);                  -- da channel 15
      have_diloopback : in integer range 0 to 1 := 0;                -- set to 1 to loop back mncdo0 to mncdi0 internally for testing
      di_dir0 : in std_logic_vector(15 downto 0) := "0000000000000000";    -- mncdi0 data input register
      di_strobe0 : in std_logic := '0';                              -- strobe
      di_reply0 : out std_logic;                                     -- reply
      di_pgmout0 : out std_logic;                                    -- pgmout
      di_event0 : out std_logic;                                     -- event
      di_dir1 : in std_logic_vector(15 downto 0) := "0000000000000000";    -- mncdi1 data input register
      di_strobe1 : in std_logic := '0';                              -- strobe
      di_reply1 : out std_logic;                                     -- reply
      di_pgmout1 : out std_logic;                                    -- pgmout
      di_event1 : out std_logic;                                     -- event
      di_dir2 : in std_logic_vector(15 downto 0) := "0000000000000000";    -- mncdi2 data input register
      di_strobe2 : in std_logic := '0';                              -- strobe
      di_reply2 : out std_logic;                                     -- reply
      di_pgmout2 : out std_logic;                                    -- pgmout
      di_event2 : out std_logic;                                     -- event
      di_dir3 : in std_logic_vector(15 downto 0) := "0000000000000000";    -- mncdi3 data input register
      di_strobe3 : in std_logic := '0';                              -- strobe
      di_reply3 : out std_logic;                                     -- reply
      di_pgmout3 : out std_logic;                                    -- pgmout
      di_event3 : out std_logic;                                     -- event
      do_dor0 : out std_logic_vector(15 downto 0);                   -- mncdo unit 0 data output
      do_hb_strobe0 : out std_logic;                                 -- mncdo unit 0 high byte strobe
      do_lb_strobe0 : out std_logic;                                 -- mncdo unit 0 low byte strobe
      do_reply0 : in std_logic := '0';                               -- mncdo unit 0 reply input
      do_dor1 : out std_logic_vector(15 downto 0);                   -- mncdo unit 1 data output
      do_hb_strobe1 : out std_logic;                                 -- mncdo unit 1 high byte strobe
      do_lb_strobe1 : out std_logic;                                 -- mncdo unit 1 low byte strobe
      do_reply1 : in std_logic := '0';                               -- mncdo unit 1 reply input
      do_dor2 : out std_logic_vector(15 downto 0);                   -- mncdo unit 2 data output
      do_hb_strobe2 : out std_logic;                                 -- mncdo unit 2 high byte strobe
      do_lb_strobe2 : out std_logic;                                 -- mncdo unit 2 low byte strobe
      do_reply2 : in std_logic := '0';                               -- mncdo unit 2 reply input
      do_dor3 : out std_logic_vector(15 downto 0);                   -- mncdo unit 3 data output
      do_hb_strobe3 : out std_logic;                                 -- mncdo unit 3 high byte strobe
      do_lb_strobe3 : out std_logic;                                 -- mncdo unit 3 low byte strobe
      do_reply3 : in std_logic := '0';                               -- mncdo unit 3 reply input

-- cpu console, switches and display register
      have_csdr : in integer range 0 to 1 := 1;

-- clock
      have_kw11l : in integer range 0 to 1 := 1;                     -- conditional compilation
      kw11l_hz : in integer range 50 to 800 := 60;                   -- valid values are 50, 60, 800

-- model code
      modelcode : in integer range 0 to 255;                         -- mostly used are 20,34,44,45,70,94; others are less well tested
      have_fp : in integer range 0 to 2 := 2;                        -- fp11 switch; 0=don't include; 1=include; 2=include if the cpu model can support fp11
      have_fpa : in integer range 0 to 1 := 1;                       -- floating point accelerator present with J11 cpu

-- cpu initial r7 and psw
      init_r7 : in std_logic_vector(15 downto 0) := x"ea10";         -- start address after reset f600 = o'173000' = m9312 hi rom; ea10 = 165020 = m9312 lo rom
      init_psw : in std_logic_vector(15 downto 0) := x"00e0";        -- initial psw for kernel mode, primary register set, priority 7

-- console
      cons_load : in std_logic := '0';
      cons_exa : in std_logic := '0';
      cons_dep : in std_logic := '0';
      cons_cont : in std_logic := '0';                               -- continue, pulse '1'
      cons_ena : in std_logic := '1';                                -- ena/halt, '1' is enable
      cons_start : in std_logic := '0';
      cons_sw : in std_logic_vector(21 downto 0) := (others => '0');
      cons_adss_mode : in std_logic_vector(1 downto 0) := (others => '0');
      cons_adss_id : in std_logic := '0';
      cons_adss_cons : in std_logic := '0';
      cons_consphy : out std_logic_vector(21 downto 0);
      cons_progphy : out std_logic_vector(21 downto 0);
      cons_br : out std_logic_vector(15 downto 0);
      cons_shfr : out std_logic_vector(15 downto 0);
      cons_maddr : out std_logic_vector(15 downto 0);                -- microcode address fpu/cpu
      cons_dr : out std_logic_vector(15 downto 0);
      cons_parh : out std_logic;
      cons_parl : out std_logic;

      cons_adrserr : out std_logic;
      cons_run : out std_logic;                                      -- '1' if executing instructions (incl wait)
      cons_pause : out std_logic;                                    -- '1' if bus has been relinquished to npr
      cons_master : out std_logic;                                   -- '1' if cpu is bus master and not running
      cons_kernel : out std_logic;                                   -- '1' if kernel mode
      cons_super : out std_logic;                                    -- '1' if super mode
      cons_user : out std_logic;                                     -- '1' if user mode
      cons_id : out std_logic;                                       -- '0' if instruction, '1' if data AND data mapping is enabled in the mmu
      cons_map16 : out std_logic;                                    -- '1' if 16-bit mapping
      cons_map18 : out std_logic;                                    -- '1' if 18-bit mapping
      cons_map22 : out std_logic;                                    -- '1' if 22-bit mapping

-- clocks and reset
      clk : in std_logic;                                            -- cpu clock
      clk50mhz : in std_logic;                                       -- 50Mhz clock for peripherals
      reset : in std_logic                                           -- active '1' synchronous reset
   );
end component;

component paneldriver is
   port(
      panel_xled : out std_logic_vector(5 downto 0);
      panel_col : inout std_logic_vector(11 downto 0);
      panel_row : out std_logic_vector(2 downto 0);

      cons_load : out std_logic;
      cons_exa : out std_logic;
      cons_dep : out std_logic;
      cons_cont : out std_logic;
      cons_ena : out std_logic;
      cons_inst : out std_logic;
      cons_start : out std_logic;
      cons_sw : out std_logic_vector(21 downto 0);
      cons_adss_mode : out std_logic_vector(1 downto 0);
      cons_adss_id : out std_logic;
      cons_adss_cons : out std_logic;

      cons_consphy : in std_logic_vector(21 downto 0);
      cons_progphy : in std_logic_vector(21 downto 0);
      cons_shfr : in std_logic_vector(15 downto 0);
      cons_maddr : in std_logic_vector(15 downto 0);                 -- microcode address fpu/cpu
      cons_br : in std_logic_vector(15 downto 0);
      cons_dr : in std_logic_vector(15 downto 0);
      cons_parh : in std_logic;
      cons_parl : in std_logic;

      cons_adrserr : in std_logic;
      cons_run : in std_logic;
      cons_pause : in std_logic;
      cons_master : in std_logic;
      cons_kernel : in std_logic;
      cons_super : in std_logic;
      cons_user : in std_logic;
      cons_id : in std_logic;
      cons_map16 : in std_logic;
      cons_map18 : in std_logic;
      cons_map22 : in std_logic;

      sample_cycles : in std_logic_vector(15 downto 0) := x"0400";   -- a sample is this many runs of the panel state machine (which has 16 cycles, so multiply by that)
      minon_cycles : in std_logic_vector(15 downto 0) := x"0400";    -- if a signal has been on for this many cycles in a sample, then the corresponding output will be on - note 16, above.

      paneltype : in integer range 0 to 3 := 0;                      -- 0 - no console; 1 - PiDP11, regular; 2 - PiDP11, widdershins; 3 - PDP2011 nanocons

      cons_reset : out std_logic;                                    -- a request for a reset from the console

      clkin : in std_logic;
      reset : in std_logic
   );
end component;

component vt is
   port(
      vga_hsync : out std_logic;                                     -- horizontal sync
      vga_vsync : out std_logic;                                     -- vertical sync
      vga_hblank : out std_logic;                                    -- horizontal blank
      vga_vblank : out std_logic;                                    -- vertical blank
      ce_pix : out std_logic;                                        -- 
      vga_fb : out std_logic;                                        -- output - full
      vga_ht : out std_logic;                                        -- output - half

-- serial port
      tx : out std_logic;                                            -- transmit
      rx : in std_logic;                                             -- receive
      rts : out std_logic;                                           -- request to send
      cts : in std_logic := '0';                                     -- clear to send
      bps : in integer range 1200 to 230400 := 9600;                 -- bps rate - don't set to more than 38400
      force7bit : in integer range 0 to 1 := 0;                      -- zero out high order bit on transmission and reception
      rtscts : in integer range 0 to 1 := 0;                         -- conditional compilation switch for rts and cts signals; also implies to include core that implements a silo buffer

-- ps2 keyboard
      ps2k_c : in std_logic;                                         -- clock
      ps2k_d : in std_logic;                                         -- data

-- debug & blinkenlights
      ifetch : out std_logic;                                        -- ifetch : the cpu is running an instruction fetch cycle
      iwait : out std_logic;                                         -- iwait : the cpu is in wait state
      teste : in std_logic := '0';                                   -- teste : display 24*80 capital E without changing the display buffer
      testf : in std_logic := '0';                                   -- testf : display 24*80 all pixels on
      vga_debug : out std_logic_vector(15 downto 0);                 -- debug output from microcode
      vga_bl : out std_logic_vector(9 downto 0);                     -- blinkenlight vector

-- vt type code : 100 or 105
      vttype : in integer range 100 to 105 := 100;                   -- vt100 or vt105
      vga_cursor_block : in std_logic := '1';                        -- cursor is block ('1') or underline ('0')
      vga_cursor_blink : in std_logic := '0';                        -- cursor blinks ('1') or not ('0')
      have_act_seconds : in integer range 0 to 7200 := 900;          -- auto screen off time, in seconds; 0 means disabled
      have_act : in integer range 1 to 2 := 2;                       -- auto screen off counter reset by keyboard and serial port activity (1) or keyboard only (2)

-- clock & reset
      cpuclk : in std_logic;                                         -- cpuclk : should be around 10MHz, give or take a few
      clk50mhz : in std_logic;                                       -- clk50mhz : used for vga signal timing
      reset : in std_logic                                           -- reset
   );
end component;

signal cpuclk : std_logic;
signal cpureset : std_logic := '1';
signal cpuresetlength : integer range 0 to 255 := 255;

signal ifetch: std_logic;
signal iwait: std_logic;

signal txtx0 : std_logic;
signal rxrx0 : std_logic;
signal ctscts0: std_logic;
signal rtsrts0: std_logic;

signal txtx1 : std_logic;
signal rxrx1 : std_logic;
signal ctscts1: std_logic;
signal rtsrts1: std_logic;

signal txtx2 : std_logic;
signal rxrx2 : std_logic;
signal txtx3 : std_logic;
signal rxrx3 : std_logic;

signal vtrx  : std_logic;
signal vttx  : std_logic;
signal vtcts : std_logic;
signal vtrts : std_logic;

signal addr : std_logic_vector(21 downto 0);
signal dati : std_logic_vector(15 downto 0);
signal dato : std_logic_vector(15 downto 0);
signal control_dati : std_logic;
signal control_dato : std_logic;
signal control_datob : std_logic;

signal cons_load : std_logic;
signal cons_exa : std_logic;
signal cons_dep : std_logic;
signal cons_cont : std_logic;
signal cons_ena : std_logic;
signal cons_start : std_logic;
signal cons_sw : std_logic_vector(21 downto 0);
signal cons_adss_mode : std_logic_vector(1 downto 0);
signal cons_adss_id : std_logic;
signal cons_adss_cons : std_logic;

signal cons_consphy : std_logic_vector(21 downto 0);
signal cons_progphy : std_logic_vector(21 downto 0);
signal cons_br : std_logic_vector(15 downto 0);
signal cons_shfr : std_logic_vector(15 downto 0);
signal cons_maddr : std_logic_vector(15 downto 0);
signal cons_dr : std_logic_vector(15 downto 0);
signal cons_parh : std_logic;
signal cons_parl : std_logic;

signal cons_adrserr : std_logic;
signal cons_run : std_logic;
signal cons_pause : std_logic;
signal cons_master : std_logic;
signal cons_kernel : std_logic;
signal cons_super : std_logic;
signal cons_user : std_logic;
signal cons_id : std_logic;
signal cons_map16 : std_logic;
signal cons_map18 : std_logic;
signal cons_map22 : std_logic;

signal cons_reset : std_logic;

signal sample_cycles : std_logic_vector(15 downto 0) := x"0400";
signal minon_cycles : std_logic_vector(15 downto 0) := x"0400";


signal dram_match : std_logic;
signal dram_counter : integer range 0 to 32767;
signal dram_wait : integer range 0 to 15;

signal dram_refresh_count : integer range 0 to 255;


type dram_fsm_type is (
   dram_init,
   dram_poweron,
   dram_pwron_pre, dram_pwron_prew,
   dram_pwron_ref, dram_pwron_refw,
   dram_pwron_mrs, dram_pwron_mrsw,
   dram_c1,
   dram_c2,
   dram_c3,
   dram_c4,
   dram_c5,
   dram_c6,
   dram_c7,
   dram_c8,
   dram_c9,
   dram_c10,
   dram_c11,
   dram_c12,
   dram_c13,
   dram_c14,
   dram_idle
);
signal dram_fsm : dram_fsm_type := dram_init;

begin



   pdp11: unibus port map(
      modelcode => modelcode,  -- 24,45,70,94...

      have_kl11 => 4,
      tx0 => txtx0,
      rx0 => rxrx0,
		cts0=> ctscts0,
		rts0=> rtsrts0,
		kl0_bps => 19200,
      kl0_force7bit => 0,
		kl0_rtscts => 1,
		
      tx1 => txtx1,
      rx1 => rxrx1,
		cts1=> ctscts1,
		rts1=> rtsrts1,
		kl1_bps => 19200,
		kl1_force7bit => 0,
		kl1_rtscts => 1,
		
      tx2 => txtx2,
      rx2 => rxrx2,
		kl2_bps => 9600,
		kl2_force7bit => 0,

      tx3 => txtx3,
      rx3 => rxrx3,
		kl3_bps => 9600,
		kl3_force7bit => 0,
		
      have_rl => have_rl,
      rl_sdcard_cs    => rl_sdcard_cs,
      rl_sdcard_miso  => rl_sdcard_miso,
      rl_sdcard_mosi  => rl_sdcard_mosi,
      rl_sdcard_sclk  => rl_sdcard_sclk,
      rl_sdcard_debug => rl_sdcard_debug,

		have_rk => have_rk,
		rk_sdcard_cs    => rk_sdcard_cs,
      rk_sdcard_mosi  => rk_sdcard_mosi,
      rk_sdcard_sclk  => rk_sdcard_sclk,
      rk_sdcard_miso  => rk_sdcard_miso,
      rk_sdcard_debug => rk_sdcard_debug,

      have_rh => have_rh,
      rh_sdcard_cs => rh_sdcard_cs,
      rh_sdcard_miso => rh_sdcard_miso,
      rh_sdcard_mosi => rh_sdcard_mosi,
      rh_sdcard_sclk => rh_sdcard_sclk,
      rh_sdcard_debug => rh_sdcard_debug,

      have_xu => have_xu,
		have_xu_debug => 0,
      xu_cs   => xu_cs,
      xu_mosi => xu_mosi,
      xu_sclk => xu_sclk,
      xu_miso => xu_miso,
      xu_debug_tx => open,

      cons_load => cons_load,
      cons_exa => cons_exa,
      cons_dep => cons_dep,
      cons_cont => cons_cont,
      cons_ena => cons_ena,
      cons_start => cons_start,
      cons_sw => cons_sw,
      cons_adss_mode => cons_adss_mode,
      cons_adss_id => cons_adss_id,
      cons_adss_cons => cons_adss_cons,

      cons_consphy => cons_consphy,
      cons_progphy => cons_progphy,
      cons_shfr => cons_shfr,
      cons_maddr => cons_maddr,
      cons_br => cons_br,
      cons_dr => cons_dr,
      cons_parh => cons_parh,
      cons_parl => cons_parl,

      cons_adrserr => cons_adrserr,
      cons_run => cons_run,
      cons_pause => cons_pause,
      cons_master => cons_master,
      cons_kernel => cons_kernel,
      cons_super => cons_super,
      cons_user => cons_user,
      cons_id => cons_id,
      cons_map16 => cons_map16,
      cons_map18 => cons_map18,
      cons_map22 => cons_map22,

      addr => addr,
      dati => dati,
      dato => dato,
      control_dati => control_dati,
      control_dato => control_dato,
      control_datob => control_datob,
      addr_match => dram_match,
		
      iwait  => iwait,
      ifetch => ifetch,
      reset => cpureset,
      clk50mhz => clk_50,
      clk => cpuclk
   );

	  vt0: vt port map(
      vttype => vttype,
      vga_hsync => vga_hsync,
      vga_vsync => vga_vsync,
      vga_hblank => vga_hblank,
      vga_vblank => vga_vblank,
		ce_pix => ce_pix,
      vga_fb => vga_fb,
      vga_ht => vga_ht,

      rx => vtrx,
      tx => vttx,
		cts=> vtcts,
		rts=> vtrts,
      bps => 19200,
		force7bit => 0,

      ps2k_c => ps2k_c,
      ps2k_d => ps2k_d,

      vga_cursor_block => vga_cursor_block,
      vga_cursor_blink => vga_cursor_blink,
      teste => teste,
      testf => testf,
		
		ifetch => ifetch,
		iwait  => iwait,

      have_act_seconds => 900,  -- screen activity counter
      have_act => have_act,     --Screen activity

      cpuclk => cpuclk,
      clk50mhz => clk_50,
      reset => cpureset
   );

	
   panel: paneldriver port map(
      panel_xled => open,
      panel_col => open,
      panel_row => open,

      cons_load => cons_load,
      cons_exa => cons_exa,
      cons_dep => cons_dep,
      cons_cont => cons_cont,
      cons_ena => cons_ena,
      cons_start => cons_start,
      cons_sw => cons_sw,
      cons_adss_mode => cons_adss_mode,
      cons_adss_id => cons_adss_id,
      cons_adss_cons => cons_adss_cons,

      cons_consphy => cons_consphy,
      cons_progphy => cons_progphy,
      cons_shfr => cons_shfr,
      cons_maddr => cons_maddr,
      cons_br => cons_br,
      cons_dr => cons_dr,
      cons_parh => cons_parh,
      cons_parl => cons_parl,

      cons_adrserr => cons_adrserr,
      cons_run => cons_run,
      cons_pause => cons_pause,
      cons_master => cons_master,
      cons_kernel => cons_kernel,
      cons_super => cons_super,
      cons_user => cons_user,
      cons_id => cons_id,
      cons_map16 => cons_map16,
      cons_map18 => cons_map18,
      cons_map22 => cons_map22,

      cons_reset => cons_reset,

      paneltype => 0,

      sample_cycles => sample_cycles,
      minon_cycles => minon_cycles,

      clkin => cpuclk,
      reset => reset
   );


   tx1   <= txtx0 when serial_console = '1' else txtx1;
	vtrx  <= txtx0 when serial_console = '0' else txtx1;

	
	
   rxrx0 <= rx1 when serial_console = '1' else vttx;   
	rxrx1 <= rx1 when serial_console = '0' else vttx; 
	
   rts1  <= rtsrts0 when serial_console = '1' else rtsrts1;
	vtrts <= rtsrts0 when serial_console = '0' else rtsrts1;

   ctscts0 <= cts1 when serial_console = '1' else vtcts;   
	ctscts1 <= cts1 when serial_console = '0' else vtcts; 
	
	
   greenled  <= not rxrx1 or not txtx1 or not rxrx0 or not txtx0;
	
	dram_match <= '1' when addr(21 downto 18) /= "1111" else '0';
   dram_ldqm <= dram_addr(11);
	dram_udqm <= dram_addr(12);
	
   process(clk_100)
   begin
		
      if clk_100='1' and clk_100'event then

         if reset = '1' then
            dram_fsm <= dram_init;
            dram_cs_n <= '0';
            dram_ras_n <= '1';
            dram_cas_n <= '1';
            dram_we_n <= '1';
            dram_addr <= (others => '0');

            dram_addr(12) <= '0';
            dram_addr(11) <= '0';
            dram_ba_1 <= '0';
            dram_ba_0 <= '0';

            cpuclk <= '0';
            cpureset <= '1';
            cpuresetlength <= 126;
            dram_refresh_count <= 1;
         else

            case dram_fsm is

               when dram_init =>
                  dram_cs_n <= '0';
                  dram_ras_n <= '1';
                  dram_cas_n <= '1';
                  dram_we_n <= '1';
                  dram_addr <= (others => '0');

                  dram_ba_1 <= '0';
                  dram_ba_0 <= '0';

                  cpureset <= '1';
                  cpuresetlength <= 126;
                  dram_counter <= 32767;
                  dram_fsm <= dram_poweron;

               when dram_poweron =>
                  dram_cs_n <= '0';
                  dram_ras_n <= '1';
                  dram_cas_n <= '1';
                  dram_we_n <= '1';
                  dram_addr <= (others => '0');

                  dram_ba_1 <= '0';
                  dram_ba_0 <= '0';

                  if dram_counter = 0 then
                     dram_fsm <= dram_pwron_pre;
                  else
                     dram_counter <= dram_counter - 1;
                  end if;

               when dram_pwron_pre =>
                  dram_cs_n <= '0';
                  dram_ras_n <= '0';
                  dram_cas_n <= '1';
                  dram_we_n <= '0';
                  dram_addr(10) <= '1';

                  dram_ba_1 <= '0';
                  dram_ba_0 <= '0';
                  dram_addr(12) <= '0';
                  dram_addr(11) <= '0';
                  dram_addr(9 downto 0) <= (others => '0');

                  dram_wait <= 4;
                  dram_fsm <= dram_pwron_prew;

               when dram_pwron_prew =>
                  dram_cs_n <= '1';
                  if dram_wait = 0 then
                     dram_fsm <= dram_pwron_ref;
                     dram_counter <= 20;
                  else
                     dram_wait <= dram_wait - 1;
                  end if;

               when dram_pwron_ref =>
                  dram_cs_n <= '0';
                  dram_ras_n <= '0';
                  dram_cas_n <= '0';
                  dram_we_n <= '1';
                  dram_addr <= (others => '0');

                  dram_ba_1 <= '0';
                  dram_ba_0 <= '0';

                  dram_wait <= 15;
                  dram_fsm <= dram_pwron_refw;

               when dram_pwron_refw =>
                  dram_cs_n <= '1';
                  if dram_wait = 0 then
                     if dram_counter = 0 then
                        dram_fsm <= dram_pwron_mrs;
                     else
                        dram_counter <= dram_counter - 1;
                        dram_fsm <= dram_pwron_ref;
                     end if;
                  else
                     dram_wait <= dram_wait - 1;
                  end if;

               when dram_pwron_mrs =>
                  dram_cs_n <= '0';
                  dram_ras_n <= '0';
                  dram_cas_n <= '0';
                  dram_we_n <= '0';

                  dram_addr(12 downto 7) <= (others => '0');
                  dram_addr(6 downto 4) <= "011";          -- cas length 3
                  dram_addr(3) <= '0';                     -- sequential
                  dram_addr(2 downto 0) <= "000";          -- length 0

                  dram_ba_1 <= '0';
                  dram_ba_0 <= '0';

                  dram_wait <= 4;
                  dram_fsm <= dram_pwron_mrsw;

               when dram_pwron_mrsw =>
                  dram_cs_n <= '1';
                  if dram_wait = 0 then
                     dram_fsm <= dram_idle;
                  else
                     dram_wait <= dram_wait - 1;
                  end if;

               when dram_idle =>
                  dram_cs_n <= '1';
                  dram_ras_n <= '1';
                  dram_cas_n <= '1';
                  dram_we_n <= '1';
                  dram_addr(10) <= '0';

                  dram_ba_1 <= '0';
                  dram_ba_0 <= '0';
                  dram_addr(12) <= '0';
                  dram_addr(11) <= '0';
                  dram_addr(9 downto 0) <= (others => '0');

                  dram_fsm <= dram_c1;

               when dram_c1 =>

                  if cpuresetlength = 0 then
                     cpureset <= '0';
                  else
                     cpuresetlength <= cpuresetlength - 1;
                  end if;
                  if cons_reset = '1' then
                     cpuresetlength <= 126;
                     cpureset <= '1';
                  end if;

               cpuclk <= '1';

                  dram_fsm <= dram_c2;

               when dram_c2 =>
                  dram_dq <= (others => 'Z');
                  dram_fsm <= dram_c3;

               when dram_c3 =>
                  dram_fsm <= dram_c4;         -- 5, for more agressive timing

               when dram_c4 =>
                  dram_fsm <= dram_c5;

               when dram_c5 =>
                  dram_fsm <= dram_c6;

               when dram_c6 =>
                  -- read, t1-t2

                  if dram_match = '1' and control_dati = '1' then
                     -- activate command
                     dram_cs_n <= '0';
                     dram_ras_n <= '0';
                     dram_cas_n <= '1';
                     dram_we_n <= '1';
                     dram_addr(12) <= '0';
                     dram_addr(11 downto 0) <= addr(20 downto 9);

                     dram_ba_1 <= '0';
                     dram_ba_0 <= addr(21);
                  end if;

                  -- write, t1-t2
                  if dram_match = '1' and control_dato = '1' then
                     -- activate command
                     dram_cs_n <= '0';
                     dram_ras_n <= '0';
                     dram_cas_n <= '1';
                     dram_we_n <= '1';
                     dram_addr(12) <= '0';
                     dram_addr(11 downto 0) <= addr(20 downto 9);

                     dram_ba_1 <= '0';
                     dram_ba_0 <= addr(21);
                  end if;

                  if dram_match = '0' or (control_dato = '0' and control_dati = '0') then
                     -- auto refresh command
                     if dram_refresh_count = 0 then
                        dram_cs_n <= '0';
                        dram_ras_n <= '0';
                        dram_cas_n <= '0';
                        dram_we_n <= '1';
                        dram_refresh_count <= 255;
                     else
                        dram_refresh_count <= dram_refresh_count - 1;
                     end if;
                  end if;

                  dram_fsm <= dram_c7;

               when dram_c7 =>
                  -- t2-t3 - set nop command
                  dram_cs_n <= '1';
                  dram_ras_n <= '1';
                  dram_cas_n <= '1';
                  dram_we_n <= '1';

                  dram_fsm <= dram_c8;

               when dram_c8 =>

                  -- read, t3-t4
                  if dram_match = '1' and control_dati = '1' then
                     -- reada command
                     dram_cs_n <= '0';
                     dram_ras_n <= '1';
                     dram_cas_n <= '0';
                     dram_we_n <= '1';
                     dram_addr(12) <= '0';
                     dram_addr(11) <= '0';
                     dram_addr(10) <= '1';
                     dram_addr(9) <= '1';
                     dram_addr(8) <= '0';
                     dram_addr(7 downto 0) <= addr(8 downto 1);

                     dram_ba_1 <= '0';
                     dram_ba_0 <= addr(21);
                  end if;

                  -- write, t3-t4
                  if dram_match = '1' and control_dato = '1' then
                     -- writea command
                     dram_cs_n <= '0';
                     dram_ras_n <= '1';
                     dram_cas_n <= '0';
                     dram_we_n <= '0';
                     dram_addr(12) <= '0';
                     dram_addr(11) <= '0';
                     dram_addr(10) <= '1';
                     dram_addr(9) <= '1';
                     dram_addr(8) <= '0';
                     dram_addr(7 downto 0) <= addr(8 downto 1);
                     if control_datob = '1' then
                        if addr(0) = '0' then
                           dram_addr(12) <= '1';
                        else
                           dram_addr(11) <= '1';
                        end if;
                     end if;
                     dram_ba_1 <= '0';
                     dram_ba_0 <= addr(21);
                     dram_dq <= dato;
                  end if;

                  dram_fsm <= dram_c9;

               cpuclk <= '0';

               when dram_c9 =>

                  -- read/write, t4-t5 - set nop command and deselect
                  dram_cs_n <= '1';
                  dram_ras_n <= '1';
                  dram_cas_n <= '1';
                  dram_we_n <= '1';

                  dram_fsm <= dram_c10;

               when dram_c10 =>
                  dram_fsm <= dram_c11;

               when dram_c11 =>
                  dram_fsm <= dram_c12;

               when dram_c12 =>
                  dram_fsm <= dram_c13;

               when dram_c13 =>
                  -- read, t5-t6
                  if dram_match = '1' and control_dati = '1' then
                     dati <= dram_dq;
                  end if;
                  dram_fsm <= dram_c14;

               when dram_c14 =>
                  dram_fsm <= dram_c1;

               when others =>
                  null;

            end case;

         end if;
      end if;
   end process;

end implementation;

