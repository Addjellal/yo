function [ahat, bhat] = unifit(x)
%UNIFIT Estimation des bornes d'une loi uniforme continue.
%   Le maximum de vraisemblance est le minimum et le maximum observés.
    x = double(x(:));
    ahat = min(x);
    bhat = max(x);
end
