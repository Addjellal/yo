-- mux4.vhd — multiplexeur 4 vers 1 (corrigé TD 04, exercice 1)
library ieee;
use ieee.std_logic_1164.all;

entity mux4 is
    port (
        e0, e1, e2, e3 : in  std_logic;
        sel            : in  std_logic_vector(1 downto 0);
        s              : out std_logic
    );
end entity;

-- Affectation sélectionnée (concurrente). La version process du TD
-- synthétise exactement le même circuit.
architecture concurrente of mux4 is
begin
    with sel select
        s <= e0 when "00",
             e1 when "01",
             e2 when "10",
             e3 when others;   -- others : couvre "11" ET 'X','U',...
end architecture;
