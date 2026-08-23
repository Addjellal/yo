function [amplitude, w, phi] = zerophase(b, a, n)
%ZEROPHASE Réponse en amplitude à phase nulle.
%   [HR,W,PHI] = ZEROPHASE(B,A,N) décompose la réponse en fréquence en
%   H(e^jw) = HR(w) exp(j PHI(w)) avec HR réelle. Contrairement au
%   module, HR peut être négative : son signe porte les sauts de phase
%   de pi que provoquent les zéros posés sur le cercle unité.
%
%   Pour un RIF à phase linéaire la décomposition est exacte : retirer le
%   retard (N-1)/2 rend la réponse réelle pour les types 1 et 2,
%   imaginaire pure pour les types 3 et 4. Sinon l'amplitude vaut le
%   module, affecté du signe qui bascule à chaque zéro sur le cercle.
%
%   Exemple :
%      [hr, w] = zerophase([1 1]);   % hr = 2 cos(w/2), jamais négatif
    if nargin < 2 || isempty(a), a = 1; end
    if nargin < 3, n = 512; end
    b = double(b(:)).';
    a = double(a(:)).';
    [h, w] = freqz(b, a, n);
    w = w(:);
    h = h(:);
    if islinphase(b, a)
        retard = (numel(b) - 1) / 2;
        redresse = h .* exp(1i * w * retard);
        if firtype(b / a(1)) <= 2
            amplitude = real(redresse);
            phi = -w * retard;
        else
            amplitude = imag(redresse);
            phi = -w * retard + pi / 2;
        end
        return
    end
    % Cas général : chaque zéro sur le cercle unité inverse le signe.
    zerosFiltre = racinesFiltre(b);
    surCercle = sort(abs(angle(zerosFiltre(abs(abs(zerosFiltre) - 1) < 1e-8))));
    signe = ones(size(w));
    for k = 1:numel(surCercle)
        signe = signe .* (1 - 2 * (w > surCercle(k)));
    end
    if sum(b) / sum(a) < 0
        signe = -signe;
    end
    amplitude = abs(h) .* signe;
    phi = unwrap(angle(h .* signe));
end

function r = racinesFiltre(c)
    while numel(c) > 1 && c(1) == 0
        c(1) = [];
    end
    if numel(c) <= 1
        r = zeros(0, 1);
    else
        r = roots(c);
    end
end
