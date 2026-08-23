function [boites, scores, indices] = selectStrongestBbox(boites, scores, seuil)
%SELECTSTRONGESTBBOX Suppression des non-maxima sur des boîtes.
%   [B,S] = SELECTSTRONGESTBBOX(BOITES,SCORES,SEUIL) garde la boîte la
%   mieux notée, écarte celles qui la recouvrent de plus de SEUIL, et
%   recommence. SEUIL vaut 0,5 par défaut.
%
%   Exemple :
%      b = [1 1 10 10; 2 2 10 10; 50 50 10 10];
%      size(selectStrongestBbox(b, [0.9; 0.8; 0.7]), 1)   % 2
    if nargin < 3 || isempty(seuil), seuil = 0.5; end
    [~, ordre] = sort(scores(:), 'descend');
    gardes = [];
    restants = ordre;
    while ~isempty(restants)
        courant = restants(1);
        gardes(end + 1) = courant; %#ok<AGROW>
        restants(1) = [];
        if isempty(restants), break, end
        recouvrement = zeros(numel(restants), 1);
        for k = 1:numel(restants)
            recouvrement(k) = bboxOverlapRatio(boites(courant, :), boites(restants(k), :));
        end
        restants = restants(recouvrement <= seuil);
    end
    indices = gardes(:);
    boites = boites(indices, :);
    scores = scores(indices);
end
