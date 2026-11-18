function [matrice, info] = blosum(identite, varargin)
%BLOSUM Matrice de substitution BLOSUM des acides aminés.
%   M = BLOSUM(N) rend la matrice BLOSUM N (Henikoff et Henikoff, 1992),
%   construite sur les blocs de séquences identiques à N % au plus :
%   N vaut 45, 50, 62, 80 ou 90. L'ordre des acides aminés est celui de
%   MATLAB : ARNDCQEGHILKMFPSTWYVBZX*.
%   [M,INFO] = BLOSUM(N) rend aussi la fiche de la matrice : Name, Scale
%   (l'échelle en bits : 1/3 pour BLOSUM50, 1/2 pour BLOSUM62), Entropy,
%   ExpectedScore, HighestScore, LowestScore, Order.
%   BLOSUM(N,'Extended',false) ne garde que les vingt acides aminés ;
%   BLOSUM(N,'Order',ORDRE) range les lignes et colonnes dans ORDRE.
%
%   Les autres pourcentages de MATLAB (30 à 100) ne sont pas fournis :
%   BLOSUM le dit au lieu de rendre une matrice voisine.
%
%   Exemple :
%      [M, info] = blosum(62);
%      M(1, 1)              % 4 : A contre A
%      info.Scale           % 0.5
%
%   Voir aussi PAM, NUC44, NWALIGN, SWALIGN.
    if ~isnumeric(identite) || ~isscalar(identite) || ...
            ~any(identite == [45 50 62 80 90])
        error('bioinfo:blosum:Identite', ...
              ['BLOSUM %s n''est pas fournie : MatLibre a BLOSUM45, 50, 62, 80 et 90, ', ...
               'tirées des fichiers du NCBI.'], num2str(identite));
    end
    [matrice, info] = matlibre_info_matrice(sprintf('BLOSUM%d', identite), varargin, 'blosum');
end
