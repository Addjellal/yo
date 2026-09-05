function [m, unique] = matlibre_rob_lignes(a, largeur, nom)
%MATLIBRE_ROB_LIGNES Normalise une entrée en matrice de N lignes.
%   [M,UNIQUE] = MATLIBRE_ROB_LIGNES(A,LARGEUR,NOM) rend A sous forme
%   d'une matrice à LARGEUR colonnes, une ligne par élément, et dit si
%   l'entrée n'en comptait qu'une — auquel cas les fonctions rendent un
%   résultat simple plutôt qu'une pile.
%
%   Les fonctions de conversion de MATLAB acceptent toutes une pile :
%   EUL2ROTM d'une matrice N sur 3 rend un tableau 3x3xN. Passer par ici
%   évite de réécrire ce contrôle dans chacune.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    m = double(a);
    if isvector(m) && numel(m) == largeur
        m = m(:).';
        unique = true;
        return
    end
    if size(m, 2) ~= largeur
        error('robotics:conversion:Largeur', ...
              '%s doit avoir %d colonnes.', nom, largeur);
    end
    unique = size(m, 1) == 1;
end
