function prix = assetbybls(courbe, actif, reglement, echeance, typeOption, exercice)
%ASSETBYBLS Prix d'une option binaire en actif.
%   P = ASSETBYBLS(COURBE,ACTIF,REGLEMENT,ECHEANCE,TYPE,EXERCICE) rend le
%   prix d'une option qui livre l'actif si elle finit dans la monnaie, et
%   rien sinon.
%
%   Une option d'achat ordinaire est une option en actif moins le prix
%   d'exercice fois une option en espèces de versement un : c'est
%   exactement la décomposition de la formule de Black et Scholes en ses
%   deux termes.
%
%   Exemple :
%      assetbybls(c, s, '01-Jan-2024', '01-Jan-2025', 'call', 100)
%
%   Voir aussi CASHBYBLS, GAPBYBLS, SUPERSHAREBYBLS.
    N = @(x) 0.5 * erfc(-x / sqrt(2));
    if ischar(typeOption) || isstring(typeOption), typeOption = {char(typeOption)}; end
    exercice = double(exercice(:));
    nombre = max([numel(typeOption), numel(exercice)]);
    prix = zeros(nombre, 1);
    for k = 1:nombre
        genre = lower(char(typeOption{min(k, numel(typeOption))}));
        K = exercice(min(k, numel(exercice)));
        [S, r, T, sigma, q] = matlibre_bls_parametres(courbe, actif, reglement, echeance);
        b = r - q;
        d1 = (log(S / K) + (b + sigma ^ 2 / 2) * T) / (sigma * sqrt(T));
        if strcmp(genre, 'put')
            prix(k) = S * exp((b - r) * T) * N(-d1);
        else
            prix(k) = S * exp((b - r) * T) * N(d1);
        end
    end
end
