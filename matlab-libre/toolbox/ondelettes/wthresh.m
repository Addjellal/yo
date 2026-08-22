function y = wthresh(x, genre, seuil)
%WTHRESH Seuillage des coefficients d'ondelettes.
%   Y = WTHRESH(X,'s',T) applique le seuillage doux, 'h' le seuillage dur.
    if strcmpi(genre, 's')
        y = sign(x) .* max(abs(x) - seuil, 0);
    else
        y = x .* (abs(x) > seuil);
    end
end
