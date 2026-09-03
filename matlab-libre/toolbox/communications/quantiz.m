function [indices, quantifie, distorsion] = quantiz(signal, partition, codebook)
%QUANTIZ Quantification scalaire d'un signal.
%   INDICES = QUANTIZ(X,PARTITION) rend, pour chaque valeur de X, le
%   nombre d'éléments de PARTITION qu'elle dépasse strictement : l'indice
%   vaut zéro quand X ne dépasse pas le premier seuil, et M quand
%   PARTITION(M) < X <= PARTITION(M+1). Il va donc de zéro à
%   NUMEL(PARTITION), et les seuils vont en ordre croissant.
%
%   [INDICES,Q] = QUANTIZ(X,PARTITION,CODEBOOK) rend en outre les valeurs
%   quantifiées : Q(k) vaut CODEBOOK(INDICES(k)+1). CODEBOOK compte un
%   élément de plus que PARTITION.
%
%   [INDICES,Q,D] = QUANTIZ(...) rend la distorsion, erreur quadratique
%   moyenne entre X et Q.
%
%   Exemple :
%      [i, q, d] = quantiz([-2 -1 0 1 2], [-1 0 1], [-1.5 -0.5 0.5 1.5]);
%      i                              % [0 0 1 2 3] : le seuil appartient
%                                     % à l'intervalle du dessous
%
%   Voir aussi LLOYDS, DPCMENCO, HUFFMANDICT.
    signal = double(signal);
    partition = double(partition(:)).';
    if any(diff(partition) <= 0)
        error('comm:quantiz:Partition', ...
              'Les seuils doivent être en ordre strictement croissant.');
    end
    indices = zeros(size(signal));
    for k = 1:numel(signal)
        indices(k) = sum(signal(k) > partition);
    end
    if nargout > 1
        if nargin < 3 || isempty(codebook)
            error('comm:quantiz:Codebook', ...
                  'Les valeurs quantifiées demandent un dictionnaire.');
        end
        codebook = double(codebook(:)).';
        if numel(codebook) ~= numel(partition) + 1
            error('comm:quantiz:Taille', ...
                  ['Le dictionnaire doit compter un élément de plus que ' ...
                   'la partition : %d au lieu de %d.'], ...
                  numel(partition) + 1, numel(codebook));
        end
        quantifie = codebook(indices + 1);
        quantifie = reshape(quantifie, size(signal));
        if nargout > 2
            distorsion = mean((signal(:) - quantifie(:)) .^ 2);
        end
    end
end
