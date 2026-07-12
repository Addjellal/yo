-- debounce.vhd — anti-rebond : synchroniseur 2 FF + filtre de stabilité
-- (corrigé TD 04, exercice 3)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity debounce is
    generic (
        F_CLK    : natural := 50_000_000;
        DUREE_MS : natural := 20
    );
    port (
        clk      : in  std_logic;
        btn_brut : in  std_logic;    -- asynchrone, rebondissant
        btn_net  : out std_logic;    -- propre, synchrone
        front    : out std_logic     -- '1' pendant 1 cycle sur front montant net
    );
end entity;

architecture rtl of debounce is
    constant CYCLES_STABLES : natural := F_CLK / 1000 * DUREE_MS;
    signal sync0, sync1 : std_logic := '0';   -- synchroniseur : OBLIGATOIRE
    signal etat_net     : std_logic := '0';
    signal etat_prec    : std_logic := '0';
    signal cpt          : natural range 0 to CYCLES_STABLES := 0;
begin
    process (clk)
    begin
        if rising_edge(clk) then
            -- 1) Synchronisation : jamais d'entree asynchrone directe
            sync0 <= btn_brut;
            sync1 <= sync0;

            -- 2) Filtre : l'etat doit rester stable CYCLES_STABLES cycles
            if sync1 /= etat_net then
                if cpt = CYCLES_STABLES - 1 then
                    etat_net <= sync1;         -- etat confirme
                    cpt <= 0;
                else
                    cpt <= cpt + 1;
                end if;
            else
                cpt <= 0;                      -- instable : on repart de zero
            end if;

            -- 3) Memoire pour le detecteur de front
            etat_prec <= etat_net;
        end if;
    end process;

    btn_net <= etat_net;
    front   <= etat_net and not etat_prec;     -- exactement 1 cycle
end architecture;
