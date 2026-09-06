function [y, t] = resample(x, p, q)
%RESAMPLE Rééchantillonnage d'un facteur rationnel P/Q.
%   Y = RESAMPLE(X,P,Q) rend le signal rééchantillonné à P/Q fois sa
%   cadence, par interpolation sur la nouvelle grille temporelle.
%   [Y,T] = RESAMPLE(...) rend aussi les instants correspondants, en
%   échantillons de la grille d'origine.
%
%   Le nombre d'échantillons rendus est floor(N P / Q) : monter la cadence
%   en produit plus, la descendre moins.
%
%   L'orientation est conservée : une ligne rend une ligne.
%
%   L'interpolation est linéaire, non par filtre polyphasé : c'est plus
%   simple et suffisant quand le signal est déjà bien suréchantillonné,
%   mais cela ne protège pas du repliement quand on décime. Filtrer avant
%   de descendre en cadence reste nécessaire — UPFIRDN le fait d'un coup.
%
%   Exemple :
%      x = sin(2 * pi * 0.01 * (0:99));
%      numel(resample(x, 3, 2))        % 149
%      isrow(resample(x, 3, 2))        % true
%
%   Voir aussi UPFIRDN, DECIMATE, INTERP, INTERP1.
    ligne = isrow(x);
    v = double(x(:)).';
    n = numel(v);
    m = floor(n * p / q);
    t = linspace(1, n, m);
    y = interp1(1:n, v, t);
    if ~ligne
        y = y(:);
        t = t(:);
    end
end
