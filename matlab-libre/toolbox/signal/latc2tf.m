function [b, a] = latc2tf(k, v)
%LATC2TF Treillis -> fonction de transfert.
%   [B,A] = LATC2TF(K,V) rend le filtre que réalise le treillis-échelle
%   de coefficients de réflexion K et d'échelle V.
%   B = LATC2TF(K,'fir') rend le filtre à réponse finie du treillis K.
%   [B,A] = LATC2TF(K,'allpole') rend le filtre tout-pôle 1/A(z).
%   Sans second argument, le treillis est pris pour un tout-pôle.
%
%   Exemple :
%      [b, a] = butter(3, 0.4);
%      [k, v] = tf2latc(b, a);
%      max(abs(latc2tf(k, v) - b))     % nul aux arrondis près
%
%   Voir aussi TF2LATC, LATCFILT, RC2POLY.
    k = double(k(:));
    if nargin < 2
        v = 'allpole';
    end
    if ischar(v) || isstring(v)
        genre = lower(char(v));
        switch genre
            case {'fir', 'min'}
                b = rc2poly(k);
                a = 1;
            case {'allpole', 'iir'}
                b = 1;
                a = rc2poly(k);
            case 'allpass'
                a = rc2poly(k);
                b = conj(a(end:-1:1));
            otherwise
                error('signal:latc2tf:Genre', 'Genre inconnu : %s.', genre);
        end
        return;
    end
    v = double(v(:));
    a = rc2poly(k);
    a = a(:).';
    na = numel(a) - 1;
    % Le numérateur se remonte en additionnant, étage par étage, le
    % polynôme retourné de chaque ordre.
    b = zeros(1, na + 1);
    for ordre = 0:min(na, numel(v) - 1)
        aOrdre = rc2poly(k(1:ordre));
        aOrdre = aOrdre(:).';
        inverse = conj(aOrdre(end:-1:1));
        b(1:(ordre + 1)) = b(1:(ordre + 1)) + v(ordre + 1) * inverse;
    end
end
