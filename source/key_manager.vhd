library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Key_Manager is
    Port (
        clk : in std_logic;

        clear_switch : in std_logic;
        start_button : in std_logic;
        buttons_rgyb : in std_logic_vector(3 downto 0);

        stable_clear_switch : out std_logic;
        stable_start_key : out std_logic;
        stable_buttons_rgyb : out std_logic_vector(3 downto 0);
        any_key_pressed : out std_logic;
        any_game_key    : out std_logic
    );
end Key_Manager;

architecture Behavioral of Key_Manager is

    ------------------------------------------------
    -- TICK 5ms GENERATOR
    -- Basys3 clk = 100 MHz
    -- 5 ms = 500,000 ciclos
    ------------------------------------------------
    signal tick_counter : unsigned(18 downto 0) := (others => '0');
    signal tick_5ms     : std_logic := '0';

    ------------------------------------------------
    -- MUESTRAS PREVIAS
    ------------------------------------------------
    signal clear_sample   : std_logic := '0';
    signal start_sample   : std_logic := '0';
    signal buttons_sample : std_logic_vector(3 downto 0) := (others => '0');

    ------------------------------------------------
    -- SALIDAS INTERNAS ESTABLES
    ------------------------------------------------
    signal clear_stable_i   : std_logic := '0';
    signal start_stable_i   : std_logic := '0';
    signal buttons_stable_i : std_logic_vector(3 downto 0) := (others => '0');

    ------------------------------------------------
    -- CONTADORES DE DEBOUNCE
    -- 4 muestras iguales * 5ms = 20ms
    ------------------------------------------------
    signal clear_cnt  : unsigned(1 downto 0) := (others => '0');
    signal start_cnt  : unsigned(1 downto 0) := (others => '0');
    signal red_cnt    : unsigned(1 downto 0) := (others => '0');
    signal green_cnt  : unsigned(1 downto 0) := (others => '0');
    signal yellow_cnt : unsigned(1 downto 0) := (others => '0');
    signal blue_cnt   : unsigned(1 downto 0) := (others => '0');

begin

    ------------------------------------------------
    -- PROCESO 1: GENERAR tick_5ms
    ------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if tick_counter = 499999 then
                tick_counter <= (others => '0');
                tick_5ms <= '1';
            else
                tick_counter <= tick_counter + 1;
                tick_5ms <= '0';
            end if;
        end if;
    end process;

    ------------------------------------------------
    -- PROCESO 2: DEBOUNCING
    ------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if tick_5ms = '1' then

                ----------------------------------------
                -- CLEAR SWITCH
                ----------------------------------------
                if clear_switch = clear_sample then
                    if clear_cnt < "11" then
                        clear_cnt <= clear_cnt + 1;
                    end if;
                else
                    clear_cnt <= (others => '0');
                end if;

                if clear_cnt = "11" then
                    clear_stable_i <= clear_switch;
                end if;

                clear_sample <= clear_switch;

                ----------------------------------------
                -- START BUTTON
                ----------------------------------------
                if start_button = start_sample then
                    if start_cnt < "11" then
                        start_cnt <= start_cnt + 1;
                    end if;
                else
                    start_cnt <= (others => '0');
                end if;

                if start_cnt = "11" then
                    start_stable_i <= start_button;
                end if;

                start_sample <= start_button;

                ----------------------------------------
                -- RED BUTTON = buttons_rgyb(3)
                ----------------------------------------
                if buttons_rgyb(3) = buttons_sample(3) then
                    if red_cnt < "11" then
                        red_cnt <= red_cnt + 1;
                    end if;
                else
                    red_cnt <= (others => '0');
                end if;

                if red_cnt = "11" then
                    buttons_stable_i(3) <= buttons_rgyb(3);
                end if;

                ----------------------------------------
                -- GREEN BUTTON = buttons_rgyb(2)
                ----------------------------------------
                if buttons_rgyb(2) = buttons_sample(2) then
                    if green_cnt < "11" then
                        green_cnt <= green_cnt + 1;
                    end if;
                else
                    green_cnt <= (others => '0');
                end if;

                if green_cnt = "11" then
                    buttons_stable_i(2) <= buttons_rgyb(2);
                end if;

                ----------------------------------------
                -- YELLOW BUTTON = buttons_rgyb(1)
                ----------------------------------------
                if buttons_rgyb(1) = buttons_sample(1) then
                    if yellow_cnt < "11" then
                        yellow_cnt <= yellow_cnt + 1;
                    end if;
                else
                    yellow_cnt <= (others => '0');
                end if;

                if yellow_cnt = "11" then
                    buttons_stable_i(1) <= buttons_rgyb(1);
                end if;

                ----------------------------------------
                -- BLUE BUTTON = buttons_rgyb(0)
                ----------------------------------------
                if buttons_rgyb(0) = buttons_sample(0) then
                    if blue_cnt < "11" then
                        blue_cnt <= blue_cnt + 1;
                    end if;
                else
                    blue_cnt <= (others => '0');
                end if;

                if blue_cnt = "11" then
                    buttons_stable_i(0) <= buttons_rgyb(0);
                end if;

                buttons_sample <= buttons_rgyb;

            end if;
        end if;
    end process;

    ------------------------------------------------
    -- SALIDAS
    ------------------------------------------------
    stable_clear_switch <= clear_stable_i;
    stable_start_key <= start_stable_i;
    stable_buttons_rgyb <= buttons_stable_i;
    any_key_pressed <= clear_stable_i or start_stable_i or
                       buttons_stable_i(3) or
                       buttons_stable_i(2) or
                       buttons_stable_i(1) or
                       buttons_stable_i(0);
                       
   any_game_key <= buttons_stable_i(3) or
                       buttons_stable_i(2) or
                       buttons_stable_i(1) or
                       buttons_stable_i(0);
end Behavioral;