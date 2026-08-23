function c = leakyReluLayer(pente)
%LEAKYRELULAYER Couche ReLU à fuite : pente non nulle pour les négatifs.
%   C = LEAKYRELULAYER(PENTE) ; PENTE vaut 0,01 par défaut.
    if nargin < 1 || isempty(pente), pente = 0.01; end
    c = struct('type', 'leakyrelu', 'pente', pente);
end
