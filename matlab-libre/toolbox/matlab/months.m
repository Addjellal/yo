function n = months(debut, fin, finDeMois)
%MONTHS Nombre de mois entre deux dates.
%   N = MONTHS(D1,D2) rend le nombre de mois entiers écoulés de D1 à D2.
%   Il est négatif quand D2 précède D1.
%
%   N = MONTHS(D1,D2,0) ne compte un mois que si le jour du mois de D2
%   atteint celui de D1 ; avec 1, valeur par défaut, deux dates en fin de
%   mois comptent un mois plein.
%
%   Exemple :
%      months('31-mar-2024', '30-apr-2024')     % 1
%
%   Voir aussi CALMONTHS, BETWEEN, DAYSACT, DATENUM.
    if nargin < 3
        finDeMois = 1;
    end
    a = versVecteurDate(debut);
    b = versVecteurDate(fin);
    if size(a, 1) == 1 && size(b, 1) > 1
        a = repmat(a, size(b, 1), 1);
    elseif size(b, 1) == 1 && size(a, 1) > 1
        b = repmat(b, size(a, 1), 1);
    end
    n = zeros(size(a, 1), 1);
    for k = 1:size(a, 1)
        n(k) = compter(a(k, :), b(k, :), finDeMois);
    end
end

function n = compter(a, b, finDeMois)
    n = (b(1) - a(1)) * 12 + (b(2) - a(2));
    if b(3) < a(3)
        dernierA = eomday(a(1), a(2));
        dernierB = eomday(b(1), b(2));
        complet = finDeMois && a(3) == dernierA && b(3) == dernierB;
        if ~complet
            n = n - 1;
        end
    end
end

function v = versVecteurDate(d)
    if isdatetime(d)
        v = [year(d(:)), month(d(:)), day(d(:))];
        return;
    end
    if ischar(d) || isstring(d) || iscell(d)
        d = datenum(d);
    end
    v = datevec(double(d(:)));
    v = v(:, 1:3);
end
