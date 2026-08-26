function [y, ym] = rceps(x)
%RCEPS Cepstre réel.
%   Y = RCEPS(X) rend le cepstre réel, transformée de Fourier inverse du
%   logarithme du module du spectre.
%
%   [Y,YM] = RCEPS(X) rend aussi la version à phase minimale de X : le
%   cepstre est replié sur les temps positifs, puis exponentié.
%
%   Exemple :
%      y = rceps([1 0 0 0 0.5 0 0 0]);   % un écho à l'échantillon 5
    x = double(x(:));
    n = numel(x);
    spectre = fft(x);
    module = abs(spectre);
    module(module == 0) = eps;
    y = real(ifft(log(module)));
    if nargout > 1
        % Repliement causal : on double les temps positifs, on garde le
        % terme constant et, pour une longueur paire, le terme milieu.
        poids = zeros(n, 1);
        poids(1) = 1;
        if mod(n, 2) == 0
            poids(2:n/2) = 2;
            poids(n/2 + 1) = 1;
        else
            poids(2:(n + 1) / 2) = 2;
        end
        ym = real(ifft(exp(fft(poids .* y))));
    end
end
