function valeur = matlibre_sym_limite(arbre, nom, cible, direction)
%MATLIBRE_SYM_LIMITE Limite approchée, par extrapolation de Richardson.
%   On évalue l'expression en une suite de points qui s'approchent
%   géométriquement, puis on extrapole : la table de Richardson efface
%   les termes d'erreur les uns après les autres, ce qu'une simple suite
%   de valeurs ne ferait pas.
%
%   Les pas restent volontairement grands — de un demi à deux
%   dix-millièmes. Les rétrécir davantage ne rapprocherait pas du
%   résultat mais l'éloignerait : (1-cos x)/x^2 en x = 1e-7 se calcule
%   sur une différence de deux nombres presque égaux, et il ne reste
%   plus un chiffre juste. C'est l'extrapolation qui fait le travail,
%   pas la petitesse du pas.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    nombre = 12;
    rapport = 2;
    valeurs = nan(1, nombre);
    if isinf(cible)
        echelle = 1;
    else
        echelle = max(1, abs(cible));
    end
    for k = 1:nombre
        pas = 0.5 * echelle / rapport ^ (k - 1);
        if isinf(cible)
            point = sign(cible) / pas;
        else
            switch direction
                case 'left',  point = cible - pas;
                case 'right', point = cible + pas;
                otherwise,    point = cible + pas;
            end
        end
        try
            valeurs(k) = symeval(symsubs(arbre, nom, symnum(point)));
        catch
            valeurs(k) = NaN;
        end
    end
    bons = isfinite(valeurs);
    if ~any(bons)
        valeur = NaN;
        return
    end
    valeurs = valeurs(bons);
    % Extrapolation de Richardson : chaque colonne annule un ordre de
    % l'erreur, le rapport des pas étant celui de la suite.
    table = valeurs(:).';
    for colonne = 1:min(8, numel(table) - 1)
        facteur = rapport ^ colonne;
        table = (facteur * table(2:end) - table(1:end-1)) / (facteur - 1);
        if numel(table) < 2
            break
        end
    end
    valeur = table(end);
    if abs(valeur) > 1e12
        valeur = sign(valeur) * Inf;
    end
    % Une limite très proche d'un entier ou d'un demi l'est.
    if isfinite(valeur) && abs(valeur - round(valeur)) < 1e-8 * max(abs(valeur), 1)
        valeur = round(valeur);
    end
end
