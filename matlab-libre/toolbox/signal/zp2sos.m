function [sos, g] = zp2sos(z, p, k)
%ZP2SOS Zéros et pôles vers sections du second ordre.
%   Les racines complexes sont appariées avec leur conjuguée ; les racines
%   réelles sont groupées deux par deux. Le résultat est réel.
%
%   Exemple :
%      [z, p, k] = butter(4, 0.3);
%      [sos, g] = zp2sos(z, p, k);
%      size(sos, 2)                % 6 colonnes par section
%
%   Voir aussi SOS2ZP, TF2SOS, ZP2TF.
    if nargin < 3, k = 1; end
    z = z(:);
    p = p(:);
    paires = @(r) apparier(r);
    zp = paires(z);
    pp = paires(p);
    n = max(size(zp, 1), size(pp, 1));
    sos = zeros(max(n, 1), 6);
    for i = 1:max(n, 1)
        if i <= size(zp, 1)
            num = real(poly(zp(i, ~isnan(zp(i, :)))));
        else
            num = 1;
        end
        if i <= size(pp, 1)
            den = real(poly(pp(i, ~isnan(pp(i, :)))));
        else
            den = 1;
        end
        % La section se lit en puissances de z^-1 : [b0 b1 b2 a0 a1 a2],
        % a0 = 1. Une section du premier ordre se complète donc par la fin
        % — (1 - z1 z^-1) s'écrit [1 -z1 0] —, non par le début, ce qui
        % aurait retardé la section d'un échantillon.
        num = [num, zeros(1, 3 - numel(num))];
        den = [den, zeros(1, 3 - numel(den))];
        sos(i, :) = [num(1:3), den(1:3)];
    end
    g = k;
end

function m = apparier(r)
%APPARIER Groupe les racines par deux : chaque complexe avec sa conjuguée,
%   puis les réelles entre elles, deux à deux, la dernière seule si leur
%   nombre est impair. Les réelles se groupent quel que soit leur rang :
%   une réelle suivie d'une paire complexe restait seule, et faisait une
%   section de trop.
    m = zeros(0, 2);
    r = r(:);
    reelles = r(abs(imag(r)) <= 1e-12);
    reste = r(abs(imag(r)) > 1e-12);
    while ~isempty(reste)
        courant = reste(1);
        reste(1) = [];
        [~, j] = min(abs(reste - conj(courant)));
        if ~isempty(j)
            m = [m; courant, reste(j)]; %#ok<AGROW>
            reste(j) = [];
        else
            m = [m; courant, NaN]; %#ok<AGROW>
        end
    end
    reelles = sort(real(reelles));
    for i = 1:2:numel(reelles)
        if i + 1 <= numel(reelles)
            m = [m; reelles(i), reelles(i + 1)]; %#ok<AGROW>
        else
            m = [m; reelles(i), NaN]; %#ok<AGROW>
        end
    end
end
