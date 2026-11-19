library ieee;
use ieee.std_logic_1164.all;
-- 100_000 ciclos * 10ns = 1ms
entity prescaler is
  generic (
    DIVISOR : positive := 100_000 -- 1kHz con clk de 100MHz lo ajusta
  );
  port (
    clk   : in  std_logic;
    reset : in  std_logic;
    tick  : out std_logic -- Usa el tick como enable (síncrono)
  );
end entity prescaler;

architecture behavioral of prescaler is
  signal s_cuenta : natural range 0 to DIVISOR - 1 := 0;
  signal s_tick : std_logic := '0'; -- Si no inicilizamos, los primeros 5ns tiene valor U, se puede propagar más adelante
begin

  process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        s_cuenta <= 0;
        s_tick     <= '0';
      elsif s_cuenta = DIVISOR - 1 then
      -- tick aparacere un ciclo después de llegat a DIVISOR-1
        s_cuenta <= 0;          -- termina de conta5çr
        s_tick     <= '1';        -- da el pulso
      else
        s_cuenta <= s_cuenta + 1; -- Sigue contando (no ha dado el pulso)
        s_tick     <= '0';
      end if;
    end if;
  end process;
  tick <= s_tick;
end architecture behavioral;