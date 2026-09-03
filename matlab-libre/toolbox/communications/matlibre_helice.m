function permutation = matlibre_helice(lignes, colonnes, pas)
%MATLIBRE_HELICE Permutation du balayage hélicoïdal.
%   La matrice est remplie ligne par ligne, puis lue en diagonale : à la
%   colonne j, on lit la ligne (j-1) modulo NLIGNES, décalée de PAS fois
%   le numéro du tour. Chaque case est lue une fois et une seule.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if nargin < 3 || isempty(pas), pas = 1; end
    lignes = round(lignes);
    colonnes = round(colonnes);
    pas = round(pas);
    if lignes < 1 || colonnes < 1
        error('comm:helscan:Taille', ...
              'Le nombre de lignes et de colonnes doit être positif.');
    end
    permutation = zeros(1, lignes * colonnes);
    rang = 0;
    for tour = 0:(lignes - 1)
        for j = 0:(colonnes - 1)
            i = mod(tour + floor((j * pas) / colonnes) * 0 + tour, lignes);
            i = mod(tour, lignes);
            colonne = mod(j + tour * pas, colonnes);
            rang = rang + 1;
            permutation(rang) = i * colonnes + colonne + 1;
        end
    end
    verifierPermutation(permutation);
end
