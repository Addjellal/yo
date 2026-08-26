function limites = stretchlim(image, tolerance)
%STRETCHLIM Bornes de contraste, pour IMADJUST.
%   L = STRETCHLIM(I,TOL) rend [bas; haut] tels que la proportion TOL(1)
%   des pixels soit sous « bas » et TOL(2) au-dessus de « haut ». TOL vaut
%   [0.01 0.99] par défaut.
    if nargin < 2 || isempty(tolerance), tolerance = [0.01 0.99]; end
    if isscalar(tolerance), tolerance = [tolerance, 1 - tolerance]; end
    x = im2double(image);
    plans = size(x, 3);
    limites = zeros(2, plans);
    for k = 1:plans
        v = sort(reshape(x(:, :, k), [], 1));
        n = numel(v);
        bas = v(max(1, ceil(tolerance(1) * n)));
        haut = v(max(1, ceil(tolerance(2) * n)));
        if haut <= bas
            bas = 0; haut = 1;
        end
        limites(:, k) = [bas; haut];
    end
end
