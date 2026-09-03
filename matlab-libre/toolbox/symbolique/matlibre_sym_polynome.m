function arbre = matlibre_sym_polynome(coefficients, nom)
%MATLIBRE_SYM_POLYNOME Arbre d'un polynôme donné par ses coefficients.
%   Les coefficients vont par puissances décroissantes. Les termes nuls
%   sont omis, les coefficients un ne sont pas écrits, et un coefficient
%   négatif donne une soustraction plutôt qu'une addition de nombre
%   négatif : « x^2 - 1 » au lieu de « x^2 + -1 ».
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    coefficients = double(coefficients(:)).';
    degre = numel(coefficients) - 1;
    arbre = [];
    for k = 1:numel(coefficients)
        c = coefficients(k);
        if c == 0
            continue
        end
        puissance = degre - k + 1;
        % Le premier terme garde son signe ; les suivants le portent dans
        % l'opérateur.
        if isempty(arbre)
            module = c;
        else
            module = abs(c);
        end
        if puissance == 0
            terme = symnum(module);
        else
            if puissance == 1
                base = {'var', nom};
            else
                base = sympow({'var', nom}, symnum(puissance));
            end
            if module == 1
                terme = base;
            else
                terme = symmul(symnum(module), base);
            end
        end
        if isempty(arbre)
            arbre = terme;
        elseif c < 0
            arbre = symsub(arbre, terme);
        else
            arbre = symadd(arbre, terme);
        end
    end
    if isempty(arbre)
        arbre = symnum(0);
    end
end
