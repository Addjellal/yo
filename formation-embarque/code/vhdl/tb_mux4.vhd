-- tb_mux4.vhd — testbench exhaustif du mux (corrigé TD 04, exercice 1)
library ieee;
use ieee.std_logic_1164.all;

entity tb_mux4 is end entity;

architecture sim of tb_mux4 is
    signal e0, e1, e2, e3, s : std_logic;
    signal sel : std_logic_vector(1 downto 0);
begin
    dut : entity work.mux4(concurrente)
        port map (e0 => e0, e1 => e1, e2 => e2, e3 => e3, sel => sel, s => s);

    stim : process
    begin
        e0 <= '1'; e1 <= '0'; e2 <= '1'; e3 <= '0';
        sel <= "00"; wait for 10 ns;
        assert s = '1' report "sel=00 : attendu e0=1" severity error;
        sel <= "01"; wait for 10 ns;
        assert s = '0' report "sel=01 : attendu e1=0" severity error;
        sel <= "10"; wait for 10 ns;
        assert s = '1' report "sel=10 : attendu e2=1" severity error;
        sel <= "11"; wait for 10 ns;
        assert s = '0' report "sel=11 : attendu e3=0" severity error;
        report "tb_mux4 : OK";
        wait;
    end process;
end architecture;
