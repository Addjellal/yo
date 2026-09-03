function d = eomday(annee, mois)
%EOMDAY Dernier jour du mois.
%   D = EOMDAY(A,M) rend le numéro du dernier jour du mois M de l'année
%   A : 28 ou 29 pour février selon que l'année est bissextile.
%
%   Exemple :
%      eomday(2024, 2)     % 29
%
%   Voir aussi CALENDAR, DATENUM, WEEKDAY, DAYSACT.
    annee = double(annee);
    mois = double(mois);
    if isscalar(annee) && ~isscalar(mois)
        annee = repmat(annee, size(mois));
    elseif isscalar(mois) && ~isscalar(annee)
        mois = repmat(mois, size(annee));
    end
    longueurs = [31 28 31 30 31 30 31 31 30 31 30 31];
    d = zeros(size(mois));
    for k = 1:numel(mois)
        m = mois(k);
        if m < 1 || m > 12 || m ~= fix(m)
            error('MATLAB:eomday:BadMonth', 'Mois hors de 1..12.');
        end
        d(k) = longueurs(m);
        if m == 2 && bissextile(annee(k))
            d(k) = 29;
        end
    end
end

function tf = bissextile(a)
    tf = (mod(a, 4) == 0 && mod(a, 100) ~= 0) || mod(a, 400) == 0;
end
