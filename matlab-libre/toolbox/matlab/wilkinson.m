function W = wilkinson(n)
%WILKINSON Matrice d'essai de Wilkinson.
%   W = WILKINSON(N) rend une matrice tridiagonale symétrique dont la
%   diagonale décroît puis recroît symétriquement, et dont les deux
%   sous-diagonales ne comptent que des uns.
%
%   Son intérêt tient à ses valeurs propres : les plus grandes vont par
%   paires presque égales, séparées de moins de 1e-14 pour N = 21. C'est
%   le cas d'école qui éprouve un algorithme de valeurs propres, car
%   distinguer deux valeurs si proches demande toute la précision de la
%   machine.
%
%   Exemple :
%      wilkinson(7)
%      v = sort(eig(wilkinson(21)), 'descend');
%      v(1) - v(2)                     % moins de 1e-13
%
%   Voir aussi EIG, PASCAL, HILB, HADAMARD.
    n = double(n);
    m = (n - 1) / 2;
    diagonale = abs((0:n-1) - m).';
    W = diag(diagonale) + diag(ones(n-1, 1), 1) + diag(ones(n-1, 1), -1);
end
