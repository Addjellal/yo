function [r, p, k] = residue(b, a, varargin)
%RESIDUE Décomposition en éléments simples d'une fraction rationnelle.
%   [R,P,K] = RESIDUE(B,A) décompose B(s)/A(s), polynômes donnés par
%   leurs coefficients en puissances décroissantes, sous la forme
%
%      B(s)     R(1)         R(n)
%      ---- = -------- +...+ -------- + K(s)
%      A(s)   s - P(1)       s - P(n)
%
%   Pour un pôle de multiplicité M, les M termes qui lui correspondent
%   sont consécutifs et valent R(j)/(s-P)^j, j = 1..M, comme dans MATLAB.
%
%   [B,A] = RESIDUE(R,P,K) fait le chemin inverse et reconstitue la
%   fraction.
%
%   Exemple :
%      [r,p,k] = residue([1 0], [1 3 2])   % 1/(s+1) et -... sur s+2
    if nargin >= 3 && ~isempty(varargin)
        [r, p] = recomposer(b, a, varargin{1});
        k = [];
        return
    elseif nargin >= 3
        [r, p] = recomposer(b, a, []);
        k = [];
        return
    end
    b = double(b(:)).';
    a = double(a(:)).';
    b = retirerZerosDeTete(b);
    a = retirerZerosDeTete(a);
    if isempty(a)
        error('MATLAB:residue:ZeroDenominator', 'Le dénominateur est nul.');
    end
    % Partie entière : la division euclidienne, si le numérateur est de
    % degré au moins égal à celui du dénominateur.
    k = [];
    if numel(b) >= numel(a)
        [k, b] = deconv(b, a);
        b = retirerZerosDeTete(b);
    end
    poles = roots(a);
    [poles, multiplicites] = regrouper(poles);
    r = [];
    p = [];
    for indice = 1:numel(poles)
        racine = poles(indice);
        m = multiplicites(indice);
        % Dénominateur privé du facteur (s - racine)^m.
        reduit = a;
        for j = 1:m
            reduit = deconv(reduit, [1 -racine]);
        end
        % Développements de Taylor autour du pôle, par divisions
        % synthétiques successives : c'est exact sur des polynômes.
        bb = taylor(b, racine, m);
        aa = taylor(reduit, racine, m);
        % Série du quotient : q0 = bb0/aa0 puis récurrence.
        q = zeros(1, m);
        for n = 0:m-1
            somme = bb(n + 1);
            for i = 1:n
                somme = somme - aa(i + 1) * q(n - i + 1);
            end
            q(n + 1) = somme / aa(1);
        end
        % Le terme en 1/(s-p)^j vaut q(m-j+1).
        for j = 1:m
            r(end + 1, 1) = q(m - j + 1);      %#ok<AGROW>
            p(end + 1, 1) = racine;            %#ok<AGROW>
        end
    end
    r = r(:);
    p = p(:);
    k = k(:).';
end

function c = taylor(poly, x0, nombre)
%TAYLOR Coefficients ascendants du développement de POLY autour de X0.
%   Divisions synthétiques successives : le reste de chaque division par
%   (s - x0) donne le coefficient suivant.
    c = zeros(1, nombre);
    reste = poly;
    for k = 1:nombre
        if isempty(reste)
            c(k) = 0;
            continue
        end
        % Horner : quotient et reste de la division par (s - x0).
        quotient = zeros(1, numel(reste) - 1);
        accumulateur = reste(1);
        for j = 2:numel(reste)
            quotient(j - 1) = accumulateur;
            accumulateur = reste(j) + accumulateur * x0;
        end
        c(k) = accumulateur;
        reste = quotient;
    end
end

function [uniques, multiplicites] = regrouper(poles)
%REGROUPER Rassemble les pôles égaux, à la tolérance de MATLAB près.
%   La tolérance est celle de MPOLES : un millième en relatif. Un pôle
%   triple sort de ROOTS avec une erreur en racine cubique de l'epsilon
%   machine — trois millionièmes —, si bien qu'une tolérance plus serrée
%   le prenait pour trois pôles distincts et faisait exploser les
%   résidus.
    uniques = [];
    multiplicites = [];
    reste = poles(:);
    while ~isempty(reste)
        courant = reste(1);
        tolerance = 1e-3 * max(1, abs(courant));
        proches = abs(reste - courant) <= tolerance;
        uniques(end + 1, 1) = mean(reste(proches));   %#ok<AGROW>
        multiplicites(end + 1, 1) = sum(proches);     %#ok<AGROW>
        reste = reste(~proches);
    end
end

function [b, a] = recomposer(r, p, k)
%RECOMPOSER Somme des éléments simples, remise sur dénominateur commun.
    r = r(:);
    p = p(:);
    a = 1;
    for j = 1:numel(p)
        a = conv(a, [1 -p(j)]);
    end
    b = zeros(1, numel(a));
    j = 1;
    while j <= numel(p)
        % Combien de fois ce pôle est-il répété à partir d'ici ?
        m = 1;
        while j + m <= numel(p) && abs(p(j + m) - p(j)) <= 1e-6 * max(1, abs(p(j)))
            m = m + 1;
        end
        for ordre = 1:m
            terme = 1;
            reste = p;
            % Le dénominateur commun privé de (s-p)^ordre.
            compte = 0;
            for i = 1:numel(reste)
                if i >= j && i < j + ordre
                    continue
                end
                terme = conv(terme, [1 -reste(i)]);
                compte = compte + 1;                    %#ok<NASGU>
            end
            terme = r(j + ordre - 1) * terme;
            b = ajouter(b, terme);
        end
        j = j + m;
    end
    if ~isempty(k)
        b = ajouter(b, conv(k(:).', a));
    end
    % Les termes de tête s'annulent en arithmétique exacte ; en flottant
    % il en reste des miettes, qu'on ne garde pas comme degré.
    b = retirerZerosNegligeables(b);
end

function v = retirerZerosNegligeables(v)
    if isempty(v), return, end
    seuil = 1e-12 * max(abs(v));
    while numel(v) > 1 && abs(v(1)) <= seuil
        v(1) = [];
    end
end

function s = ajouter(u, v)
    n = max(numel(u), numel(v));
    s = [zeros(1, n - numel(u)) u] + [zeros(1, n - numel(v)) v];
end

function v = retirerZerosDeTete(v)
    while ~isempty(v) && v(1) == 0
        v(1) = [];
    end
end
