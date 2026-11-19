library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Si la entrada vuelve al valor de la salida la cuenta se reinicia
-- tick = tick_1kHz (Transforma ESTABLE_MS en milisegundos).
entity antirrebote is
generic(
ESTABLE_MS : positive := 20 --Ticks seguidos en los que se mantiene estable la entrada
);
port(
clk : in std_logic;
reset : in std_logic;
--tick funcionara como entrada más adelante conectada al prescaler de 1kHZ
tick : in std_logic; -- muestreo de un ciclo de pulso
entrada : in std_logic;
salida : out std_logic
);
end antirrebote;

architecture Behavioral of antirrebote is
signal s_salida : std_logic := '0';-- Señal interna para leer la salida
-- "range" da información de los bits que necesita (5 en este caso)
signal s_cuenta : natural range 0 to ESTABLE_MS := 0; 
begin
process(clk)
begin
if rising_edge(clk) then
      if reset = '1' then --Pone ambos a cero
        s_salida <= '0';
        s_cuenta <= 0;
      elsif entrada = s_salida then
        s_cuenta <= 0;                    -- si la entrada = salida (reset)
      elsif tick = '1' then -- tick vale 1 cada 100_000 (cuenta ms sin un reloj nuevo) "enable"
        if s_cuenta = ESTABLE_MS - 1 then
          s_salida <= entrada;            -- cambio estable
          s_cuenta <= 0;
        else
          s_cuenta <= s_cuenta + 1; -- No ha llegado (sumo 1)
        end if;
      end if;
    end if;
  end process;

  salida <= s_salida; --salida es out (no se puede leer) le asignamos la señal

end Behavioral;
