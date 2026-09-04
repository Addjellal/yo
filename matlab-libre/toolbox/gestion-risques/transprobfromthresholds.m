function transition = transprobfromthresholds(seuils)
%TRANSPROBFROMTHRESHOLDS Matrice de transition tirée de seuils.
%   P = TRANSPROBFROMTHRESHOLDS(S) est l'inverse de
%   TRANSPROBTOTHRESHOLDS : la probabilité d'aller vers une notation est
%   celle que la variable tombe entre son seuil et le suivant.
%
%   Exemple :
%      p = [0.9 0.08 0.02; 0.05 0.9 0.05; 0 0 1];
%      max(max(abs(transprobfromthresholds(transprobtothresholds(p)) - p)))
%
%   Voir aussi TRANSPROBTOTHRESHOLDS, TRANSPROB.
    seuils = double(seuils);
    n = size(seuils, 2);
    cumulees = normcdf(seuils);
    cumulees(:, 1) = 1;
    transition = zeros(size(seuils));
    for j = 1:(n - 1)
        transition(:, j) = cumulees(:, j) - cumulees(:, j + 1);
    end
    transition(:, n) = cumulees(:, n);
    transition = max(transition, 0);
end
