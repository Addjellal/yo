function y = dpskmod(x, M, phase)
%DPSKMOD Modulation par déplacement de phase différentiel.
%   Y = DPSKMOD(X,M) code l'information dans la différence de phase entre
%   deux symboles consécutifs : le récepteur n'a pas besoin de connaître
%   la phase absolue.
%
%   Exemple :
%      y = dpskmod([0 1 0], 2);   % [1 -1 -1] : la phase bascule au 1
    if nargin < 3, phase = 0; end
    x = x(:);
    n = numel(x);
    y = zeros(n, 1);
    courante = phase;
    for k = 1:n
        courante = courante + 2 * pi * x(k) / M;
        y(k) = exp(1i * courante);
    end
    % Un signal réel reste réel : on nettoie l'imaginaire résiduel.
    if max(abs(imag(y))) < 1e-12
        y = real(y);
    end
end
