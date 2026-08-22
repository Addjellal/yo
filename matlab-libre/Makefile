# MatLibre — raccourcis de compilation.
#
# Tout passe par CMake ; ce fichier n'existe que pour taper moins.

BUILD ?= build
TYPE  ?= Release
PREFIX ?= /usr/local
JOBS  ?= $(shell nproc 2>/dev/null || echo 4)

.PHONY: aide tout configurer test tests doc install propre reference exemples

aide:
	@echo "make tout        compile l'interpreteur"
	@echo "make test        compile puis execute toute la suite de tests"
	@echo "make doc         regenere documentation/reference/"
	@echo "make exemples    execute les scripts de exemples/"
	@echo "make install     installe dans $(PREFIX)"
	@echo "make propre      efface $(BUILD)"

tout: configurer
	@cmake --build $(BUILD) -j $(JOBS)

configurer:
	@cmake -S . -B $(BUILD) -DCMAKE_BUILD_TYPE=$(TYPE) > /dev/null

test: tout
	@$(BUILD)/matlibre_tests
	@for f in tests/scripts/test_*.m; do \
	  echo "--> $$f"; \
	  MATLIBRE_TOOLBOX=$(CURDIR)/toolbox $(BUILD)/matlibre --path tests/scripts $$f || exit 1; \
	done
	@echo "tous les tests passent"

tests: test

doc: tout
	@MATLIBRE_TOOLBOX=$(CURDIR)/toolbox $(BUILD)/matlibre outils/genererReference.m

reference: doc

exemples: tout
	@for f in exemples/*.m; do \
	  echo "--> $$f"; \
	  MATLIBRE_TOOLBOX=$(CURDIR)/toolbox $(BUILD)/matlibre $$f || exit 1; \
	done

install: tout
	@cmake --install $(BUILD) --prefix $(PREFIX)

propre:
	@rm -rf $(BUILD)
