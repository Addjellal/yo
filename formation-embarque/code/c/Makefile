# Makefile du corrigé TD 06 exercice 2, appliqué aux sources du TD 01.
#   make        : compile
#   make test   : compile puis exécute les tests
#   make clean  : nettoie
CC      := gcc
CFLAGS  := -Wall -Wextra -Werror -std=c11 -O2 -MMD -MP
SRCS    := bits.c ring_buffer.c fsm_feu.c trame.c tests.c
OBJS    := $(SRCS:.c=.o)
DEPS    := $(OBJS:.o=.d)
CIBLE   := tests

all: $(CIBLE)

$(CIBLE): $(OBJS)
	$(CC) $(CFLAGS) $^ -o $@

%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

test: $(CIBLE)
	./$(CIBLE)

clean:
	rm -f $(OBJS) $(DEPS) $(CIBLE)

-include $(DEPS)

.PHONY: all test clean
