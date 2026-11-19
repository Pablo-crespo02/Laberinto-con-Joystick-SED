-- Ignora rebotes más cortos que ESTABLE_MS ticks y acepta un cambio
-- estable, tanto al pulsar como al soltar.
-- Tick generado aquí cada 5 ciclos y ESTABLE_MS = 4 para simular en ns en lugar de ms

library ieee;
use ieee.std_logic_1164.all;

entity antirrebote_tb is --No tiene puertos
end entity antirrebote_tb;

architecture behavioral of antirrebote_tb is

  constant T_CLK   : time     := 10 ns;     -- 100 MHz
  constant ESTABLE : positive := 4;         -- ticks exigidos (en la realidad 20)
  constant T_TICK  : time     := 5 * T_CLK; -- un tick cada 5 ciclos (50 ns)

  signal clk     : std_logic := '0';
  signal reset   : std_logic := '1'; -- Empezamos con reset H
  signal tick    : std_logic := '0';
  signal entrada : std_logic := '0';
  signal salida  : std_logic;
  signal fin_sim : boolean := false;

begin
--Modulo con ESTABLE_MS a 4 para probar más facilmente
  uut : entity work.antirrebote
    generic map (ESTABLE_MS => ESTABLE)
    port map (
      clk     => clk,
      reset   => reset,
      tick    => tick,
      entrada => entrada,
      salida  => salida
    );

  clk <= not clk after T_CLK / 2 when not fin_sim; -- ciclo de reloj
  -- Tick: 1 ciclo a '1' cada 5 ciclos. (Futuro prescaler)
  gen_tick : process
  begin
    while not fin_sim loop
      wait until rising_edge(clk);
      tick <= '0';
      for i in 1 to 4 loop -- Bucle espera 5 ciclos
        wait until rising_edge(clk);
      end loop;
      tick <= '1'; -- Tras espera pasa a 1
    end loop;
    wait;
  end process gen_tick;
-- Comprobación:
  estimulos : process
  begin
    wait for 3 * T_CLK;
    reset <= '0';

    -- Prueba 1: rebotes al pulsar (cada pulso dura 1 tick, menos que ESTABLE)
    -- Salida no cambia
    for i in 1 to 3 loop
      entrada <= '1'; wait for T_TICK;
      entrada <= '0'; wait for T_TICK;
    end loop;
    assert salida = '0'
      report "ERROR: un rebote corto ha cambiado la salida" severity error;

    -- Prueba 2: pulsación estable (más ticks que estable)
    entrada <= '1';
    wait for (ESTABLE + 2) * T_TICK;
    assert salida = '1'
      report "ERROR: no acepta una pulsación estable" severity error;

    -- Prueba 3: rebotes al soltar. La salida debe seguir a 1
    for i in 1 to 3 loop
      entrada <= '0'; wait for T_TICK;
      entrada <= '1'; wait for T_TICK;
    end loop;
    assert salida = '1'
      report "ERROR: un rebote al soltar ha cambiado la salida" severity error;

    -- Prueba 4: suelta estable. La salida vuelve a 0
    entrada <= '0';
    wait for (ESTABLE + 2) * T_TICK;
    assert salida = '0'
      report "ERROR: no acepta la suelta estable" severity error;

    report "antirrebote_tb: FIN DE SIMULACION" severity note;
    fin_sim <= true;
    wait;
  end process estimulos;

end architecture behavioral;