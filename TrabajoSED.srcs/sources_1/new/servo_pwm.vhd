library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity servo_pwm is
  generic (
    PERIODO   : positive := 2_000_000;  -- ciclos de clk (2ms) en sumas de 10 ns
    PULSO_MIN : positive := 100_000;    -- ancho con pos = 0
    PASO      : positive := 392         -- ciclos que añade cada unidad de pos
  );
  port (
    clk     : in  std_logic;
    reset   : in  std_logic;
    pos     : in  unsigned(7 downto 0); -- 0 = 1 ms ... 255 ~ 2 ms (8bits)
    pwm_out : out std_logic
  );
end entity servo_pwm;

architecture behavioral of servo_pwm is
  signal s_cuenta : natural range 0 to PERIODO - 1 := 0; -- 21 bits
  signal s_ancho  : natural range 0 to PULSO_MIN + 255 * PASO := PULSO_MIN; -- 18 bits
  signal s_pwm    : std_logic := '0';
begin

  process (clk)
  begin
    if rising_edge(clk) then
      if reset = '1' then
        s_cuenta <= 0;
        s_ancho  <= PULSO_MIN;
        s_pwm    <= '0';
      else
        -- Contador del periodo: desde 0 a PERIODO-1
        if s_cuenta = PERIODO - 1 then
          s_cuenta <= 0;
          s_ancho  <= PULSO_MIN + to_integer(pos) * PASO;  -- ANCHO
        else
          s_cuenta <= s_cuenta + 1;
        end if;

        -- Comparador: salida a 1 mientras la cuenta sea menor que el ancho
        if s_cuenta < s_ancho then
          s_pwm <= '1';
        else
          s_pwm <= '0';
        end if;
      end if;
    end if;
  end process;

  pwm_out <= s_pwm;

end architecture behavioral;