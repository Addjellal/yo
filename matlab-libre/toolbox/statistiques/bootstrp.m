function statistiques = bootstrp(n, fonction, varargin)
%BOOTSTRP Rééchantillonnage bootstrap.
%   S = BOOTSTRP(N,F,DONNEES) tire N échantillons avec remise dans les
%   données et applique F à chacun. Chaque ligne de S est un tirage.
%
%   Exemple :
%      s = bootstrp(100, @mean, randn(50, 1));
    donnees = varargin;
    m = size(donnees{1}, 1);
    statistiques = [];
    for k = 1:n
        indices = randi(m, m, 1);
        echantillon = cell(1, numel(donnees));
        for j = 1:numel(donnees)
            echantillon{j} = donnees{j}(indices, :);
        end
        valeur = fonction(echantillon{:});
        statistiques = [statistiques; reshape(valeur, 1, [])]; %#ok<AGROW>
    end
end
