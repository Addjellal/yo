function [moyennes, covariance] = ewstats(rendements, facteur, fenetre)
%EWSTATS Moyenne et covariance pondérées exponentiellement.
%   [M,C] = EWSTATS(R,FACTEUR) donne plus de poids aux observations
%   récentes : le poids décroît d'un facteur constant à chaque pas vers
%   le passé. FACTEUR vaut 1 par défaut, ce qui redonne les estimations
%   ordinaires.
%
%   EWSTATS(R,FACTEUR,FENETRE) ne retient que les FENETRE dernières
%   observations.
%
%   Une covariance estimée sur dix ans traite pareillement la crise
%   d'il y a neuf ans et le mois dernier. La pondération exponentielle
%   corrige cela sans qu'il faille choisir une date de coupure.
%
%   Exemple :
%      [m, c] = ewstats(randn(200, 3), 0.98)
%
%   Voir aussi COV2CORR, CORR2COV, PORTSTATS, COV.
    if nargin < 2 || isempty(facteur)
        facteur = 1;
    end
    rendements = double(rendements);
    if size(rendements, 1) == 1
        rendements = rendements.';
    end
    n = size(rendements, 1);
    if nargin >= 3 && ~isempty(fenetre)
        fenetre = min(round(fenetre), n);
        rendements = rendements((end - fenetre + 1):end, :);
        n = fenetre;
    end
    if facteur <= 0 || facteur > 1
        error('finance:ewstats:Facteur', ...
              'Le facteur de pondération doit rester dans ]0, 1].');
    end
    poids = facteur .^ ((n - 1):-1:0).';
    poids = poids / sum(poids);
    moyennes = sum(rendements .* repmat(poids, 1, size(rendements, 2)), 1);
    centres = rendements - repmat(moyennes, n, 1);
    ponderes = centres .* repmat(poids, 1, size(rendements, 2));
    covariance = centres.' * ponderes;
    % Correction du biais : la somme des poids vaut un, celle de leurs
    % carrés donne le nombre d'observations effectif.
    effectif = 1 - sum(poids .^ 2);
    if effectif > 0
        covariance = covariance / effectif;
    end
end
