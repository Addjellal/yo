function r = symsubs(e, variable, valeur)
%SYMSUBS Substitution d'une variable par une expression ou un nombre.
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
