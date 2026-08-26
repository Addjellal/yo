function sys = feedback(direct, retour, signe)
%FEEDBACK Boucle fermée.
%   SYS = FEEDBACK(G,H) rend G/(1+GH) : contre-réaction négative.
%   SYS = FEEDBACK(G,H,+1) rend G/(1-GH).
    if nargin < 3
        signe = -1;
    end
    g = tf(direct);
    if nargin < 2 || isempty(retour)
        h = tf(1, 1);
    else
        h = tf(retour);
    end
    num = conv(g.num, h.den);
    den = polyadd(conv(g.den, h.den), -signe * conv(g.num, h.num));
    sys = tf(num, den, max(g.Ts, h.Ts));
end

function s = polyadd(p, q)
    n = max(numel(p), numel(q));
    p = [zeros(1, n - numel(p)), p];
    q = [zeros(1, n - numel(q)), q];
    s = p + q;
end
