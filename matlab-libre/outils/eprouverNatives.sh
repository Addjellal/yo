#!/bin/sh
# eprouverNatives.sh — appelle chaque fonction native avec des arguments
# qu'elle n'attend pas, et signale celles qui font tomber le programme.
#
#   ./outils/eprouverNatives.sh [chemin de matlibre]
#
# Une erreur MATLAB est le bon comportement : l'utilisateur s'est trompé,
# on le lui dit. Un plantage n'en est jamais un — et c'est ce que produit
# une fonction qui parcourt « re » d'une valeur qui n'en a pas : une
# cellule, une structure, un objet, une poignée et un tableau de chaînes
# comptent des éléments que le tableau de réels ne porte pas.
#
# Chaque appel tourne dans son propre processus : un plantage n'arrête
# pas le passage, il est simplement noté. Compter une demi-heure.
set -u

racine=$(cd "$(dirname "$0")/.." && pwd)
matlibre=${1:-$racine/build/bin/matlibre}
if [ ! -x "$matlibre" ]; then
    echo "matlibre est introuvable : $matlibre" >&2
    echo "Compilez d'abord (make), ou donnez son chemin en argument." >&2
    exit 2
fi
MATLIBRE_TOOLBOX="$racine/toolbox"
export MATLIBRE_TOOLBOX

# Certaines fonctions écrivent des fichiers — « dlmwrite », « csvwrite ».
# On travaille donc dans un dossier jetable : le dépôt reste propre.
travail=$(mktemp -d)
cd "$travail" || exit 2

# Ce qu'on n'appelle pas : ce qui sort du programme, lit au clavier, écrit
# sur le disque ou lance un processus.
exclus=" exit quit input keyboard pause system dos unix delete rmdir mkdir
 fclose fopen fwrite fprintf save load diary rehash clc close parpool gcp
 matlabpool tic toc web edit open dbquit dbcont dbstep print saveas imwrite
 audiowrite movefile copyfile fileattrib winopen cd addpath rmpath path "

# Les formes qui ont trouvé des défauts : rien, une valeur qui ne porte
# aucun nombre, une taille absurde, une dimension négative. Une par ligne.
formes=$(mktemp)
trap 'rm -f "$formes"; rm -rf "$travail"' EXIT
cat > "$formes" <<'FIN'

1
[]
''
""
{}
struct()
@sin
[1 2 3]
NaN
Inf
-1
0
int8(1)
true
{1,2}
1, 1
[], []
'', ''
struct(), 1
1, 'x'
'x', 1
[1 2; 3 4], 3
1, -1
@sin, 1
{1,2}, 1
1, {1,2}
struct('a',1), 'a'
'abc', {}
1, 2, 3
{1,2}, 1, 1
struct(), 1, 1
FIN

noms=$("$matlibre" -e "f = matlibre_fonctions(); for k = 1:size(f,1), fprintf('%s\n', f{k,1}); end" 2>/dev/null)
eprouvees=0
for nom in $noms; do
    case "$exclus" in *" $nom "*) continue ;; esac
    eprouvees=$((eprouvees + 1))
    while IFS= read -r a; do
        "$matlibre" -e "try, [~] = $nom($a); catch, end" > /dev/null 2>&1
        if [ $? -ge 128 ]; then
            echo "PLANTAGE  $nom($a)"
        fi
    done < "$formes"
done
echo "---"
echo "$eprouvees fonctions eprouvees ; les plantages, s'il y en a, sont ci-dessus."
