function arbre = matlibre_sym_developper(arbre)
%MATLIBRE_SYM_DEVELOPPER Distribue les produits sur les sommes.
%   La règle est celle de l'école : a(b+c) devient ab+ac, et une
%   puissance entière positive se développe par produits répétés. Le
%   développement s'arrête quand plus rien ne change.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    for tour = 1:20
        nouveau = matlibre_sym_distribuer(arbre);
        if isequal(nouveau, arbre)
            break
        end
        arbre = nouveau;
    end
end

function arbre = matlibre_sym_distribuer(arbre)
    operateur = arbre{1};
    if strcmp(operateur, 'num') || strcmp(operateur, 'var')
        return
    end
    if numel(arbre) == 2
        arbre = {operateur, matlibre_sym_distribuer(arbre{2})};
        return
    end
    a = matlibre_sym_distribuer(arbre{2});
    b = matlibre_sym_distribuer(arbre{3});
    switch operateur
        case '*'
            if any(strcmp(a{1}, {'+', '-'}))
                arbre = {a{1}, symsimplify(symmul(a{2}, b)), ...
                                symsimplify(symmul(a{3}, b))};
                return
            end
            if any(strcmp(b{1}, {'+', '-'}))
                arbre = {b{1}, symsimplify(symmul(a, b{2})), ...
                                symsimplify(symmul(a, b{3}))};
                return
            end
        case '^'
            if strcmp(b{1}, 'num') && b{2} == round(b{2}) && b{2} >= 2 && b{2} <= 12
                produit = a;
                for k = 2:b{2}
                    produit = symmul(produit, a);
                end
                arbre = matlibre_sym_distribuer(produit);
                return
            end
        case '/'
            % Une somme divisée par un facteur se répartit terme à terme.
            if any(strcmp(a{1}, {'+', '-'}))
                arbre = {a{1}, symsimplify(symdiv(a{2}, b)), ...
                                symsimplify(symdiv(a{3}, b))};
                return
            end
    end
    arbre = {operateur, a, b};
end
