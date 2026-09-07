function [ahat, bhat] = unifit(x)
%UNIFIT Estimation des bornes d'une loi uniforme continue.
%   Le maximum de vraisemblance est le minimum et le maximum observés.
%
%   Exemple :
%      [a, b] = unifit([2 3 5 7]);
%      [a b]                       % 2 7 : les bornes observees
%
%   Voir aussi UNIFCDF, UNIFPDF, UNIFINV.
    x = double(x(:));
    ahat = min(x);
    bhat = max(x);
end
