function x = icdf(nom, p, varargin)
%ICDF Quantile d'une loi nommée.
%   X = ICDF('name', P, A, B, C).
%
%   X = ICDF(PD,P) prend une loi ajustée par FITDIST.
%
%   Exemples :
%      icdf('Normal', 0.975, 0, 1)             % 1.9600
%      pd = fitdist(normrnd(0, 1, 500, 1), 'Normal');
%      abs(cdf(pd, icdf(pd, 0.3)) - 0.3) < 1e-10   % l'aller-retour
    [ajustee, nomLoi, parametres] = matlibre_stat_loi_ajustee(nom);
    if ajustee
        x = feval([statPrefixeLoi(nomLoi) 'inv'], p, parametres{:});
        return
    end
    x = feval([statPrefixeLoi(nom) 'inv'], p, varargin{:});
end
