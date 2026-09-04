function prix = lookbackbybls(courbe, actif, typeOption, exercice, reglement, echeance)
%LOOKBACKBYBLS Prix d'une option rétrospective, formule fermée.
%   P = LOOKBACKBYBLS(COURBE,ACTIF,TYPE,EXERCICE,REGLEMENT,ECHEANCE) rend
%   le prix d'une option dont le gain dépend de l'extremum atteint par le
%   cours pendant la vie de l'option.
%
%   EXERCICE valant NaN ou zéro demande une rétrospective à prix
%   d'exercice flottant : l'achat paie le cours final moins le plus bas
%   atteint, la vente le plus haut moins le cours final. Un prix
%   d'exercice donné demande la variante à prix fixe, où l'achat paie
%   l'excédent du plus haut sur ce prix.
%
%   Une rétrospective flottante ne peut pas finir sans valeur : son gain
%   est l'amplitude du parcours, toujours positive. C'est pourquoi elle
%   coûte plus cher qu'une option ordinaire.
%
%   Les formules sont celles de Goldman, Sosin et Gatto pour le prix
%   flottant, de Conze et Viswanathan pour le prix fixe. L'extremum
%   observé jusqu'ici est pris égal au cours du jour.
%
%   Exemple :
%      lookbackbybls(c, s, 'call', NaN, '01-Jan-2024', '01-Jan-2025')
%
%   Voir aussi BARRIERBYBLS, ASIANBYKV, OPTSTOCKBYBLS.
    if ischar(typeOption) || isstring(typeOption), typeOption = {char(typeOption)}; end
    exercice = double(exercice(:));
    echeance = matlibre_dates(echeance);
    echeance = echeance(:);
    nombre = max([numel(typeOption), numel(exercice), numel(echeance)]);
    prix = zeros(nombre, 1);
    for k = 1:nombre
        genre = lower(char(typeOption{min(k, numel(typeOption))}));
        K = exercice(min(k, numel(exercice)));
        fin = echeance(min(k, numel(echeance)));
        [S, r, T, sigma, q] = matlibre_bls_parametres(courbe, actif, reglement, fin);
        b = r - q;
        if isnan(K) || K == 0
            prix(k) = flottant(S, r, b, T, sigma, genre);
        else
            prix(k) = fixe(S, K, r, b, T, sigma, genre);
        end
    end
end

function valeur = flottant(S, r, b, T, sigma, genre)
    N = @(x) 0.5 * erfc(-x / sqrt(2));
    racine = sigma * sqrt(T);
    if abs(b) < 1e-10
        b = 1e-10;
    end
    % L'extremum observé vaut le cours du jour : le logarithme du rapport
    % s'annule, ce qui simplifie les arguments.
    a1 = (b + sigma ^ 2 / 2) * T / racine;
    a2 = a1 - racine;
    facteur = sigma ^ 2 / (2 * b);
    if strcmp(genre, 'put')
        valeur = S * exp(-r * T) * N(-a2) - S * exp((b - r) * T) * N(-a1) + ...
                 S * exp(-r * T) * facteur * (-N(a1 - 2 * b * sqrt(T) / sigma) + ...
                                              exp(b * T) * N(a1));
    else
        valeur = S * exp((b - r) * T) * N(a1) - S * exp(-r * T) * N(a2) + ...
                 S * exp(-r * T) * facteur * (N(-a1 + 2 * b * sqrt(T) / sigma) - ...
                                              exp(b * T) * N(-a1));
    end
end

function valeur = fixe(S, K, r, b, T, sigma, genre)
    N = @(x) 0.5 * erfc(-x / sqrt(2));
    racine = sigma * sqrt(T);
    if abs(b) < 1e-10
        b = 1e-10;
    end
    d1 = (log(S / K) + (b + sigma ^ 2 / 2) * T) / racine;
    d2 = d1 - racine;
    facteur = sigma ^ 2 / (2 * b);
    if strcmp(genre, 'put')
        valeur = K * exp(-r * T) * N(-d2) - S * exp((b - r) * T) * N(-d1) + ...
                 S * exp(-r * T) * facteur * ((S / K) ^ (-2 * b / sigma ^ 2) * ...
                     N(d1 - 2 * b * sqrt(T) / sigma) - exp(b * T) * N(d1));
    else
        valeur = S * exp((b - r) * T) * N(d1) - K * exp(-r * T) * N(d2) + ...
                 S * exp(-r * T) * facteur * (-(S / K) ^ (-2 * b / sigma ^ 2) * ...
                     N(d1 - 2 * b * sqrt(T) / sigma) + exp(b * T) * N(d1));
    end
end
