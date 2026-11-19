library ieee;
use ieee.std_logic_1164.all;
-- Genera un pulso de 1 ciclo de reloj en cada flanco de subida
entity detector_flanco is
  port (
    clk     : in  std_logic;
    reset   : in  std_logic;
    entrada : in  std_logic;
    pulso   : out std_logic -- pulso generado con el flanco
  );
end entity detector_flanco;

architecture behavioral of detector_flanco is
  signal s_anterior : std_logic := '0';
begin
  process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        s_anterior <= '0'; -- Reset
      else
        s_anterior <= entrada; -- Guarda el estado actual para el siguiente ciclo
      end if;
    end if;
  end process;
  -- Ahora 1, antes 0 -> flanco de subida (no espera al reloj) es asíncrono
  pulso <= entrada and not s_anterior;
end architecture behavioral;
