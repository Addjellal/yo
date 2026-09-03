function sortie = latex(expression)
%LATEX Écriture LaTeX d'une expression symbolique.
%   S = LATEX(F) rend le code LaTeX de F : les fractions deviennent des
%   \frac, les puissances des exposants, les fonctions élémentaires des
%   commandes.
%
%   Exemple :
%      syms x
%      latex((x + 1) / (x ^ 2))       % '\frac{x + 1}{x^{2}}'
%
%   Voir aussi PRETTY, CHAR, SYM.
    sortie = matlibre_sym_latex(matlibre_sym_arbre(expression), 0);
end
