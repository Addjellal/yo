function prix = asianbylevy(courbe, actif, typeOption, exercice, reglement, echeance)
%ASIANBYLEVY Prix d'une option asiatique arithmétique, approximation de Levy.
%   P = ASIANBYLEVY(COURBE,ACTIF,TYPE,EXERCICE,REGLEMENT,ECHEANCE) rend
%   le prix d'une option sur la moyenne arithmétique du cours.
%
%   La moyenne arithmétique de lognormales n'est pas lognormale, et n'a
%   pas de loi commode. Levy propose de lui substituer la lognormale de
%   mêmes deux premiers moments, qui se calculent exactement ; l'erreur
%   est petite tant que la volatilité reste modérée.
%
%   Le prix est supérieur à celui de la moyenne géométrique, l'inégalité
%   des moyennes valant terme à terme.
%
%   Exemple :
%      asianbylevy(c, s, 'call', 100, '01-Jan-2024', '01-Jan-2025')
%
%   Voir aussi ASIANBYKV, LOOKBACKBYBLS, OPTSTOCKBYBLS.
    if ischar(typeOption) || isstring(typeOption), typeOption = {char(typeOption)}; end
    exercice = double(exercice(:));
    echeance = matlibre_dates(echeance);
    echeance = echeance(:);
    nombre = max([numel(typeOption), numel(exercice), numel(echeance)]);
    prix = zeros(nombre, 1);
    N = @(x) 0.5 * erfc(-x / sqrt(2));
    for k = 1:nombre
        genre = lower(char(typeOption{min(k, numel(typeOption))}));
        K = exercice(min(k, numel(exercice)));
        fin = echeance(min(k, numel(echeance)));
        [S, r, T, sigma, q] = matlibre_bls_parametres(courbe, actif, reglement, fin);
        b = r - q;
        if abs(b) < 1e-10
            b = 1e-10;
        end
        % Premier et second moments de la moyenne arithmétique.
        moyenne = S * (exp((b - r) * T) - exp(-r * T)) / (b * T);
        second = 2 * S ^ 2 / (b + sigma ^ 2) * ...
                 ((exp((2 * b + sigma ^ 2) * T) - 1) / (2 * b + sigma ^ 2) - ...
                  (exp(b * T) - 1) / b);
        D = second / T ^ 2;
        variance = log(D) - 2 * (r * T + log(moyenne));
        d1 = (log(D) / 2 - log(K)) / sqrt(variance);
        d2 = d1 - sqrt(variance);
        achat = moyenne * N(d1) - K * exp(-r * T) * N(d2);
        if strcmp(genre, 'put')
            % Parité : l'achat moins la vente vaut la valeur actuelle de
            % la moyenne moins celle du prix d'exercice.
            prix(k) = achat - moyenne + K * exp(-r * T);
        else
            prix(k) = achat;
        end
    end
end
