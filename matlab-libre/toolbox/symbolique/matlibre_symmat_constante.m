function texte = matlibre_symmat_constante(valeurs)
%MATLIBRE_SYMMAT_CONSTANTE Écriture d'une matrice constante.
%   TEXTE = MATLIBRE_SYMMAT_CONSTANTE(VALEURS) rend « [a, b; c, d] ».
%   Une matrice 1x1 s'écrit sans crochets : dans une expression, les
%   crochets d'un scalaire ne disent rien de plus.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_symmat_constante([1 2; 3 4])    % '[1, 2; 3, 4]'
%
%   Voir aussi SYMMATRIX, MATLIBRE_SYMMAT_ECRIRE.
    [m, n] = size(valeurs);
    lignes = cell(1, m);
    for i = 1:m
        cases = cell(1, n);
        for j = 1:n
            cases{j} = element(valeurs, i, j);
        end
        lignes{i} = strjoin(cases, ', ');
    end
    if m == 1 && n == 1
        texte = lignes{1};
    else
        texte = ['[' strjoin(lignes, '; ') ']'];
    end
end

function t = element(valeurs, i, j)
    if isa(valeurs, 'sym')
        t = char(valeurs(i, j));
    else
        v = valeurs(i, j);
        if v == round(v)
            t = sprintf('%d', v);
        else
            t = sprintf('%g', v);
        end
    end
end
