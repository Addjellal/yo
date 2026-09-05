# MatLibre — raccourcis de compilation.
#
# Tout passe par CMake ; ce fichier n'existe que pour taper moins.

BUILD ?= build
# Les binaires vivent dans build/bin : l'arbre de construction reste lisible.
BIN   ?= $(BUILD)/bin
TYPE  ?= Release
PREFIX ?= /usr/local
JOBS  ?= $(shell nproc 2>/dev/null || echo 4)

# Une compilation part d'un arbre neuf : l'ancien est efface avant de
# reconfigurer. C'est ce qui evite les objets orphelins — le .o d'un
# fichier source supprime, un cache CMake qui garde une option qui
# n'existe plus, une bibliotheque trouvee la derniere fois et disparue
# depuis — et les pannes qui n'arrivent que chez celui qui n'a pas
# efface. Pour iterer sans tout refaire : « make incrementale », ou
# n'importe quelle cible avec « NEUF=0 ».
NEUF ?= 1

.PHONY: aide tout incrementale configurer test tests doc install propre \
        reference exemples windows ninja generateurs bureau

aide:
	@echo "make tout        compile l'interpreteur"
	@echo "make test        compile puis execute toute la suite de tests"
	@echo "make doc         regenere documentation/reference/ et les comptes"
	@echo "make exemples    execute les scripts de exemples/"
	@echo "make bureau      ouvre le bureau natif (fenetre Qt)"
	@echo "make windows     verifie la compilation pour Windows (MinGW)"
	@echo "make ninja       verifie la compilation avec le generateur Ninja"
	@echo "make generateurs verifie Ninja et MinGW : les deux autres chemins"
	@echo "make incrementale  recompile sans effacer l'arbre (iteration)"
	@echo "make install     installe dans $(PREFIX)"
	@echo "make propre      efface les arbres de construction"
	@echo ""
	@echo "Chaque compilation efface $(BUILD) avant de reconfigurer."
	@echo "Pour la garder : NEUF=0, par exemple « make test NEUF=0 »"

tout: configurer
	@cmake --build $(BUILD) -j $(JOBS)

# Recompiler sans effacer : ce qu'on veut en boucle courte, quand on sait
# que rien n'a bouge du cote de la configuration.
incrementale:
	@$(MAKE) --no-print-directory tout NEUF=0

configurer:
	@if [ "$(NEUF)" != "0" ]; then rm -rf $(BUILD); fi
	@cmake -S . -B $(BUILD) -DCMAKE_BUILD_TYPE=$(TYPE) > /dev/null

test: tout
	@$(BIN)/matlibre_tests
	@if [ -x $(BIN)/matlibre_tests_bureau ]; then \
	  MATLIBRE_TOOLBOX=$(CURDIR)/toolbox QT_QPA_PLATFORM=offscreen \
	    $(BIN)/matlibre_tests_bureau; \
	fi
	@MATLIBRE_TOOLBOX=$(CURDIR)/toolbox $(BIN)/matlibre outils/verifierDoublons.m
	@for f in tests/scripts/test_*.m; do \
	  echo "--> $$f"; \
	  MATLIBRE_TOOLBOX=$(CURDIR)/toolbox $(BIN)/matlibre --path tests/scripts $$f || exit 1; \
	done
	@echo "tous les tests passent"

tests: test

doc: tout
	@MATLIBRE_TOOLBOX=$(CURDIR)/toolbox $(BIN)/matlibre outils/genererReference.m
	@MATLIBRE_TOOLBOX=$(CURDIR)/toolbox $(BIN)/matlibre outils/majComptes.m

reference: doc

exemples: tout
	@for f in exemples/*.m exemples/toolboxes/*.m; do \
	  echo "--> $$f"; \
	  MATLIBRE_TOOLBOX=$(CURDIR)/toolbox $(BIN)/matlibre $$f || exit 1; \
	done

# Compilation croisee pour Windows : elle ne sert pas a livrer, mais a
# verifier la portabilite depuis la machine de developpement. Sans le
# cross-compilateur, la cible le dit et s'arrete sans echouer.
# Le bureau natif : un seul executable, une vraie fenetre.
bureau: tout
	@if [ ! -x $(BIN)/matlibre-bureau ]; then \
	  echo "Le bureau n'a pas ete construit : Qt6 est absent."; \
	  echo "  apt install qt6-base-dev   (Debian, Ubuntu)"; \
	  exit 1; \
	fi; \
	MATLIBRE_TOOLBOX=$(CURDIR)/toolbox $(BIN)/matlibre-bureau

windows:
	@if ! command -v x86_64-w64-mingw32-g++ > /dev/null; then \
	  echo "MinGW-w64 absent : apt install g++-mingw-w64-x86-64"; \
	  exit 0; \
	fi; \
	if [ "$(NEUF)" != "0" ]; then rm -rf build-windows; fi && \
	cmake -S . -B build-windows -DCMAKE_TOOLCHAIN_FILE=outils/mingw.cmake \
	      -DCMAKE_BUILD_TYPE=Release > /dev/null && \
	cmake --build build-windows -j $(JOBS) && \
	echo "MatLibre : la compilation pour Windows passe"

# Le générateur Ninja met le type de construction dans le nom de ses
# règles, là où les Makefiles ne le font pas : une valeur qui contient un
# « $$ » n'y casse que sous Ninja. Ce chemin-là n'était vérifié nulle part,
# et c'est par là que le défaut est passé.
ninja:
	@if ! command -v ninja > /dev/null; then \
	  echo "ninja absent : apt install ninja-build"; \
	  exit 0; \
	fi; \
	rm -rf build-ninja && \
	cmake -S . -B build-ninja -G Ninja -DCMAKE_BUILD_TYPE=$(TYPE) > /dev/null && \
	cmake --build build-ninja -j $(JOBS) > /dev/null && \
	echo "MatLibre : la compilation avec Ninja passe"

generateurs: ninja windows

install: tout
	@cmake --install $(BUILD) --prefix $(PREFIX)

# Efface tout ce qu'une compilation a pu deposer : les trois arbres de
# construction, et les fichiers que CMake laisse a la racine.
propre:
	@rm -rf $(BUILD) build build-windows build-ninja compile_commands.json
