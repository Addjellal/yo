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

  Propriétés lisibles et modifiables : Text, Value, Position, Items,
  Limits, Enable, Visible, Callback. Type et Parent sont en lecture
  seule.

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

## `uiaxes`

```
UIAXES Zone de tracé dans une application.
  Le tracé se fait avec les fonctions graphiques ordinaires ; l'interface
  affiche la figure courante dans la zone réservée.
```

## `uibutton`

```
UIBUTTON Bouton poussoir.
  B = UIBUTTON(PARENT,TEXTE,[X Y L H]) pose un bouton.
  B = UIBUTTON(...,RAPPEL) lui donne son rappel, appelé avec (source,
  evenement) comme dans MATLAB.
```

## `uicheckbox`

```
UICHECKBOX Case à cocher.
```

## `uidropdown`

```
UIDROPDOWN Liste déroulante.
  H = UIDROPDOWN(PARENT,{'un','deux'},[X Y L H]) ; Value est le texte
  choisi, comme dans MATLAB.
```

## `uieditfield`

```
UIEDITFIELD Champ de saisie, textuel ou numérique.
  H = UIEDITFIELD(PARENT,VALEUR,[X Y L H]) crée un champ de texte.
  H = UIEDITFIELD(...,'numeric') crée un champ numérique : Value est
  alors un nombre.
```

## `uifigure`

```
UIFIGURE Fenêtre d'application.
  F = UIFIGURE(TITRE,[LARGEUR HAUTEUR]) crée la fenêtre et rend sa
  poignée. Les composants s'y posent ensuite avec UIBUTTON, UILABEL…

  Exemple :
     f = uifigure('Convertisseur', [320 200]);
```

## `uilabel`

```
UILABEL Étiquette de texte.
```

## `uipanel`

```
UIPANEL Panneau, qui regroupe d'autres composants.
```

## `uiresume`

```
UIRESUME Reprend après UIWAIT. Sans effet ici : UIWAIT ne bloque pas.
```

## `uislider`

```
UISLIDER Curseur.
  H = UISLIDER(PARENT,[MIN MAX],VALEUR,[X Y L H]).
```

## `uitable`

```
UITABLE Table de valeurs.
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

