function x = qamdemod(y, M, ordre)
%QAMDEMOD Démodulation QAM par décision sur la grille.
%   X = QAMDEMOD(Y,M) rend le symbole du point de la grille le plus
%   proche.
%   X = QAMDEMOD(Y,M,ORDRE) reprend l'ordre employé à la modulation ;
%   ORDRE vaut 'gray' (défaut) ou 'bin'.
%
%   La grille étant un produit de deux axes, la décision se prend axe par
%   axe : arrondir la partie réelle et la partie imaginaire suffit, et
%   aucune recherche du plus proche point n'est nécessaire.
%
%   Exemple :
%      qamdemod(qammod(0:15, 16), 16)      % 0:15
%
%   Voir aussi QAMMOD, PSKDEMOD, GENQAMDEMOD.
    if nargin < 3 || isempty(ordre)
        ordre = 'gray';
    end
    cote = round(sqrt(M));
    i = round((real(y) + cote - 1) / 2);
    q = round((imag(y) + cote - 1) / 2);
    i = min(max(i, 0), cote - 1);
    q = min(max(q, 0), cote - 1);
    i = matlibre_comm_symbole(i, cote, ordre);
    q = matlibre_comm_symbole(q, cote, ordre);
    x = q * cote + i;
end
