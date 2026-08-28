# MatLibre — raccourcis de compilation.
#
# Tout passe par CMake ; ce fichier n'existe que pour taper moins.

BUILD ?= build
TYPE  ?= Release
PREFIX ?= /usr/local
JOBS  ?= $(shell nproc 2>/dev/null || echo 4)
PORT  ?= 8421

.PHONY: aide tout configurer test tests doc install propre reference exemples \
        atelier verifier-atelier windows

aide:
	@echo "make tout        compile l'interpreteur"
	@echo "make test        compile puis execute toute la suite de tests"
	@echo "make doc         regenere documentation/reference/ et les comptes"
	@echo "make exemples    execute les scripts de exemples/"
	@echo "make atelier     ouvre l'atelier dans le navigateur (port $(PORT))"
	@echo "make verifier-atelier   pilote l'atelier avec un vrai navigateur"
	@echo "make windows     verifie la compilation pour Windows (MinGW)"
	@echo "make install     installe dans $(PREFIX)"
	@echo "make propre      efface $(BUILD)"

tout: configurer
	@cmake --build $(BUILD) -j $(JOBS)

configurer:
	@cmake -S . -B $(BUILD) -DCMAKE_BUILD_TYPE=$(TYPE) > /dev/null

test: tout
	@$(BUILD)/matlibre_tests
	@MATLIBRE_TOOLBOX=$(CURDIR)/toolbox $(BUILD)/matlibre outils/verifierDoublons.m
	@for f in tests/scripts/test_*.m; do \
	  echo "--> $$f"; \
	  MATLIBRE_TOOLBOX=$(CURDIR)/toolbox $(BUILD)/matlibre --path tests/scripts $$f || exit 1; \
	done
	@echo "tous les tests passent"

tests: test

doc: tout
	@MATLIBRE_TOOLBOX=$(CURDIR)/toolbox $(BUILD)/matlibre outils/genererReference.m
	@MATLIBRE_TOOLBOX=$(CURDIR)/toolbox $(BUILD)/matlibre outils/majComptes.m

reference: doc

exemples: tout
	@for f in exemples/*.m; do \
	  echo "--> $$f"; \
	  MATLIBRE_TOOLBOX=$(CURDIR)/toolbox $(BUILD)/matlibre $$f || exit 1; \
	done

atelier: tout
	@MATLIBRE_TOOLBOX=$(CURDIR)/toolbox MATLIBRE_IDE=$(CURDIR)/ide \
	  $(BUILD)/matlibre --ide $(PORT)

# Vérification de bout en bout : l'atelier est lancé, un vrai navigateur le
# pilote, puis tout est arrêté. Playwright est nécessaire ; sans lui la
# vérification se déclare sautée plutôt qu'en échec.
verifier-atelier: tout
	@MATLIBRE_TOOLBOX=$(CURDIR)/toolbox MATLIBRE_IDE=$(CURDIR)/ide \
	  $(BUILD)/matlibre --ide-sans-navigateur $(PORT) & echo $$! > .atelier.pid; \
	  sleep 2; \
	  NO_PROXY='*' node tests/ide/verifierAtelier.mjs http://127.0.0.1:$(PORT); \
	  code=$$?; \
	  kill `cat .atelier.pid` 2>/dev/null; rm -f .atelier.pid; \
	  if [ $$code -eq 77 ]; then exit 0; fi; exit $$code

# Compilation croisee pour Windows : elle ne sert pas a livrer, mais a
# verifier la portabilite depuis la machine de developpement. Sans le
# cross-compilateur, la cible le dit et s'arrete sans echouer.
windows:
	@if ! command -v x86_64-w64-mingw32-g++ > /dev/null; then \
	  echo "MinGW-w64 absent : apt install g++-mingw-w64-x86-64"; \
	  exit 0; \
	fi; \
	cmake -S . -B build-windows -DCMAKE_TOOLCHAIN_FILE=outils/mingw.cmake \
	      -DCMAKE_BUILD_TYPE=Release > /dev/null && \
	cmake --build build-windows -j $(JOBS) && \
	echo "MatLibre : la compilation pour Windows passe"

install: tout
	@cmake --install $(BUILD) --prefix $(PREFIX)

propre:
	@rm -rf $(BUILD) build-windows
