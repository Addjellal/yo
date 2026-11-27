function sortie = matlibre_unite_longueur(unite, quoi)
%MATLIBRE_UNITE_LONGUEUR Le nombre de mètres d'une unité de longueur.
%   F = MATLIBRE_UNITE_LONGUEUR(UNITE) rend la longueur de UNITE en mètres ;
%   NOM = MATLIBRE_UNITE_LONGUEUR(UNITE,'nom') son nom canonique.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_unite_longueur('km')            % 1000
%
%   Voir aussi REFERENCEELLIPSOID.
    switch lower(char(unite))
        case {'m', 'meter', 'meters', 'metre', 'metres'}
            f = 1; nom = 'meter';
        case {'km', 'kilometer', 'kilometers', 'kilometre', 'kilometres'}
            f = 1000; nom = 'kilometer';
        case {'ft', 'foot', 'feet', 'international foot'}
            f = 0.3048; nom = 'foot';
        case {'mi', 'mile', 'miles', 'statute mile'}
            f = 1609.344; nom = 'mile';
        case {'nm', 'nautical mile', 'nauticalmile', 'nmi'}
            f = 1852; nom = 'nautical mile';
        otherwise
            error('map:unite:Inconnue', 'Unknown length unit: %s.', char(unite));
    end
    if nargin > 1 && strcmpi(quoi, 'nom')
        sortie = nom;
    else
        sortie = f;
    end
end
