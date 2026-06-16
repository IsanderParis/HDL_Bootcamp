library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Random_3_0 is
    Port (
        clk           : in  std_logic;
        reset         : in  std_logic;
        next_rand     : in  std_logic;
        rand_num_rgyb : out std_logic_vector(3 downto 0)
    );
end Random_3_0;

architecture Behavioral of Random_3_0 is

    -- LFSR corriendo continuamente
    signal lfsr        : std_logic_vector(3 downto 0) := "1011";

    -- valor capturado cuando se pide un nuevo random
    signal rand_code   : std_logic_vector(1 downto 0) := "00";

begin

    ----------------------------------------------------------------
    -- LFSR free-running
    ----------------------------------------------------------------
    process(clk)
        variable feedback : std_logic;
    begin
        if rising_edge(clk) then
            if reset = '1' then
                lfsr      <= "1011";
                rand_code <= "00";
            else
                -- el LFSR siempre avanza
                feedback := lfsr(3) xor lfsr(2);
                lfsr <= lfsr(2 downto 0) & feedback;

                -- solo capturamos un nuevo valor cuando lo piden
                if next_rand = '1' then
                    rand_code <= lfsr(1 downto 0);
                end if;
            end if;
        end if;
    end process;

    ----------------------------------------------------------------
    -- Mapeo de 2 bits a formato RGYB one-hot
    ----------------------------------------------------------------
    process(rand_code)
    begin
        case rand_code is
            when "00" =>
                rand_num_rgyb <= "1000"; -- RED
            when "01" =>
                rand_num_rgyb <= "0100"; -- GREEN
            when "10" =>
                rand_num_rgyb <= "0010"; -- YELLOW
            when others =>
                rand_num_rgyb <= "0001"; -- BLUE
        end case;
    end process;

end Behavioral;