library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity display_controller is
    Port (
        clk           : in  std_logic;
        reset         : in  std_logic;
        enable        : in  std_logic;  -- NUEVA SEÑAL

        high_score    : in  unsigned(6 downto 0); -- 0 a 99
        current_score : in  unsigned(6 downto 0); -- 0 a 99

        an            : out std_logic_vector(3 downto 0);
        seg           : out std_logic_vector(0 to 7)
    );
end display_controller;

architecture Behavioral of display_controller is

    -- contador para multiplexing
    signal refresh_counter : unsigned(15 downto 0) := (others => '0');
    signal digit_select    : unsigned(1 downto 0);

    -- dígitos individuales
    signal hs_tens : integer range 0 to 9;
    signal hs_ones : integer range 0 to 9;
    signal cs_tens : integer range 0 to 9;
    signal cs_ones : integer range 0 to 9;

    -- dígito actualmente mostrado
    signal current_digit : integer range 0 to 9;

begin

    ----------------------------------------------------------------
    -- Separar high_score y current_score en decenas y unidades
    ----------------------------------------------------------------
    hs_tens <= to_integer(high_score) / 10;
    hs_ones <= to_integer(high_score) mod 10;

    cs_tens <= to_integer(current_score) / 10;
    cs_ones <= to_integer(current_score) mod 10;

    ----------------------------------------------------------------
    -- Contador de refresco
    ----------------------------------------------------------------
    process(clk, reset)
    begin
        if reset = '1' then
            refresh_counter <= (others => '0');
        elsif rising_edge(clk) then
            refresh_counter <= refresh_counter + 1;
        end if;
    end process;

    digit_select <= refresh_counter(15 downto 14);

    ----------------------------------------------------------------
    -- Multiplexing
    ----------------------------------------------------------------
    process(digit_select, hs_tens, hs_ones, cs_tens, cs_ones, enable)
    begin

        -- Si enable = 0 apagamos el display
        if enable = '0' then
            an <= "1111";
            current_digit <= 0;

        else
            case digit_select is

                when "00" =>
                    an <= "1110";          -- display 0 activo
                    current_digit <= cs_ones;

                when "01" =>
                    an <= "1101";          -- display 1 activo
                    current_digit <= cs_tens;

                when "10" =>
                    an <= "1011";          -- display 2 activo
                    current_digit <= hs_ones;

                when others =>
                    an <= "0111";          -- display 3 activo
                    current_digit <= hs_tens;

            end case;
        end if;

    end process;

    ----------------------------------------------------------------
    -- Decoder: número a 7 segmentos
    -- seg = abcdefgp, active-low
    ----------------------------------------------------------------
    process(current_digit, enable)
    begin

        if enable = '0' then
            seg <= "11111111"; -- display apagado

        else
            case current_digit is
                when 0 => seg <= "00000011";
                when 1 => seg <= "10011111";
                when 2 => seg <= "00100101";
                when 3 => seg <= "00001101";
                when 4 => seg <= "10011001";
                when 5 => seg <= "01001001";
                when 6 => seg <= "01000001";
                when 7 => seg <= "00011111";
                when 8 => seg <= "00000001";
                when 9 => seg <= "00001001";
                when others => seg <= "11111111";
            end case;
        end if;

    end process;

end Behavioral;