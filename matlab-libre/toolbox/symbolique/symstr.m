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
        case '+'
            % Ajouter un nombre negatif s'ecrit comme une soustraction :
            % « x + -1 » se lit mal, « x - 1 » se lit.
            if strcmp(e{3}{1}, 'num') && e{3}{2} < 0
                s = ['(' symstr(e{2}) ' - ' symstr(symnum(-e{3}{2})) ')'];
            else
                s = ['(' symstr(e{2}) ' + ' symstr(e{3}) ')'];
            end
        case {'-', '*', '/', '^'}
            s = ['(' symstr(e{2}) ' ' operateur ' ' symstr(e{3}) ')'];
        otherwise
            s = [operateur '(' symstr(e{2}) ')'];
    end
end
