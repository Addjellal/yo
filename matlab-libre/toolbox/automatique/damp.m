function [wn, zeta, p] = damp(sys)
%DAMP Pulsations propres et amortissements.
%   [WN,ZETA] = DAMP(SYS) rend, pour chaque pôle, la pulsation propre et
%   le coefficient d'amortissement.
    p = pole(sys);
    if sys.Ts > 0
        p = log(p) / sys.Ts;
    end
    wn = abs(p);
    zeta = -real(p) ./ max(wn, eps);
end
