function w = chebwin(n, r)
%CHEBWIN Fenêtre de Dolph-Tchebychev.
%   W = CHEBWIN(N,R) rend la fenêtre de N points dont les lobes
%   secondaires sont tous à R décibels sous le lobe principal ; R vaut
%   100 par défaut. C'est la fenêtre qui minimise la largeur du lobe
%   principal à atténuation donnée.
%
%   La construction est celle de Dolph : la transformée de la fenêtre est
%   le polynôme de Tchebychev T(N-1) échantillonné sur le cercle, ce qui
%   donne exactement des lobes secondaires égaux.
%
%   Exemple :
%      w = chebwin(51, 60);   % lobes secondaires à -60 dB
    if nargin < 2, r = 100; end
    n = round(n);
    if n <= 1
        w = ones(max(n, 0), 1);
        return
    end
    r = abs(r);
    beta = cosh(acosh(10 ^ (r / 20)) / (n - 1));
    k = 0:n-1;
    x = beta * cos(pi * k / n);
    p = tchebychev(n - 1, x);
    if mod(n, 2) == 1
        spectre = real(fft(p));
        m = (n + 1) / 2;
        moitie = spectre(1:m);
        w = [moitie(m:-1:2) moitie];
    else
        % Longueur paire : un demi-échantillon de décalage remet la
        % fenêtre au centre.
        p = p .* exp(1i * pi / n * k);
        spectre = real(fft(p));
        m = n / 2 + 1;
        moitie = spectre(1:m);
        w = [moitie(m:-1:2) moitie(2:m)];
    end
    w = w(:) / max(w);
end

function t = tchebychev(ordre, x)
%TCHEBYCHEV Polynôme de Tchebychev de première espèce, hors de [-1,1] aussi.
    t = zeros(size(x));
    dedans = abs(x) <= 1;
    t(dedans) = cos(ordre * acos(x(dedans)));
    grand = x > 1;
    t(grand) = cosh(ordre * acosh(x(grand)));
    petit = x < -1;
    t(petit) = (-1) ^ ordre * cosh(ordre * acosh(-x(petit)));
end
