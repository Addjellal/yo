function [premiere, seconde] = matlibre_deriver_ajustement(ajustement, x)
%MATLIBRE_DERIVER_AJUSTEMENT Dérivées d'une courbe ajustée.
%   [D1,D2] = MATLIBRE_DERIVER_AJUSTEMENT(FO,X) rend la dérivée première
%   et la dérivée seconde. Une spline est dérivée exactement, morceau par
%   morceau ; un modèle écrit en formule l'est par différences centrées,
%   dont le pas est pris proportionnel à l'étendue des abscisses.
%
%   Exemple :
%      fo = fit((1:10)', (1:10)'.^2, 'poly2');
%      matlibre_deriver_ajustement(fo, 3)      % environ 6
%
%   Voir aussi DIFFERENTIATE, INTEGRATE.
    x = double(x);
    forme = size(x);
    colonne = x(:);
    if ~isempty(ajustement.Interpolant) && strcmp(ajustement.Interpolant.genre, 'pp')
        xa = (colonne - ajustement.Normalisation(1)) / ajustement.Normalisation(2);
        pp = ajustement.Interpolant.pp;
        premiere = ppval(fnder(pp), xa) / ajustement.Normalisation(2);
        seconde = ppval(fnder(pp, 2), xa) / ajustement.Normalisation(2) ^ 2;
        premiere = reshape(premiere, forme);
        seconde = reshape(seconde, forme);
        return
    end
    etendue = max(abs(colonne));
    if etendue == 0
        etendue = 1;
    end
    pas = etendue * 1e-5;
    haut = feval(ajustement, colonne + pas);
    bas = feval(ajustement, colonne - pas);
    milieu = feval(ajustement, colonne);
    premiere = reshape((haut - bas) / (2 * pas), forme);
    seconde = reshape((haut - 2 * milieu + bas) / pas ^ 2, forme);
end
