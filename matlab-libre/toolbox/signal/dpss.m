function [E, V] = dpss(n, nw, k)
%DPSS Suites sphéroïdales aplaties discrètes, ou fenêtres de Slepian.
%   [E,V] = DPSS(N,NW,K) rend les K premières suites de longueur N et de
%   produit temps-bande NW, ainsi que leurs taux de concentration V.
%
%   Ce sont les suites de longueur N dont l'énergie est la plus
%   concentrée dans la bande [-NW/N, NW/N]. Elles s'obtiennent comme
%   vecteurs propres d'une matrice tridiagonale symétrique qui commute
%   avec le noyau de concentration : c'est numériquement bien plus sûr
%   que de diagonaliser le noyau lui-même, et la structure tridiagonale
%   permet de n'extraire que les K vecteurs voulus, par bissection sur la
%   suite de Sturm puis itération inverse.
%
%   Exemple :
%      [E, V] = dpss(128, 4, 7);   % sept fenêtres, V proches de 1
    if nargin < 3 || isempty(k), k = 2 * nw - 1; end
    k = max(1, round(k));
    n = round(n);
    k = min(k, n);
    W = nw / n;
    indices = (0:n-1)';
    diagonale = ((n - 1 - 2 * indices) / 2) .^ 2 * cos(2 * pi * W);
    horsDiagonale = indices(2:end) .* (n - indices(2:end)) / 2;
    valeurs = plusGrandesValeursPropres(diagonale, horsDiagonale, k);
    E = zeros(n, k);
    for j = 1:k
        E(:, j) = vecteurPropreTridiagonal(diagonale, horsDiagonale, valeurs(j));
    end
    % Convention de signe de MATLAB : somme positive pour les suites
    % d'indice impair, pente positive pour les paires.
    for j = 1:k
        if mod(j, 2) == 1
            if sum(E(:, j)) < 0, E(:, j) = -E(:, j); end
        else
            if sum((1:n)' .* E(:, j)) < 0, E(:, j) = -E(:, j); end
        end
    end
    if nargout > 1
        V = concentrations(E, W);
    end
end

function valeurs = plusGrandesValeursPropres(d, e, k)
%PLUSGRANDESVALEURSPROPRES Les K plus grandes, par bissection de Sturm.
    n = numel(d);
    rayon = zeros(n, 1);
    for i = 1:n
        r = 0;
        if i > 1, r = r + abs(e(i - 1)); end
        if i < n, r = r + abs(e(i)); end
        rayon(i) = r;
    end
    bas = min(d - rayon);
    haut = max(d + rayon);
    etendue = haut - bas;
    if etendue == 0, etendue = 1; end
    valeurs = zeros(k, 1);
    for j = 1:k
        % On cherche la j-ième valeur propre en partant du haut : c'est
        % le point où le compte des valeurs propres inférieures passe de
        % n-j à n-j+1.
        cible = n - j;
        a = bas - etendue;
        b = haut + etendue;
        for iteration = 1:200
            milieu = (a + b) / 2;
            if compteSturm(d, e, milieu) <= cible
                a = milieu;
            else
                b = milieu;
            end
            if b - a <= 1e-14 * max(1, abs(b)), break, end
        end
        valeurs(j) = (a + b) / 2;
    end
end

function compte = compteSturm(d, e, x)
%COMPTESTURM Nombre de valeurs propres strictement inférieures à X.
    n = numel(d);
    compte = 0;
    q = d(1) - x;
    if q < 0, compte = compte + 1; end
    for i = 2:n
        if q == 0
            q = 1e-300;
        end
        q = d(i) - x - e(i - 1) ^ 2 / q;
        if q < 0, compte = compte + 1; end
    end
end

function v = vecteurPropreTridiagonal(d, e, lambda)
%VECTEURPROPRETRIDIAGONAL Itération inverse sur une tridiagonale.
    n = numel(d);
    % Un décalage minuscule évite une matrice exactement singulière.
    decalage = lambda + 1e-12 * max(1, abs(lambda));
    v = ones(n, 1) / sqrt(n);
    for iteration = 1:5
        v = resoudreTridiagonale(d - decalage, e, v);
        normeV = norm(v);
        if normeV == 0 || ~isfinite(normeV)
            v = ones(n, 1) / sqrt(n);
            break
        end
        v = v / normeV;
    end
end

function x = resoudreTridiagonale(d, e, b)
%RESOUDRETRIDIAGONALE Algorithme de Thomas, avec garde contre le pivot nul.
    n = numel(d);
    c = zeros(n, 1);
    y = zeros(n, 1);
    pivot = d(1);
    if pivot == 0, pivot = 1e-300; end
    if n > 1, c(1) = e(1) / pivot; end
    y(1) = b(1) / pivot;
    for i = 2:n
        pivot = d(i) - e(i - 1) * c(i - 1);
        if pivot == 0, pivot = 1e-300; end
        if i < n
            c(i) = e(i) / pivot;
        end
        y(i) = (b(i) - e(i - 1) * y(i - 1)) / pivot;
    end
    x = zeros(n, 1);
    x(n) = y(n);
    for i = n-1:-1:1
        x(i) = y(i) - c(i) * x(i + 1);
    end
end

function V = concentrations(E, W)
%CONCENTRATIONS Part de l'énergie tombant dans la bande.
%   Le taux vaut v' K v avec K le noyau en sinus cardinal. Comme K ne
%   dépend que de l'écart des indices, la forme quadratique se ramène à
%   la somme des autocorrélations de v pondérées par le noyau : exact,
%   et en n log n au lieu de n au carré.
    n = size(E, 1);
    tau = (1:n-1)';
    noyau = sin(2 * pi * W * tau) ./ (pi * tau);
    V = zeros(size(E, 2), 1);
    for j = 1:size(E, 2)
        v = E(:, j);
        spectre = abs(fft(v, 2 * n)) .^ 2;
        auto = real(ifft(spectre));
        V(j) = auto(1) * 2 * W + 2 * sum(auto(2:n) .* noyau);
    end
end
