-- 1) al arrancar todo está en reset y los LEDs apagados
-- 2) LED(0) cambia cada DIV_1HZ ciclos
-- 3) con rebotes en BTNC, LED(1) sigue al botón ya filtrado y LED(2) cambia una sola vez por pulsación
-- 4) CPU_RESETN apaga LED(0) y LED(2)
library ieee;
use ieee.std_logic_1164.all;

entity top_laberinto_tb is
end entity top_laberinto_tb;

architecture behavioral of top_laberinto_tb is

  constant T_CLK    : time     := 10 ns;
  constant DIV_1KHZ : positive := 5;     -- "1 ms" = 5 ciclos
  constant DIV_1HZ  : positive := 40;    -- "1 s"  = 40 ciclos
  constant ESTABLE  : positive := 3;     -- antirrebote = 3 ticks
  constant T_TICK   : time     := DIV_1KHZ * T_CLK;

  signal clk        : std_logic := '0';
  signal cpu_resetn : std_logic := '0';  -- empieza con el reset pulsado
  signal btnc       : std_logic := '0';
  signal led        : std_logic_vector(2 downto 0);
  signal fin_sim    : boolean := false;

  -- Pulsación con rebotes: 3 rebotes cortos y luego estable durante 'duracion'
  procedure pulsar_con_rebotes (signal boton : out std_logic; duracion : in time) is
  begin
    for i in 1 to 3 loop
      boton <= '1'; wait for 2 * T_CLK;
      boton <= '0'; wait for 2 * T_CLK;
    end loop;
    boton <= '1';
    wait for duracion;
  end procedure;

begin

  uut : entity work.top_laberinto
    generic map (DIV_1KHZ => DIV_1KHZ, DIV_1HZ => DIV_1HZ, ESTABLE_MS => ESTABLE)
    port map (CLK100MHZ => clk, CPU_RESETN => cpu_resetn, BTNC => btnc, LED => led);

  clk <= not clk after T_CLK / 2 when not fin_sim;

  estimulos : process
    variable t_cambio : time;
  begin
    -- 1) Arranque con reset
    wait for 5 * T_CLK;
    assert led = "000" report "ERROR: LEDs encendidos durante el reset" severity error;
    cpu_resetn <= '1';

    -- 2) LED(0): medir el tiempo entre dos cambios
    wait until led(0)'event;
    t_cambio := now;
    wait until led(0)'event;
    assert now - t_cambio = DIV_1HZ * T_CLK
      report "ERROR: LED(0) no cambia cada DIV_1HZ ciclos: " & time'image(now - t_cambio)
      severity error;

    -- 3a) Pulsación con rebotes, mantenida
    pulsar_con_rebotes(btnc, (ESTABLE + 3) * T_TICK);
    assert led(1) = '1' report "ERROR: LED(1) no se enciende al pulsar" severity error;
    assert led(2) = '1' report "ERROR: LED(2) no cambia al pulsar" severity error;

    -- Mantener pulsado más tiempo: LED(2) no debe volver a cambiar
    wait for 10 * T_TICK;
    assert led(2) = '1' report "ERROR: LED(2) cambia más de una vez por pulsación" severity error;

    -- 3b) Soltar: LED(1) se apaga, LED(2) se mantiene
    btnc <= '0';
    wait for (ESTABLE + 3) * T_TICK;
    assert led(1) = '0' report "ERROR: LED(1) no se apaga al soltar" severity error;
    assert led(2) = '1' report "ERROR: LED(2) cambia al soltar" severity error;

    -- 3c) Segunda pulsación: LED(2) vuelve a 0
    pulsar_con_rebotes(btnc, (ESTABLE + 3) * T_TICK);
    assert led(2) = '0' report "ERROR: LED(2) no cambia en la segunda pulsación" severity error;
    btnc <= '0';

    -- 4) Reset: LED(0) y LED(2) a 0
    wait until led(0) = '1';
    cpu_resetn <= '0';
    wait for 5 * T_CLK;
    assert led(0) = '0' and led(2) = '0'
      report "ERROR: CPU_RESETN no apaga los LEDs" severity error;

    report "top_laberinto_tb: FIN DE SIMULACION" severity note;
    fin_sim <= true;
    wait;
  end process estimulos;

end architecture behavioral;