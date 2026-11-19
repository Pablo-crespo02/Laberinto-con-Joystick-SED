-- Comprueba: la salida sigue a la entrada con 2 ciclos de retardo (en subida y en bajada)
-- El reset pone la salida a 0.
library ieee;
use ieee.std_logic_1164.all;

entity sincronizador_tb is --Vacío (no tiene puertos)
end entity sincronizador_tb;

architecture behavioral of sincronizador_tb is

  constant T_CLK : time := 10 ns; --La placa trabaja a 100MHz (10ns)
--Señales:
  signal clk      : std_logic := '0';
  signal reset    : std_logic := '1';   --Inicio:Reset
  signal async_in : std_logic := '0';
  signal sync_out : std_logic;

  signal fin_sim  : boolean := false; --Si es true se detiene la simulación

begin

  uut : entity work.sincronizador --Unit under test
    port map (
      clk      => clk,
      reset    => reset,
      async_in => async_in,
      sync_out => sync_out
    );
--Invierte cada 5ns mientras dure la simulación
  clk <= not clk after T_CLK / 2 when not fin_sim;
--Procesos:
  estimulos : process
  begin
    -- Mantener el reset 2 ciclos y soltarlo en un flanco de bajada
    wait for 2 * T_CLK;
    wait until falling_edge(clk);
    reset <= '0';
    -- Prueba 1: subida de la entrada
    async_in <= '1';
    wait until rising_edge(clk);   -- 1.er flanco: dato llega a s_ff1
    wait for 1 ns;                 -- se actualizan las señales
    assert sync_out = '0'
      report "ERROR: salida a 1 tras solo 1 ciclo" severity error;

    wait until rising_edge(clk);   -- 2.º flanco: el dato llega a s_ff2
    wait for 1 ns;
    assert sync_out = '1'
      report "ERROR: salida no a 1 tras 2 ciclos" severity error;

    -- Prueba 2: bajada de la entrada
    wait until falling_edge(clk);
    async_in <= '0';
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    wait for 1 ns;
    assert sync_out = '0'
      report "ERROR: salida no a 0 tras 2 ciclos" severity error;

    -- Prueba 3: con la entrada a 1, el reset debe poner la salida a 0
    async_in <= '1';
    wait for 4 * T_CLK;
    assert sync_out = '1'
      report "ERROR: no sigue a la entrada" severity error;

    reset <= '1';
    wait until rising_edge(clk);
    wait for 1 ns;
    assert sync_out = '0'
      report "ERROR: el reset no pone la salida a 0" severity error;

    -- Fin: si no ha salido ningún ERROR, el módulo funciona
    report "sincronizador_tb: FIN DE SIMULACION" severity note;
    fin_sim <= true;
    wait;   -- el proceso se queda parado para siempre
  end process estimulos;

end architecture behavioral;

