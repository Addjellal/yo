function r = symsubs(e, variable, valeur)
%SYMSUBS Substitution d'une variable par une expression ou un nombre.
%   R = SYMSUBS(E,VARIABLE,VALEUR) remplace toutes les occurrences de la
%   variable nommée par VALEUR, qui peut être un nombre ou une autre
%   expression.
%
%   La substitution ne simplifie pas : remplacer x par 2 dans x + x donne
%   « 2 + 2 », non « 4 ». C'est voulu — SYMSIMPLIFY fait ce travail, et
%   les séparer permet de voir ce que chaque étape produit.
%
%   Substituer une expression, non un nombre, est ce qui permet de
%   composer des fonctions symboliquement.
%
%   Exemple :
%      x = sym('x');
%      symstr(symsubs(symadd(x, x), 'x', 2))       % '2 + 2'
%      symstr(symsimplify(symsubs(symadd(x, x), 'x', 2)))   % '4'
%
%   Voir aussi SYMSIMPLIFY, SYMSTR, SUBS.
    if ~iscell(valeur)
        valeur = symnum(valeur);
    end
    operateur = e{1};
    switch operateur
        case 'num'
            r = e;
        case 'var'
            if strcmp(e{2}, variable)
                r = valeur;
            else
                r = e;
            end
        otherwise
            if numel(e) == 2
                r = {operateur, symsubs(e{2}, variable, valeur)};
            else
                r = {operateur, symsubs(e{2}, variable, valeur), ...
                     symsubs(e{3}, variable, valeur)};
            end
    end
    r = symsimplify(r);
end
