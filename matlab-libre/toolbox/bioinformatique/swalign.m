function [score, alignement] = swalign(a, b, correspondance, difference, trou)
%SWALIGN Alignement local par l'algorithme de Smith-Waterman.
    if nargin < 3, correspondance = 2; end
    if nargin < 4, difference = -1; end
    if nargin < 5, trou = -2; end
    a = upper(char(a));
    b = upper(char(b));
    n = numel(a);
    m = numel(b);
    H = zeros(n + 1, m + 1);
    meilleur = 0;
    bi = 1;
    bj = 1;
    for i = 1:n
        for j = 1:m
            if a(i) == b(j)
                diagonale = H(i, j) + correspondance;
            else
                diagonale = H(i, j) + difference;
            end
            H(i+1, j+1) = max([0, diagonale, H(i, j+1) + trou, H(i+1, j) + trou]);
            if H(i+1, j+1) > meilleur
                meilleur = H(i+1, j+1);
                bi = i;
                bj = j;
            end
        end
    end
    score = meilleur;
    ligneA = '';
    ligneB = '';
    i = bi;
    j = bj;
    while i > 0 && j > 0 && H(i+1, j+1) > 0
        if a(i) == b(j)
            attendu = H(i, j) + correspondance;
        else
            attendu = H(i, j) + difference;
        end
        if H(i+1, j+1) == attendu
            ligneA = [a(i), ligneA];
            ligneB = [b(j), ligneB];
            i = i - 1;
            j = j - 1;
        elseif H(i+1, j+1) == H(i, j+1) + trou
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
