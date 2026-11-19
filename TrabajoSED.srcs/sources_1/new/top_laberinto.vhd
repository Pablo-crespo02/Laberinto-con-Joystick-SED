--Instanciacióin de los módulos (prueba de los módulos básicos).
-- LED(0): cambia cada segundo -> prescaler 1 Hz
-- LED(1): BTNC filtrado (nivel) -> sincronizador + antirrebote
-- LED(2): cambia en cada pulsación -> detector_flanco
-- CPU_RESETN reinicia todo (LED(0) y LED(2) se apagan).
library ieee;
use ieee.std_logic_1164.all;

entity top_laberinto is
  generic (
    DIV_1KHZ   : positive := 100_000;      -- 100 MHz / 100 000     = 1 kHz
    DIV_1HZ    : positive := 100_000_000;  -- 100 MHz / 100 000 000 = 1 Hz
    ESTABLE_MS : positive := 20            -- tiempo de antirrebote en ticks de 1 ms
  );
  port (
    CLK100MHZ  : in  std_logic;
    CPU_RESETN : in  std_logic;                     -- activo a nivel bajo
    BTNC       : in  std_logic;                     -- START
    LED        : out std_logic_vector(2 downto 0)
  );
end entity top_laberinto;

architecture estructural of top_laberinto is

  -- Cables internos entre módulos
  signal s_reset_n_sync : std_logic;
  signal s_reset        : std_logic;
  signal s_tick_1khz    : std_logic;
  signal s_tick_1hz     : std_logic;
  signal s_btnc_sync    : std_logic;
  signal s_btnc_filt    : std_logic;
  signal s_start_p      : std_logic;

  -- Solo para v0.1
  signal s_led_1hz    : std_logic := '0';
  signal s_led_toggle : std_logic := '0';

begin

-- Reset: CPU_RESETN se sincroniza y se invierte

  u_sync_reset : entity work.sincronizador
    port map (
      clk      => CLK100MHZ,
      reset    => '0',              -- no se resetea el sincro
      async_in => CPU_RESETN,
      sync_out => s_reset_n_sync
    );

  s_reset <= not s_reset_n_sync;

-- Bases de tiempo

  u_presc_1khz : entity work.prescaler
    generic map (DIVISOR => DIV_1KHZ)
    port map (clk => CLK100MHZ, reset => s_reset, tick => s_tick_1khz);

  u_presc_1hz : entity work.prescaler
    generic map (DIVISOR => DIV_1HZ)
    port map (clk => CLK100MHZ, reset => s_reset, tick => s_tick_1hz);

-- Cadena de entrada de START: sincronizar -> filtrar -> detectar flanco
 
  u_sync_btnc : entity work.sincronizador
    port map (clk => CLK100MHZ, reset => s_reset, async_in => BTNC, sync_out => s_btnc_sync);

  u_debo_btnc : entity work.antirrebote
    generic map (ESTABLE_MS => ESTABLE_MS)
    port map (
      clk     => CLK100MHZ,
      reset   => s_reset,
      tick    => s_tick_1khz,
      entrada => s_btnc_sync,
      salida  => s_btnc_filt
    );

  u_flanco_btnc : entity work.detector_flanco
    port map (clk => CLK100MHZ, reset => s_reset, entrada => s_btnc_filt, pulso => s_start_p);
    
    -- Lógica de prueba v0.1 
  prueba : process (CLK100MHZ)
  begin
    if rising_edge(CLK100MHZ) then
      if s_reset = '1' then
        s_led_1hz    <= '0';
        s_led_toggle <= '0';
      else
        if s_tick_1hz = '1' then
          s_led_1hz <= not s_led_1hz;
        end if;
        if s_start_p = '1' then
          s_led_toggle <= not s_led_toggle;
        end if;
      end if;
    end if;
  end process prueba;

  LED(0) <= s_led_1hz;
  LED(1) <= s_btnc_filt;
  LED(2) <= s_led_toggle;

end architecture estructural;