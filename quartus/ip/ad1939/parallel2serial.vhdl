library ieee;
use ieee.std_logic_1164.all;

entity parallel2serial is
  generic (
    width : natural := 32
  );
  port (
    clk      : in    std_logic;
    data_in  : in    std_logic_vector(width - 1 downto 0);
    load     : in    std_logic;
    data_out : out   std_logic
  );
end entity parallel2serial;

architecture rtl of parallel2serial is

  signal data_in_reg : std_logic_vector(width - 1 downto 0);

begin

  shift_reg : process (clk) is
  begin

    if rising_edge(clk) then
      if load = '1' then
        data_in_reg <= data_in;
      else
        data_in_reg <= data_in_reg(width - 2 downto 0) & '0';
      end if;
    end if;

    -- shift the MSB out first
    data_out <= data_in_reg(width - 1);

  end process shift_reg;

end architecture rtl;
