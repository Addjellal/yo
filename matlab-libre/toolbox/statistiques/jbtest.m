function [h, p, statistique, critique] = jbtest(x, alpha)
%JBTEST Test de normalité de Jarque-Bera.
%   H = JBTEST(X) teste l'hypothèse « X suit une loi normale, de moyenne
%   et de variance quelconques ». Il ne regarde que les deux moments qui
%   distinguent la normale : l'asymétrie, qui doit être nulle, et
%   l'aplatissement, qui doit valoir trois. La statistique est
%
%      JB = N/6 * (S^2 + (K-3)^2/4)
%
%   où S est l'asymétrie et K l'aplatissement de l'échantillon.
%
%   H vaut 1 si la normalité est rejetée au seuil ALPHA, 0.05 par défaut.
%
%   [H,P] = JBTEST(...) rend la probabilité critique.
%   [H,P,JB] = JBTEST(...) rend la statistique.
%   [H,P,JB,CV] = JBTEST(...) rend la valeur critique au seuil ALPHA.
%
%   Pour un grand échantillon, JB suit une loi du khi-deux à deux degrés
%   de liberté. Pour un petit — moins de deux mille observations —, cette
%   approximation est trop indulgente ; MatLibre calcule alors la
%   probabilité par simulation, comme le fait MATLAB, avec un germe fixé
%   pour que deux appels donnent la même réponse.
%
%   Le test ne voit que l'asymétrie et l'aplatissement : une loi qui
%   partage ces deux moments avec la normale sans lui ressembler passe
%   sans encombre. LILLIETEST, qui compare les répartitions entières, est
%   plus complet.
%
%   Exemples :
%      jbtest(randn(1000, 1))            % 0 : normal
%      jbtest(exprnd(1, 1000, 1))        % 1 : tres dissymetrique
%      [h, p, jb] = jbtest(rand(500, 1)) % la loi uniforme est plate
%
%   Voir aussi LILLIETEST, KSTEST, SKEWNESS, KURTOSIS, CHI2GOF.
    if nargin < 2 || isempty(alpha)
        alpha = 0.05;
    end
    x = x(:);
    x = x(~isnan(x));
    n = numel(x);
    if n < 4
        error('stats:jbtest:NotEnoughData', 'JBTEST needs at least four values.');
    end
    S = skewness(x);
    K = kurtosis(x);
    statistique = n / 6 * (S ^ 2 + (K - 3) ^ 2 / 4);
    if n >= 2000
        p = 1 - chi2cdf(statistique, 2);
        critique = chi2inv(1 - alpha, 2);
        h = double(p < alpha);
        return;
    end
    % Petit échantillon : la loi du khi-deux est trop optimiste. On tire
    % la loi de la statistique sous normalité.
    etat = rng();
    rng(20240118);
    tirages = 20000;
    simulees = zeros(tirages, 1);
    for i = 1:tirages
        z = randn(n, 1);
        s = skewness(z);
        k = kurtosis(z);
        simulees(i) = n / 6 * (s ^ 2 + (k - 3) ^ 2 / 4);
    end
    rng(etat);
    p = sum(simulees >= statistique) / tirages;
    p = max(p, 1 / tirages);
    critique = prctile(simulees, 100 * (1 - alpha));
    h = double(statistique > critique);
end
