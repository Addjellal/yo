function arbre = matlibre_sym_horner(coefficients, nom)
%MATLIBRE_SYM_HORNER Arbre de la forme de Horner d'un polynôme.
%   Les coefficients vont par puissances décroissantes. La forme
%   emboîtée s'écrit
%
%      a x^3 + b x^2 + c x + d  =  ((a x + b) x + c) x + d
%
%   ce qui l'évalue en n multiplications et n additions au lieu des
%   n(n+1)/2 que demanderait le calcul terme à terme. C'est aussi la
%   forme la plus stable : chaque étape ne combine que deux nombres.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      a = matlibre_sym_horner([1 2 3], 'x');
%      char(sym(a))                    % (x + 2)*x + 3
%
%   Voir aussi HORNER, POLYVAL, MATLIBRE_SYM_POLYNOME.
    coefficients = double(coefficients(:)).';
    if isempty(coefficients)
        arbre = symnum(0);
        return
    end
    % Un coefficient dominant egal a un ne s'ecrit pas : « (x + 2)*x »
    % plutot que « (1*x + 2)*x ».
    if coefficients(1) == 1 && numel(coefficients) > 1
        arbre = {'var', nom};
        depart = 3;
        if numel(coefficients) >= 2 && coefficients(2) ~= 0
            if coefficients(2) > 0
                arbre = symadd(arbre, symnum(coefficients(2)));
            else
                arbre = symsub(arbre, symnum(-coefficients(2)));
            end
        end
    else
        arbre = symnum(coefficients(1));
        depart = 2;
    end
    for k = depart:numel(coefficients)
        arbre = symmul(arbre, {'var', nom});
        if coefficients(k) ~= 0
            if coefficients(k) > 0
                arbre = symadd(arbre, symnum(coefficients(k)));
            else
                arbre = symsub(arbre, symnum(-coefficients(k)));
            end
        end
    end
end
