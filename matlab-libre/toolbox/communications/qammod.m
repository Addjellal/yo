function y = qammod(x, M, ordre)
%QAMMOD Modulation d'amplitude en quadrature à M états (M carré).
%   Y = QAMMOD(X,M) place le symbole X sur une grille carrée centrée,
%   d'espacement deux.
%   Y = QAMMOD(X,M,ORDRE) où ORDRE vaut 'gray' (défaut, comme MATLAB) ou
%   'bin'.
%
%   Contrairement à une modulation de phase, l'amplitude porte ici de
%   l'information : on gagne des points, donc des bits par symbole, mais
%   on les rapproche, donc on perd en résistance au bruit. C'est
%   l'arbitrage qui décide de la modulation d'un lien.
%
%   Le codage de Gray s'applique à chaque axe séparément : deux points
%   voisins de la grille, en abscisse comme en ordonnée, ne diffèrent que
%   d'un bit.
%
%   Exemple :
%      c = qammod(0:15, 16);
%      mean(abs(c) .^ 2)               % energie moyenne
%
%   Voir aussi QAMDEMOD, PSKMOD, GENQAMMOD, MODNORM.
    if nargin < 3 || isempty(ordre)
        ordre = 'gray';
    end
    cote = sqrt(M);
    if abs(cote - round(cote)) > 1e-9
        error('comm:qammod:notSquare', 'M must be a perfect square.');
    end
    cote = round(cote);
    i = mod(x, cote);
    q = floor(x / cote);
    i = matlibre_comm_position(i, cote, ordre);
    q = matlibre_comm_position(q, cote, ordre);
    y = (2 * i - cote + 1) + 1i * (2 * q - cote + 1);
end
