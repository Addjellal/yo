function [f, g] = latcfilt(k, varargin)
%LATCFILT Filtrage par une structure en treillis.
%   [F,G] = LATCFILT(K,X) filtre X par le treillis à réponse finie de
%   coefficients de réflexion K : F porte la sortie directe, G la sortie
%   rétrograde.
%
%   [F,G] = LATCFILT(K,V,X) emploie le treillis-échelle de coefficients
%   K et V : F est alors la sortie du filtre récursif.
%
%   Exemple :
%      [b, a] = butter(3, 0.4);
%      k = tf2latc(b / b(1));
%      x = randn(1, 100);
%      max(abs(latcfilt(k, x) * b(1) - filter(b, 1, x)))
%
%   Voir aussi TF2LATC, LATC2TF, FILTER.
    k = double(k(:));
    if numel(varargin) >= 2
        v = double(varargin{1}(:));
        x = varargin{2};
        [b, a] = latc2tf(k, v);
        f = filter(b, a, x);
        g = [];
        return;
    end
    x = varargin{1};
    ligne = isrow(x);
    x = double(x(:));
    n = numel(x);
    m = numel(k);
    % Récurrence du treillis : f_m(n) = f_(m-1)(n) + k_m g_(m-1)(n-1),
    % g_m(n) = conj(k_m) f_(m-1)(n) + g_(m-1)(n-1).
    fPrecedent = x;
    gPrecedent = x;
    for etage = 1:m
        gRetarde = [0; gPrecedent(1:end-1)];
        fCourant = fPrecedent + k(etage) * gRetarde;
        gCourant = conj(k(etage)) * fPrecedent + gRetarde;
        fPrecedent = fCourant;
        gPrecedent = gCourant;
    end
    f = fPrecedent;
    g = gPrecedent;
    if ligne
        f = f.';
        g = g.';
    end
    if m == 0
        f = x;
        g = x;
        if ligne
            f = f.';
            g = g.';
        end
    end
end
