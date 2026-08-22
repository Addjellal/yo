function x = qamdemod(y, M)
%QAMDEMOD Démodulation QAM par décision sur la grille.
    cote = round(sqrt(M));
    i = round((real(y) + cote - 1) / 2);
    q = round((imag(y) + cote - 1) / 2);
    i = min(max(i, 0), cote - 1);
    q = min(max(q, 0), cote - 1);
    x = q * cote + i;
end
