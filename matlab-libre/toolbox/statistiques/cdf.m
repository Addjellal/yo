function p = cdf(nom, x, varargin)
%CDF Fonction de répartition d'une loi nommée.
%   P = CDF('name', X, A, B, C).
%
%   P = CDF(PD,X) prend une loi ajustée par FITDIST, qui porte déjà son
%   nom et ses paramètres.
%
%   Exemples :
%      cdf('Poisson', 2, 1)                    % 0.9197
%      pd = fitdist(normrnd(0, 1, 500, 1), 'Normal');
%      abs(cdf(pd, pd.mu) - 0.5) < 1e-12       % la mediane d'une gaussienne
%
%   Voir aussi PDF, ICDF, RANDOM, FITDIST.
    [ajustee, nomLoi, parametres] = matlibre_stat_loi_ajustee(nom);
    if ajustee
        p = feval([statPrefixeLoi(nomLoi) 'cdf'], x, parametres{:});
        return
    end
    p = feval([statPrefixeLoi(nom) 'cdf'], x, varargin{:});
end
