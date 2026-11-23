-- 1) el periodo es exactamente PERIODO ciclos
-- 2) el ancho del pulso es PULSO_MIN + pos*PASO para pos = 0, 128 y 255
-- 3) si pos cambia a mitad de un pulso, ese pulso no se altera
-- (el cambio se aplica en el periodo siguiente)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity servo_pwm_tb is
end entity servo_pwm_tb;

architecture behavioral of servo_pwm_tb is

  constant T_CLK     : time     := 10 ns;
  constant PERIODO   : positive := 600; -- periodo de 600 ciclos
  constant PULSO_MIN : positive := 100; -- pulso de 100 a 355
  constant PASO      : positive := 1;

  signal clk     : std_logic := '0';
  signal reset   : std_logic := '1';
  signal pos     : unsigned(7 downto 0) := (others => '0');
  signal pwm_out : std_logic;
  signal fin_sim : boolean := false;

  -- Ancho esperado en tiempo para una posición
  function ancho_esperado (p : natural) return time is
  begin
    return (PULSO_MIN + p * PASO) * T_CLK;
  end function;

begin

  uut : entity work.servo_pwm
    generic map (PERIODO => PERIODO, PULSO_MIN => PULSO_MIN, PASO => PASO)
    port map (clk => clk, reset => reset, pos => pos, pwm_out => pwm_out);

  clk <= not clk after T_CLK / 2 when not fin_sim;

  estimulos : process
    variable t_subida, t_bajada, t_subida_ant : time;

    -- Mide un pulso completo: espera a la subida y a la bajada
    procedure medir_pulso is
    begin
      wait until rising_edge(pwm_out);
      t_subida_ant := t_subida;
      t_subida     := now;
      wait until falling_edge(pwm_out);
      t_bajada     := now;
    end procedure;

    -- Posición y comprueba el ancho del pulso del periodo siguiente
    procedure probar_posicion (p : natural) is
    begin
      pos <= to_unsigned(p, 8);
      medir_pulso;   -- este pulso puede ser del valor anterior (no vale)
      medir_pulso;   -- este ya usa la nueva posición
      assert t_bajada - t_subida = ancho_esperado(p)
        report "ERROR: pos = " & integer'image(p) & ", ancho " &
               time'image(t_bajada - t_subida) & ", esperado " &
               time'image(ancho_esperado(p))
        severity error;
    end procedure;

  begin
    wait for 3 * T_CLK;
    reset <= '0';

    -- 1) Periodo (distancia entre dos subidas seguidas)
    medir_pulso;
    medir_pulso;
    assert t_subida - t_subida_ant = PERIODO * T_CLK
      report "ERROR: periodo " & time'image(t_subida - t_subida_ant) &
             ", esperado " & time'image(PERIODO * T_CLK)
      severity error;

    -- 2) Anchos para max, mitad y min.
    probar_posicion(0);
    probar_posicion(128);
    probar_posicion(255);

    -- 3) Cambio de pos a mitad de un pulso (mantiene su ancho)
    pos <= to_unsigned(0, 8);
    medir_pulso;                        -- periodo completos con pos = 0
    wait until rising_edge(pwm_out);
    t_subida := now;
    wait for 50 * T_CLK;                -- a mitad de pulso (50 ciclos de 100)
    pos <= to_unsigned(255, 8);         -- MAX
    wait until falling_edge(pwm_out);
    assert now - t_subida = ancho_esperado(0)
      report "ERROR: el pulso en curso ha cambiado al cambiar pos: " &
             time'image(now - t_subida)
      severity error;
    medir_pulso;                        -- el siguiente ha de ser MAX
    assert t_bajada - t_subida = ancho_esperado(255)
      report "ERROR: el periodo siguiente no aplica la nueva posición" severity error;

    report "servo_pwm_tb: FIN DE SIMULACION" severity note;
    fin_sim <= true;
    wait;
  end process estimulos;

end architecture behavioral;