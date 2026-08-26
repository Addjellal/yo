function [courbes, grille] = plotmf(fis, genre, indice, resolution)
%PLOTMF Tracé des fonctions d'appartenance d'une variable.
%   PLOTMF(FIS,'input',I) trace, sur l'étendue de la variable, toutes ses
%   fonctions d'appartenance superposées. C'est le premier regard qu'on
%   porte sur un système flou : il montre si les modalités se recouvrent
%   assez pour que la sortie soit continue, et si elles couvrent bien
%   toute l'étendue.
%
%   [Y,X] = PLOTMF(...) rend les courbes au lieu de les tracer, une
%   colonne par fonction.
%
%   Exemple :
%      [y, x] = plotmf(fis, 'input', 1);
%      max(sum(y, 2))   % somme des appartenances au point le plus couvert
%
%   Voir aussi EVALMF, PLOTFIS, GENSURF.
    if nargin < 4 || isempty(resolution), resolution = 181; end
    entree = estEntree(genre);
    variables = variablesDe(fis, entree);
    if indice < 1 || indice > numel(variables)
        error('fuzzy:plotmf:BadVariable', 'Variable %d inexistante.', indice);
    end
    v = variables{indice};
    grille = linspace(v.intervalle(1), v.intervalle(2), resolution)';
    courbes = zeros(resolution, numel(v.mf));
    for j = 1:numel(v.mf)
        mf = v.mf{j};
        courbes(:, j) = reshape(evalmf(grille, mf.type, mf.parametres), [], 1);
    end
    if nargout == 0
        plot(grille, courbes);
        grid on;
        xlabel(v.nom);
        ylabel('Appartenance');
        title(sprintf('Fonctions d''appartenance de %s', v.nom));
        clear courbes grille
    end
end
