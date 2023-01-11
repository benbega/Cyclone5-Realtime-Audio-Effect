library ieee;
use ieee.std_logic_1164.all;

entity serial2parallel is
  generic (
    width : natural := 32
  );
  port (
    clk      : in    std_logic;
    data_in  : in    std_logic;
    data_out : out   std_logic_vector(width - 1 downto 0)
  );
end entity serial2parallel;

architecture rtl of serial2parallel is

  signal data_out_reg : std_logic_vector(width - 1 downto 0);

begin

  shift_reg : process (clk) is
  begin

    if rising_edge(clk) then
      data_out_reg <= data_out_reg(width - 2 downto 0) & data_in;
    end if;

  end process shift_reg;

  data_out <= data_out_reg;

end architecture rtl;
