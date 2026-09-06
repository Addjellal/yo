function rul = rulDegradation(indicateur, seuil)
%RULDEGRADATION Durée de vie restante par extrapolation linéaire.
%   RUL = RULDEGRADATION(INDICATEUR,SEUIL) rend le nombre de cycles avant
%   que la tendance n'atteigne le seuil.
%
%   La méthode est directe : ajuster une droite sur l'indicateur, et
%   chercher quand elle coupera le seuil. Elle demande peu — un seul
%   historique, le sien — et ne vaut que si la dégradation est bien
%   linéaire.
%
%   Sur une dégradation accélérée, l'extrapolation linéaire est trop
%   optimiste tant qu'on est loin de la fin : la droite sous-estime la
%   pente à venir. RULSIMILARITY, qui n'impose aucune forme, fait mieux
%   dans ce cas — au prix d'historiques à fournir.
%
%   Un indicateur qui ne monte pas rend l'infini : rien ne permet alors de
%   prédire une panne, et le dire vaut mieux qu'inventer un chiffre. Un
%   seuil déjà franchi rend zéro, jamais un nombre négatif.
%
%   Exemple :
%      rulDegradation(0.01 * (1:50).', 1.0)        % 50 cycles restants
%      rulDegradation(ones(50, 1), 1.0)            % Inf : rien ne bouge
%
%   Voir aussi RULSIMILARITY, HEALTHINDICATOR.
    n = numel(indicateur);
    t = (1:n).';
    p = polyfit(t, indicateur(:), 1);
    if p(1) <= 0
        rul = inf;
        return;
    end
    tSeuil = (seuil - p(2)) / p(1);
    rul = max(0, tSeuil - n);
end
