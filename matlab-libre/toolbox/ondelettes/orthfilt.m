function [Lo_D, Hi_D, Lo_R, Hi_R] = orthfilt(W)
%ORTHFILT Banc de filtres orthogonal à partir du filtre d'échelle.
%   [LO_D,HI_D,LO_R,HI_R] = ORTHFILT(W) normalise W à une somme de racine
%   de deux, puis applique les relations du banc à reconstruction
%   parfaite : l'analyse est la synthèse renversée, et le passe-haut est
%   le miroir en quadrature du passe-bas.
%
%      Lo_R = sqrt(2) * W / sum(W)
%      Lo_D[n] = Lo_R[N+1-n]
%      Hi_D[n] = (-1)^n Lo_R[n]
%      Hi_R[n] = Hi_D[N+1-n]
%
%   Exemple :
%      [lod, hid, lor, hir] = orthfilt([1 1]);   % Haar
%      hid    % [-0.7071 0.7071]
%
%   Voir aussi WFILTERS, QMF.
    W = double(W(:))';
    Lo_R = W / sum(W) * sqrt(2);
    n = numel(Lo_R);
    Lo_D = Lo_R(end:-1:1);
    Hi_D = Lo_R .* (-1) .^ (1:n);
    Hi_R = Hi_D(end:-1:1);
end
