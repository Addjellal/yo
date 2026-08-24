function x = genqamdemod(y, constellation)
%GENQAMDEMOD Démodulation sur une constellation quelconque.
%   X = GENQAMDEMOD(Y,CONST) rend, pour chaque échantillon, l'indice du
%   point de CONST le plus proche au sens de la distance euclidienne.
%   C'est le décodage à maximum de vraisemblance sur canal gaussien.
%
%   Exemple :
%      c = [1, 1i, -1, -1i];
%      genqamdemod([0.9+0.1i, -0.2+1.1i], c)   % [0 1]
%
%   Voir aussi GENQAMMOD, QAMDEMOD.
    constellation = constellation(:).';
    y = double(y);
    forme = size(y);
    v = y(:);
    distances = abs(v * ones(1, numel(constellation)) - ones(numel(v), 1) * constellation);
    [~, indices] = min(distances, [], 2);
    x = reshape(indices - 1, forme);
end
