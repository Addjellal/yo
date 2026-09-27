function varargout = matlibre_fixe_type(action, varargin)
%MATLIBRE_FIXE_TYPE Les travaux de NUMERICTYPE : construire, lire, montrer.
%   T = MATLIBRE_FIXE_TYPE('positionnel',T,ARGS) règle T sur (S), (S,W),
%   (S,W,F), (S,W,PENTE,BIAIS) ou (S,W,AJUSTEMENT,EXPOSANT,BIAIS).
%   T = MATLIBRE_FIXE_TYPE('flottant',T,NOM) en fait un double, un single
%   ou un booléen ; T = MATLIBRE_FIXE_TYPE('mode',T,TEXTE) le règle sur un
%   DataTypeMode écrit ; S = MATLIBRE_FIXE_TYPE('echelle',TEXTE) vérifie
%   un Scaling ; TEXTE = MATLIBRE_FIXE_TYPE('texte',T) l'écrit
%   « numerictype(1,16,8) » ; MATLIBRE_FIXE_TYPE('afficher',T) le montre.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Voir aussi NUMERICTYPE, FI.
    switch action
        case 'positionnel'
            varargout{1} = positionnel(varargin{:});
        case 'flottant'
            T = varargin{1};
            T.Mode = varargin{2};
            T.Scaling = 'Unspecified';
            switch varargin{2}
                case 'double'
                    T.WordLength = 64;
                case 'single'
                    T.WordLength = 32;
                otherwise
                    T.WordLength = 1;
                    T.Signed = false;
                    T.FractionLength = 0;
                    T.Scaling = 'BinaryPoint';
            end
            varargout{1} = T;
        case 'mode'
            varargout{1} = mode(varargin{:});
        case 'echelle'
            choix = {'BinaryPoint', 'SlopeBias', 'Unspecified'};
            k = find(strcmpi(varargin{1}, choix), 1);
            if isempty(k)
                error('fixed:numerictype:invalidScaling', ...
                      'Scaling vaut BinaryPoint, SlopeBias ou Unspecified.');
            end
            varargout{1} = choix{k};
        case 'texte'
            varargout{1} = texte(varargin{1});
        case 'afficher'
            afficher(varargin{1});
        case 'lignes'
            varargout{1} = lignes(varargin{1});
    end
end

function T = positionnel(T, args)
    n = numel(args);
    for i = 1:n
        if ~(isnumeric(args{i}) || islogical(args{i})) || ~isscalar(args{i})
            error('fixed:numerictype:invalidArgument', ...
                  'L''argument %d de NUMERICTYPE doit etre un nombre.', i);
        end
    end
    if n >= 1
        T.Signed = logical(args{1});
    end
    if n >= 2
        T.WordLength = args{2};
        if n == 2
            T.Scaling = 'Unspecified';
        end
    end
    switch n
        case 3
            T.FractionLength = args{3};
        case 4
            T.Bias = args{4};
            T.Slope = args{3};
            if args{4} ~= 0
                T.Scaling = 'SlopeBias';
            end
        case 5
            ajustement = double(args{3});
            if ~(ajustement >= 1 && ajustement < 2)
                error('fixed:numerictype:invalidSlopeAdjustmentFactor', ...
                      'Le facteur d''ajustement de la pente va de 1 (compris) a 2 (exclu).');
            end
            T.SlopeAdjustmentFactor = ajustement;
            T.FractionLength = -double(args{4});
            T.Bias = args{5};
            if ajustement ~= 1 || args{5} ~= 0
                T.Scaling = 'SlopeBias';
            end
        otherwise
            if n > 5
                error('fixed:numerictype:invalidArgument', ...
                      'NUMERICTYPE prend au plus cinq nombres.');
            end
    end
end

function T = mode(T, texte)
    switch lower(texte)
        case {'double', 'single', 'boolean'}
            T = matlibre_fixe_type('flottant', T, lower(texte));
        case 'fixed-point: binary point scaling'
            T.Mode = 'fixe';
            T.Scaling = 'BinaryPoint';
        case 'fixed-point: slope and bias scaling'
            T.Mode = 'fixe';
            T.Scaling = 'SlopeBias';
        case 'fixed-point: unspecified scaling'
            T.Mode = 'fixe';
            T.Scaling = 'Unspecified';
        otherwise
            error('fixed:numerictype:invalidDataTypeMode', ...
                  'DataTypeMode ''%s'' est inconnu.', texte);
    end
end

function t = texte(T)
    switch T.Mode
        case {'double', 'single', 'boolean'}
            t = sprintf('numerictype(''%s'')', T.Mode);
        otherwise
            switch T.Scaling
                case 'Unspecified'
                    t = sprintf('numerictype(%d,%d)', T.Signed, T.WordLength);
                case 'SlopeBias'
                    t = sprintf('numerictype(%d,%d,%s,%s)', T.Signed, T.WordLength, ...
                                num2str(T.Slope, 17), num2str(T.Bias, 17));
                otherwise
                    t = sprintf('numerictype(%d,%d,%d)', T.Signed, T.WordLength, ...
                                T.FractionLength);
            end
    end
end

% Les lignes de l'affichage, un nom aligné à droite et sa valeur.
function L = lignes(T)
    L = {'DataTypeMode', T.DataTypeMode};
    if strcmp(T.Mode, 'fixe')
        L(end + 1, :) = {'Signedness', T.Signedness};
        L(end + 1, :) = {'WordLength', sprintf('%d', T.WordLength)};
        switch T.Scaling
            case 'BinaryPoint'
                L(end + 1, :) = {'FractionLength', sprintf('%d', T.FractionLength)};
            case 'SlopeBias'
                L(end + 1, :) = {'Slope', num2str(T.Slope)};
                L(end + 1, :) = {'Bias', num2str(T.Bias)};
        end
    end
end

function afficher(T)
    L = lignes(T);
    for i = 1:size(L, 1)
        fprintf('%22s: %s\n', L{i, 1}, L{i, 2});
    end
end
