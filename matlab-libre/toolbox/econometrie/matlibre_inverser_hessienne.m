function covariance = matlibre_inverser_hessienne(H)
%MATLIBRE_INVERSER_HESSIENNE Covariance tirée d'une hessienne numérique.
%   Une hessienne calculée par différences finies peut n'être ni définie
%   ni même inversible ; on rend alors une matrice de NaN plutôt qu'un
%   résultat faux.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    n = size(H, 1);
    if n == 0
        covariance = zeros(0, 0);
        return
    end
    H = (H + H.') / 2;
    if any(~isfinite(H(:))) || rcond(H) < 1e-14
        covariance = nan(n);
        return
    end
    covariance = inv(H);
end
