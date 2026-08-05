# Formation embarquée — tâches courantes
#
#   make            affiche cette aide
#   make test       compile et exécute TOUS les corrigés (C, C++, Java, VHDL)
#   make verif      vérifie tous les liens des documents Markdown
#   make pdf        régénère les 70+ PDF (nécessite markdown, pygments, chromium)
#   make zip        crée une archive des PDF, prête à partager
#   make clean      supprime les artefacts de compilation
#   make check      verif + test  (à lancer avant de committer)

.DEFAULT_GOAL := aide
CODE := code

aide:
	@echo "Formation embarquée — cibles disponibles :"
	@echo "  make test    compile + exécute les corrigés C, C++, Java, VHDL"
	@echo "  make verif   vérifie les liens de tous les .md"
	@echo "  make check   verif + test (avant un commit)"
	@echo "  make pdf     régénère les PDF dans pdf/"
	@echo "  make zip     archive des PDF (formation-pdf.zip)"
	@echo "  make clean   nettoie les artefacts de compilation"

test:
	@echo "=== C ==="   && $(MAKE) -s -C $(CODE)/c test
	@echo "=== C++ ===" && $(MAKE) -s -C $(CODE)/cpp test
	@echo "=== Java ==="&& $(MAKE) -s -C $(CODE)/java test
	@echo "=== VHDL ===" && $(MAKE) -s -C $(CODE)/vhdl test 2>/dev/null \
		|| echo "  (GHDL absent : sudo apt install ghdl — ou edaplayground.com)"

verif:
	@python3 _build/verif_liens.py

check: verif test

pdf:
	@python3 _build/build_pdf.py

zip:
	@cd pdf && zip -qr ../formation-pdf.zip . -x ".gitignore" && cd ..
	@echo "archive créée : formation-pdf.zip"

clean:
	@$(MAKE) -s -C $(CODE)/c clean
	@$(MAKE) -s -C $(CODE)/cpp clean
	@$(MAKE) -s -C $(CODE)/java clean
	@$(MAKE) -s -C $(CODE)/vhdl clean 2>/dev/null || true
	@rm -rf _build/__pycache__ formation-pdf.zip
	@echo "nettoyé."

.PHONY: aide test verif check pdf zip clean
