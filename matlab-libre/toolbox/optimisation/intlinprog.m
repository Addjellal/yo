function [x, fval, exitflag] = intlinprog(f, entieres, A, b, Aeq, beq, lb, ub)
%INTLINPROG Programmation linéaire en nombres entiers.
%   X = INTLINPROG(F,INTCON,A,B,AEQ,BEQ,LB,UB) minimise F'*X sous
%   A*X <= B et AEQ*X = BEQ, les variables d'indices INTCON étant
%   entières.
%
%   La résolution se fait par séparation et évaluation : on résout la
%   relaxation continue, puis on scinde sur une variable fractionnaire.
%   C'est exact, au prix d'un arbre qui peut grandir.
%
%   Exemple :
%      x = intlinprog([-1; -2], [1 2], [1 1], 4, [], [], [0; 0], []);
%
%   Voir aussi LINPROG, QUADPROG, BINTPROG, OPTIMPROBLEM, SOLVE.
    if nargin < 3, A = []; end

    if nargin < 4, b = []; end
    if nargin < 5, Aeq = []; end
    if nargin < 6, beq = []; end
    if nargin < 7, lb = []; end
    if nargin < 8, ub = []; end
    f = f(:);
    n = numel(f);
    if isempty(lb), lb = -inf(n, 1); else, lb = lb(:); lb(end+1:n) = -inf; end
    if isempty(ub), ub = inf(n, 1); else, ub = ub(:); ub(end+1:n) = inf; end
    entieres = entieres(:)';

    meilleure = inf;
    meilleurX = [];
    pile = {struct('lb', lb, 'ub', ub)};
    tours = 0;
    while ~isempty(pile) && tours < 2000
        tours = tours + 1;
        noeud = pile{end};
        pile(end) = [];
        [xr, fr, ok] = linprog(f, A, b, Aeq, beq, ...
                               bornesFinies(noeud.lb, -1e9), bornesFinies(noeud.ub, 1e9));
        if ~ok || isempty(xr), continue, end
        if fr >= meilleure - 1e-9, continue, end          % borne : coupe
        fractionnaire = 0;
        for k = entieres
            if abs(xr(k) - round(xr(k))) > 1e-6
                fractionnaire = k;
                break
            end
        end
        if fractionnaire == 0
            candidat = xr;
            candidat(entieres) = round(candidat(entieres));
            meilleure = f' * candidat;
            meilleurX = candidat;
            continue
        end
        valeur = xr(fractionnaire);
        gauche = noeud;
        gauche.ub(fractionnaire) = floor(valeur);
        droite = noeud;
        droite.lb(fractionnaire) = ceil(valeur);
        if gauche.lb(fractionnaire) <= gauche.ub(fractionnaire)
            pile{end + 1} = gauche; %#ok<AGROW>
        end
        if droite.lb(fractionnaire) <= droite.ub(fractionnaire)
            pile{end + 1} = droite; %#ok<AGROW>
        end
    end
    if isempty(meilleurX)
        x = [];
        fval = [];
        exitflag = -2;
    else
        x = meilleurX;
        fval = meilleure;
        exitflag = 1;
    end
end

function v = bornesFinies(b, remplacement)
%BORNESFINIES Remplace les bornes infinies : la barrière logarithmique de
%   linprog ne sait pas les traiter.
    v = b;
    v(isinf(v)) = remplacement * sign(v(isinf(v)));
end
