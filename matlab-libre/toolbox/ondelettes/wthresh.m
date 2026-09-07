function y = wthresh(x, genre, seuil)
%WTHRESH Seuillage des coefficients d'ondelettes.
%   Y = WTHRESH(X,'s',T) applique le seuillage doux, 'h' le seuillage dur.
%
%   Exemple :
%      wthresh([-3 -1 0 1 3], 'h', 2)     % -3 0 0 0 3 : le seuillage dur
%      wthresh([-3 -1 0 1 3], 's', 2)     % -1 0 0 0 1 : le seuillage doux
%
%   Voir aussi WDENCMP, THSELECT, WNOISEST.
    if strcmpi(genre, 's')
        y = sign(x) .* max(abs(x) - seuil, 0);
    else
        y = x .* (abs(x) > seuil);
    end
end
