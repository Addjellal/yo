# Simulation GHDL des corrigés VHDL (TD 04 et TP 2).
#   make test        : lance les trois testbenchs
#   make ondes       : rejoue tb_uart_boucle avec traces pour GTKWave
# Prérequis : sudo apt install ghdl gtkwave   (ou edaplayground.com)
GHDL  ?= ghdl
STD   := --std=08
SRCS  := mux4.vhd compteur_bcd.vhd debounce.vhd uart_tx.vhd uart_rx.vhd
TBS   := tb_mux4 tb_compteur_bcd tb_uart_boucle

test: analyse
	@for tb in $(TBS); do \
	    echo "=== $$tb ==="; \
	    $(GHDL) -e $(STD) $$tb && $(GHDL) -r $(STD) $$tb --stop-time=100ms; \
	done

analyse:
	$(GHDL) -a $(STD) $(SRCS) tb_mux4.vhd tb_compteur_bcd.vhd tb_uart_boucle.vhd

ondes: analyse
	$(GHDL) -e $(STD) tb_uart_boucle
	$(GHDL) -r $(STD) tb_uart_boucle --wave=uart.ghw --stop-time=100ms
	gtkwave uart.ghw &

clean:
	rm -f *.o *.cf uart.ghw $(TBS)

.PHONY: test analyse ondes clean
