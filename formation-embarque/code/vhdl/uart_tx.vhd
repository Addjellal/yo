-- uart_tx.vhd — émetteur UART 8N1 (corrigé TD 04, exercice 5)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity uart_tx is
    generic (
        F_CLK : natural := 50_000_000;
        BAUD  : natural := 115_200
    );
    port (
        clk      : in  std_logic;
        tx_start : in  std_logic;                      -- impulsion 1 cycle
        tx_data  : in  std_logic_vector(7 downto 0);
        tx       : out std_logic;                      -- ligne série
        busy     : out std_logic
    );
end entity;

architecture rtl of uart_tx is
    constant TICKS_PAR_BIT : natural := F_CLK / BAUD;
    type t_etat is (REPOS, START, DONNEES, STOP);
    signal etat     : t_etat := REPOS;
    signal cpt_tick : natural range 0 to TICKS_PAR_BIT - 1 := 0;
    signal idx_bit  : natural range 0 to 7 := 0;
    signal registre : std_logic_vector(7 downto 0) := (others => '0');
begin
    process (clk)
    begin
        if rising_edge(clk) then
            case etat is
                when REPOS =>
                    tx   <= '1';               -- repos = etat haut
                    busy <= '0';
                    if tx_start = '1' then
                        registre <= tx_data;   -- CAPTURER la donnee maintenant
                        cpt_tick <= 0;
                        busy     <= '1';
                        etat     <= START;
                    end if;

                when START =>
                    tx <= '0';                 -- bit de start
                    if cpt_tick = TICKS_PAR_BIT - 1 then
                        cpt_tick <= 0;
                        idx_bit  <= 0;
                        etat     <= DONNEES;
                    else
                        cpt_tick <= cpt_tick + 1;
                    end if;

                when DONNEES =>
                    tx <= registre(idx_bit);   -- LSB en premier (norme UART)
                    if cpt_tick = TICKS_PAR_BIT - 1 then
                        cpt_tick <= 0;
                        if idx_bit = 7 then
                            etat <= STOP;
                        else
                            idx_bit <= idx_bit + 1;
                        end if;
                    else
                        cpt_tick <= cpt_tick + 1;
                    end if;

                when STOP =>
                    tx <= '1';                 -- bit de stop
                    if cpt_tick = TICKS_PAR_BIT - 1 then
                        etat <= REPOS;
                    else
                        cpt_tick <= cpt_tick + 1;
                    end if;
            end case;
        end if;
    end process;
end architecture;
