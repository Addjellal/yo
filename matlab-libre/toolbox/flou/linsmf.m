function y = linsmf(x, params)
%LINSMF Fonction d'appartenance en S linéaire.
%   Y = LINSMF(X,[A B]) monte en ligne droite de zéro en A à un en B, et
%   reste à zéro avant et à un après. Si B est plus petit que A, la
%   courbe descend au lieu de monter.
%
%   C'est la plus simple des courbes croissantes : là où SMF adoucit les
%   deux coudes, celle-ci les garde nets, ce qui rend la règle plus
%   facile à lire.
%
%   Exemple :
%      linsmf([0 2 5 8 10], [2 8])   % [0 0 0.5 1 1]
%
%   Voir aussi LINZMF, SMF, ZMF, TRIMF, EVALMF.
    if numel(params) < 2
        error('fuzzy:linsmf:Parametres', 'LINSMF demande deux paramètres.');
    end
    a = params(1);
    b = params(2);
    x = double(x);
    if a == b
        y = double(x >= a);
        return
    end
    y = (x - a) / (b - a);
    y = min(max(y, 0), 1);
end
