-- uart_rx.vhd — récepteur UART 8N1 (corrigé TP 2, séance 2)
-- Resynchronisation sur le front du start, vérification à mi-start
-- (filtre anti-glitch), échantillonnage de chaque bit en son milieu.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_rx is
    generic (
        F_CLK : natural := 50_000_000;
        BAUD  : natural := 115_200
    );
    port (
        clk    : in  std_logic;
        rx     : in  std_logic;                     -- ligne série (ASYNCHRONE)
        donnee : out std_logic_vector(7 downto 0);
        valide : out std_logic                      -- '1' pendant 1 cycle
    );
end entity;

architecture rtl of uart_rx is
    constant TPB : natural := F_CLK / BAUD;
    type t_etat is (REPOS, VERIF_START, DONNEES, STOP);
    signal etat  : t_etat := REPOS;
    signal sync0, sync1 : std_logic := '1';         -- synchroniseur 2 FF
    signal cpt   : natural range 0 to TPB - 1 := 0;
    signal idx   : natural range 0 to 7 := 0;
    signal shreg : std_logic_vector(7 downto 0) := (others => '0');
begin
    process (clk)
    begin
        if rising_edge(clk) then
            sync0 <= rx;                            -- JAMAIS rx directement
            sync1 <= sync0;
            valide <= '0';                          -- impulsion par defaut

            case etat is
                when REPOS =>
                    if sync1 = '0' then             -- front de start ?
                        cpt <= 0;
                        etat <= VERIF_START;
                    end if;

                when VERIF_START =>
                    if cpt = TPB / 2 - 1 then       -- milieu du start
                        if sync1 = '0' then         -- toujours bas : vrai start
                            cpt <= 0;
                            idx <= 0;
                            etat <= DONNEES;
                        else
                            etat <= REPOS;          -- glitch : abandon
                        end if;
                    else
                        cpt <= cpt + 1;
                    end if;

                when DONNEES =>
                    -- TPB cycles apres le milieu du start = milieu du bit 0,
                    -- puis milieu de chaque bit suivant.
                    if cpt = TPB - 1 then
                        cpt <= 0;
                        shreg(idx) <= sync1;        -- LSB d'abord
                        if idx = 7 then
                            etat <= STOP;
                        else
                            idx <= idx + 1;
                        end if;
                    else
                        cpt <= cpt + 1;
                    end if;

                when STOP =>
                    if cpt = TPB - 1 then           -- milieu du bit de stop
                        if sync1 = '1' then         -- stop valide
                            donnee <= shreg;
                            valide <= '1';
                        end if;                     -- sinon : erreur de trame,
                        etat <= REPOS;              -- octet silencieusement jete
                    else
                        cpt <= cpt + 1;
                    end if;
            end case;
        end if;
    end process;
end architecture;
