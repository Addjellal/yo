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
    coefficients = double(coefficients(:)).';
    racines = [];
    if numel(coefficients) < 2 || any(coefficients ~= round(coefficients))
        return
    end
    reste = coefficients;
    continuer = true;
    while continuer && numel(reste) > 1
        continuer = false;
        % Un terme constant nul veut dire que zero est racine : le
        % theoreme ne s'applique qu'ensuite.
        if reste(end) == 0
            racines(end + 1) = 0;   %#ok<AGROW>
            reste = reste(1:end-1);
            continuer = true;
            continue
        end
        candidats = quotientsPossibles(reste(end), reste(1));
        for c = candidats
            if abs(polyval(reste, c)) < 1e-9 * max(1, max(abs(reste)))
                racines(end + 1) = c;   %#ok<AGROW>
                reste = deconv(reste, [1 -c]);
                continuer = true;
                break
            end
        end
    end
    racines = sort(racines);
end

function q = quotientsPossibles(constant, dominant)
% Les p/q avec p divisant le terme constant et q le dominant, dans les
% deux signes. C'est l'ensemble fini que le theoreme designe.
    p = diviseurs(abs(constant));
    d = diviseurs(abs(dominant));
    q = [];
    for a = p
        for b = d
            q(end + 1) = a / b;    %#ok<AGROW>
            q(end + 1) = -a / b;   %#ok<AGROW>
        end
    end
    q = unique(q);
    % Les entiers d'abord : ce sont les plus frequents, et les trouver
    % tot raccourcit le polynome avant les essais suivants.
    [~, ordre] = sort(abs(q - round(q)) + abs(q) * 1e-6);
    q = q(ordre);
end

function d = diviseurs(n)
% Tous les diviseurs positifs de n.
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
