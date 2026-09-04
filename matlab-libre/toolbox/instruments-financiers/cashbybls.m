function prix = cashbybls(courbe, actif, reglement, echeance, typeOption, exercice, versement)
%CASHBYBLS Prix d'une option binaire en espèces.
%   P = CASHBYBLS(COURBE,ACTIF,REGLEMENT,ECHEANCE,TYPE,EXERCICE,
%   VERSEMENT) rend le prix d'une option qui verse une somme fixe si elle
%   finit dans la monnaie, et rien sinon.
%
%   Son prix est la valeur actuelle du versement multipliée par la
%   probabilité risque-neutre de finir dans la monnaie : c'est la lecture
%   la plus directe de ce que le second terme de Black et Scholes
%   signifie.
%
%   Exemple :
%      cashbybls(c, s, '01-Jan-2024', '01-Jan-2025', 'call', 100, 10)
%
%   Voir aussi ASSETBYBLS, GAPBYBLS, SUPERSHAREBYBLS.
    N = @(x) 0.5 * erfc(-x / sqrt(2));
    if ischar(typeOption) || isstring(typeOption), typeOption = {char(typeOption)}; end
    exercice = double(exercice(:));
    if nargin < 7 || isempty(versement), versement = 1; end
    versement = double(versement(:));
    nombre = max([numel(typeOption), numel(exercice), numel(versement)]);
    prix = zeros(nombre, 1);
    for k = 1:nombre
        genre = lower(char(typeOption{min(k, numel(typeOption))}));
        K = exercice(min(k, numel(exercice)));
        Q = versement(min(k, numel(versement)));
        [S, r, T, sigma, q] = matlibre_bls_parametres(courbe, actif, reglement, echeance);
        b = r - q;
        d2 = (log(S / K) + (b - sigma ^ 2 / 2) * T) / (sigma * sqrt(T));
        if strcmp(genre, 'put')
            prix(k) = Q * exp(-r * T) * N(-d2);
        else
            prix(k) = Q * exp(-r * T) * N(d2);
        end
    end
end
