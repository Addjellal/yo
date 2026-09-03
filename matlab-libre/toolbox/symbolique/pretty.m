function sortie = pretty(expression)
%PRETTY Écriture lisible d'une expression symbolique.
%   PRETTY(F) affiche F sans les parenthèses que la priorité des
%   opérateurs rend inutiles.
%   S = PRETTY(F) rend le texte au lieu de l'afficher.
%
%   Exemple :
%      syms x
%      pretty(x ^ 2 + 3 * x - 1)      % x^2 + 3*x - 1
%
%   Voir aussi SYM, CHAR, LATEX, DISP.
    texte = matlibre_sym_ecrire(matlibre_sym_arbre(expression), 0);
    if nargout > 0
        sortie = texte;
    else
        fprintf('%s\n', texte);
    end
end
