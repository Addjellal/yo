function s = symsimplify(e)
%SYMSIMPLIFY Simplification des cas triviaux (0, 1, constantes).
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
