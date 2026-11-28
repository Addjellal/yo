function [piste, valeurs, a, e, radians, donne] = ...
    matlibre_geodesie_arguments(arguments, nombre, fonction)
%MATLIBRE_GEODESIE_ARGUMENTS Les arguments de DISTANCE, AZIMUTH et RECKON.
%   [PISTE,VALEURS,A,E,RADIANS,DONNE] = MATLIBRE_GEODESIE_ARGUMENTS(ARGS,N,NOM)
%   lit la forme de MATLAB : une piste facultative en tête ('gc' grand
%   cercle, 'rh' loxodromie), N tableaux numériques — ou deux matrices de
%   points [lat lon] quand N vaut 4 —, puis un ellipsoïde facultatif —
%   [a e], un rayon, ou un objet REFERENCEELLIPSOID — et l'unité des
%   angles, 'degrees' (par défaut) ou 'radians'. Sans ellipsoïde, la
%   sphère est la sphère unité, A = 1 et E = 0, et DONNE est faux.
%
%   Les tableaux sont rendus tels quels — c'est l'appelant qui convertit
%   ses angles —, étendus à une taille commune.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      [p, v] = matlibre_geodesie_arguments({0, 0, 0, 90}, 4, 'distance');
%      v{4}                 % 90
%
%   Voir aussi DISTANCE, AZIMUTH, RECKON.
    piste = 'gc';
    if ~isempty(arguments) && (ischar(arguments{1}) || isstring(arguments{1}))
        piste = lower(char(arguments{1}));
        arguments = arguments(2:end);
        if ~any(strcmp(piste, {'gc', 'rh'}))
            error(['map:' fonction ':Piste'], ...
                  'Track must be ''gc'' (great circle) or ''rh'' (rhumb line).');
        end
    end
    % Deux matrices de points [lat lon] à la place de quatre vecteurs.
    if nombre == 4 && numel(arguments) >= 2 && size(arguments{1}, 2) == 2 && ...
            size(arguments{2}, 2) == 2 && (numel(arguments) == 2 || ~isnumeric(arguments{3}) || ...
            ~isequal(size(arguments{3}), size(arguments{1}(:, 1))))
        p1 = arguments{1};
        p2 = arguments{2};
        arguments = [{p1(:, 1), p1(:, 2), p2(:, 1), p2(:, 2)}, arguments(3:end)];
    end
    if numel(arguments) < nombre
        error(['map:' fonction ':Arguments'], 'Not enough input arguments.');
    end
    valeurs = arguments(1:nombre);
    reste = arguments(nombre + 1:end);
    a = 1;
    e = 0;
    radians = false;
    donne = false;
    for k = 1:numel(reste)
        r = reste{k};
        if ischar(r) || isstring(r)
            switch lower(char(r))
                case {'degrees', 'degree', 'deg'}
                    radians = false;
                case {'radians', 'radian', 'rad'}
                    radians = true;
                otherwise
                    error(['map:' fonction ':Unite'], ...
                          'Unknown angle unit: %s (degrees, radians).', char(r));
            end
        elseif isa(r, 'referenceEllipsoid')
            a = r.SemimajorAxis;
            e = r.Eccentricity;
            donne = true;
        elseif isnumeric(r) && numel(r) <= 2 && ~isempty(r)
            a = r(1);
            if numel(r) == 2
                e = r(2);
            end
            donne = true;
        else
            error(['map:' fonction ':Ellipsoide'], ...
                  'The ellipsoid must be [a e], a radius, or a referenceEllipsoid object.');
        end
    end
    if ~(a > 0) || ~(e >= 0 && e < 1)
        error(['map:' fonction ':Ellipsoide'], 'Invalid ellipsoid: a > 0 and 0 <= e < 1 are required.');
    end
    % Taille commune, scalaires étendus.
    taille = [1 1];
    for k = 1:nombre
        if ~isscalar(valeurs{k})
            if isequal(taille, [1 1])
                taille = size(valeurs{k});
            elseif ~isequal(size(valeurs{k}), taille)
                error(['map:' fonction ':Tailles'], ...
                      'Arrays must have the same size, or be scalars.');
            end
        end
    end
    for k = 1:nombre
        v = double(valeurs{k});
        if isscalar(v)
            v = v * ones(taille);
        end
        valeurs{k} = v;
    end
end
