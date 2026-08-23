function [xhat, nd] = cceps(x)
%CCEPS Cepstre complexe.
%   [XHAT,ND] = CCEPS(X) rend le cepstre complexe et le nombre
%   d'échantillons de retard retirés avant le déroulement de la phase.
%   Le cepstre complexe garde la phase, à la différence de RCEPS.
%
%   Exemple :
%      xhat = cceps([1 0 0 0 0.5 0 0 0]);
    x = double(x(:));
    n = numel(x);
    spectre = fft(x);
    module = abs(spectre);
    module(module == 0) = eps;
    phase = unwrap(angle(spectre));
    % Retard entier : la phase totale sur un tour vaut -2 pi nd.
    nd = round(phase(round(n / 2) + 1) / pi);
    phase = phase - pi * nd * (0:n-1)' / (n / 2) / 2;
    xhat = real(ifft(log(module) + 1i * phase));
end
