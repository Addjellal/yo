function [score, alignement] = nwalign(a, b, correspondance, difference, trou)
%NWALIGN Alignement global par l'algorithme de Needleman-Wunsch.
%   [SCORE,ALIGNEMENT] = NWALIGN(A,B) rend le score optimal et les deux
%   séquences alignées, empilées sur deux lignes.
%
%   [SCORE,ALIGNEMENT] = NWALIGN(A,B,CORRESPONDANCE,DIFFERENCE,TROU)
%   impose les trois coûts : le gain d'une correspondance, la pénalité
%   d'une différence, celle d'un trou.
%
%   Needleman-Wunsch est un alignement *global* : il aligne les séquences
%   sur toute leur longueur, quitte à ouvrir des trous aux extrémités.
%   C'est ce qu'on veut pour comparer deux gènes homologues de longueur
%   voisine, et ce qu'on ne veut pas pour chercher un motif court dans une
%   longue séquence — Smith-Waterman est fait pour cela.
%
%   La programmation dynamique le rend exact : contrairement à une
%   heuristique, il trouve l'alignement optimal, pas seulement un bon.
%   Le prix en est un coût en O(n m), en temps comme en mémoire.
%
%   Contrairement à la distance de Hamming, l'alignement sait traiter les
%   insertions et les suppressions : deux séquences identiques à une
%   insertion près lui paraissent proches, alors que SEQDIST les dit
%   totalement différentes.
%
%   Exemple :
%      [score, alignement] = nwalign('ACGTACGT', 'ACGACGT');
%      disp(alignement)                % le trou apparait
%
%   Voir aussi SWALIGN, SEQDIST, EDITDISTANCE.
    if nargin < 3, correspondance = 1; end
    if nargin < 4, difference = -1; end
    if nargin < 5, trou = -2; end
    a = upper(char(a));
    b = upper(char(b));
    n = numel(a);
    m = numel(b);
    F = zeros(n + 1, m + 1);
    F(:, 1) = (0:n).' * trou;
    F(1, :) = (0:m) * trou;
    for i = 1:n
        for j = 1:m
            if a(i) == b(j)
                diagonale = F(i, j) + correspondance;
            else
                diagonale = F(i, j) + difference;
            end
            F(i+1, j+1) = max([diagonale, F(i, j+1) + trou, F(i+1, j) + trou]);
        end
    end
    score = F(n+1, m+1);
    ligneA = '';
    ligneB = '';
    i = n;
    j = m;
    while i > 0 || j > 0
        if i > 0 && j > 0
            if a(i) == b(j)
                attendu = F(i, j) + correspondance;
            else
                attendu = F(i, j) + difference;
            end
        else
            attendu = -inf;
        end
        if i > 0 && j > 0 && F(i+1, j+1) == attendu
            ligneA = [a(i), ligneA];
            ligneB = [b(j), ligneB];
            i = i - 1;
            j = j - 1;
        elseif i > 0 && F(i+1, j+1) == F(i, j+1) + trou
            ligneA = [a(i), ligneA];
            ligneB = ['-', ligneB];
            i = i - 1;
        else
            ligneA = ['-', ligneA];
            ligneB = [b(j), ligneB];
            j = j - 1;
        end
    end
    alignement = [ligneA; ligneB];
end
