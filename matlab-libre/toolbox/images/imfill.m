function r = imfill(bw, mode)
%IMFILL Bouche les trous d'une image binaire.
%   R = IMFILL(BW,'holes') remplit les régions de faux qui ne touchent pas
%   le bord. C'est une reconstruction morphologique depuis le bord, prise
%   par complément.
%
%   Exemple :
%      a = true(5); a(3,3) = false; sum(sum(imfill(a,'holes')))   % 25
    if nargin < 2, mode = 'holes'; end
    bw = logical(bw);
    if ~strcmpi(mode, 'holes')
        r = bw;
        return
    end
    fond = ~bw;
    [m, n] = size(bw);
    atteint = false(m, n);
    % Propagation depuis les bords, par balayages successifs.
    atteint(1, :) = fond(1, :);
    atteint(m, :) = fond(m, :);
    atteint(:, 1) = fond(:, 1);
    atteint(:, n) = fond(:, n);
    change = true;
    while change
        avant = atteint;
        for i = 2:m
            atteint(i, :) = atteint(i, :) | (fond(i, :) & atteint(i-1, :));
        end
        for i = m-1:-1:1
            atteint(i, :) = atteint(i, :) | (fond(i, :) & atteint(i+1, :));
        end
        for j = 2:n
            atteint(:, j) = atteint(:, j) | (fond(:, j) & atteint(:, j-1));
        end
        for j = n-1:-1:1
            atteint(:, j) = atteint(:, j) | (fond(:, j) & atteint(:, j+1));
        end
        change = any(any(atteint ~= avant));
    end
    r = bw | (fond & ~atteint);
end
