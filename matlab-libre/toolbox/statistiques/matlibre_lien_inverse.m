function mu = matlibre_lien_inverse(eta, lien)
%MATLIBRE_LIEN_INVERSE Réciproque d'une fonction de lien.
%   Le lien transforme la moyenne en prédicteur linéaire ; sa réciproque
%   ramène une prédiction linéaire sur l'échelle de la réponse.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    switch lower(char(lien))
        case {'identity', 'normal'},   mu = eta;
        case {'log', 'poisson'},       mu = exp(eta);
        case {'logit', 'binomial'},    mu = 1 ./ (1 + exp(-eta));
        case 'probit',                 mu = normcdf(eta);
        case 'loglog',                 mu = exp(-exp(eta));
        case 'comploglog',             mu = 1 - exp(-exp(eta));
        case {'reciprocal', 'gamma'},  mu = 1 ./ eta;
        otherwise
            error('stats:lien:Inconnu', 'Fonction de lien inconnue : %s.', char(lien));
    end
end
