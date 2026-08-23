function x = idwt2(ca, ch, cv, cd, ondelette)
%IDWT2 Transformée en ondelettes bidimensionnelle inverse, un niveau.
%   X = IDWT2(CA,CH,CV,CD,ONDELETTE) reconstruit l'image.
    % Colonnes d'abord, dans l'ordre inverse de DWT2.
    for j = 1:size(ca, 2)
        r = idwt(ca(:, j)', ch(:, j)', ondelette);
        if j == 1, ligneA = zeros(numel(r), size(ca, 2)); end
        ligneA(:, j) = r(:);
    end
    for j = 1:size(cv, 2)
        r = idwt(cv(:, j)', cd(:, j)', ondelette);
        if j == 1, ligneD = zeros(numel(r), size(cv, 2)); end
        ligneD(:, j) = r(:);
    end
    for i = 1:size(ligneA, 1)
        r = idwt(ligneA(i, :), ligneD(i, :), ondelette);
        if i == 1, x = zeros(size(ligneA, 1), numel(r)); end
        x(i, :) = r;
    end
end
