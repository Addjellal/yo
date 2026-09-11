function M = symmatrix2sym(a)
%SYMMATRIX2SYM Développe une matrice symbolique en ses éléments.
%   M = SYMMATRIX2SYM(A) rend la matrice de SYM que A représente. Une
%   matrice nommée A de taille MxN donne les éléments A1_1 à AM_N ; une
%   expression est développée selon l'algèbre matricielle — le produit
%   devient une somme de produits, l'inverse un quotient de
%   déterminants.
%
%   C'est le passage du raisonnement sur la matrice au calcul sur ses
%   coefficients : l'un se relit, l'autre se substitue et s'évalue.
%
%   Exemple :
%      A = symmatrix('A', [2 2]);
%      M = symmatrix2sym(A * A);
%      char(M(1, 1))                   % 'A1_1^2 + A1_2*A2_1'
%
%   Voir aussi SYMMATRIX, SYM, SUBS, DOUBLE.
    if ~isa(a, 'symmatrix')
        a = symmatrix(a);
    end
    M = matlibre_symmat_etendre(a.arbre);
end
