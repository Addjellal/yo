-- Testbench auto-verifiant du mini-TP compteur (NE PAS MODIFIER).
-- edaplayground.com : fenetre TESTBENCH, top entity = tb_compteur.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_compteur is end entity;

architecture sim of tb_compteur is
    signal clk   : std_logic := '0';
    signal reset : std_logic := '0';
    signal en    : std_logic := '0';
    signal cpt   : unsigned(3 downto 0);
    signal plein : std_logic;
    signal fini  : boolean := false;
begin
    dut : entity work.compteur
        port map (clk => clk, reset => reset, en => en,
                  cpt => cpt, plein => plein);

    horloge : process
    begin
        while not fini loop
            clk <= '0'; wait for 5 ns;
            clk <= '1'; wait for 5 ns;
        end loop;
        wait;
    end process;

    stim : process
    begin
        -- 1) reset synchrone
        reset <= '1'; wait for 20 ns; reset <= '0';
        wait for 1 ns;
        assert cpt = 0 report "ECHEC reset : cpt devrait valoir 0" severity failure;

        -- 2) enable coupe : le compteur ne doit pas bouger
        en <= '0'; wait for 50 ns;
        assert cpt = 0 report "ECHEC enable : cpt a bouge avec en='0'" severity failure;

        -- 3) comptage : 5 fronts avec en='1'
        en <= '1'; wait for 50 ns; en <= '0'; wait for 1 ns;
        assert cpt = 5 report "ECHEC comptage : attendu 5" severity failure;

        -- 4) enroulement 15 -> 0 et drapeau plein
        en <= '1'; wait for 100 ns; en <= '0'; wait for 1 ns;  -- 5+10 = 15
        assert cpt = 15    report "ECHEC : attendu 15" severity failure;
        assert plein = '1' report "ECHEC : plein devrait etre '1' a 15" severity failure;
        en <= '1'; wait for 10 ns; en <= '0'; wait for 1 ns;   -- 15 -> 0
        assert cpt = 0     report "ECHEC enroulement : attendu 0 apres 15" severity failure;
        assert plein = '0' report "ECHEC : plein devrait retomber a 0" severity failure;

        report "MINI-TP VHDL : TOUS LES TESTS PASSENT";
        fini <= true;
        wait;
    end process;
end architecture;
