function a = lsf2poly(lsf)
%LSF2POLY Polynôme de prédiction à partir des fréquences de raies.
%   Inverse de POLY2LSF : les racines de rangs pairs reconstituent Q,
%   celles de rangs impairs P, et A = (P + Q)/2.
    lsf = double(lsf(:));
    p = numel(lsf);
    % Les LSF s'entrelacent : une racine sur deux appartient à P.
    anglesP = lsf(1:2:end);
    anglesQ = lsf(2:2:end);
    P = 1;
    for k = 1:numel(anglesP)
        P = conv(P, [1 -2*cos(anglesP(k)) 1]);
    end
    Q = 1;
    for k = 1:numel(anglesQ)
        Q = conv(Q, [1 -2*cos(anglesQ(k)) 1]);
    end
    if mod(p, 2) == 0
        P = conv(P, [1 1]);
        Q = conv(Q, [1 -1]);
    else
        Q = conv(Q, [1 0 -1]);
    end
    n = max(numel(P), numel(Q));
    P = [P zeros(1, n - numel(P))];
    Q = [Q zeros(1, n - numel(Q))];
    a = (P + Q) / 2;
    a = a(1:end-1);
end
