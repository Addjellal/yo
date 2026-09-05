function [a, e] = lpc(x, p)
%LPC Coefficients de prédiction linéaire.
%   [A,E] = LPC(X,P) rend le prédicteur d'ordre P qui minimise l'erreur
%   quadratique, et E la variance de cette erreur.
%
%   A est le polynôme du filtre inverse : FILTER(A,1,X) rend l'erreur de
%   prédiction, et FILTER(1,A,E) reconstruit le signal à partir d'elle.
%   A(1) vaut toujours un.
%
%   Le prédicteur se lit sur l'autocorrélation seule : c'est ce qui rend
%   la méthode utilisable en temps réel, et ce qui explique qu'elle soit
%   au cœur du codage de la parole. Au lieu de transmettre le signal, on
%   transmet P coefficients et une erreur bien plus petite.
%
%   L'autocorrélation est estimée par la moyenne, non par la somme : sans
%   cela E serait proportionnelle à la longueur du signal au lieu d'en
%   être la variance. Les coefficients, eux, ne changent pas — un facteur
%   commun sur l'autocorrélation ne les déplace pas.
%
%   Exemple :
%      x = filter(1, [1 -1.6 0.9], randn(2000, 1));
%      [a, e] = lpc(x, 2);
%      a                               % voisin de [1 -1.6 0.9]
%      abs(e - var(filter(a, 1, x)))   % petit : E est bien la variance
%
%   Voir aussi LEVINSON, XCORR, FILTER, ARBURG.
    x = x(:).';
    n = numel(x);
    if nargin < 2 || isempty(p)
        p = 1;
    end
    if p >= n
        error('dsp:lpc:Ordre', ...
              'L''ordre doit être inférieur au nombre d''échantillons.');
    end
    r = zeros(1, p + 1);
    for k = 0:p
        r(k + 1) = sum(x(1:n-k) .* x(1+k:n)) / n;
    end
    [a, e] = levinson(r, p);
end
