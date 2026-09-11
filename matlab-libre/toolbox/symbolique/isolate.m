function r = isolate(equation, variable)
%ISOLATE Isole une variable dans une équation.
%   ISOLATE(EQ,X) réécrit l'équation sous la forme X = ..., en défaisant
%   une à une les opérations qui entourent X.
%
%   Le procédé est celui qu'on apprend à l'école : on regarde ce qui
%   enveloppe l'inconnue et on applique l'opération inverse des deux
%   côtés. Une addition se défait par une soustraction, un produit par une
%   division, un carré par une racine, un sinus par un arc sinus. Cela ne
%   marche que si l'inconnue n'apparaît qu'une fois ; sinon il n'y a rien
%   à défaire, et ISOLATE le dit.
%
%   L'équation se donne comme une expression à annuler, ou avec un signe
%   d'égalité construit par EQ.
%
%   Exemple :
%      syms x
%      isolate(2*x + 3, x)             % x = -3/2
%      isolate(x^2 - 4, x)             % x = 2
%
%   Voir aussi SOLVE, VPASOLVE, SUBS, SIMPLIFY.
    equation = sym(equation);
    if nargin < 2 || isempty(variable)
        variable = matlibre_sym_defaut(equation);
    end
    nom = matlibre_sym_nom(variable);

    gauche = equation.arbre;
    droite = symnum(0);
    if strcmp(gauche{1}, '=')
        droite = gauche{3};
        gauche = gauche{2};
    end
    if matlibre_sym_compter(gauche, nom) + matlibre_sym_compter(droite, nom) ~= 1
        error('symbolic:isolate:plusieurs', ...
              ['ISOLATE ne sait defaire les operations que si ''%s'' ' ...
               'n''apparait qu''une fois.'], nom);
    end
    % Si l'inconnue est a droite, on echange : le procede ne sait
    % descendre que dans le membre de gauche.
    if matlibre_sym_compter(gauche, nom) == 0
        [gauche, droite] = deal(droite, gauche);
    end

    for pas = 1:100
        if strcmp(gauche{1}, 'var') && strcmp(gauche{2}, nom)
            break
        end
        [gauche, droite] = matlibre_sym_defaire(gauche, droite, nom);
    end
    r = sym({'=', {'var', nom}, matlibre_sym_reduire(droite)});
end
