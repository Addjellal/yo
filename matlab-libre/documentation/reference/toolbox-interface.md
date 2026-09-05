# Toolbox `interface`

```
% Interface — construction d'applications à fenêtres.
%
% Une application décrit son interface en appelant uifigure puis les
% constructeurs de composants. Chaque composant vit dans le registre de
% l'interpréteur ; une interface le dessine et renvoie les
% événements, qui déclenchent les rappels. Sans interface, le registre reste
% consultable et les rappels se déclenchent à la main : une application est
% donc testable en ligne de commande.
%
%   uifigure     - Fenêtre d'application
%   uibutton     - Bouton poussoir
%   uilabel      - Étiquette de texte
%   uieditfield  - Champ de saisie, textuel ou numérique
%   uislider     - Curseur
%   uicheckbox   - Case à cocher
%   uidropdown   - Liste déroulante
%   uiaxes       - Zone de tracé
%   uitable      - Table de valeurs
%   uipanel      - Panneau
%   uiwait       - Attente (sans effet hors interface)
%   uiresume     - Reprise
%   closeApp     - Ferme une fenêtre et ses composants
%   UIComposant  - Poignée vers un composant
```

## `UIComposant`

```
UICOMPOSANT Poignée vers un composant d'interface.
  Un composant vit dans le registre de l'interpréteur ; cet objet n'en
  porte que le numéro. La sémantique est donc celle de MATLAB : deux
  copies de la poignée désignent le même bouton, et modifier l'une se
  voit dans l'autre.

  Propriétés lisibles et modifiables : Text, Name, Title, Value,
  Position, Items, Limits, Enable, Visible, Callback,
  ButtonPushedFcn, ValueChangedFcn, Data, ColumnName. Type, Parent et
  Children sont en lecture seule.

  Name, Title et Text désignent le même texte : c'est le nom qu'en
  donne MATLAB selon le composant — Name pour une fenêtre, Title pour
  un panneau, Text pour le reste.

  Poser une valeur hors des limites d'un curseur, ou hors des éléments
  d'une liste, lève une erreur : un composant borné n'accepte pas ce
  qu'il ne peut pas montrer.

  Exemple :
     f = uifigure('Essai', [300 200]);
     b = uibutton(f, 'Cliquer', [20 20 100 30]);
     b.Text = 'Encore';
     b.Callback = @(source, evenement) disp('clic');

  Voir aussi UIFIGURE, UIBUTTON, UILABEL, UISLIDER, UIDROPDOWN.
```

## `closeApp`

```
CLOSEAPP Ferme une fenêtre d'application et tous ses composants.
```

## `identifiantParent`

```
IDENTIFIANTPARENT Numéro du composant parent, quelle qu'en soit la forme.
  Accepte une poignée UIComposant, un numéro, ou rien : la fenêtre
  courante sert alors de parent.
```

## `matlibre_ui_appliquer`

```
MATLIBRE_UI_APPLIQUER Pose des propriétés données par couples nom-valeur.
  MATLIBRE_UI_APPLIQUER(ID,ARGUMENTS) applique au composant les couples
  contenus dans la cellule ARGUMENTS.

  C'est ce qui permet aux constructeurs d'accepter la forme de MATLAB —
  UILABEL(f,'Text','Salut','Position',p) — en plus de la forme
  positionnelle plus courte.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Voir aussi UIFIGURE, UILABEL, UIBUTTON, MATLIBRE_UI_POSER.
```

## `matlibre_ui_nomme`

```
MATLIBRE_UI_NOMME Les arguments sont-ils des couples nom-valeur ?
  Un constructeur d'interface accepte deux écritures : la forme
  positionnelle de MatLibre, plus courte, et la forme nom-valeur de
  MATLAB. On les distingue au premier argument : un nom de propriété
  connu ouvre la seconde.

  Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.

  Voir aussi MATLIBRE_UI_APPLIQUER.
```

## `uiaxes`

```
UIAXES Axes de tracé dans une fenêtre d'application.
  H = UIAXES(PARENT,'Position',P) pose des axes.
  H = UIAXES(PARENT,POSITION) est la forme courte.

  Ce composant réserve la place des axes dans la fenêtre et la décrit
  au registre d'interface. Le tracé lui-même passe par le moteur
  graphique, qui est un système distinct dans MatLibre : PLOT dessine
  donc dans la figure graphique courante, non dans ce composant. La
  place est réservée, le dessin ne s'y rend pas encore.

  Exemples :
     f = uifigure;
     a = uiaxes(f, 'Position', [20 20 300 200]);
     a.Position

  Voir aussi UIFIGURE, UIPANEL, PLOT.
```

## `uibutton`

```
UIBUTTON Bouton qui déclenche une action.
  H = UIBUTTON(PARENT,'Text',TEXTE,'ButtonPushedFcn',F) pose un bouton
  et son rappel.
  H = UIBUTTON(PARENT,TEXTE,POSITION,RAPPEL) est la forme courte.

  Le rappel reçoit deux arguments, la source et l'événement, comme dans
  MATLAB : c'est ce qui permet à une même fonction de servir plusieurs
  boutons, en lisant la source pour savoir lequel a été pressé.

  Exemples :
     f = uifigure;
     b = uibutton(f, 'Text', 'Appliquer', 'Position', [20 20 100 30], ...
                  'ButtonPushedFcn', @(s, e) disp('clic'));
     declencher(b);

  Voir aussi UIFIGURE, UILABEL, UISLIDER, UICHECKBOX.
```

## `uicheckbox`

