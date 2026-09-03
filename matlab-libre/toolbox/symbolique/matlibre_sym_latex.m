function texte = matlibre_sym_latex(arbre, priorite)
%MATLIBRE_SYM_LATEX Écriture LaTeX d'un arbre d'expression.
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
                texte = ['\left(' texte '\right)'];
            end
            return
        case 'var'
            texte = arbre{2};
            return
    end
    if numel(arbre) == 2
        interieur = matlibre_sym_latex(arbre{2}, 0);
        switch operateur
            case 'sqrt'
                texte = ['\sqrt{' interieur '}'];
            case 'log'
                texte = ['\ln\left(' interieur '\right)'];
            otherwise
                texte = ['\' operateur '\left(' interieur '\right)'];
        end
        return
    end
    switch operateur
        case '/'
            texte = ['\frac{' matlibre_sym_latex(arbre{2}, 0) '}{' ...
                     matlibre_sym_latex(arbre{3}, 0) '}'];
            return
        case '^'
            texte = [matlibre_sym_latex(arbre{2}, 4) '^{' ...
                     matlibre_sym_latex(arbre{3}, 0) '}'];
            return
        case '*', rang = 2; signe = ' ';
        case '+', rang = 1; signe = ' + ';
        case '-', rang = 1; signe = ' - ';
        otherwise, rang = 3; signe = operateur;
    end
    gauche = matlibre_sym_latex(arbre{2}, rang);
    if strcmp(operateur, '-')
        droite = matlibre_sym_latex(arbre{3}, rang + 1);
    else
        droite = matlibre_sym_latex(arbre{3}, rang);
    end
    texte = [gauche signe droite];
    if rang < priorite
        texte = ['\left(' texte '\right)'];
    end
end
