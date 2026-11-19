library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity sincronizador is
port(
 clk      : in  std_logic;
    reset    : in  std_logic;  -- sínc_H
    async_in : in  std_logic;
    sync_out : out std_logic
  );
end entity sincronizador;

architecture behavorial of sincronizador is
signal s_ff1, s_ff2 : std_logic := '0' ; --Señal-flipflop1/2 (señales interna)
begin
process(clk)
begin
if rising_edge(clk) then --Flanco de subida (Biestable D)
  if reset = '1' then
        s_ff1 <= '0';
        s_ff2 <= '0';
      else
        s_ff1 <= async_in; --Filtro que estabiliza la señal
        s_ff2 <= s_ff1; --Recibe el valor antiguo
      end if;
    end if;
  end process;
  sync_out <= s_ff2;
end architecture behavorial;