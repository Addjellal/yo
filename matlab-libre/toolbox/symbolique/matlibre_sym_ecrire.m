function texte = matlibre_sym_ecrire(arbre, priorite)
%MATLIBRE_SYM_ECRIRE Écriture d'une expression, parenthèses minimales.
%   PRIORITE est celle du contexte : on n'entoure de parenthèses que ce
%   qui lierait moins fort que lui.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    operateur = arbre{1};
    switch operateur
        case 'num'
            valeur = arbre{2};
            if valeur == round(valeur)
                texte = sprintf('%d', valeur);
            else
                texte = sprintf('%g', valeur);
            end
            if valeur < 0 && priorite > 0
                texte = ['(' texte ')'];
            end
            return
        case 'var'
            texte = arbre{2};
            return
    end
    if numel(arbre) == 2
        texte = [operateur '(' matlibre_sym_ecrire(arbre{2}, 0) ')'];
        return
    end
    switch operateur
        case '+', rang = 1;
        case '-', rang = 1;
        case '*', rang = 2;
        case '/', rang = 2;
        case '^', rang = 3;
        otherwise, rang = 3;
    end
    gauche = matlibre_sym_ecrire(arbre{2}, rang);
    % Le membre droit d'une soustraction, d'une division ou d'une
    % puissance doit être protégé au même rang : a - (b - c) n'est pas
    % a - b - c.
    if any(strcmp(operateur, {'-', '/', '^'}))
        droite = matlibre_sym_ecrire(arbre{3}, rang + 1);
    else
        droite = matlibre_sym_ecrire(arbre{3}, rang);
    end
    if strcmp(operateur, '^')
        texte = [gauche '^' droite];
    else
        texte = [gauche ' ' operateur ' ' droite];
    end
    if rang < priorite
        texte = ['(' texte ')'];
    end
end
