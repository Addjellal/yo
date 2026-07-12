-- compteur_bcd.vhd — compteur 0-9 + décodeur 7 segments (TD 04, ex. 2)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity compteur_bcd is
    port (
        clk, reset, en : in  std_logic;
        chiffre        : out unsigned(3 downto 0);
        seg            : out std_logic_vector(6 downto 0)  -- gfedcba, actif bas
    );
end entity;

architecture rtl of compteur_bcd is
    signal cpt : unsigned(3 downto 0) := (others => '0');
begin
    -- Partie SÉQUENTIELLE : le compteur (des bascules)
    process (clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                cpt <= (others => '0');
            elsif en = '1' then
                if cpt = 9 then                 -- BCD : retour a 0 apres 9
                    cpt <= (others => '0');
                else
                    cpt <= cpt + 1;
                end if;
            end if;
        end if;
    end process;

    chiffre <= cpt;

    -- Partie COMBINATOIRE : le décodeur 7 segments (une table)
    with cpt select
        seg <= "1000000" when "0000",  -- 0
               "1111001" when "0001",  -- 1
               "0100100" when "0010",  -- 2
               "0110000" when "0011",  -- 3
               "0011001" when "0100",  -- 4
               "0010010" when "0101",  -- 5
               "0000010" when "0110",  -- 6
               "1111000" when "0111",  -- 7
               "0000000" when "1000",  -- 8
               "0010000" when "1001",  -- 9
               "1111111" when others;  -- éteint si valeur invalide
end architecture;