```
UICHECKBOX Case à cocher.
  H = UICHECKBOX(PARENT,'Text',TEXTE,'Value',V) pose une case.
  H = UICHECKBOX(PARENT,TEXTE,VALEUR,POSITION) est la forme courte.

  Sa valeur est un booléen : vraie quand la case est cochée.

  Exemples :
     f = uifigure;
     c = uicheckbox(f, 'Text', 'Actif', 'Value', true);
     c.Value

  Voir aussi UIFIGURE, UIDROPDOWN, UISLIDER.
```

## `uidropdown`

```
UIDROPDOWN Liste déroulante.
  H = UIDROPDOWN(PARENT,'Items',LISTE,'Value',V) pose une liste.
  H = UIDROPDOWN(PARENT,ITEMS,POSITION,VALEUR) est la forme courte.

  La valeur d'une liste est l'un de ses éléments : lui en donner un
  autre lève une erreur. C'est ce qui garantit qu'une application ne se
  retrouve jamais devant un choix qu'elle n'a pas prévu.

  Exemples :
     f = uifigure;
     d = uidropdown(f, 'Items', {'sinus', 'carre'}, 'Value', 'carre');
     d.Value

  Voir aussi UIFIGURE, UICHECKBOX, UISLIDER.
```

## `uieditfield`

```
UIEDITFIELD Champ de saisie.
  H = UIEDITFIELD(PARENT,GENRE,'Value',V) où GENRE vaut 'text' ou
  'numeric'.
  H = UIEDITFIELD(PARENT,VALEUR,POSITION,GENRE) est la forme courte.

  Un champ numérique n'accepte que des nombres : le genre décide, et
  un texte donné à un champ numérique est converti. Un texte qui ne
  désigne aucun nombre est refusé.

  Exemples :
     f = uifigure;
     e = uieditfield(f, 'numeric', 'Value', 1.5);
     e.Value

  Voir aussi UIFIGURE, UISLIDER, UILABEL.
```

## `uifigure`

```
UIFIGURE Fenêtre d'application.
  F = UIFIGURE crée une fenêtre par défaut.
  F = UIFIGURE('Name',NOM,'Position',[X Y L H],...) la règle par
  couples nom-valeur, comme dans MATLAB.
  F = UIFIGURE(TITRE,[LARGEUR HAUTEUR]) est la forme courte de
  MatLibre : le titre puis la taille.

  Les composants s'y posent ensuite avec UIBUTTON, UILABEL, UISLIDER…
  La fenêtre est leur parent, et la fermer les emporte.

  Exemples :
     f = uifigure('Name', 'Convertisseur', 'Position', [100 100 320 200]);
     f = uifigure('Convertisseur', [320 200]);

  Voir aussi UIBUTTON, UILABEL, UISLIDER, UIPANEL, CLOSEAPP.
```

## `uilabel`

```
UILABEL Étiquette de texte.
  H = UILABEL(PARENT,'Text',TEXTE,'Position',P) pose une étiquette.
  H = UILABEL(PARENT,TEXTE,POSITION) est la forme courte.

  Une étiquette ne réagit à rien : elle nomme ce qui est à côté. C'est
  le seul composant qui n'a ni valeur ni rappel.

  Exemples :
     f = uifigure;
     uilabel(f, 'Text', 'Amplitude', 'Position', [20 100 100 22]);
     uilabel(f, 'Amplitude', [20 100 100 22]);

  Voir aussi UIFIGURE, UIBUTTON, UIEDITFIELD.
```

## `uipanel`

```
UIPANEL Panneau qui groupe des composants.
  H = UIPANEL(PARENT,'Title',TITRE,'Position',P) pose un panneau.
  H = UIPANEL(PARENT,TITRE,POSITION) est la forme courte.

  Un panneau devient le parent de ce qu'on y pose : le déplacer déplace
  tout son contenu, et le fermer l'emporte.

  Exemples :
     f = uifigure;
     p = uipanel(f, 'Title', 'Options', 'Position', [20 20 200 150]);
     uicheckbox(p, 'Text', 'Journaliser');
     numel(p.Children)

  Voir aussi UIFIGURE, UITABLE, UIAXES.
```

## `uiresume`

```
UIRESUME Reprend après UIWAIT. Sans effet ici : UIWAIT ne bloque pas.
```

## `uislider`

```
UISLIDER Curseur.
  H = UISLIDER(PARENT,'Limits',[MIN MAX],'Value',V) pose un curseur.
  H = UISLIDER(PARENT,LIMITES,VALEUR,POSITION) est la forme courte.

  Un curseur borne sa valeur : lui en donner une hors des limites lève
  une erreur au lieu de l'accepter. C'est ce qui le distingue d'une
  simple variable, et ce qui rend inutile de vérifier après coup.

  Exemples :
     f = uifigure;
     s = uislider(f, 'Limits', [0 10], 'Value', 3);
     s.Value = 7;

  Voir aussi UIFIGURE, UIEDITFIELD, UICHECKBOX.
```

## `uitable`

```
UITABLE Tableau de données.
  H = UITABLE(PARENT,'Data',D,'ColumnName',N) pose un tableau.
  H = UITABLE(PARENT,DONNEES,POSITION) est la forme courte.

  Les données se remplacent d'un bloc : écrire dans H.Data change tout
  le tableau, ce qui évite d'avoir à suivre chaque case.

  Exemples :
     f = uifigure;
     t = uitable(f, 'Data', magic(4), 'ColumnName', {'a','b','c','d'});
     t.Data(1, 1)

  Voir aussi UIFIGURE, UIPANEL, UIAXES.
```

## `uiwait`

```
UIWAIT Attend la fermeture d'une fenêtre.
  L'interface vit dans le registre de composants, et les rappels
  s'exécutent au fur et à mesure : UIWAIT rend donc la main
  immédiatement, sans quoi l'interpréteur ne pourrait plus traiter les
  événements. La fonction existe pour que le code écrit pour MATLAB
  s'exécute sans retouche.
```

