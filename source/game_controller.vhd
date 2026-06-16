library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Game_Controller is
    Port(
        clk                 : in  std_logic;
        tick_show           : in  std_logic;
        WDT_16s             : in  std_logic;
        WDT_LEDs            : in  std_logic_vector(15 downto 0);
        stable_clear_switch : in  std_logic;
        stable_start_key    : in  std_logic;
        stable_buttons_rgyb : in  std_logic_vector(3 downto 0);
        any_key_pressed     : in  std_logic;
        any_game_key        : in  std_logic;
        rand_value          : in  std_logic_vector(3 downto 0);
        diff_sw0            : in  std_logic;
        diff_sw1            : in  std_logic;
        high_score_out      : out unsigned(6 downto 0);
        current_score_out   : out unsigned(6 downto 0);
        get_new_rand        : out std_logic;
        display_enable      : out std_logic;
        leds                : out std_logic_vector(15 downto 0);
        reset               : out std_logic;
        buzzer_enable       : out std_logic;
        buzzer_tone         : out std_logic_vector(2 downto 0)
    );
end Game_Controller;

architecture Behavioral of Game_Controller is

    type STATE is (INIT_ST, ON_ST, SLEEP_ST, CLEAR_ST, PLAY_ST);
    type PLAY_PHASE_TYPE is (
        LOAD_NEW_STEP, SHOW_SEQ_ON, SHOW_SEQ_OFF,
        WAIT_INPUT, LAST_INPUT_HOLD, CHECK_END, GAME_OVER
    );
    type seq_array is array (0 to 6) of std_logic_vector(3 downto 0);

    signal current_state, next_state : STATE := INIT_ST;
    signal play_phase                : PLAY_PHASE_TYPE := LOAD_NEW_STEP;
    signal game_sequence             : seq_array := (others => (others => '0'));

    signal current_score  : integer range 0 to 99 := 0;
    signal current_level  : integer range 0 to 6  := 0;
    signal high_score     : integer range 0 to 99 := 0;
    signal show_index     : integer range 0 to 6  := 0;
    signal input_index    : integer range 0 to 6  := 0;

    signal get_new_rand_reg    : std_logic := '0';
    signal leds_reg            : std_logic_vector(15 downto 0) := (others => '0');
    signal reset_reg           : std_logic := '0';
    signal display_enable_reg  : std_logic := '0';

    -- FIX 1 & 2: internal registers for buzzer outputs (were driven
    --            directly on port signals, causing multiple-driver errors)
    signal buzzer_enable_reg   : std_logic := '0';
    signal buzzer_tone_reg     : std_logic_vector(2 downto 0) := (others => '0');

    signal prev_buttons_rgyb   : std_logic_vector(3 downto 0) := (others => '0');
    signal button_event        : std_logic := '0';
    signal prev_start_key      : std_logic := '0';
    signal start_event         : std_logic := '0';
    signal prev_clear_switch   : std_logic := '0';
    signal clear_fall_event    : std_logic := '0';

    signal difficulty_sel_reg  : std_logic_vector(1 downto 0) := "00";
    signal speed_count         : integer range 0 to 3 := 0;
    signal game_tick           : std_logic := '0';

    function color_to_leds(color : std_logic_vector(3 downto 0))
        return std_logic_vector is
        variable result : std_logic_vector(15 downto 0);
    begin
        result := (others => '0');
        case color is
            when "0001" => result := "1111000000000000"; -- RED
            when "0010" => result := "0000111100000000"; -- GREEN
            when "0100" => result := "0000000011110000"; -- YELLOW
            when "1000" => result := "0000000000001111"; -- BLUE
            when others => result := (others => '0');
        end case;
        return result;
    end function;

    function color_to_tone(color : std_logic_vector(3 downto 0))
        return std_logic_vector is
        variable result : std_logic_vector(2 downto 0);
    begin
        result := (others => '0');
        case color is
            when "1000" => result := "000"; -- red
            when "0100" => result := "001"; -- green
            when "0010" => result := "010"; -- yellow
            when "0001" => result := "011"; -- blue
            when others => result := (others => '0');
        end case;
        return result;
    end function;

