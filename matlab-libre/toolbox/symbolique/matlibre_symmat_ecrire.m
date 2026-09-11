function texte = matlibre_symmat_ecrire(arbre, priorite)
%MATLIBRE_SYMMAT_ECRIRE Écriture d'une expression matricielle symbolique.
%   TEXTE = MATLIBRE_SYMMAT_ECRIRE(ARBRE,PRIORITE) rend l'expression avec
%   le moins de parenthèses possible : on n'entoure que ce qui lierait
%   moins fort que le contexte. Une matrice se lit comme son nom, un
%   produit s'écrit collé, une somme espacée.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_symmat_ecrire({'*', {'mat','A',[2 2]}, {'mat','B',[2 2]}}, 0)
%
%   Voir aussi SYMMATRIX, MATLIBRE_SYM_ECRIRE.
    if nargin < 2, priorite = 0; end
    switch arbre{1}
        case 'mat'
            texte = arbre{2};
            return
        case 'const'
            texte = matlibre_symmat_constante(arbre{2});
            return
        case 'trans'
            texte = [matlibre_symmat_ecrire(arbre{2}, 4) ''''];
            return
        case {'inv', 'det', 'trace'}
            texte = [arbre{1} '(' matlibre_symmat_ecrire(arbre{2}, 0) ')'];
            return
        case 'kron'
            texte = ['kron(' matlibre_symmat_ecrire(arbre{2}, 0) ', ' ...
                     matlibre_symmat_ecrire(arbre{3}, 0) ')'];
            return
        case 'neg'
            texte = ['-' matlibre_symmat_ecrire(arbre{2}, 3)];
            if priorite > 1, texte = ['(' texte ')']; end
            return
        case 'pow'
            texte = [matlibre_symmat_ecrire(arbre{2}, 4) '^' num2str(arbre{3})];
            if priorite > 3, texte = ['(' texte ')']; end
            return
    end
    switch arbre{1}
        case {'+', '-'}, rang = 1;
        otherwise,       rang = 2;
    end
    gauche = matlibre_symmat_ecrire(arbre{2}, rang);
    if strcmp(arbre{1}, '-')
        droite = matlibre_symmat_ecrire(arbre{3}, rang + 1);
    else
        droite = matlibre_symmat_ecrire(arbre{3}, rang);
    end
    if rang == 1
        texte = [gauche ' ' arbre{1} ' ' droite];
    else
        texte = [gauche arbre{1} droite];
    end
    if rang < priorite
        texte = ['(' texte ')'];
    end
end
