function matlibre_ui_appliquer(id, arguments)
%MATLIBRE_UI_APPLIQUER Pose des propriétés données par couples nom-valeur.
%   MATLIBRE_UI_APPLIQUER(ID,ARGUMENTS) applique au composant les couples
%   contenus dans la cellule ARGUMENTS.
%
%   C'est ce qui permet aux constructeurs d'accepter la forme de MATLAB —
%   UILABEL(f,'Text','Salut','Position',p) — en plus de la forme
%   positionnelle plus courte.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Voir aussi UIFIGURE, UILABEL, UIBUTTON, MATLIBRE_UI_POSER.
    if isempty(arguments)
        return
    end
    if mod(numel(arguments), 2) ~= 0
        error('MATLAB:ui:Paire', ...
              'Les propriétés se donnent par couples nom-valeur.');
    end
    for k = 1:2:numel(arguments)
        nom = char(arguments{k});
        if isempty(nom) || ~ischar(nom)
            error('MATLAB:ui:Nom', 'Un nom de propriété est attendu.');
        end
        matlibre_ui_poser(id, nom, arguments{k + 1});
    end
end
