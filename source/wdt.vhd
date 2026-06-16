library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity WDT_16s is
    Port ( 
        clk            : in std_logic;
        reset          : in std_logic;
        any_key_pressed: in std_logic;

        wdt_16s        : out std_logic;
        wdt_led_out    : out std_logic_vector(15 downto 0)
    );
end WDT_16s;

architecture Behavioral of WDT_16s is

    -- clock divider → 1ms
    signal clk_cnt : unsigned(16 downto 0) := (others => '0');

    signal tick_1ms : std_logic := '0';

    -- contador milisegundos
    signal ms_cnt : unsigned(9 downto 0) := (others => '0');

    -- contador segundos
    signal sec_cnt : unsigned(4 downto 0) := (others => '0');

begin


------------------------------------------------
-- GENERADOR DE 1ms
------------------------------------------------
process(clk)
begin
    if rising_edge(clk) then

        if reset = '1' then
            clk_cnt  <= (others => '0');
            tick_1ms <= '0';

        elsif clk_cnt = 99999 then
            clk_cnt  <= (others => '0');
            tick_1ms <= '1';

        else
            clk_cnt  <= clk_cnt + 1;
            tick_1ms <= '0';
        end if;

    end if;
end process;


------------------------------------------------
-- CONTADOR DE SEGUNDOS
------------------------------------------------
process(clk)
begin
    if rising_edge(clk) then

        if reset = '1' or any_key_pressed = '1' then

            ms_cnt  <= (others => '0');
            sec_cnt <= (others => '0');

        elsif tick_1ms = '1' then

            if ms_cnt = 999 then
                ms_cnt <= (others => '0');

                if sec_cnt < 16 then
                    sec_cnt <= sec_cnt + 1;
                end if;

            else
                ms_cnt <= ms_cnt + 1;
            end if;

        end if;

    end if;
end process;


------------------------------------------------
-- TIMEOUT
------------------------------------------------
wdt_16s <= '1' when sec_cnt = 16 else '0';


------------------------------------------------
-- LED PROGRESS BAR
------------------------------------------------
process(sec_cnt)
    variable led_pattern : std_logic_vector(15 downto 0);
begin

    led_pattern := (others => '1');

    for i in 0 to 15 loop
        if i < to_integer(sec_cnt) then
            led_pattern(15 - i) := '0';
        end if;
    end loop;

    wdt_led_out <= led_pattern;

end process;


end Behavioral;