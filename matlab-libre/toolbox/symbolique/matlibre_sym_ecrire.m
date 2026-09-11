function texte = matlibre_sym_ecrire(arbre, priorite, aGauche)
%MATLIBRE_SYM_ECRIRE Écriture d'une expression, parenthèses minimales.
%   PRIORITE est celle du contexte : on n'entoure de parenthèses que ce
%   qui lierait moins fort que lui. AGAUCHE dit si l'expression est
%   l'opérande de gauche : un nombre négatif y est sans danger — « -1/x »
%   se lit —, alors qu'à droite il en faut — « a - (-1) ».
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if nargin < 3, aGauche = false; end
    operateur = arbre{1};
    switch operateur
        case 'num'
            valeur = arbre{2};
            if valeur == round(valeur)
                texte = sprintf('%d', valeur);
            else
                texte = sprintf('%g', valeur);
            end
            if valeur < 0 && priorite > 0 && ~aGauche
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
        % L'egalite lie moins fort que tout le reste : ses deux membres
        % n'ont donc jamais besoin de parentheses.
        case '=', rang = 0;
        case '+', rang = 1;
        case '-', rang = 1;
        case '*', rang = 2;
        case '/', rang = 2;
        case '^', rang = 3;
        otherwise, rang = 3;
    end
    % Ajouter un terme negatif s'ecrit comme une soustraction : « x + -1 »
    % et « a + -1/b » se lisent mal, « x - 1 » et « a - 1/b » se lisent.
    % Un terme est negatif si son facteur de tete l'est, ce qui descend
    % dans les produits et les quotients.
    if strcmp(operateur, '+')
        [negatif, oppose] = matlibre_sym_oppose(arbre{3});
        if negatif
            arbre = {'-', arbre{2}, oppose};
            operateur = '-';
        end
    end
    gauche = matlibre_sym_ecrire(arbre{2}, rang, true);
    % Le membre droit d'une soustraction, d'une division ou d'une
    % puissance doit être protégé au même rang : a - (b - c) n'est pas
    % a - b - c.
    if strcmp(operateur, '=')
        droite = matlibre_sym_ecrire(arbre{3}, 0, true);
    elseif any(strcmp(operateur, {'-', '/', '^'}))
        droite = matlibre_sym_ecrire(arbre{3}, rang + 1);
    else
        droite = matlibre_sym_ecrire(arbre{3}, rang);
    end
    % L'espacement suit MATLAB : les termes d'une somme sont ecartes, les
    % facteurs d'un produit sont colles. C'est ce qui fait voir la
    % structure d'un coup d'oeil — « x^2 + 2*x + 1 » se lit en trois
    % termes, « x^2 + 2 * x + 1 » demande de compter.
    if any(strcmp(operateur, {'^', '*', '/'}))
        texte = [gauche operateur droite];
    else
        texte = [gauche ' ' operateur ' ' droite];
    end
    if rang < priorite
        texte = ['(' texte ')'];
    end
end
