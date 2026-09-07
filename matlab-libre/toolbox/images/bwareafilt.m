function [sortie, aires] = bwareafilt(bw, n, connexite)
%BWAREAFILT Ne garde que les composantes de l'aire voulue.
%   BWAREAFILT(BW,N) garde les N plus grandes ; BWAREAFILT(BW,[MIN MAX])
%   garde celles dont l'aire est dans l'intervalle.
%
%   Exemple :
%      bw = false(20, 20);
%      bw(3:6, 3:6) = true;        % un carre de 16 pixels
%      bw(10:18, 10:18) = true;    % un autre de 81
%      garde = bwareafilt(bw, 1);
%      sum(garde(:))               % 81 : seule la plus grande reste
    if nargin < 3 || isempty(connexite), connexite = 8; end
    bw = logical(bw);
    [etiquettes, nombre] = bwlabeln(bw, connexite);
    aires = zeros(nombre, 1);
    for k = 1:nombre
        aires(k) = sum(sum(etiquettes == k));
    end
    if numel(n) == 2
        gardes = find(aires >= n(1) & aires <= n(2));
    else
        [~, ordre] = sort(aires, 'descend');
        gardes = ordre(1:min(n, nombre));
    end
    sortie = false(size(bw));
    for k = gardes(:)'
        sortie(etiquettes == k) = true;
    end
end
