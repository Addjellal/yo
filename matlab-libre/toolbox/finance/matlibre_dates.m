function numeros = matlibre_dates(dates)
%MATLIBRE_DATES Numéros de série d'une date écrite de n'importe quelle façon.
%   Accepte les numéros, le texte, les tableaux de cellules et les
%   tableaux de chaînes. Les fonctions financières s'en servent pour
%   accepter les mêmes formes que MATLAB sans les répéter.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if isnumeric(dates)
        numeros = double(dates);
    elseif iscell(dates) || ischar(dates) || isstring(dates)
        numeros = datenum(dates);
    else
        error('finance:dates:Type', ...
              'Une date se donne par un numéro de série ou par du texte.');
    end
end
