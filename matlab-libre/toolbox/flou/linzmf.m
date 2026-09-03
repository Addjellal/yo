function y = linzmf(x, params)
%LINZMF Fonction d'appartenance en Z linéaire.
%   Y = LINZMF(X,[A B]) descend en ligne droite de un en A à zéro en B,
%   et reste à un avant et à zéro après.
%
%   C'est le complément de LINSMF sur le même intervalle : la somme des
%   deux vaut un partout.
%
%   Exemple :
%      linzmf([0 2 5 8 10], [2 8])   % [1 1 0.5 0 0]
%
%   Voir aussi LINSMF, ZMF, SMF, TRIMF, EVALMF.
    if numel(params) < 2
        error('fuzzy:linzmf:Parametres', 'LINZMF demande deux paramètres.');
    end
    y = 1 - linsmf(x, params);
end
