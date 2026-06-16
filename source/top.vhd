library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Top_Game is
    Port(
        clk           : in  std_logic;

        clear_switch  : in  std_logic;
        start_button  : in  std_logic;
        buttons_rgyb  : in  std_logic_vector(3 downto 0);
        switch0       : in std_logic;
        switch1       : in std_logic;

        leds          : out std_logic_vector(15 downto 0);
        an            : out std_logic_vector(3 downto 0);
        seg           : out std_logic_vector(0 to 7);
        buzzer_out    : out std_logic
    );
end Top_Game;

architecture Behavioral of Top_Game is

    ----------------------------------------------------------------
    -- Señales internas: Key Manager
    ----------------------------------------------------------------
    signal stable_clear_switch_s : std_logic;
    signal stable_start_key_s    : std_logic;
    signal stable_buttons_rgyb_s : std_logic_vector(3 downto 0);
    signal any_key_pressed_s     : std_logic;
    signal any_game_key_s        : std_logic;

    ----------------------------------------------------------------
    -- Señales internas: WDT
    ----------------------------------------------------------------
    signal reset_s               : std_logic;
    signal wdt_16s_s             : std_logic;
    signal wdt_leds_s            : std_logic_vector(15 downto 0);

    ----------------------------------------------------------------
    -- Señales internas: Random
    ----------------------------------------------------------------
    signal rand_value_s          : std_logic_vector(3 downto 0);
    signal get_new_rand_s        : std_logic;

    ----------------------------------------------------------------
    -- Señales internas: Game Controller
    ----------------------------------------------------------------
    signal high_score_s          : unsigned(6 downto 0);
    signal current_score_s       : unsigned(6 downto 0);
    signal leds_s                : std_logic_vector(15 downto 0);
    signal enable_display_s       : std_logic;

    ----------------------------------------------------------------
    -- Señal interna: tick_show
    ----------------------------------------------------------------
    signal tick_show_s           : std_logic := '0';
    signal show_counter          : unsigned(24 downto 0) := (others => '0');
    constant SHOW_MAX_COUNT      : unsigned(24 downto 0) := to_unsigned(25000000 - 1, 25);
    
    --------
    --senales buzzer
    ----------
    signal enable_cable :std_logic := '0';
    signal tone_cable    : std_logic_vector (2 downto 0);

begin

    ----------------------------------------------------------------
    -- Salida final de LEDs
    ----------------------------------------------------------------
    leds <= leds_s;

    ----------------------------------------------------------------
    -- Generador de tick_show
    ----------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if show_counter = SHOW_MAX_COUNT then
                show_counter <= (others => '0');
                tick_show_s  <= '1';
            else
                show_counter <= show_counter + 1;
                tick_show_s  <= '0';
            end if;
        end if;
    end process;

    ----------------------------------------------------------------
    -- Instancia: Key Manager
    ----------------------------------------------------------------
    U_KEY_MANAGER : entity work.Key_Manager
        port map(
            clk                 => clk,
            clear_switch        => clear_switch,
            start_button        => start_button,
            buttons_rgyb        => buttons_rgyb,

            stable_clear_switch => stable_clear_switch_s,
            stable_start_key    => stable_start_key_s,
            stable_buttons_rgyb => stable_buttons_rgyb_s,
            any_key_pressed     => any_key_pressed_s,
            any_game_key        => any_game_key_s
        );

    ----------------------------------------------------------------
    -- Instancia: WDT_16s
    ----------------------------------------------------------------
    U_WDT : entity work.WDT_16s
        port map(
            clk             => clk,
            reset           => reset_s,
            any_key_pressed => any_game_key_s,
            wdt_16s         => wdt_16s_s,
            wdt_led_out        => wdt_leds_s
        );

    ----------------------------------------------------------------
    -- Instancia: Random_3_0
    ----------------------------------------------------------------
    U_RANDOM : entity work.Random_3_0
        port map(
            clk           => clk,
            reset         => stable_clear_switch_s,
            next_rand     => get_new_rand_s,
            rand_num_rgyb => rand_value_s
        );

    ----------------------------------------------------------------
    -- Instancia: Game_Controller
    ----------------------------------------------------------------
    U_GAME_CONTROLLER : entity work.Game_Controller
        port map(
            clk                 => clk,
            tick_show           => tick_show_s,

            WDT_16s             => wdt_16s_s,
            WDT_LEDs            => wdt_leds_s,
            
            diff_sw0            => switch0,
            diff_sw1            => switch1,

            stable_clear_switch => stable_clear_switch_s,
            stable_start_key    => stable_start_key_s,
            stable_buttons_rgyb => stable_buttons_rgyb_s,
            any_key_pressed     => any_key_pressed_s,
            any_game_key        => any_game_key_s,
            rand_value          => rand_value_s,

            high_score_out      => high_score_s,
            current_score_out   => current_score_s,
            get_new_rand        => get_new_rand_s,
            display_enable      => enable_display_s,
            leds                => leds_s,
            buzzer_enable       => enable_cable,
            buzzer_tone     => tone_cable,
            reset               => reset_s
        );

    ----------------------------------------------------------------
    -- Instancia: Display Controller
    ----------------------------------------------------------------
    U_DISPLAY : entity work.display_controller
        port map(
            clk           => clk,
            reset         => stable_clear_switch_s,
            high_score    => high_score_s,
            current_score => current_score_s,
            an            => an,
            seg           => seg,
            enable        => enable_display_s
        );
        
     buzzer : entity work.buzzer
        port map (
            clk => clk,
            enable => enable_cable,
            tone => tone_cable,
            buzzer_out => buzzer_out
        
        
        );

end Behavioral;