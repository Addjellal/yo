function p = matlibre_sl_tables(type, p, chemin)
%MATLIBRE_SL_TABLES Les données d'un bloc de table, rendues explicites.
%   P = MATLIBRE_SL_TABLES(TYPE,P,CHEMIN) rend les paramètres P du bloc
%   CHEMIN — de type 'lookup' (n-D Lookup Table), 'prelookup' ou
%   'interpolationusingprelookup' — avec leur table et leurs points de
%   rupture écrits en valeurs :
%      - DataSpecification 'Lookup table object' ou TableSpecification
%        'Lookup table object' : la table et les points du
%        Simulink.LookupTable que nomme LookupTableObject, lu comme une
%        variable du bloc — espace du modèle, dictionnaire de données,
%        espace de base ;
%      - BreakpointsSpecification 'Even spacing' : des points espacés
%        régulièrement, à partir de FirstPoint, de Spacing en Spacing ;
%      - BreakpointsSpecification 'Breakpoint object' (Prelookup) : les
%        points du Simulink.Breakpoint que nomme BreakpointObject.
%   Un objet absent, d'une autre classe, ou dont la table et les points ne
%   s'accordent pas, est refusé en nommant le bloc.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      p = struct('NumberOfTableDimensions', 1, 'DataSpecification', ...
%                 'Table and breakpoints', 'BreakpointsSpecification', ...
%                 'Even spacing', 'TableData', [5 6 7], ...
%                 'BreakpointsForDimension1FirstPoint', 1, ...
%                 'BreakpointsForDimension1Spacing', 2);
%      q = matlibre_sl_tables('lookup', p, 'm/table');
%      q.BreakpointsData                  % [1 3 5]
%
%   Voir aussi SIMULINK.LOOKUPTABLE, SIMULINK.BREAKPOINT.
    switch type
        case 'lookup'
            n = double(p.NumberOfTableDimensions);
            if strcmp(champ(p, 'DataSpecification', ''), 'Lookup table object')
                nom = strtrim(char(champ(p, 'LookupTableObject', '')));
                lut = objet(nom, 'Simulink.LookupTable', chemin, 'LookupTableObject');
                [points, table] = donneesTable(lut, nom, chemin);
                if numel(points) ~= n
                    error('Simulink:blocks:LookupTableObjectDimensionMismatch', ...
                          ['Le bloc ''%s'' est une table a %d dimension(s) ' ...
                           '(NumberOfTableDimensions), et l''objet ''%s'' en a %d.'], ...
                          chemin, n, nom, numel(points));
                end
                p.TableData = table;
                for d = 1:n
                    p.(nomPoints(d)) = points{d};
                end
            elseif strcmp(champ(p, 'BreakpointsSpecification', ''), 'Even spacing')
                tailles = taillesTable(p.TableData, n);
                for d = 1:n
                    premier = p.(sprintf('BreakpointsForDimension%dFirstPoint', d));
                    pas = p.(sprintf('BreakpointsForDimension%dSpacing', d));
                    p.(nomPoints(d)) = espaces(premier, pas, tailles(d), chemin, ...
                        sprintf('BreakpointsForDimension%dFirstPoint', d), ...
                        sprintf('BreakpointsForDimension%dSpacing', d));
                end
            end
        case 'prelookup'
            switch champ(p, 'BreakpointsSpecification', 'Explicit values')
                case 'Breakpoint object'
                    nom = strtrim(char(champ(p, 'BreakpointObject', '')));
                    bp = objet(nom, 'Simulink.Breakpoint', chemin, 'BreakpointObject');
                    b = bp.Breakpoints;
                    p.BreakpointsData = b.Value;
                    if isempty(p.BreakpointsData)
                        error('Simulink:blocks:LookupTableObjectEmpty', ...
                              'Le Simulink.Breakpoint ''%s'', que lit ''%s'', n''a pas de points.', ...
                              nom, chemin);
                    end
                case 'Even spacing'
                    nombre = double(p.BreakpointsNumPoints);
                    if ~isscalar(nombre) || ~isreal(nombre) || nombre ~= round(nombre) || nombre < 2
                        error('Simulink:blocks:LookupEvenSpacingInvalid', ...
                              ['Le bloc ''%s'' : BreakpointsNumPoints est un entier, au moins ' ...
                               '2 ; pas %s.'], chemin, mat2str(nombre));
                    end
                    p.BreakpointsData = espaces(p.BreakpointsFirstPoint, p.BreakpointsSpacing, ...
                                                nombre, chemin, 'BreakpointsFirstPoint', ...
                                                'BreakpointsSpacing');
            end
        case 'interpolationusingprelookup'
            if strcmp(champ(p, 'TableSpecification', ''), 'Lookup table object')
                nom = strtrim(char(champ(p, 'LookupTableObject', '')));
                lut = objet(nom, 'Simulink.LookupTable', chemin, 'LookupTableObject');
                t = lut.Table;
                table = double(t.Value);
                n = double(p.NumberOfTableDimensions);
                if isempty(table)
                    error('Simulink:blocks:LookupTableObjectEmpty', ...
                          'Le Simulink.LookupTable ''%s'', que lit ''%s'', n''a pas de valeurs.', ...
                          nom, chemin);
                end
                if dimensionsDe(table) ~= n && ~(n > dimensionsDe(table))
                    error('Simulink:blocks:LookupTableObjectDimensionMismatch', ...
                          ['Le bloc ''%s'' interpole une table a %d dimension(s) ' ...
                           '(NumberOfTableDimensions), et la table de ''%s'' en a %d.'], ...
                          chemin, n, nom, dimensionsDe(table));
                end
                p.Table = table;
            end
    end
