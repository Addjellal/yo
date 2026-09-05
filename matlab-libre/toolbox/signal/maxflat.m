function [b, a, b1, b2] = maxflat(n, m, Wn, affichage)
%MAXFLAT Filtre passe-bas à réponse la plus plate possible.
%   [B,A] = MAXFLAT(N,M,WN) rend un filtre de Butterworth généralisé de
%   degré N au numérateur et M au dénominateur, de fréquence de coupure
%   WN normalisée entre 0 et 1, 1 valant Nyquist. Le gain y vaut
%   1/racine de deux.
%
%   B = MAXFLAT(N,'sym',WN) rend un filtre à réponse impulsionnelle finie
%   et symétrique, d'ordre N pair. WN n'est alors atteignable que dans un
%   sous-intervalle de [0,1] : les degrés de platitude sont entiers, donc
%   les coupures possibles sont en nombre fini.
%
%   [B,A,B1,B2] = MAXFLAT(...) sépare le numérateur en ses deux facteurs :
%   B1 porte les N zéros en z = -1, B2 le reste.
%
%   MAXFLAT(...,'design') affiche ce que le filtre obtenu vérifie.
%
%   « Le plus plat possible » a un sens précis. En posant
%   x = sin(w/2)^2, le module au carré s'écrit
%
%      |H|^2 = (1-x)^N / D(x),   D de degré M, D(0) = 1
%
%   La forme (1-x)^N impose N zéros en x = 1, c'est-à-dire à Nyquist :
%   la bande coupée est aussi plate que le degré le permet. Restent M
%   coefficients libres dans D. On en dépense M-1 à annuler les M-1
%   premières dérivées de |H|^2 en x = 0, ce qui donne
%
%      D(x) = somme_{k<M} C(N,k) (-1)^k x^k + beta x^M
%
%   et le dernier, beta, à placer la coupure là où on la veut. C'est tout
%   le filtre : rien n'est optimisé, tout est imposé.
%
%   Pour N = M on retrouve exactement le filtre de Butterworth ordinaire,
%   dont BUTTER donne les mêmes coefficients.
%
%   Exemple :
%      [b, a] = maxflat(10, 2, 0.2);
%      [b, a] = maxflat(4, 4, 0.3);        % identique à butter(4, 0.3)
%      b = maxflat(8, 'sym', 0.5);
%
%   Voir aussi BUTTER, FIRLS, FIRPM, FREQZ.
    if nargin < 4, affichage = ''; end
    if nargin < 3
        error('signal:maxflat:Arguments', 'MAXFLAT demande N, M et WN.');
    end
    n = round(double(n));
    Wn = double(Wn);
    if Wn <= 0 || Wn >= 1
        error('signal:maxflat:Coupure', ...
              'La fréquence de coupure doit être dans ]0,1[.');
    end
    if ischar(m) || isstring(m)
        if ~strcmpi(char(m), 'sym')
            error('signal:maxflat:Genre', ...
                  'Le second argument vaut un degré ou ''sym''.');
        end
        [b, a, b1, b2] = maxflatSymetrique(n, Wn);
    else
        m = round(double(m));
        if n < 1 || m < 1
            error('signal:maxflat:Degres', ...
                  'Les degrés doivent valoir au moins un.');
        end
        [b, a, b1, b2] = maxflatButterworth(n, m, Wn);
    end
    if strcmpi(char(affichage), 'design')
        decrireMaxflat(b, a, Wn);
    end
end

