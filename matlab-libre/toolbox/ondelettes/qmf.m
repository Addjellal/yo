function y = qmf(x, p)
%QMF Miroir en quadrature d'un filtre.
%   Y = QMF(X) rend le filtre renversé dont un échantillon sur deux
%   change de signe. QMF(X,P) décale la parité du changement de signe.
%
%   Exemple :
%      qmf([1 2 3 4])   % [4 -3 2 -1]
    if nargin < 2 || isempty(p), p = 0; end
    x = double(x);
    ligne = isrow(x);
    y = flipud(x(:));
    n = numel(y);
    % MATLAB change le signe des éléments d'indice pair du vecteur
    % renversé : le premier garde donc le sien.
    signes = (-1) .^ ((1:n)' + 1 + p);
    y = y .* signes;
    if ligne, y = y.'; end
end
