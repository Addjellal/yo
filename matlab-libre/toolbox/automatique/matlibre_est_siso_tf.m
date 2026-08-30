function r = matlibre_est_siso_tf(x)
%MATLIBRE_EST_SISO_TF Vrai si l'objet se met en polynômes sans perte.
%   Les interconnexions gardent la forme polynomiale tant que tout est
%   monovariable : le résultat s'écrit alors comme dans un cours, en
%   numérateur sur dénominateur. Dès qu'un modèle d'état à plusieurs
%   voies entre en jeu, le calcul passe dans l'espace d'état.
%
%   Cette fonction est un utilitaire interne de la boîte à outils
%   Automatique : elle n'existe pas dans MATLAB.
%
%   Voir aussi FEEDBACK, SERIES, PARALLEL.
    if isnumeric(x)
        r = isscalar(x);
    elseif isa(x, 'tf') || isa(x, 'zpk')
        r = true;
    elseif isa(x, 'ss')
        r = isequal(size(x), [1 1]);
    else
        r = false;
    end
end
