# L'atelier

`matlibre --ide` ouvre l'atelier dans le navigateur : éditeur, console,
explorateur de variables, débogueur, profileur, concepteur d'applications
et éditeur de schémas-blocs. L'interpréteur tourne sur son propre fil ; le
serveur HTTP répond sur le fil principal, et n'écoute que la boucle locale.

```bash
make atelier              # http://127.0.0.1:8421
make atelier PORT=9000    # un autre port
matlibre --ide 8421       # sans passer par make
matlibre --ide-sans-navigateur 8421
```

Les fichiers de l'interface sont dans `ide/`. Ils sont cherchés dans
`$MATLIBRE_IDE`, puis autour de l'exécutable
(`../share/matlibre-ide`, `../ide`, `./ide`).

## Éditeur

Coloration syntaxique écrite à la main : mots-clés, chaînes — l'apostrophe
de transposition est distinguée de celle des chaînes —, commentaires,
nombres, appels de fonction. La gouttière numérote les lignes ; un clic y
pose un point d'arrêt.

| Raccourci | Effet |
| --- | --- |
| `F5` | enregistre puis exécute le fichier |
| `Ctrl`/`Cmd` + `S` | enregistre |
| `F10` | pas à pas |
| `F11` | entrer dans l'appel |
| `F8` | continuer |

## Console

La console partage l'espace de travail de l'éditeur. Les flèches haut et
bas rappellent l'historique. Un clic sur une variable de l'explorateur
l'affiche.

## Débogueur

Un point d'arrêt posé dans la gouttière arrête l'exécution : l'état passe
à « arrêté ligne N », l'explorateur montre les variables de la fonction
interrompue, et les boutons « Continuer », « Pas à pas », « Entrer »,
« Sortir » et « Arrêter » pilotent la suite. Les mêmes commandes existent
en ligne de commande : `dbstop`, `dbstep`, `dbcont`, `dbquit`, `dbstatus`,
`dbstack`, `keyboard`.

## Profileur

« Démarrer », du code, « Arrêter », « Rafraîchir » : la table donne pour
chaque fonction le nombre d'appels, le temps total, le temps propre hors
appels imbriqués, et une barre de proportion. `matlibre_profil_lignes`
rend le détail ligne par ligne.

## Concepteur d'applications

On glisse un composant depuis la palette — bouton, étiquette, champ de
texte, champ numérique, curseur, case à cocher, liste déroulante, axes,
table, panneau —, on le place, on règle ses propriétés, et « Produire le
code » écrit la fonction `.m` correspondante : `uifigure` puis les
constructeurs, avec les rappels en fonctions locales.

« Exécuter » va plus loin : le code est enregistré, lancé dans
l'interpréteur, et l'atelier dessine la fenêtre décrite par le registre
des composants. Les clics repartent vers l'interpréteur, qui déclenche les
rappels. C'est la même application que celle qu'on lancerait en ligne de
commande.

Les rappels s'écrivent naturellement avec des fonctions imbriquées, comme
dans MATLAB :

```matlab
function appCompteur()
    f = uifigure('Compteur', [300 160]);
    etiquette = uilabel(f, '0', [20 100 200 22]);
    bouton = uibutton(f, 'Incrementer', [20 40 140 28]);
    compteur = 0;
    bouton.Callback = @(source, evenement) incrementer();
    function incrementer()
        compteur = compteur + 1;
        etiquette.Text = sprintf('%d', compteur);
    end
end
```

## Éditeur de schémas-blocs

La palette donne les dix-sept blocs du solveur : sources (constante,
échelon, rampe, sinusoïde), opérateurs (gain, somme, produit, valeur
absolue, fonction), dynamique (intégrateur, dérivée, fonction de
transfert, espace d'état, retard), non-linéarités (saturation, relais) et
l'oscilloscope.

On glisse un bloc, on tire un fil d'une sortie vers une entrée, on règle
les paramètres dans le panneau de droite. « Produire le code » écrit le
modèle en appels `new_system`, `add_block` et `add_line` — le même modèle
qu'on écrirait à la main. « Simuler » l'exécute et ramène la courbe.

## Vérification

```bash
npm install playwright
make verifier-atelier
```

Un vrai navigateur pilote l'atelier et contrôle vingt-neuf points : la
somme d'un carré magique dans la console, le type et la taille dans
l'explorateur, la coloration, la figure en SVG, le compte d'appels du
profileur, le code produit par le concepteur, le fil tracé à la souris
dans l'éditeur de schémas, la courbe de simulation, l'application vivante
dont deux clics font passer l'étiquette à 2, et le débogueur qui s'arrête
ligne 3 avec `a = 5`, avance ligne 4, puis rend 7.

## Protocole

L'interface parle à l'interpréteur par HTTP. Les mêmes points d'entrée
servent à écrire un autre client.

| Route | Effet |
| --- | --- |
| `GET /api/version` | version de MatLibre |
| `POST /api/executer` | met du code dans la file d'exécution |
| `GET /api/etat` | sortie accumulée, état, variables, figures |
| `POST /api/debogueur` | `continuer`, `pas`, `entrer`, `sortir`, `quitter` |
| `POST /api/pointsarret` | `poser`, `retirer`, `tout` |
| `GET`/`POST /api/fichier` | lit, écrit un fichier |
| `GET /api/dossier` | contenu d'un dossier |
| `GET /api/figure` | une figure, en SVG |
| `GET /api/profil` | table du profileur |
| `GET /api/ui` | composants d'interface |
| `POST /api/ui/evenement` | déclenche un rappel |
| `GET /api/aide` | aide d'une fonction |
| `GET /api/fonctions` | tous les noms connus |
