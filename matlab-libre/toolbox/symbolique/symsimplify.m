function s = symsimplify(e)
%SYMSIMPLIFY Simplification des cas triviaux.
%   S = SYMSIMPLIFY(E) réduit ce qui se réduit sans ruse : les constantes
%   se calculent, l'addition de zéro et la multiplication par un
%   disparaissent, la multiplication par zéro annule, la puissance zéro
%   ou un se résout.
%
%   Elle ne factorise pas, ne développe pas et ne reconnaît pas les
%   identités remarquables : la simplification symbolique complète est un
%   problème difficile, et une simplification partielle honnête vaut mieux
%   qu'une simplification approximative.
%
%   Elle est appliquée récursivement, des feuilles vers la racine : une
%   simplification en profondeur peut donc en déclencher une au-dessus.
%
%   Exemple :
%      x = sym('x');
%      symstr(symsimplify(symmul(symnum(1), x)))           % 'x'
%      symstr(symsimplify(symadd(symnum(2), symnum(3))))   % '5'
%      symstr(symsimplify(symmul(symnum(0), x)))           % '0'
%
%   Voir aussi SYMSTR, SYMSUBS, SIMPLIFY.
    operateur = e{1};
    if strcmp(operateur, 'num') || strcmp(operateur, 'var')
        s = e;
        return;
    end
    if numel(e) == 2
        s = {operateur, symsimplify(e{2})};
        return;
    end
    a = symsimplify(e{2});
    b = symsimplify(e{3});
    na = strcmp(a{1}, 'num');
    nb = strcmp(b{1}, 'num');
    switch operateur
        case '+'
            if na && a{2} == 0, s = b; return; end
            if nb && b{2} == 0, s = a; return; end
            if na && nb, s = symnum(a{2} + b{2}); return; end
        case '-'
            if nb && b{2} == 0, s = a; return; end
            if na && nb, s = symnum(a{2} - b{2}); return; end
        case '*'
            if (na && a{2} == 0) || (nb && b{2} == 0), s = symnum(0); return; end
            if na && a{2} == 1, s = b; return; end
            if nb && b{2} == 1, s = a; return; end
            if na && nb, s = symnum(a{2} * b{2}); return; end
        case '/'
            if na && a{2} == 0, s = symnum(0); return; end
            if nb && b{2} == 1, s = a; return; end
            if na && nb && b{2} ~= 0, s = symnum(a{2} / b{2}); return; end
        case '^'
            if nb && b{2} == 0, s = symnum(1); return; end
            if nb && b{2} == 1, s = a; return; end
            if na && nb, s = symnum(a{2} ^ b{2}); return; end
    end
    s = {operateur, a, b};
end
