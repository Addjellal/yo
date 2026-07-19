-- Mini-TP VHDL — compteur 4 bits avec enable (cours 04 §3)
-- Plateforme : edaplayground.com (GHDL) — fenetre DESIGN.
-- Complete les 3 trous. Le testbench s'auto-verifie.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity compteur is
    port (
        clk   : in  std_logic;
        reset : in  std_logic;                  -- synchrone, actif haut
        en    : in  std_logic;                  -- n'avance que si en='1'
        cpt   : out unsigned(3 downto 0);
        plein : out std_logic                   -- '1' quand cpt = 15
    );
end entity;

architecture rtl of compteur is
    signal c : unsigned(3 downto 0) := (others => '0');
begin
    process (clk)
    begin
        if rising_edge(clk) then
            -- A COMPLETER (1) : si reset='1', remettre c a zero
            --                   (indice : (others => '0'))

            -- A COMPLETER (2) : sinon, si en='1', incrementer c
            --                   (l'enroulement 15 -> 0 est automatique
            --                    avec unsigned : c <= c + 1 suffit)

        end if;
    end process;

    cpt <= c;

    -- A COMPLETER (3) : plein = '1' quand c vaut 15, sinon '0'
    -- (UNE affectation concurrente avec when/else — PAS de process)

end architecture;
