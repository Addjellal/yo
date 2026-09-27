function varargout = matlibre_sl_parametre(action, varargin)
%MATLIBRE_SL_PARAMETRE Ce que valent les objets Simulink.Parameter.
%   V = MATLIBRE_SL_PARAMETRE('valeur',P,VARIABLE,BLOC,PARAMETRE) rend la
%   valeur que lit un bloc dont le paramètre PARAMETRE nomme la variable
%   VARIABLE, qui porte le Simulink.Parameter P : sa valeur, convertie
%   dans son DataType quand il n'est pas 'auto', et vérifiée contre ses
%   bornes Min et Max. Une valeur qui en sort, qui déborde son type
%   entier, ou un type que MatLibre n'a pas, arrête tout par une erreur
%   qui nomme le bloc, le paramètre et la variable.
%
%   L = MATLIBRE_SL_PARAMETRE('types') rend les noms de types que
%   Simulink.Parameter et Simulink.Signal convertissent : 'auto',
%   'double', 'single', les entiers, 'boolean'.
%
%   B = MATLIBRE_SL_PARAMETRE('borne',V,NOM), T =
%   MATLIBRE_SL_PARAMETRE('texte',V,NOM) et C =
%   MATLIBRE_SL_PARAMETRE('choix',V,NOM,ADMIS) vérifient une propriété
%   avant qu'un objet la pose.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      K = Simulink.Parameter(300);
%      K.DataType = 'int16';
%      v = matlibre_sl_parametre('valeur', K, 'K', 'm/c', 'Value');
%      class(v)                           % 'int16'
%
%   Voir aussi SIMULINK.PARAMETER, SIMULINK.SIGNAL, MATLIBRE_SL_EXPRESSION.
    switch action
        case 'valeur'
            varargout{1} = valeur(varargin{:});
        case 'types'
            varargout{1} = {'auto', 'double', 'single', 'int8', 'uint8', 'int16', 'uint16', ...
                            'int32', 'uint32', 'int64', 'uint64', 'boolean'};
        case 'borne'
            v = varargin{1};
            if ~(isempty(v) || (isnumeric(v) && isreal(v) && isscalar(v) && ~isnan(v)))
                error('Simulink:Data:InvalidMinMax', ...
                      '%s est un nombre reel, ou [] pour ne pas borner.', varargin{2});
            end
            if isempty(v)
                v = [];
            end
            varargout{1} = double(v);
        case 'texte'
            v = varargin{1};
            if isstring(v) && isscalar(v)
                v = char(v);
            end
            if ~(ischar(v) && (isempty(v) || isrow(v)))
                error('Simulink:Data:InvalidValue', '%s est un texte.', varargin{2});
            end
            varargout{1} = v;
        case 'choix'
            [v, nom, admis] = varargin{:};
            trouve = [];
            if ischar(v) || (isstring(v) && isscalar(v))
                trouve = find(strcmpi(char(v), admis), 1);
            end
            if isempty(trouve)
                error('Simulink:Data:InvalidValue', '%s vaut l''une de ces valeurs : %s.', ...
                      nom, strjoin(admis, ', '));
            end
            varargout{1} = admis{trouve};
        otherwise
            error('Simulink:Data:Action', 'Action inconnue : %s.', char(action));
    end
end

function v = valeur(p, variable, bloc, parametre)
    v = p.Value;
    type = p.DataType;
    if strncmp(type, 'fixdt', 5) || ~isempty(regexp(type, '^[su]fix\d', 'once'))
        % à virgule fixe : la valeur sur la grille du type, un FI que le
        % bloc lit dans ce type
        try
            T = matlibre_fixe_versType(type);
        catch
            error('Simulink:DataType:UnknownDataType', ...
                  ['Le parametre ''%s'' du bloc ''%s'' lit %s, un Simulink.Parameter de ' ...
                   'type ''%s'', qui est mal ecrit.'], parametre, bloc, variable, type);
        end
        if ~(isnumeric(v) || islogical(v)) || ~isreal(v)
            error('Simulink:Data:ParameterTypeMismatch', ...
                  ['Le parametre ''%s'' du bloc ''%s'' lit %s, un Simulink.Parameter de ' ...
                   'type ''%s'' dont la valeur est un %s.'], parametre, bloc, variable, ...
                  type, class(v));
        end
        v = fi(double(v), T);
    elseif strncmp(type, 'Bus:', 4)
        if ~isstruct(v)
            error('Simulink:Data:ParameterTypeMismatch', ...
                  ['Le parametre ''%s'' du bloc ''%s'' lit %s, un Simulink.Parameter de ' ...
                   'type ''%s'' : sa valeur doit etre une structure, pas un %s.'], ...
                  parametre, bloc, variable, type, class(v));
        end
    elseif strncmp(type, 'Enum:', 5) || strcmp(type, 'auto')
        % la valeur telle quelle
    elseif any(strcmp(type, matlibre_sl_parametre('types')))
        if ~(isnumeric(v) || islogical(v))
            error('Simulink:Data:ParameterTypeMismatch', ...
                  ['Le parametre ''%s'' du bloc ''%s'' lit %s, un Simulink.Parameter de ' ...
                   'type ''%s'' dont la valeur est un %s.'], parametre, bloc, variable, ...
                  type, class(v));
        end
        v = convertir(v, type, variable, bloc, parametre);
    else
        error('Simulink:DataType:UnknownDataType', ...
              ['Le parametre ''%s'' du bloc ''%s'' lit %s, un Simulink.Parameter de ' ...
               'type ''%s'', que MatLibre ne connait pas : les types sont ''auto'', ' ...
               '''double'', ''single'', les entiers et ''boolean''.'], ...
              parametre, bloc, variable, type);
    end
    if (isnumeric(v) || islogical(v)) && ~isempty(v)
        reels = real(double(v(:)));
        if (~isempty(p.Min) && any(reels < p.Min)) || (~isempty(p.Max) && any(reels > p.Max))
            error('Simulink:Data:ParameterOutOfRange', ...
                  ['Le parametre ''%s'' du bloc ''%s'' lit %s, un Simulink.Parameter qui ' ...
                   'vaut %s : c''est hors de ses bornes [%s, %s] (Min, Max).'], ...
                  parametre, bloc, variable, mat2str(double(v), 6), borneTexte(p.Min, '-Inf'), ...
                  borneTexte(p.Max, 'Inf'));
        end
    end
end

function v = convertir(v, type, variable, bloc, parametre)
    if strcmp(type, 'boolean')
        v = logical(v ~= 0);
        return
    end
    if any(strcmp(type, {'double', 'single'}))
        v = cast(v, type);
        return
    end
    d = double(real(v(:)));
    if any(d < double(intmin(type))) || any(d > double(intmax(type)))
        error('Simulink:Data:ParameterOverflow', ...
              ['Le parametre ''%s'' du bloc ''%s'' lit %s, un Simulink.Parameter de ' ...
               'type %s : sa valeur %s deborde ce type, qui va de %d a %d.'], ...
              parametre, bloc, variable, type, mat2str(double(v), 6), ...
              intmin(type), intmax(type));
    end
    if any(d ~= round(d))
        warning('Simulink:Data:ParameterPrecisionLoss', ...
                ['Le parametre ''%s'' du bloc ''%s'' lit %s, un Simulink.Parameter de ' ...
                 'type %s : sa valeur %s est arrondie a l''entier.'], ...
                parametre, bloc, variable, type, mat2str(double(v), 6));
    end
    v = cast(v, type);
end

function t = borneTexte(b, infini)
    if isempty(b)
        t = infini;
    else
        t = num2str(b);
    end
end
