function racines = matlibre_sym_racines_rationnelles(coefficients)
%MATLIBRE_SYM_RACINES_RATIONNELLES Racines rationnelles d'un polynôme entier.
%   Le théorème des racines rationnelles : si p/q est racine d'un
%   polynôme à coefficients entiers, alors p divise le terme constant et
%   q divise le coefficient dominant. Il suffit donc d'essayer les
%   quotients des diviseurs de l'un par ceux de l'autre — leur nombre est
%   fini, et aucune autre racine rationnelle n'existe.
%
%   C'est une preuve, non une recherche numérique : une racine trouvée
%   l'est exactement, et une racine non trouvée n'existe pas.
%
%   Les racines sont rendues avec leur multiplicité, en ordre croissant.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      r = matlibre_sym_racines_rationnelles([1 -3 2]);   % x^2 - 3x + 2
%      isequal(r, [1 2])
%
%   Voir aussi FACTOR, ROOTS, SOLVE.
    [racines, ~] = racinesEtQuotient(coefficients);
end

function [racines, reste] = racinesEtQuotient(coefficients)
%RACINESETQUOTIENT Les racines p/q, et le quotient entier qui reste.
%   Chaque racine est vérifiée exactement — q^n*P(p/q), calculé en
%   entiers par Horner, doit valoir zéro —, et le polynôme est divisé par
%   (q*x - p), ce qui garde des coefficients entiers : aucune tolérance
%   n'intervient, sauf quand les entiers dépassent 2^53.
    coefficients = double(coefficients(:)).';
    racines = [];
    reste = coefficients;
    if numel(coefficients) < 2 || any(~isfinite(coefficients)) || ...
            any(coefficients ~= round(coefficients))
        return
    end
    while numel(reste) > 1
        if reste(end) == 0
            racines(end + 1) = 0;   %#ok<AGROW>
            reste = reste(1:end-1);
            continue
        end
        [p, q] = quotientsPossibles(reste(end), reste(1));
        trouve = false;
        for k = 1:numel(p)
            if estRacine(reste, p(k), q(k))
                racines(end + 1) = p(k) / q(k);   %#ok<AGROW>
                reste = round(deconv(reste, [q(k) -p(k)]));
                trouve = true;
                break
            end
        end
        if ~trouve
            break
        end
    end
    racines = sort(racines);
end

function oui = estRacine(c, p, q)
%ESTRACINE P(p/q) = 0, exactement : q^n*P(p/q) = somme c(i)*p^(n-i)*q^i.
    s = c(1);
    exact = true;
    for i = 2:numel(c)
        s = s * p + c(i) * q ^ (i - 1);
        if abs(s) > flintmax || abs(c(i) * q ^ (i - 1)) > flintmax
            exact = false;
            break
        end
    end
    if exact
        oui = s == 0;
        return
    end
    % Au delà de 2^53, les entiers ne sont plus exacts : on retombe sur une
    % tolérance relative à la taille des termes.
    x = p / q;
    n = numel(c) - 1;
    termes = abs(c) .* abs(x) .^ (n:-1:0);
    oui = abs(polyval(c, x)) <= 1e-12 * sum(termes);
end

function [p, q] = quotientsPossibles(constant, dominant)
%QUOTIENTSPOSSIBLES Les candidats ±a/b, a divise le terme constant et b
%   le coefficient dominant, irréductibles, les entiers d'abord.
    a = diviseurs(abs(constant));
    b = diviseurs(abs(dominant));
    p = [];
    q = [];
    for i = 1:numel(a)
        for j = 1:numel(b)
            if gcd(a(i), b(j)) == 1
                p(end + 1) = a(i);    %#ok<AGROW>
                q(end + 1) = b(j);    %#ok<AGROW>
                p(end + 1) = -a(i);   %#ok<AGROW>
                q(end + 1) = b(j);    %#ok<AGROW>
            end
        end
    end
    [~, ordre] = sortrows([q(:), abs(p(:))]);
    p = p(ordre);
    q = q(ordre);
end

function d = diviseurs(n)
    if n == 0
        d = 1;
        return
    end
    d = [];
    for k = 1:floor(sqrt(n))
        if mod(n, k) == 0
            d(end + 1) = k;      %#ok<AGROW>
            if k ~= n / k
                d(end + 1) = n / k;   %#ok<AGROW>
            end
        end
    end
    d = sort(d);
end
