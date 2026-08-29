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
