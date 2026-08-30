## Ce qui manque au-delà des fonctions

Le tableau ci-dessus compte des noms. Ce qui suit compte davantage : ce
sont les manques de structure, ceux qu'aucune fonction ajoutée ne
comblerait. Ils sont classés par ce qu'ils coûtent à l'utilisateur.

### Formats de fichiers

- **MAT niveau 7.3**. C'est un fichier HDF5, non le format MAT. Il est
  reconnu et l'erreur dit quoi faire — réenregistrer en `-v7` —, mais il
  n'est pas lu. Le lire demanderait un lecteur HDF5 complet.
- **Objets MCOS dans un fichier MAT**. Un `ss`, un `tf`, une `table`
  sauvés par MATLAB sont rangés dans une forme opaque qui renvoie à un
  sous-système du fichier. MatLibre lit la forme, nomme la variable et
  dit ce qu'il n'a pas su reconstruire, mais ne rebâtit pas l'objet.
- **Figures `.fig`**. Ce sont des fichiers MAT portant le modèle d'objets
  graphiques de MathWorks, que MatLibre n'a pas.
- **Modèles Simulink `.slx`**. `sim` existe pour les modèles écrits en
  MatLibre ; le format de MathWorks, non.
- **Scripts vivants `.mlx`**. Le format est une archive OPC ; l'éditeur
  ne les ouvre pas.

### Langage

- **Dossiers `private/`** : les fonctions privées d'un dossier ne sont pas
  reconnues comme telles.
- **Dossiers de paquet `+nom/`** : la notation `paquet.fonction` marche
  pour ce qui est enregistré sous ce nom, non par découverte de dossier.
- **Classes poignées** (`handle`), événements et écouteurs (`events`,
  `addlistener`, `notify`).
- **Énumérations** (`enumeration`) dans un `classdef`.
- **`matlab.unittest`** : le cadre de tests à classes. Les tests de
  MatLibre sont des scripts à `assert`.
- **Interfaces externes** : MEX, appel de Java, de Python, de C++.

### Bureau

- **App Designer et GUIDE** : la construction d'interfaces. `uicontrol`
  et `uifigure` n'existent pas.
- **Éditeur de variables** : le tableau des variables se lit, il ne
  s'édite pas au clavier comme celui de MATLAB.
- **Outils interactifs des figures** : zoom à la souris, curseur de
  données, brosse, rotation 3D.
- **Comparaison de fichiers** (`visdiff`), **analyse de code**
  (`checkcode`, l'analyseur qui souligne dans l'éditeur).

### Graphique

- **Rendu 3D avec éclairage** : `light`, `material`, `lighting`, et les
  surfaces qui en dépendent.
- **Objets graphiques de bas niveau** : `line`, `patch`, `rectangle`,
  `annotation`, et le modèle de poignées complet qui va avec.
- **`tiledlayout` / `nexttile`**, la disposition qui remplace `subplot`
  depuis R2019b.
- **Axes polaires**, `polarplot`, `compass`, `rose`.

### Calcul

- **Décomposition de Schur** (`schur`, `ordschur`, `qz`) : elle manque à
  l'algèbre linéaire, et les solveurs de Riccati doivent s'en passer.
- **Matrices creuses** : elles existent, mais les factorisations creuses
  (`chol`, `lu`, `qr` creux) travaillent en dense.
- **Précision variable** (`vpa`) et calcul symbolique complet : la boîte
  Symbolique couvre le dérivé, l'intégré simple et la résolution
  polynomiale, non l'algèbre générale.
