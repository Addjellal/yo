function [x, y, portee, methode, degre] = matlibre_smooth_arguments(arguments)
%MATLIBRE_SMOOTH_ARGUMENTS Démêle les arguments de SMOOTH.
%   [X,Y,PORTEE,METHODE,DEGRE] = MATLIBRE_SMOOTH_ARGUMENTS(ARGUMENTS) lit
%   les formes acceptées : avec ou sans abscisses, avec ou sans portée,
%   avec ou sans nom de méthode.
%
%   Exemple :
%      [x, y, p, m] = matlibre_smooth_arguments({[1 2 3], 'lowess'});
%
%   Voir aussi SMOOTH.
    methodes = {'moving', 'lowess', 'loess', 'rlowess', 'rloess', 'sgolay'};
    x = [];
    y = [];
    portee = [];
    methode = 'moving';
    degre = 2;
    k = 1;
    if numel(arguments) >= 2 && isnumeric(arguments{1}) && isnumeric(arguments{2}) && ...
       numel(arguments{1}) == numel(arguments{2}) && numel(arguments{1}) > 1
        x = double(arguments{1}(:));
        y = double(arguments{2}(:));
        k = 3;
    else
        y = double(arguments{1}(:));
        x = (1:numel(y)).';
        k = 2;
    end
    while k <= numel(arguments)
        courant = arguments{k};
        if ischar(courant)
            nom = lower(courant);
            if any(strcmp(methodes, nom))
                methode = nom;
            else
                error('curvefit:smooth:Methode', 'Méthode inconnue : %s.', nom);
            end
        elseif isempty(portee)
            portee = double(courant);
        else
            degre = double(courant);
        end
        k = k + 1;
    end
    if isempty(portee)
        if strcmp(methode, 'moving') || strcmp(methode, 'sgolay')
            portee = 5;
        else
            portee = 0.1;
        end
    end
end
