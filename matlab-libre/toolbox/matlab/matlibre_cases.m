function [lignes, colonnes, courante] = matlibre_cases(nouvellesLignes, ...
                                                       nouvellesColonnes, nouvelleCase)
%MATLIBRE_CASES Le découpage courant de TILEDLAYOUT.
%   [L,C,K] = MATLIBRE_CASES() rend le découpage préparé et la dernière
%   case remplie. MATLIBRE_CASES(L,C,K) les pose.
%
%   L'état est gardé par figure : passer d'une figure à l'autre ne mélange
%   pas les découpages.
%
%   Cette fonction est un utilitaire interne : elle n'existe pas dans
%   MATLAB.
%
%   Exemple :
%      figure; matlibre_cases(2, 2, 0);
%      [l, c, k] = matlibre_cases();     % 2  2  0
%
%   Voir aussi TILEDLAYOUT, NEXTTILE, SUBPLOT.
    persistent memoire
    if isempty(memoire)
        memoire = containers.Map();
    end
    cle = sprintf('f%d', get(gcf, 'Number'));
    if nargin >= 3
        memoire(cle) = [nouvellesLignes, nouvellesColonnes, nouvelleCase];
    end
    if isKey(memoire, cle)
        valeurs = memoire(cle);
    else
        valeurs = [1 1 0];
    end
    lignes = valeurs(1);
    colonnes = valeurs(2);
    courante = valeurs(3);
end
