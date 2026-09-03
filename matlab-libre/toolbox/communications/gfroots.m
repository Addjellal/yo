function [racines, polynomeMinimal] = gfroots(f, m, p)
%GFROOTS Racines d'un polynôme dans un corps de Galois d'extension.
%   R = GFROOTS(F,M,P) cherche les racines du polynôme F — coefficients
%   par puissances croissantes, à valeurs dans GF(P) — parmi les éléments
%   de GF(P^M). Les racines sont rendues sous forme d'exposants : la
%   valeur K désigne l'élément x^K, et -Inf l'élément nul.
%
%   R = GFROOTS(F,M) travaille sur GF(2^M) ; GFROOTS(F,PRIM,P) emploie le
%   polynôme primitif PRIM au lieu du polynôme par défaut.
%
%   [R,MIN] = GFROOTS(...) rend en outre, pour chaque racine, le polynôme
%   minimal de la classe cyclotomique à laquelle elle appartient.
%
%   Un polynôme de degré D a au plus D racines dans une extension ; il
%   les a toutes dès que l'extension est assez grande.
%
%   Exemple :
%      gfroots([1 1 1], 2)            % [1; 2] : les deux éléments
%                                     % d'ordre trois de GF(4)
%
%   Voir aussi GFPRIMDF, GFTABLE, GFCOSETS, GFDECONV.
    if nargin < 3 || isempty(p), p = 2; end
    exigerPremier(p, 'gfroots');
    if numel(m) > 1
        prim = mod(double(gftrunc(m(:).')), p);
        degre = numel(prim) - 1;
    else
        degre = round(m);
        prim = gfprimdf(degre, p);
    end
    table = gftable(degre, prim, p);
    f = mod(double(gftrunc(f(:).')), p);
    nombre = p ^ degre;
    racines = [];
    for k = 1:nombre
        element = table(k, :);
        if estRacine(f, element, prim, p)
            if k == 1
                racines(end + 1) = -Inf;   %#ok<AGROW>
            else
                racines(end + 1) = k - 2;  %#ok<AGROW>
            end
        end
    end
    racines = racines(:);
    if nargout > 1
        polynomeMinimal = cell(numel(racines), 1);
        for k = 1:numel(racines)
            polynomeMinimal{k} = minimalDe(racines(k), degre, prim, p);
        end
    end
end

function oui = estRacine(f, element, prim, p)
%ESTRACINE Évalue F en un élément du corps, par la méthode de Horner.
    valeur = zeros(1, numel(prim) - 1);
    for k = numel(f):-1:1
        valeur = reduire(conv(valeur, element), prim, p);
        valeur(1) = mod(valeur(1) + f(k), p);
    end
    oui = all(mod(valeur, p) == 0);
end

function r = reduire(v, prim, p)
    [~, reste] = gfdeconv(mod(v, p), prim, p);
    r = completerLongueur(gftrunc(reste), numel(prim) - 1);
end

function poly = minimalDe(exposant, degre, prim, p)
%MINIMALDE Polynôme minimal d'un élément, produit sur sa classe.
%   Le produit des (x - alpha^k) sur toute la classe cyclotomique est à
%   coefficients dans GF(p) : c'est ce qui en fait le polynôme minimal de
%   l'élément, celui de plus bas degré qui l'annule.
    if isinf(exposant)
        poly = [0 1];        % x, dont zéro est la racine
        return
    end
    n = p ^ degre - 1;
    classe = exposant;
    courant = mod(exposant * p, n);
    while courant ~= exposant
        classe(end + 1) = courant;   %#ok<AGROW>
        courant = mod(courant * p, n);
    end
    table = gftable(degre, prim, p);
    % Le polynôme est une cellule : une case par degré, chacune portant
    % un élément du corps écrit sur « degre » coefficients.
    un = zeros(1, degre);
    un(1) = 1;
    poly = {un};
    for k = 1:numel(classe)
        racine = table(classe(k) + 2, :);
        poly = multiplierParFacteur(poly, racine, prim, p, degre);
    end
    poly = coefficientsScalaires(poly, p);
end

function q = multiplierParFacteur(poly, racine, prim, p, degre)
%MULTIPLIERPARFACTEUR Multiplie par (x - racine) un polynôme à
%   coefficients dans le corps.
    n = numel(poly);
    q = cell(1, n + 1);
    for k = 1:(n + 1)
        q{k} = zeros(1, degre);
    end
    for k = 1:n
        % Le terme monté d'un degré : x fois le coefficient.
        q{k + 1} = mod(q{k + 1} + poly{k}, p);
        % Et le terme retenu : moins la racine fois le coefficient.
        produit = reduire(conv(poly{k}, racine), prim, p);
        q{k} = mod(q{k} - produit, p);
    end
end

function c = coefficientsScalaires(poly, p)
%COEFFICIENTSSCALAIRES Ramène des coefficients du corps à GF(p).
    c = zeros(1, numel(poly));
    for k = 1:numel(poly)
        v = poly{k};
        if any(mod(v(2:end), p) ~= 0)
            error('comm:gfroots:NonMinimal', ...
                  'Le produit sur la classe n''est pas à coefficients dans GF(p).');
        end
        c(k) = mod(v(1), p);
    end
    c = gftrunc(c);
end
