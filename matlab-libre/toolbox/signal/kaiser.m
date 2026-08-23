function w = kaiser(n, beta)
%KAISER Fenêtre de Kaiser.
%   W = KAISER(N,BETA) rend la fenêtre de Kaiser de N points, de paramètre
%   BETA. BETA vaut 0,5 par défaut. La fenêtre est symétrique.
%
%   Elle vaut I0(BETA*sqrt(1-(2k/(N-1)-1)^2)) / I0(BETA), où I0 est la
%   fonction de Bessel modifiée de première espèce d'ordre zéro.
%
%   Exemple :
%      w = kaiser(5, 5);   % w(3) == 1
%
%   Voir aussi HAMMING, HANN, BLACKMAN, CHEBWIN, KAISERORD.
    if nargin < 2, beta = 0.5; end
    n = round(n);
    if n <= 1
        w = ones(max(n, 0), 1);
        return
    end
    k = (0:n-1)';
    r = 2 * k / (n - 1) - 1;
    w = besseli0(beta * sqrt(max(0, 1 - r.^2))) / besseli0(beta);
end

function y = besseli0(x)
%BESSELI0 Bessel modifiée I0, par sa série entière.
    y = ones(size(x));
    for k = 1:numel(x)
        somme = 1;
        terme = 1;
        m = 1;
        while true
            terme = terme * (x(k) / (2 * m))^2;
            somme = somme + terme;
            if terme < 1e-16 * somme || m > 200
                break
            end
            m = m + 1;
        end
        y(k) = somme;
    end
end
