# make test : compile et exécute les tests du TD 02
CXX      := g++
CXXFLAGS := -Wall -Wextra -Werror -std=c++17 -O2
CIBLE    := tests

all: $(CIBLE)

$(CIBLE): tests.cpp tampon_circulaire.hpp afficheur.hpp chip_select.hpp feu_tricolore.hpp
	$(CXX) $(CXXFLAGS) tests.cpp -o $@

test: $(CIBLE)
	./$(CIBLE)

clean:
	rm -f $(CIBLE)

.PHONY: all test clean
