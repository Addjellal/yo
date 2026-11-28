#!/bin/sh
# couverture.sh — ce que les tests exercent du code C++, fichier par fichier.
#
#   cmake -S . -B build-couverture -DCMAKE_BUILD_TYPE=Debug -DMATLIBRE_COUVERTURE=ON
#   cmake --build build-couverture -j
#   (cd build-couverture && ctest -LE lent)        # ou la batterie entière
#   outils/couverture.sh build-couverture           # le tableau, en Markdown
#
# Lit les compteurs (.gcda) que les tests ont laissés dans l'arbre et les
# passe à gcov, sans rien écrire à côté (-n). Ne compte que les sources de
# src/coeur, src/bibliotheque et src/graphique : le bureau se mesure à
# part, et les en-têtes, comptés une fois par fichier qui les inclut,
# brouilleraient le total. Le tableau va du fichier le moins couvert au
# plus couvert, le total en dernier ; l'intégration continue de nuit
# l'écrit dans le résumé de sa tâche.
#
# Aucune dépendance au-delà de gcov, qui vient avec gcc : ni lcov ni gcovr.
set -eu

arbre="${1:-build-couverture}"
if [ ! -d "$arbre" ]; then
    echo "couverture.sh : pas d'arbre de construction « $arbre »" >&2
    exit 2
fi
gcov_="${GCOV:-gcov}"

liste=$(mktemp)
trap 'rm -f "$liste" "$liste.total"' EXIT
find "$arbre" -name '*.gcda' > "$liste"
if [ ! -s "$liste" ]; then
    echo "couverture.sh : aucun compteur .gcda dans « $arbre » ;" \
         "l'arbre est-il instrumenté (-DMATLIBRE_COUVERTURE=ON), les tests ont-ils tourné ?" >&2
    exit 1
fi

# gcov écrit, pour chaque source :   File '.../src/coeur/Lexeur.cpp'
#                                    Lines executed:93.10% of 1234
# On garde le dernier relevé de chaque fichier, et l'on recompte les lignes
# exécutées à partir du pourcentage (gcov l'arrondit au centième : l'écart
# est d'une ligne au plus).
while read -r gcda; do
    "$gcov_" -n -o "$(dirname "$gcda")" "$gcda" 2>/dev/null || true
done < "$liste" | awk '
    /^File / {
        f = $0; sub(/^File \047/, "", f); sub(/\047$/, "", f); fichier = f; next
    }
    /^Lines executed:/ && fichier != "" {
        if (fichier ~ /\/src\/(coeur|bibliotheque|graphique)\/[^\/]*\.cpp$/) {
            split($0, a, /[:% ]+/)      # Lines executed:93.10% of 1234
            pct = a[3]; n = a[5]
            court = fichier; sub(/.*\/src\//, "src/", court)
            lignes[court] = n; faites[court] = int(pct * n / 100 + 0.5)
        }
        fichier = ""
    }
    END {
        for (f in lignes) {
            t += lignes[f]; e += faites[f]
            printf "%08.3f|%s|%d|%d\n", (lignes[f] ? 100 * faites[f] / lignes[f] : 100), f,
                   faites[f], lignes[f]
        }
        printf "TOTAL|%d|%d\n", e, t > "/dev/stderr"
    }' 2> "$liste.total" | sort | awk -F'|' '
    BEGIN { print "| fichier | lignes exercées | lignes | % |"; print "|---|---:|---:|---:|" }
    { printf "| `%s` | %d | %d | %.1f |\n", $2, $3, $4, $1 + 0 }'

awk -F'|' '$1 == "TOTAL" {
    printf "| **total** | **%d** | **%d** | **%.1f** |\n", $2, $3, ($3 ? 100 * $2 / $3 : 0)
}' "$liste.total"
rm -f "$liste.total"
