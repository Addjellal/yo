function prix = gapbybls(courbe, actif, reglement, echeance, typeOption, seuil, versement)
%GAPBYBLS Prix d'une option à saut.
%   P = GAPBYBLS(COURBE,ACTIF,REGLEMENT,ECHEANCE,TYPE,SEUIL,VERSEMENT)
%   rend le prix d'une option qui s'exerce au-delà du SEUIL mais paie
%   l'écart au VERSEMENT : le gain saute au moment de l'exercice, d'où le
%   nom.
%
%   Quand le seuil et le versement coïncident, l'option redevient
%   ordinaire.
%
%   Exemple :
%      gapbybls(c, s, '01-Jan-2024', '01-Jan-2025', 'call', 100, 95)
%
%   Voir aussi CASHBYBLS, ASSETBYBLS, SUPERSHAREBYBLS, OPTSTOCKBYBLS.
    N = @(x) 0.5 * erfc(-x / sqrt(2));
    if ischar(typeOption) || isstring(typeOption), typeOption = {char(typeOption)}; end
    seuil = double(seuil(:));
    versement = double(versement(:));
    nombre = max([numel(typeOption), numel(seuil), numel(versement)]);
    prix = zeros(nombre, 1);
    for k = 1:nombre
        genre = lower(char(typeOption{min(k, numel(typeOption))}));
        K1 = seuil(min(k, numel(seuil)));
        K2 = versement(min(k, numel(versement)));
        [S, r, T, sigma, q] = matlibre_bls_parametres(courbe, actif, reglement, echeance);
        b = r - q;
        racine = sigma * sqrt(T);
        d1 = (log(S / K1) + (b + sigma ^ 2 / 2) * T) / racine;
        d2 = d1 - racine;
        if strcmp(genre, 'put')
            prix(k) = K2 * exp(-r * T) * N(-d2) - S * exp((b - r) * T) * N(-d1);
        else
            prix(k) = S * exp((b - r) * T) * N(d1) - K2 * exp(-r * T) * N(d2);
        end
    end
end
