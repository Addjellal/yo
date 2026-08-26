function y = sgolayfilt(x, ordre, longueur)
%SGOLAYFILT Lissage polynomial de Savitzky-Golay.
%   Y = SGOLAYFILT(X,ORDRE,LONGUEUR) ajuste, sur chaque fenêtre de
%   LONGUEUR points, un polynôme de degré ORDRE au sens des moindres
%   carrés, et garde la valeur ajustée au centre.
    x = x(:).';
    m = numel(x);
    demi = floor(longueur / 2);
    y = x;
    t = (-demi:demi).';
    A = zeros(numel(t), ordre + 1);
    for j = 0:ordre
        A(:, j+1) = t .^ j;
    end
    for k = 1:m
        a = k - demi;
        b = k + demi;
        if a < 1 || b > m
            continue;
        end
        c = A \ x(a:b).';
        y(k) = c(1);
    end
end
