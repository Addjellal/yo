function prix = chooserbybls(courbe, actif, reglement, echeance, exercice, dateChoix)
%CHOOSERBYBLS Prix d'une option au choix.
%   P = CHOOSERBYBLS(COURBE,ACTIF,REGLEMENT,ECHEANCE,EXERCICE,DATECHOIX)
%   rend le prix d'une option dont le détenteur choisit, à la date
%   indiquée, si elle sera un achat ou une vente.
%
%   Elle coûte moins qu'un achat plus une vente, et plus que le plus cher
%   des deux : choisir plus tard vaut mieux que choisir maintenant, mais
%   moins bien que garder les deux. Quand la date du choix rejoint
%   l'échéance, le prix rejoint celui du couple.
%
%   La formule est celle de Rubinstein.
%
%   Exemple :
%      chooserbybls(c, s, '01-Jan-2024', '01-Jan-2025', 100, '01-Jul-2024')
%
%   Voir aussi OPTSTOCKBYBLS, BARRIERBYBLS.
    N = @(x) 0.5 * erfc(-x / sqrt(2));
    exercice = double(exercice(:));
    dateChoix = matlibre_dates(dateChoix);
    dateChoix = dateChoix(:);
    nombre = max(numel(exercice), numel(dateChoix));
    prix = zeros(nombre, 1);
    for k = 1:nombre
        K = exercice(min(k, numel(exercice)));
        choix = dateChoix(min(k, numel(dateChoix)));
        [S, r, T2, sigma, q] = matlibre_bls_parametres(courbe, actif, reglement, echeance);
        T1 = yearfrac(reglement, choix, courbe.Basis);
        b = r - q;
        d = (log(S / K) + (b + sigma ^ 2 / 2) * T2) / (sigma * sqrt(T2));
        y = (log(S / K) + b * T2 + sigma ^ 2 * T1 / 2) / (sigma * sqrt(T1));
        prix(k) = S * exp((b - r) * T2) * N(d) - K * exp(-r * T2) * N(d - sigma * sqrt(T2)) ...
                  - S * exp((b - r) * T2) * N(-y) + K * exp(-r * T2) * N(-y + sigma * sqrt(T1));
    end
end
