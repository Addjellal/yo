function motif = matlibre_police_5x7(texte)
%MATLIBRE_POLICE_5X7 Motif binaire d'un texte, cinq colonnes par lettre.
%   M = MATLIBRE_POLICE_5X7(TEXTE) rend une matrice logique de sept
%   lignes : le dessin du texte dans une fonte de chiffres tracée ici même,
%   cinq colonnes par caractère et une colonne blanche entre deux.
%
%   Le tableau couvre l'ASCII imprimable, de l'espace au tilde. Un
%   caractère hors de cet intervalle est dessiné comme un espace.
%
%   Exemple :
%      m = matlibre_police_5x7('ok');
%      size(m)    % 7 11
%
%   Voir aussi INSERTTEXT, INSERTOBJECTANNOTATION.
    persistent table
    if isempty(table)
        table = tableGlyphes();
    end
    texte = char(texte);
    texte = texte(:).';
    if isempty(texte)
        motif = false(7, 0);
        return
    end
    motif = false(7, 6 * numel(texte) - 1);
    for k = 1:numel(texte)
        code = double(texte(k));
        if code < 32 || code > 126
            code = 32;
        end
        lignes = table(code - 31, :);
        colonne = 6 * (k - 1);
        for i = 1:7
            bits = lignes(i);
            for j = 1:5
                % Le bit de poids fort est la colonne de gauche.
                if bitand(bits, 2 ^ (5 - j)) ~= 0
                    motif(i, colonne + j) = true;
                end
            end
        end
    end
end

function table = tableGlyphes()
% Une ligne par caractère, de l'espace (32) au tilde (126) ; sept nombres
% de cinq bits, du haut vers le bas.
    table = [ ...
         0  0  0  0  0  0  0; ...   %
         4  4  4  4  4  0  4; ...   % !
        10 10  0  0  0  0  0; ...   % "
        10 10 31 10 31 10 10; ...   % #
         4 15 20 14  5 30  4; ...   % $
        24 25  2  4  8 19  3; ...   % %
        12 18 20  8 21 18 13; ...   % &
         4  4  0  0  0  0  0; ...   % '
         2  4  8  8  8  4  2; ...   % (
         8  4  2  2  2  4  8; ...   % )
         0  4 21 14 21  4  0; ...   % *
         0  4  4 31  4  4  0; ...   % +
         0  0  0  0  0  4  8; ...   % ,
         0  0  0 31  0  0  0; ...   % -
         0  0  0  0  0  0  4; ...   % .
         1  2  2  4  8  8 16; ...   % /
        14 17 19 21 25 17 14; ...   % 0
         4 12  4  4  4  4 14; ...   % 1
        14 17  1  2  4  8 31; ...   % 2
        31  2  4  2  1 17 14; ...   % 3
         2  6 10 18 31  2  2; ...   % 4
        31 16 30  1  1 17 14; ...   % 5
         6  8 16 30 17 17 14; ...   % 6
        31  1  2  4  8  8  8; ...   % 7
        14 17 17 14 17 17 14; ...   % 8
        14 17 17 15  1  2 12; ...   % 9
         0  4  4  0  4  4  0; ...   % :
         0  4  4  0  4  4  8; ...   % ;
         2  4  8 16  8  4  2; ...   % <
         0  0 31  0 31  0  0; ...   % =
         8  4  2  1  2  4  8; ...   % >
        14 17  1  2  4  0  4; ...   % ?
        14 17 23 21 23 16 14; ...   % @
        14 17 17 31 17 17 17; ...   % A
        30 17 17 30 17 17 30; ...   % B
        14 17 16 16 16 17 14; ...   % C
        28 18 17 17 17 18 28; ...   % D
        31 16 16 30 16 16 31; ...   % E
        31 16 16 30 16 16 16; ...   % F
        14 17 16 23 17 17 15; ...   % G
        17 17 17 31 17 17 17; ...   % H
        14  4  4  4  4  4 14; ...   % I
         7  2  2  2  2 18 12; ...   % J
        17 18 20 24 20 18 17; ...   % K
        16 16 16 16 16 16 31; ...   % L
        17 27 21 21 17 17 17; ...   % M
        17 17 25 21 19 17 17; ...   % N
        14 17 17 17 17 17 14; ...   % O
        30 17 17 30 16 16 16; ...   % P
        14 17 17 17 21 18 13; ...   % Q
        30 17 17 30 20 18 17; ...   % R
        15 16 16 14  1  1 30; ...   % S
        31  4  4  4  4  4  4; ...   % T
        17 17 17 17 17 17 14; ...   % U
        17 17 17 17 17 10  4; ...   % V
        17 17 17 21 21 27 17; ...   % W
        17 17 10  4 10 17 17; ...   % X
        17 17 10  4  4  4  4; ...   % Y
        31  1  2  4  8 16 31; ...   % Z
        14  8  8  8  8  8 14; ...   % [
        16  8  8  4  2  2  1; ...   % \
        14  2  2  2  2  2 14; ...   % ]
         4 10 17  0  0  0  0; ...   % ^
         0  0  0  0  0  0 31; ...   % _
         8  4  0  0  0  0  0; ...   % `
         0  0 14  1 15 17 15; ...   % a
        16 16 30 17 17 17 30; ...   % b
         0  0 14 16 16 17 14; ...   % c
         1  1 15 17 17 17 15; ...   % d
         0  0 14 17 31 16 14; ...   % e
         6  9  8 28  8  8  8; ...   % f
         0  0 15 17 15  1 14; ...   % g
        16 16 30 17 17 17 17; ...   % h
         4  0 12  4  4  4 14; ...   % i
         2  0  6  2  2 18 12; ...   % j
        16 16 18 20 24 20 18; ...   % k
        12  4  4  4  4  4 14; ...   % l
         0  0 26 21 21 21 21; ...   % m
         0  0 30 17 17 17 17; ...   % n
         0  0 14 17 17 17 14; ...   % o
         0  0 30 17 30 16 16; ...   % p
         0  0 15 17 15  1  1; ...   % q
         0  0 22 25 16 16 16; ...   % r
         0  0 15 16 14  1 30; ...   % s
         8  8 28  8  8  9  6; ...   % t
         0  0 17 17 17 19 13; ...   % u
         0  0 17 17 17 10  4; ...   % v
         0  0 17 17 21 21 10; ...   % w
         0  0 17 10  4 10 17; ...   % x
         0  0 17 17 15  1 14; ...   % y
         0  0 31  2  4  8 31; ...   % z
         2  4  4  8  4  4  2; ...   % {
         4  4  4  4  4  4  4; ...   % |
         8  4  4  2  4  4  8; ...   % }
         0  8 21  2  0  0  0];      % ~
end
