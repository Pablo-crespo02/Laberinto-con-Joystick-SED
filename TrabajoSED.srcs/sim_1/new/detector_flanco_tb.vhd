-- Comprueba: un único pulso de 1 ciclo por cada flanco de subida, aunque la
--            entrada se mantenga a 1, y ningún pulso en el flanco de bajada.
library ieee;
use ieee.std_logic_1164.all;

entity detector_flanco_tb is
end entity detector_flanco_tb;

architecture behavioral of detector_flanco_tb is

  constant T_CLK : time := 10 ns;

  signal clk      : std_logic := '0';
  signal reset    : std_logic := '1';
  signal entrada  : std_logic := '0';
  signal pulso    : std_logic;
  signal n_pulsos : natural := 0;     -- cuántos ciclos ha valido pulso = 1
  signal fin_sim  : boolean := false;

begin

  uut : entity work.detector_flanco
    port map (
      clk     => clk,
      reset   => reset,
      entrada => entrada,
      pulso   => pulso
    );

  clk <= not clk after T_CLK / 2 when not fin_sim;

  -- Contador de pulsos: suma 1 en cada flanco en que pulso vale 1.
  -- Así comprobamos cuántos pulsos ha habido, no solo si hay uno ahora.
 
  contador : process (clk)
  begin
    if rising_edge(clk) and pulso = '1' then
      n_pulsos <= n_pulsos + 1;
    end if;
  end process contador;

  -- Simulacion:
  estimulos : process
  begin
    wait for 3 * T_CLK;
    wait until falling_edge(clk);
    reset <= '0';

    -- Prueba 1: pulsación larga (10 ciclos). Debe haber UN solo pulso
    entrada <= '1';
    wait for 10 * T_CLK;
    assert n_pulsos = 1
      report "ERROR: esperado 1 pulso, obtenidos " & integer'image(n_pulsos)
      severity error;

    -- Prueba 2: flanco de bajada. NO debe haber pulso nuevo
    entrada <= '0';
    wait for 5 * T_CLK;
    assert n_pulsos = 1
      report "ERROR: pulso en el flanco de bajada" severity error;

    -- Prueba 3: segunda pulsación. Debe aparecer el segundo pulso
    entrada <= '1';
    wait for 5 * T_CLK;
    assert n_pulsos = 2
      report "ERROR: no detecta la segunda pulsación" severity error;

    report "detector_flanco_tb: FIN DE SIMULACION" severity note;
    fin_sim <= true;
    wait;
  end process estimulos;
  
end architecture behavioral;