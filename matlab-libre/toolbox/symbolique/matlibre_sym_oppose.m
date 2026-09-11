function [negatif, oppose] = matlibre_sym_oppose(arbre)
%MATLIBRE_SYM_OPPOSE Un terme est-il négatif, et quel est son opposé ?
%   Un terme est négatif quand son facteur de tête l'est : c'est vrai
%   d'un nombre, et cela descend dans les produits et les quotients, dont
%   le signe est celui du numérateur.
%
%   Sert à écrire « a - 1/b » plutôt que « a + -1/b » : la somme d'un
%   terme négatif est une soustraction, et l'écrire ainsi est la seule
%   façon d'obtenir une expression qui se lit.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      [n, o] = matlibre_sym_oppose({'num', -3});
%      n && o{2} == 3
%      matlibre_sym_oppose({'var', 'x'})      % faux : x n'a pas de signe
%
%   Voir aussi MATLIBRE_SYM_ECRIRE, SYMSTR.
    negatif = false;
    oppose = arbre;
    switch arbre{1}
        case 'num'
            if arbre{2} < 0
                negatif = true;
                oppose = {'num', -arbre{2}};
            end
        case {'*', '/'}
            % Le signe d'un produit ou d'un quotient est celui de son
            % premier facteur : c'est lui qu'on retourne, les autres ne
            % bougent pas.
            [negatif, tete] = matlibre_sym_oppose(arbre{2});
            if negatif
                if strcmp(arbre{1}, '*') && isequal(tete, {'num', 1})
                    % Retourner -1 donne 1 : un facteur qui ne dit rien,
                    % et qu'on n'écrit donc pas.
                    oppose = arbre{3};
                else
                    oppose = {arbre{1}, tete, arbre{3}};
                end
            end
    end
end
