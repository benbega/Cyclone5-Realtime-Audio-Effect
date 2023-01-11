--! @file led_array.vhd
--! @brief A generic memory-mapped LED array component.
--! @details This entity implements a memory-mapped LED array that supports
--!          widths between 1 and 32. It's really just a generic memory-maped
--!          component with an output conduit that can be hooked up to pins
--!          at the top-level. 
--! @author Trevor Vannoy
--! @author Ross Snider
-- SPDX-License-Identifier: MIT

library ieee;
use ieee.std_logic_1164.all;

entity led_array is
  generic (
    n_leds : positive range 1 to 32 := 8
  );
  port (
    clk                    : in    std_logic;
    reset                  : in    std_logic;
    avalon_slave_address   : in    std_logic;
    avalon_slave_write     : in    std_logic;
    avalon_slave_writedata : in    std_logic_vector(31 downto 0);
    avalon_slave_read      : in    std_logic;
    avalon_slave_readdata  : out   std_logic_vector(31 downto 0);
    leds                   : out   std_logic_vector(n_leds - 1 downto 0)
  );
end entity led_array;

architecture rtl of led_array is

  signal leds_reg : std_logic_vector(n_leds - 1 downto 0) := (others => '0');

begin

  bus_read : process (clk) is
  begin
    if rising_edge(clk) and avalon_slave_read ='1' then
      case avalon_slave_address is
        when '0' =>
          avalon_slave_readdata(31 downto n_leds) <= (31 downto n_leds => '0');
          avalon_slave_readdata(n_leds - 1 downto 0) <= leds_reg;
        when others =>
          -- return zeros for undefined registers
          avalon_slave_readdata <= (others => '0');
      end case;
    end if;
  end process bus_read;

  bus_write : process (clk) is
  begin
    if reset = '1' then
      leds_reg <= (others => '0');
    elsif rising_edge(clk) and avalon_slave_write ='1' then
      case avalon_slave_address is
        when '0' =>
          leds_reg <= avalon_slave_writedata(n_leds - 1 downto 0);
        when others =>
          null;
      end case;
    end if;
  end process bus_write;

  leds <= leds_reg;

end architecture rtl;