function [b, a, b1, b2] = maxflatButterworth(n, m, Wn)
    xc = sin(pi * Wn / 2) ^ 2;
    % D(x) = somme des M premiers termes de (1-x)^N, plus beta x^M.
    D = zeros(1, m + 1);
    for k = 0:(m - 1)
        D(k + 1) = nchoosek(n, min(k, n)) * (-1) ^ k * (k <= n);
    end
    reste = 0;
    for k = 0:(m - 1)
        reste = reste + D(k + 1) * xc ^ k;
    end
    D(m + 1) = (2 * (1 - xc) ^ n - reste) / xc ^ m;
    if ~positifSurSegment(D)
        [bas, haut] = intervalleMaxflat(n, m);
        if isempty(bas)
            error('signal:maxflat:Impossible', ...
                  ['Aucune coupure ne convient pour N = %d et M = %d : ' ...
                   'le module au carré demandé deviendrait négatif. ' ...
                   'Augmentez M ou diminuez N.'], n, m);
        end
        error('signal:maxflat:Coupure', ...
              ['Pour N = %d et M = %d la coupure doit être entre %.4f et ' ...
               '%.4f : au-delà, le module au carré demandé deviendrait ' ...
               'négatif, et aucun filtre ne le réalise.'], n, m, bas, haut);
    end
    % D(x) devient un polynôme de Laurent en z par x = (2 - z - 1/z)/4,
    % puis on garde les racines de module inférieur à un : c'est la
    % factorisation spectrale, et c'est elle qui rend le filtre stable.
    laurent = polynomeEnZ(D);
    racines = roots(laurent);
    racines = racines(abs(racines) < 1 - 1e-9);
    if numel(racines) ~= m
        % Racines sur le cercle ou multiples : on prend les M plus petites.
        toutes = roots(laurent);
        [~, ordre] = sort(abs(toutes));
        racines = toutes(ordre(1:m));
    end
    a = real(poly(racines(:).'));
    b1 = poly(-ones(1, n));
    b1 = b1 / sum(b1);
    b2 = sum(a);
    b = b1 * b2;
end

function bon = positifSurSegment(D)
%POSITIFSURSEGMENT Le module au carré reste-t-il positif ?
%   D(x) est le dénominateur de |H|^2 sur [0,1]. S'il change de signe,
%   aucun filtre ne réalise la réponse demandée : un module au carré ne
%   peut pas être négatif, et la factorisation spectrale n'existe pas.
    x = linspace(0, 1, 2001);
    valeurs = polyval(D(end:-1:1), x);
    bon = all(valeurs > 1e-12);
end

function [bas, haut] = intervalleMaxflat(n, m)
%INTERVALLEMAXFLAT Coupures réalisables pour ces deux degrés.
    grille = linspace(0.001, 0.999, 999);
    bon = false(size(grille));
    for k = 1:numel(grille)
        bon(k) = positifSurSegment(denominateurMaxflat(n, m, grille(k)));
    end
    indices = find(bon);
    if isempty(indices)
        bas = [];
        haut = [];
        return
    end
    bas = grille(indices(1));
    haut = grille(indices(end));
end

function D = denominateurMaxflat(n, m, Wn)
    xc = sin(pi * Wn / 2) ^ 2;
    D = zeros(1, m + 1);
    for k = 0:(m - 1)
        D(k + 1) = nchoosek(n, min(k, n)) * (-1) ^ k * (k <= n);
    end
    reste = 0;
    for k = 0:(m - 1)
        reste = reste + D(k + 1) * xc ^ k;
    end
    D(m + 1) = (2 * (1 - xc) ^ n - reste) / xc ^ m;
end

function laurent = ajouterCentre(laurent, terme)
%AJOUTERCENTRE Somme de polynômes centrés sur leur terme du milieu.
    if isequal(laurent, 0)
        laurent = terme;
        return
    end
    ecart = (numel(terme) - numel(laurent)) / 2;
    if ecart > 0
        laurent = [zeros(1, ecart), laurent, zeros(1, ecart)];
    elseif ecart < 0
        terme = [zeros(1, -ecart), terme, zeros(1, -ecart)];
    end
    laurent = laurent + terme;
end

function [b, a, b1, b2] = maxflatSymetrique(n, Wn)
    if mod(n, 2) ~= 0
        error('signal:maxflat:Pair', ...
              'Pour un filtre symétrique, N doit être pair.');
    end
    d = n / 2;
    if d < 2
        error('signal:maxflat:Ordre', ...
              'Un filtre symétrique demande N au moins égal à quatre.');
    end
    % La réponse en phase nulle d'un filtre symétrique d'ordre N est un
    % polynôme M(x) de degré N/2, avec x = sin(w/2)^2. On lui impose K
    % zéros en x = 1 — la bande coupée — puis on écrit
    %
    %    M(x) = (1-x)^K [ somme_{k<D-K} C(K-1+k,k) x^k + gamma x^(D-K) ]
    %
    % où la somme est le développement de (1-x)^(-K) : elle rend M(x) - 1
    % nul à l'ordre D-K en x = 0, c'est la platitude en continu. Le
    % dernier coefficient, gamma, reste libre et sert à placer la coupure
    % exactement où on la demande. Gamma nul redonne le filtre de
    % Herrmann, dont la coupure n'est pas choisie mais subie.
    xc = sin(pi * Wn / 2) ^ 2;
    naturelles = zeros(1, d);
    for K = 1:d
        naturelles(K) = coupureHerrmann(K, d - K + 1);
    end
    [~, K] = min(abs(naturelles - Wn));
    K = min(max(K, 1), d - 1);
    L = d - K;
    coefficients = zeros(1, L + 1);
    for k = 0:(L - 1)
        coefficients(k + 1) = nchoosek(K - 1 + k, k);
    end
    facteur = developperPuissance([1 -1], K);
    reste = 0;
    for k = 0:(L - 1)
        reste = reste + coefficients(k + 1) * xc ^ k;
    end
    coefficients(L + 1) = (0.5 / max((1 - xc) ^ K, realmin) - reste) / xc ^ L;
    enX = conv(coefficients, facteur);
    if min(polyval(enX(end:-1:1), linspace(0, 1, 2001))) < -1e-9
        error('signal:maxflat:Intervalle', ...
              ['Pour N = %d la coupure d''un filtre symétrique va de ' ...
               '%.4f à %.4f.'], n, min(naturelles), max(naturelles));
    end
    b = polynomeEnZ(enX);
    a = 1;
    b1 = poly(-ones(1, 2 * K));
    b1 = b1 / sum(b1);
    b2 = deconv(b, b1);
end

function laurent = polynomeEnZ(enX)
%POLYNOMEENZ Passage d'un polynôme en x = sin(w/2)^2 à un polynôme en z.
%   La substitution est x = (2 - z - 1/z)/4 ; le résultat est symétrique,
%   donc c'est bien un filtre à phase nulle décalé d'un demi-support.
    laurent = 0;
    base = [-1 2 -1] / 4;
    puissance = 1;
    for k = 0:(numel(enX) - 1)
        if k > 0
            puissance = conv(puissance, base);
        end
        laurent = ajouterCentre(laurent, enX(k + 1) * puissance);
    end
end

function p = developperPuissance(base, K)
%DEVELOPPERPUISSANCE Puissance K d'un polynôme, en puissances croissantes.
    p = 1;
    for k = 1:K
        p = conv(p, base);
    end
end

function Wn = coupureHerrmann(K, L)
    coefficients = zeros(1, L);
    for k = 0:(L - 1)
        coefficients(k + 1) = nchoosek(K - 1 + k, k);
    end
    valeur = @(x) (1 - x) ^ K * sum(coefficients .* x .^ (0:(L - 1)));
    bas = 0;
    haut = 1;
    for it = 1:200
        milieu = (bas + haut) / 2;
        if valeur(milieu) > 0.5
            bas = milieu;
        else
            haut = milieu;
        end
    end
    Wn = 2 * asin(sqrt((bas + haut) / 2)) / pi;
end

function decrireMaxflat(b, a, Wn)
    fprintf('  gain continu : %.6f\n', abs(sum(b) / sum(a)));
    z = exp(1i * pi * Wn);
    fprintf('  gain à la coupure : %.6f (attendu %.6f)\n', ...
            abs(polyval(b, 1 / z) / polyval(a, 1 / z)), 1 / sqrt(2));
    fprintf('  gain à Nyquist : %.3e\n', abs(polyval(b, -1) / polyval(a, -1)));
end