begin

    -- FIX 1 & 2: route internal registers to ports
    buzzer_enable     <= buzzer_enable_reg;
    buzzer_tone       <= buzzer_tone_reg;

    high_score_out    <= to_unsigned(high_score, 7);
    current_score_out <= to_unsigned(current_score, 7);
    get_new_rand      <= get_new_rand_reg;
    leds              <= leds_reg;
    reset             <= reset_reg;
    display_enable    <= display_enable_reg;

    ----------------------------------------------------------------
    -- Edge detectors
    ----------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            button_event <= '0';
            if (stable_buttons_rgyb /= "0000") and (prev_buttons_rgyb = "0000") then
                button_event <= '1';
            end if;
            prev_buttons_rgyb <= stable_buttons_rgyb;

            start_event <= '0';
            if (stable_start_key = '1') and (prev_start_key = '0') then
                start_event <= '1';
            end if;
            prev_start_key <= stable_start_key;

            clear_fall_event <= '0';
            if (stable_clear_switch = '0') and (prev_clear_switch = '1') then
                clear_fall_event <= '1';
            end if;
            prev_clear_switch <= stable_clear_switch;
        end if;
    end process;

    ----------------------------------------------------------------
    -- Difficulty latch
    ----------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            if current_state = INIT_ST then
                difficulty_sel_reg <= "00";
            elsif (current_state = ON_ST) and (start_event = '1') then
                difficulty_sel_reg <= diff_sw1 & diff_sw0;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------
    -- Game tick generator
    ----------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then
            game_tick <= '0';
            if current_state /= PLAY_ST then
                speed_count <= 0;
            elsif tick_show = '1' then
                case difficulty_sel_reg is
                    when "00" =>
                        if speed_count = 3 then speed_count <= 0; game_tick <= '1';
                        else speed_count <= speed_count + 1; end if;
                    when "01" =>
                        if speed_count = 2 then speed_count <= 0; game_tick <= '1';
                        else speed_count <= speed_count + 1; end if;
                    when "10" =>
                        if speed_count = 1 then speed_count <= 0; game_tick <= '1';
                        else speed_count <= speed_count + 1; end if;
                    when others =>
                        speed_count <= 0; game_tick <= '1';
                end case;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------
    -- Sequential state + datapath
    ----------------------------------------------------------------
    process(clk)
    begin
        if rising_edge(clk) then

            current_state      <= next_state;
            get_new_rand_reg   <= '0';
            reset_reg          <= '0';
            display_enable_reg <= '0';

            case current_state is

                when INIT_ST =>
                    leds_reg           <= (others => '0');
                    buzzer_enable_reg  <= '0';          -- FIX 1
                    buzzer_tone_reg    <= (others => '0'); -- FIX 2
                    reset_reg          <= '1';
                    current_score      <= 0;
                    high_score         <= 0;
                    current_level      <= 0;
                    show_index         <= 0;
                    input_index        <= 0;
                    game_sequence      <= (others => (others => '0'));
                    play_phase         <= LOAD_NEW_STEP;

                when ON_ST =>
                    leds_reg           <= WDT_LEDs;
                    display_enable_reg <= '1';
                    buzzer_enable_reg  <= '0';          -- FIX 3: silence on idle
                    -- FIX 6: reset play_phase here so re-entry is always clean
                    play_phase         <= LOAD_NEW_STEP;

                when SLEEP_ST =>
                    leds_reg           <= (others => '0');
                    buzzer_enable_reg  <= '0';

                when CLEAR_ST =>
                    display_enable_reg <= '1';
                    leds_reg           <= WDT_LEDs;
                    buzzer_enable_reg  <= '0';
                    if clear_fall_event = '1' then
                        current_score  <= 0;
                        high_score     <= 0;
                        current_level  <= 0;
                        show_index     <= 0;
                        input_index    <= 0;
                        game_sequence  <= (others => (others => '0'));
                        play_phase     <= LOAD_NEW_STEP;
                    end if;

                when PLAY_ST =>
                    display_enable_reg <= '1';

                    case play_phase is

                        when LOAD_NEW_STEP =>
                            buzzer_enable_reg              <= '0';
                            get_new_rand_reg               <= '1';
                            game_sequence(current_level)   <= rand_value;
                            show_index                     <= 0;
                            input_index                    <= 0;
                            leds_reg                       <= (others => '0');
                            play_phase                     <= SHOW_SEQ_ON;

                        when SHOW_SEQ_ON =>
                            if game_tick = '1' then
                                leds_reg          <= color_to_leds(game_sequence(show_index));
                                buzzer_enable_reg <= '1';
                                buzzer_tone_reg   <= color_to_tone(game_sequence(show_index));
                                play_phase        <= SHOW_SEQ_OFF;
                            end if;

                        when SHOW_SEQ_OFF =>
                            if game_tick = '1' then
                                leds_reg          <= (others => '0');
                                buzzer_enable_reg <= '0';
                                if show_index < current_level then
                                    show_index <= show_index + 1;
                                    play_phase <= SHOW_SEQ_ON;
                                else
                                    input_index <= 0;
                                    play_phase  <= WAIT_INPUT;
                                end if;
                            end if;

                        when WAIT_INPUT =>
                            -- FIX 4: only drive LEDs/buzzer while a button is held
                            if stable_buttons_rgyb /= "0000" then
                                leds_reg          <= color_to_leds(stable_buttons_rgyb);
                                buzzer_enable_reg <= '1';
                                buzzer_tone_reg   <= color_to_tone(stable_buttons_rgyb);
                            else
                                leds_reg          <= (others => '0');
                                buzzer_enable_reg <= '0';
                            end if;

                            if button_event = '1' then
                                if stable_buttons_rgyb = game_sequence(input_index) then
                                    if input_index < current_level then
                                        input_index <= input_index + 1;
                                    else
                                        play_phase <= LAST_INPUT_HOLD;
                                    end if;
                                else
                                    play_phase <= GAME_OVER;
                                end if;
                            end if;

                        when LAST_INPUT_HOLD =>
                            if game_tick = '1' then
                                play_phase <= CHECK_END;
                            end if;

                        when CHECK_END =>
                            leds_reg      <= (others => '0');
                            buzzer_enable_reg <= '0';
                            current_score <= current_level + 1;
                            if (current_level + 1) > high_score then
                                high_score <= current_level + 1;
                            end if;
                            if current_level < 6 then
                                current_level <= current_level + 1;
                                play_phase    <= LOAD_NEW_STEP;
                            else
                                current_level <= 0;
                                current_score <= 0;
                                play_phase    <= LOAD_NEW_STEP;
                            end if;

                        when GAME_OVER =>
                            -- FIX 3 & 5: buzzer on for exactly one game_tick,
                            --            then next_state logic moves to ON_ST
                            leds_reg          <= (others => '1');
                            buzzer_enable_reg <= '1';
                            buzzer_tone_reg   <= "100";
                            current_level     <= 0;
                            current_score     <= 0;
                            show_index        <= 0;
                            input_index       <= 0;
                            -- stay in GAME_OVER; next_state process handles exit

                    end case;
            end case;
        end if;
    end process;

    ----------------------------------------------------------------
    -- Next-state logic
    ----------------------------------------------------------------
    process(current_state, stable_clear_switch, start_event,
            any_key_pressed, WDT_16s, play_phase, clear_fall_event)
    begin
        next_state <= current_state;
        case current_state is

            when INIT_ST =>
                next_state <= ON_ST;

            when ON_ST =>
                if stable_clear_switch = '1' then
                    next_state <= CLEAR_ST;
                elsif start_event = '1' then
                    next_state <= PLAY_ST;
                elsif WDT_16s = '1' then
                    next_state <= SLEEP_ST;
                end if;

            when SLEEP_ST =>
                if any_key_pressed = '1' then
                    next_state <= ON_ST;
                end if;

            when CLEAR_ST =>
                if WDT_16s = '1' or clear_fall_event = '1' then
                    next_state <= ON_ST;
                end if;

            when PLAY_ST =>
                -- FIX 5: exit on GAME_OVER phase after the buzzer has fired once
                if WDT_16s = '1' or play_phase = GAME_OVER then
                    next_state <= ON_ST;
                end if;

        end case;
    end process;

end Behavioral;