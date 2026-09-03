function b = intfilt(l, p, alpha)
%INTFILT Filtre d'interpolation.
%   B = INTFILT(L,P,ALPHA) conçoit le filtre à phase linéaire qui
%   interpole idéalement une séquence intercalée de L-1 zéros, en
%   s'appuyant sur les 2*P échantillons non nuls les plus proches. ALPHA
%   est la largeur de bande du signal d'origine, en fraction de la
%   fréquence de Nyquist : ALPHA = 1 suppose le signal occupant toute la
%   bande, une valeur plus petite laisse de la marge et donne un filtre
%   plus doux.
%
%   B = INTFILT(L,N,'Lagrange') interpole par un polynôme de degré N au
%   lieu d'une bande limitée.
%
%   Le filtre est long de 2*P*L-1 coefficients et laisse passer les
%   échantillons d'origine sans les changer : B(L:L:end) est une
%   impulsion.
%
%   Exemple :
%      b = intfilt(4, 3, 0.8);
%      x = sin(2*pi*0.05*(0:99));
%      y = filter(b, 1, upsample(x, 4));
%
%   Voir aussi INTERP, RESAMPLE, UPFIRDN, DECIMATE, SINC.
    l = round(l);
    if l < 1
        error('signal:intfilt:BadRate', 'Le facteur d''interpolation doit être positif.');
    end
    if nargin < 3
        alpha = 1;
    end
    lagrange = (ischar(alpha) || isstring(alpha)) && strncmpi(char(alpha), 'l', 1);
    if lagrange
        degre = round(p);
        points = degre + 1;
        pDemi = ceil(points / 2);
        noeuds = ((1 - pDemi):(points - pDemi)).';
    else
        pDemi = round(p);
        noeuds = ((1 - pDemi):pDemi).';
        points = numel(noeuds);
        if alpha <= 0 || alpha > 1
            error('signal:intfilt:BadAlpha', 'ALPHA doit être dans ]0, 1].');
        end
    end
    coefficients = zeros(points, l);
    for phase = 0:(l - 1)
        d = phase / l;
        if lagrange
            coefficients(:, phase + 1) = lagrangeBase(noeuds, d);
        else
            % Interpolation optimale d'un signal de bande ALPHA : les
            % équations normales ont pour matrice les sinc des écarts
            % entre échantillons, et pour second membre les sinc des
            % écarts au point cherché.
            R = sinc(alpha * (noeuds - noeuds.'));
            r = sinc(alpha * (noeuds - d));
            coefficients(:, phase + 1) = R \ r;
        end
    end
    % Les coefficients se rangent phase par phase. Pour la phase M, la
    % sortie vaut somme_j c_m(j) x[i + noeud(j)] ; comme y[n] = somme_k
    % b[k] xu[n-k] et que seuls les k congrus à M modulo L portent un
    % échantillon, il vient b[(P - noeud(j)) L + M] = c_m(j). Le premier
    % coefficient est nul par construction — la phase nulle est une
    % impulsion —, d'où la longueur 2 P L - 1 de MATLAB.
    total = 2 * pDemi * l;
    bb = zeros(1, total);
    for j = 1:points
        for phase = 0:(l - 1)
            k = (pDemi - noeuds(j)) * l + phase;
            if k >= 0 && k < total
                bb(k + 1) = coefficients(j, phase + 1);
            end
        end
    end
    b = bb(2:end);
end

function c = lagrangeBase(noeuds, d)
%LAGRANGEBASE Coefficients de l'interpolation de Lagrange en D.
    n = numel(noeuds);
    c = ones(n, 1);
    for i = 1:n
        for j = 1:n
            if i ~= j
                c(i) = c(i) * (d - noeuds(j)) / (noeuds(i) - noeuds(j));
            end
        end
    end
end