end

function v = champ(p, nom, defaut)
    if isfield(p, nom)
        v = p.(nom);
    else
        v = defaut;
    end
end

function nom = nomPoints(d)
    if d == 1
        nom = 'BreakpointsData';
    else
        nom = sprintf('BreakpointsForDimension%d', d);
    end
end

function n = dimensionsDe(T)
    if isvector(T)
        n = 1;
    else
        n = ndims(T);
    end
end

function tailles = taillesTable(T, n)
    if n == 1
        tailles = numel(T);
    else
        tailles = size(T);
        tailles(end + 1:n) = 1;
    end
end

% Des points espacés régulièrement, vérifiés.
function points = espaces(premier, pas, nombre, chemin, nomPremier, nomPas)
    premier = double(premier);
    pas = double(pas);
    if ~isscalar(premier) || ~isreal(premier) || ~isfinite(premier)
        error('Simulink:blocks:LookupEvenSpacingInvalid', ...
              'Le bloc ''%s'' : %s est un nombre reel fini ; pas %s.', chemin, nomPremier, ...
              mat2str(premier));
    end
    if ~isscalar(pas) || ~isreal(pas) || ~isfinite(pas) || pas <= 0
        error('Simulink:blocks:LookupEvenSpacingInvalid', ...
              ['Le bloc ''%s'' : %s, l''ecart entre deux points de rupture, est un nombre ' ...
               'reel strictement positif ; pas %s.'], chemin, nomPas, mat2str(pas));
    end
    points = premier + pas * (0:nombre - 1);
end

% L'objet que nomme un paramètre, lu comme une variable du bloc.
function v = objet(nom, classe, chemin, parametre)
    if isempty(nom)
        error('Simulink:blocks:LookupTableObjectNotSpecified', ...
              ['Le bloc ''%s'' lit ses donnees dans un %s, mais son parametre %s ne le ' ...
               'nomme pas.'], chemin, classe, parametre);
    end
    if ~isvarname(nom)
        error('Simulink:blocks:LookupTableObjectNotFound', ...
              ['Le parametre %s du bloc ''%s'' vaut ''%s'' : il nomme une variable qui porte ' ...
               'un %s.'], parametre, chemin, nom, classe);
    end
    [trouve, v] = matlibre_sl_espace('valeur', chemin, nom);
    if ~trouve
        error('Simulink:blocks:LookupTableObjectNotFound', ...
              ['Le parametre %s du bloc ''%s'' nomme ''%s'', qui n''est ni dans l''espace ' ...
               'du modele, ni dans son dictionnaire de donnees, ni dans l''espace de travail ' ...
               'de base.'], parametre, chemin, nom);
    end
    if ~isa(v, classe)
        error('Simulink:blocks:LookupTableObjectInvalidClass', ...
              'La variable ''%s'', que nomme le parametre %s du bloc ''%s'', est un %s : il faut un %s.', ...
              nom, parametre, chemin, class(v), classe);
    end
end

% La table d'un Simulink.LookupTable et ses points, une cellule par
% dimension, vérifiés ensemble.
function [points, table] = donneesTable(lut, nom, chemin)
    t = lut.Table;
    table = double(t.Value);
    if isempty(table)
        error('Simulink:blocks:LookupTableObjectEmpty', ...
              'Le Simulink.LookupTable ''%s'', que lit ''%s'', n''a pas de valeurs.', nom, chemin);
    end
    B = lut.Breakpoints;
    n = numel(B);
    if n ~= dimensionsDe(table)
        error('Simulink:blocks:LookupTableObjectDimensionMismatch', ...
              ['Le Simulink.LookupTable ''%s'', que lit ''%s'', porte une table a %d ' ...
               'dimension(s) et %d jeu(x) de points de rupture.'], nom, chemin, ...
              dimensionsDe(table), n);
    end
    tailles = taillesTable(table, n);
    points = cell(1, n);
    for d = 1:n
        switch lut.BreakpointsSpecification
            case 'Explicit values'
                b = B(d);
                points{d} = double(b.Value(:).');
            case 'Even spacing'
                e = B(d);
                points{d} = e.FirstPoint + e.Spacing * (0:tailles(d) - 1);
            otherwise
                bp = objet(B{d}, 'Simulink.Breakpoint', chemin, ...
                           sprintf('Breakpoints{%d} de ''%s''', d, nom));
                b = bp.Breakpoints;
                points{d} = double(b.Value(:).');
        end
        if numel(points{d}) ~= tailles(d)
            error('Simulink:blocks:LookupTableObjectSizeMismatch', ...
                  ['Le Simulink.LookupTable ''%s'', que lit ''%s'', a %d element(s) sur la ' ...
                   'dimension %d de sa table, et %d point(s) de rupture pour elle.'], nom, ...
                  chemin, tailles(d), d, numel(points{d}));
        end
        if any(diff(points{d}) <= 0)
            error('Simulink:blocks:LookupBreakpointsNotMonotonic', ...
                  ['Les points de rupture de la dimension %d du Simulink.LookupTable ''%s'', ' ...
                   'que lit ''%s'', ne croissent pas strictement.'], d, nom, chemin);
        end
    end
end
