function s = symstr(e)
%SYMSTR Écriture lisible d'une expression symbolique.
    operateur = e{1};
    switch operateur
        case 'num'
            if e{2} == round(e{2})
                s = sprintf('%d', e{2});
            else
                s = sprintf('%g', e{2});
            end
        case 'var'
            s = e{2};
        case {'+', '-', '*', '/', '^'}
            s = ['(' symstr(e{2}) ' ' operateur ' ' symstr(e{3}) ')'];
        otherwise
            s = [operateur '(' symstr(e{2}) ')'];
    end
end
