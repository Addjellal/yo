function [pd, w] = phasedelay(b, a, n)
%PHASEDELAY Retard de phase d'un filtre numérique.
%   Le retard de phase vaut -phi(w)/w. Pour un filtre à phase linéaire
%   d'ordre N il vaut N/2 échantillons, constant.
    if nargin < 2 || isempty(a), a = 1; end
    if nargin < 3, n = 512; end
    [phi, w] = phasez(b, a, n);
    pd = -phi ./ w;
    if ~isempty(w) && w(1) == 0 && numel(w) > 1
        pd(1) = pd(2);      % la limite en zéro, par continuité
    end
end
