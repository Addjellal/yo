-- tb_uart_boucle.vhd — TX branché sur RX : test exhaustif des 256 octets
-- (corrigé TP 2, séance 2, étape 2.3)
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_uart_boucle is end entity;

architecture sim of tb_uart_boucle is
    signal clk      : std_logic := '0';
    signal tx_start : std_logic := '0';
    signal fil      : std_logic;             -- la "liaison serie"
    signal busy     : std_logic;
    signal valide   : std_logic;
    signal d_in     : std_logic_vector(7 downto 0) := (others => '0');
    signal d_out    : std_logic_vector(7 downto 0);
    signal fini     : boolean := false;
begin
    emetteur : entity work.uart_tx
        port map (clk => clk, tx_start => tx_start, tx_data => d_in,
                  tx => fil, busy => busy);

    recepteur : entity work.uart_rx
        port map (clk => clk, rx => fil, donnee => d_out, valide => valide);

    horloge : process
    begin
        while not fini loop
            clk <= '0'; wait for 10 ns;      -- 50 MHz
            clk <= '1'; wait for 10 ns;
        end loop;
        wait;
    end process;

    stim : process
    begin
        wait for 100 ns;
        for i in 0 to 255 loop               -- test EXHAUSTIF
            d_in <= std_logic_vector(to_unsigned(i, 8));
            wait until rising_edge(clk);
            tx_start <= '1';
            wait until rising_edge(clk);
            tx_start <= '0';
            wait until valide = '1';
            assert d_out = d_in
                report "echec pour l'octet " & integer'image(i)
                severity failure;
            wait until busy = '0';
        end loop;
        report "tb_uart_boucle : BOUCLE OK, 256/256 octets";
        fini <= true;
        wait;
    end process;
end architecture;
