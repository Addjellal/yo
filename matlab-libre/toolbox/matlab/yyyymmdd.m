function n = yyyymmdd(d)
%YYYYMMDD Date écrite comme un nombre AAAAMMJJ.
%   N = YYYYMMDD(D) rend la date sous la forme du nombre entier
%   AAAAMMJJ : le 3 février 2024 devient 20240203. D est une date, un
%   numéro de série ou du texte.
%
%   Exemple :
%      yyyymmdd(datetime(2024, 2, 3))     % 20240203
%
%   Voir aussi DATENUM, DATESTR, DATEVEC, YEAR, MONTH, DAY.
    if isdatetime(d)
        v = [year(d(:)), month(d(:)), day(d(:))];
        forme = size(d);
    else
        if ischar(d) || isstring(d) || iscell(d)
            d = datenum(d);
        end
        forme = size(d);
        v = datevec(double(d(:)));
        v = v(:, 1:3);
    end
    n = v(:, 1) * 10000 + v(:, 2) * 100 + v(:, 3);
    n = reshape(n, forme);
end
