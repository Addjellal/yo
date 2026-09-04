function contraintes = pcpval(valeurPortefeuille, nombreActifs)
%PCPVAL Contraintes de budget d'un portefeuille.
%   C = PCPVAL(VALEUR,N) rend le jeu de contraintes qui impose que la
%   somme des poids vaille VALEUR et qu'aucun poids ne soit négatif.
%
%   Un jeu de contraintes s'écrit [A b] et se lit A*w <= b. Une égalité y
%   tient en deux lignes de sens contraires.
%
%   Exemple :
%      pcpval(1, 3)
%
%   Voir aussi PCALIMS, PCGLIMS, PORTCONS, PORTOPT.
    if nargin < 2 || isempty(nombreActifs)
        error('finance:pcpval:Arguments', 'Il faut le nombre d''actifs.');
    end
    n = round(nombreActifs);
    A = [ones(1, n); -ones(1, n); -eye(n)];
    b = [valeurPortefeuille; -valeurPortefeuille; zeros(n, 1)];
    contraintes = [A, b];
end
