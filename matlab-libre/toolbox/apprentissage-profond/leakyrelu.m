function y = leakyrelu(x, pente)
%LEAKYRELU Redresseur à fuite : X si X est positif, PENTE fois X sinon.
%   Y = LEAKYRELU(X) applique une pente de 0,01 aux valeurs négatives.
%   Y = LEAKYRELU(X,PENTE) impose la pente.
%
%   Le redresseur ordinaire annule tout le négatif, et la dérivée avec :
%   une unité qui y tombe n'apprend plus. La fuite lui laisse un gradient,
%   petit mais non nul.
%
%   X peut être un DLARRAY.
%
%   Exemple :
%      leakyrelu([-2 3], 0.1)      % -0.2  3
%
%   Voir aussi RELU, LEAKYRELULAYER, ELULAYER.
    if nargin < 2
        pente = 0.01;
    end
    y = max(x, 0) + pente * min(x, 0);
end
