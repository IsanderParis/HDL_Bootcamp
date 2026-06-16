library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity buzzer is
    Port ( enable : in STD_LOGIC;
           tone : in std_logic_vector (2 downto 0);
           buzzer_out : out STD_LOGIC;
           clk : in STD_LOGIC);
end buzzer;

architecture Behavioral of buzzer is

    signal counter : unsigned(31 downto 0) := (others => '0');
    signal limit : unsigned(31 downto 0);
    signal buzzer_reg : std_logic := '0';
    

begin

    buzzer_out <= buzzer_reg;
    
    process(tone) begin
        case tone is
            when "000" => limit <= to_unsigned(191110, 32); -- rojo
            when "001" => limit <= to_unsigned(151686, 32); -- verde
            when "010" => limit <= to_unsigned(127551, 32); -- amarillo
            when "011" => limit <= to_unsigned(95602, 32); -- azul
            when "100" => limit <= to_unsigned(50000, 32); -- game_over
            when others => limit <= TO_UNSIGNED(191110, 32);
        end case;
   end process ;
   
   process(clk) begin 
    if rising_edge(clk) then
        if enable = '0' then
            counter <= (others  => '0');
            buzzer_reg <= '0';
        else
            if counter >= limit then
                counter <= (others  => '0');
                buzzer_reg <= not buzzer_reg;
            else
                counter<= counter + 1;
            end if;
        end if;
    end if;
end process;


end Behavioral;
