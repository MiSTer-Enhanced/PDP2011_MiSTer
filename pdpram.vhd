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

entity pdpram is
   port(
	   -- control
		addr : in  std_logic_vector(21 downto 0);
		dati : out  std_logic_vector(15 downto 0);
		dato : in std_logic_vector(15 downto 0);
		control_dati : in std_logic;
		control_dato : in std_logic;
		control_datob : in std_logic;
	   dram_match : out std_logic;
		memory : in std_logic;

		-- clocks
		clk    : in std_logic;
	   cpuclk : out std_logic;

      -- reset		
		reset   : in std_logic;
		cons_reset : in std_logic;
		cpureset: out std_logic;

      -- dram
      dram_addr : out std_logic_vector(12 downto 0);
      dram_dq : inout std_logic_vector(15 downto 0);
      dram_ba_1 : out std_logic;
      dram_ba_0 : out std_logic;
      dram_udqm : out std_logic;
      dram_ldqm : out std_logic;
      dram_ras_n : out std_logic;
      dram_cas_n : out std_logic;
      dram_cke : out std_logic;
      dram_clk : out std_logic;
      dram_we_n : out std_logic;
      dram_cs_n : out std_logic
   );
	
end pdpram;

architecture implementation of pdpram is

signal cpuresetlength : integer range 0 to 63 := 63;
signal dram_counter : integer range 0 to 32767;
signal dram_wait : integer range 0 to 15;
signal dram_match_v : std_logic;
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

   dram_match <= dram_match_v;	  
   dram_cke <= '1';
   dram_clk <= clk;
   dram_match_v <= '1' when (addr(21 downto 18) /= "1111" and memory = '1') else 
                 '1' when (addr(21 downto 13) /= "111111111" and memory ='0') else '0';

   process(clk)
   begin		
      if clk='1' and clk'event then

         if reset = '1' then
            dram_fsm <= dram_init;
            dram_cs_n <= '0';
            dram_ras_n <= '1';
            dram_cas_n <= '1';
            dram_we_n <= '1';
            dram_addr <= (others => '0');

            dram_udqm <= '1';
            dram_ldqm <= '1';
            dram_ba_1 <= '0';
            dram_ba_0 <= '0';

            cpuclk <= '0';
            cpureset <= '1';
            cpuresetlength <= 63;
            dram_refresh_count <= 1;
         else

            case dram_fsm is

               when dram_init =>
                  dram_cs_n <= '0';
                  dram_ras_n <= '1';
                  dram_cas_n <= '1';
                  dram_we_n <= '1';
                  dram_addr <= (others => '0');

                  dram_udqm <= '1';
                  dram_ldqm <= '1';
                  dram_ba_1 <= '0';
                  dram_ba_0 <= '0';

                  cpureset <= '1';
                  cpuresetlength <= 63;
                  dram_counter <= 32767;
                  dram_fsm <= dram_poweron;

               when dram_poweron =>
                  dram_cs_n <= '0';
                  dram_ras_n <= '1';
                  dram_cas_n <= '1';
                  dram_we_n <= '1';
                  dram_addr <= (others => '0');

                  dram_udqm <= '1';
                  dram_ldqm <= '1';
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

                  dram_udqm <= '1';
                  dram_ldqm <= '1';
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

                  dram_udqm <= '1';
                  dram_ldqm <= '1';
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

                  dram_udqm <= '1';
                  dram_ldqm <= '1';
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

                  dram_udqm <= '1';
                  dram_ldqm <= '1';
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
                     cpuresetlength <= 63;
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

                  if dram_match_v = '1' and control_dati = '1' then
                     -- activate command
                     dram_cs_n <= '0';
                     dram_ras_n <= '0';
                     dram_cas_n <= '1';
                     dram_we_n <= '1';
                     dram_addr(12) <= '0';
                     dram_addr(11 downto 0) <= addr(20 downto 9);

                     dram_udqm <= '0';
                     dram_ldqm <= '0';
                     dram_ba_1 <= '0';
                     dram_ba_0 <= addr(21);
                  end if;

                  -- write, t1-t2
                  if dram_match_v = '1' and control_dato = '1' then
                     -- activate command
                     dram_cs_n <= '0';
                     dram_ras_n <= '0';
                     dram_cas_n <= '1';
                     dram_we_n <= '1';
                     dram_addr(12) <= '0';
                     dram_addr(11 downto 0) <= addr(20 downto 9);

                     dram_udqm <= '0';
                     dram_ldqm <= '0';
                     dram_ba_1 <= '0';
                     dram_ba_0 <= addr(21);
                  end if;

                  if dram_match_v = '0' or (control_dato = '0' and control_dati = '0') then
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
                  if dram_match_v = '1' and control_dati = '1' then
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

                     dram_udqm <= '0';
                     dram_ldqm <= '0';
                     dram_ba_1 <= '0';
                     dram_ba_0 <= addr(21);
                  end if;

                  -- write, t3-t4
                  if dram_match_v = '1' and control_dato = '1' then
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
                     dram_udqm <= '0';
                     dram_ldqm <= '0';
                     if control_datob = '1' then
                        if addr(0) = '0' then
                           dram_udqm <= '1';
                        else
                           dram_ldqm <= '1';
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
                  if dram_match_v = '1' and control_dati = '1' then
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
