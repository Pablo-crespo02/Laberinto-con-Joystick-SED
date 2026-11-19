library ieee;
use ieee.std_logic_1164.all;

entity prescaler_tb is
end entity prescaler_tb;

architecture behavioral of prescaler_tb is

  constant T_CLK   : time     := 10 ns;
  constant DIVISOR : positive := 10; -- 10 para simular más fácil

  signal clk     : std_logic := '0';
  signal reset   : std_logic := '1';
  signal tick    : std_logic;
  signal fin_sim : boolean := false;

begin

  uut : entity work.prescaler
    generic map (DIVISOR => DIVISOR)
    port map (
      clk   => clk,
      reset => reset,
      tick  => tick
    );

  clk <= not clk after T_CLK / 2 when not fin_sim;

  estimulos : process
    -- Variable: guarda el instante del tick anterior para medir el periodo
    variable t_anterior : time := 0 ns;
  begin
    wait for 3 * T_CLK;
    reset <= '0';

    -- Primer tick: solo sirve de referencia de tiempo
    wait until rising_edge(clk) and tick = '1';
    t_anterior := now;

    -- Medimos 5 periodos seguidos
    for i in 1 to 5 loop
      -- En el flanco siguiente el tick ya debe haber bajado (dura 1 ciclo)
      wait until rising_edge(clk);
      assert tick = '0'
        report "ERROR: el tick dura más de 1 ciclo" severity error;

      -- El siguiente tick debe llegar justo DIVISOR ciclos después
      wait until rising_edge(clk) and tick = '1';
      assert now - t_anterior = DIVISOR * T_CLK
        report "ERROR: periodo del tick incorrecto: " & time'image(now - t_anterior)
        severity error;
      t_anterior := now;
    end loop;

    report "prescaler_tb: FIN DE SIMULACION" severity note;
    fin_sim <= true;
    wait;
  end process estimulos;

end architecture behavioral;