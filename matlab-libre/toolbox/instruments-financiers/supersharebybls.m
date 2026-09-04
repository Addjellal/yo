function prix = supersharebybls(courbe, actif, reglement, echeance, borneBasse, borneHaute)
%SUPERSHAREBYBLS Prix d'une superaction.
%   P = SUPERSHAREBYBLS(COURBE,ACTIF,REGLEMENT,ECHEANCE,BASSE,HAUTE) rend
%   le prix d'un titre qui livre une part de l'actif si le cours final
%   tombe entre les deux bornes, et rien sinon.
%
%   C'est la brique élémentaire de la théorie des marchés complets : avec
%   assez de superactions on reproduit n'importe quel gain, comme on
%   reproduit une fonction par des indicatrices.
%
%   Exemple :
%      supersharebybls(c, s, '01-Jan-2024', '01-Jan-2025', 90, 110)
%
%   Voir aussi CASHBYBLS, ASSETBYBLS, GAPBYBLS.
    N = @(x) 0.5 * erfc(-x / sqrt(2));
    borneBasse = double(borneBasse(:));
    borneHaute = double(borneHaute(:));
    nombre = max(numel(borneBasse), numel(borneHaute));
    prix = zeros(nombre, 1);
    for k = 1:nombre
        KL = borneBasse(min(k, numel(borneBasse)));
        KH = borneHaute(min(k, numel(borneHaute)));
        [S, r, T, sigma, q] = matlibre_bls_parametres(courbe, actif, reglement, echeance);
        b = r - q;
        racine = sigma * sqrt(T);
        d1 = (log(S / KL) + (b + sigma ^ 2 / 2) * T) / racine;
        d2 = (log(S / KH) + (b + sigma ^ 2 / 2) * T) / racine;
        prix(k) = S * exp((b - r) * T) / KL * (N(d1) - N(d2));
    end
end
