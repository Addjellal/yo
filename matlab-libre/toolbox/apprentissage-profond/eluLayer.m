function c = eluLayer(alpha, varargin)
%ELULAYER Couche ELU : linéaire pour les positifs, exponentielle sinon.
%   C = ELULAYER(ALPHA) ; ALPHA vaut 1 par défaut.
%
%   Exemple :
%      c = eluLayer();
%      c.type                      % 'elu'
%
%   Voir aussi RELULAYER, LEAKYRELULAYER, GELULAYER.
    if nargin < 1 || isempty(alpha), alpha = 1; end
    c = struct('type', 'elu', 'alpha', alpha, 'nom', matlibre_couche_nom(varargin));
end
