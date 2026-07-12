-- tb_compteur_bcd.vhd — vérifie 0..9 puis le retour a 0 (TD 04, ex. 2)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_compteur_bcd is end entity;

architecture sim of tb_compteur_bcd is
    signal clk   : std_logic := '0';
    signal reset : std_logic := '0';
    signal en    : std_logic := '0';
    signal chiffre : unsigned(3 downto 0);
    signal seg     : std_logic_vector(6 downto 0);
    constant PERIODE : time := 10 ns;
    signal fini : boolean := false;
begin
    dut : entity work.compteur_bcd
        port map (clk => clk, reset => reset, en => en,
                  chiffre => chiffre, seg => seg);

    horloge : process
    begin
        while not fini loop
            clk <= '0'; wait for PERIODE / 2;
            clk <= '1'; wait for PERIODE / 2;
        end loop;
        wait;
    end process;

    stim : process
    begin
        reset <= '1';
        wait for 2 * PERIODE;
        reset <= '0'; en <= '1';
        for i in 0 to 9 loop
            assert chiffre = i
                report "attendu " & integer'image(i) severity error;
            wait for PERIODE;
        end loop;
        wait for PERIODE / 4;               -- s'ecarter du front avant de lire
        assert chiffre = 0 report "pas revenu a 0 apres 9 !" severity error;
        assert seg = "1000000" report "decodeur : motif du 0 attendu" severity error;
        report "tb_compteur_bcd : OK";
        fini <= true;
        wait;
    end process;
end architecture;
