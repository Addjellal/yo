function nom = matlibre_sl_nouveau(varargin)
%MATLIBRE_SL_NOUVEAU Pose un modèle vide dans l'espace de travail.
%   MATLIBRE_SL_NOUVEAU pose dans l'espace de travail de base un modèle
%   neuf et vide, nommé comme Simulink nomme les siens : « untitled »,
%   puis « untitled1 », « untitled2 »..., le premier nom qu'aucune
%   variable ne porte encore. Rien n'est écrasé.
%   MATLIBRE_SL_NOUVEAU(TYPE, NOM, ...) y pose aussitôt un premier bloc,
%   les arguments étant ceux d'ADD_BLOCK après le modèle.
%   NOM = MATLIBRE_SL_NOUVEAU(...) rend le nom choisi.
%
%   C'est ce que fait l'éditeur Simulink du bureau : « Nouveau modèle »
%   ouvre un modèle vide sur la feuille, et un bloc déposé quand aucun
%   modèle n'est ouvert en ouvre un qui le porte. Le modèle est une
%   variable comme une autre : la console, l'explorateur de variables et
%   l'éditeur le voient.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      nom = matlibre_sl_nouveau('gain', 'k', 'Gain', 2);
%      m = evalin('base', nom);
%      numel(m.blocs)                          % 1 : le bloc déposé
%      evalin('base', ['clear ' nom]);
%
%   Voir aussi NEW_SYSTEM, ADD_BLOCK, MATLIBRE_SL_CHARGER.
    existants = evalin('base', 'who');
    nom = 'untitled';
    k = 0;
    while any(strcmp(existants, nom))
        k = k + 1;
        nom = sprintf('untitled%d', k);
    end
    modele = new_system(nom);
    if nargin > 0
        modele = add_block(modele, varargin{:});
    end
    % Un modèle de même nom a pu vivre et mourir dans la session : ses
    % états passés ne sont pas ceux de celui-ci.
    matlibre_sl_pile('vider', modele);
    assignin('base', nom, modele);
    if nargout == 0
        clear nom
    end
end
