function valeurs = jackknife(fonction, varargin)
%JACKKNIFE Rééchantillonnage en retirant une observation à la fois.
%   VALEURS = JACKKNIFE(FONCTION,D) évalue FONCTION sur les N
%   échantillons obtenus en retirant tour à tour chacune des N
%   observations de D. Le résultat compte une ligne par observation
%   retirée.
%
%   VALEURS = JACKKNIFE(FONCTION,D1,D2,...) retire la même ligne de tous
%   les jeux à la fois, ce qui préserve leur appariement.
%
%   Le jackknife répond à la même question que le bootstrap — de combien
%   l'estimation varierait-elle ? — mais de façon déterministe : il n'y a
%   pas de tirage au sort, donc pas de germe, et deux appels donnent
%   exactement la même chose. Son estimation de la variance est
%
%      (N-1)/N * somme (valeur_i - moyenne des valeurs)^2
%
%   Il ne convient qu'aux statistiques régulières : sur une médiane, il
%   donne des résultats trompeurs, là où le bootstrap tient encore.
%
%   Exemples :
%      x = randn(50, 1);
%      v = jackknife(@mean, x);
%      variance = (49 / 50) * sum((v - mean(v)) .^ 2);
%      [variance, var(x) / 50]        % les deux coincident
%
%      jackknife(@(a, b) corr(a, b), randn(30,1), randn(30,1));
%
%   Voir aussi BOOTSTRP, BOOTCI, RANDSAMPLE, VAR.
    donnees = varargin;
    if isempty(donnees)
        error('stats:jackknife:NoData', 'JACKKNIFE needs at least one data argument.');
    end
    n = size(donnees{1}, 1);
    if n == 1 && isvector(donnees{1})
        for j = 1:numel(donnees)
            donnees{j} = donnees{j}(:);
        end
        n = numel(donnees{1});
    end
    premiere = [];
    for i = 1:n
        indices = [1:i - 1, i + 1:n]';
        arguments_ = cell(1, numel(donnees));
        for j = 1:numel(donnees)
            d = donnees{j};
            if isvector(d)
                arguments_{j} = d(indices);
            else
                arguments_{j} = d(indices, :);
            end
        end
        valeur = reshape(fonction(arguments_{:}), 1, []);
        if isempty(premiere)
            premiere = numel(valeur);
            valeurs = zeros(n, premiere);
        end
        valeurs(i, :) = valeur;
    end
end
