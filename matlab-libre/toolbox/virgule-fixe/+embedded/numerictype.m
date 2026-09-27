classdef numerictype
%NUMERICTYPE Le type d'un nombre à virgule fixe : signe, taille, échelle.
%   T = NUMERICTYPE rend le type par défaut : signé, mots de 16 bits dont
%   15 après la virgule.
%   T = NUMERICTYPE(S) et T = NUMERICTYPE(S,W) : signé ou non (S vrai ou
%   faux), mots de W bits ; l'échelle reste à fixer, et FI prend alors la
%   meilleure précision pour la valeur qu'il range.
%   T = NUMERICTYPE(S,W,F) : F bits après la virgule — une valeur vaut
%   son entier stocké fois 2^-F.
%   T = NUMERICTYPE(S,W,PENTE,BIAIS) : une valeur vaut PENTE fois son
%   entier stocké, plus BIAIS.
%   T = NUMERICTYPE(S,W,AJUSTEMENT,EXPOSANT,BIAIS) : la pente vaut
%   AJUSTEMENT * 2^EXPOSANT.
%   T = NUMERICTYPE('double'), NUMERICTYPE('single'),
%   NUMERICTYPE('boolean') : les types flottants et booléen.
%   Les propriétés se donnent aussi par paires, après ou sans ce qui
%   précède : NUMERICTYPE('Signed', false, 'WordLength', 8,
%   'FractionLength', 4).
%
%   Propriétés : DataTypeMode, Signed, Signedness, WordLength,
%   FractionLength, Slope, Bias, FixedExponent, SlopeAdjustmentFactor,
%   Scaling ('BinaryPoint', 'SlopeBias' ou 'Unspecified').
%
%   Exemple :
%      T = numerictype(1, 16, 8)
%      T.Slope                            % 0.0039
%      fi(pi, T)                          % 3.1406
%
%   Voir aussi FI, FIMATH, FIXDT.
    properties
        Signed = true
        WordLength = 16
        FractionLength = 15
        SlopeAdjustmentFactor = 1
        Bias = 0
        Scaling = 'BinaryPoint'
        Mode = 'fixe'          % 'fixe', 'double', 'single' ou 'boolean'
    end
    properties (Dependent)
        DataTypeMode
        Signedness
        Slope
        FixedExponent
    end
    methods
        function T = numerictype(varargin)
            args = varargin;
            if ~isempty(args) && (ischar(args{1}) || isstring(args{1})) && ...
               any(strcmpi(char(args{1}), {'double', 'single', 'boolean'}))
                T = matlibre_fixe_type('flottant', T, lower(char(args{1})));
                args(1) = [];
            else
                n = 0;
                while n < numel(args) && ~(ischar(args{n + 1}) || isstring(args{n + 1}))
                    n = n + 1;
                end
                T = matlibre_fixe_type('positionnel', T, args(1:n));
                args(1:n) = [];
            end
            if mod(numel(args), 2) ~= 0
                error('fixed:numerictype:invalidPVPairs', ...
                      'Les proprietes de NUMERICTYPE se donnent par paires nom, valeur.');
            end
            for i = 1:2:numel(args)
                T = poser(T, char(args{i}), args{i + 1});
            end
        end

        function v = get.DataTypeMode(T)
            switch T.Mode
                case 'double'
                    v = 'Double';
                case 'single'
                    v = 'Single';
                case 'boolean'
                    v = 'Boolean';
                otherwise
                    switch T.Scaling
                        case 'SlopeBias'
                            v = 'Fixed-point: slope and bias scaling';
                        case 'Unspecified'
                            v = 'Fixed-point: unspecified scaling';
                        otherwise
                            v = 'Fixed-point: binary point scaling';
                    end
            end
        end
        function T = set.DataTypeMode(T, v)
            T = matlibre_fixe_type('mode', T, char(v));
        end
        function v = get.Signedness(T)
            if T.Signed
                v = 'Signed';
            else
                v = 'Unsigned';
            end
        end
        function T = set.Signedness(T, v)
            T.Signed = strcmpi(char(v), 'Signed');
        end
        function v = get.Slope(T)
            v = T.SlopeAdjustmentFactor * 2 ^ -T.FractionLength;
        end
        function T = set.Slope(T, pente)
            if ~(isnumeric(pente) && isscalar(pente) && pente > 0 && isfinite(pente))
                error('fixed:numerictype:invalidSlope', 'La pente doit etre un nombre positif.');
            end
            exposant = floor(log2(pente));
            T.SlopeAdjustmentFactor = pente / 2 ^ exposant;
            T.FractionLength = -exposant;
            if T.SlopeAdjustmentFactor ~= 1 || T.Bias ~= 0
                T.Scaling = 'SlopeBias';
            else
                T.Scaling = 'BinaryPoint';
            end
        end
        function v = get.FixedExponent(T)
            v = -T.FractionLength;
        end
        function T = set.FixedExponent(T, v)
            T.FractionLength = -double(v);
        end
        function T = set.Bias(T, v)
            T.Bias = double(v);
            if T.Bias ~= 0
                T.Scaling = 'SlopeBias'; %#ok<MCSUP>
            end
        end
        function T = set.WordLength(T, w)
            if ~(isnumeric(w) && isscalar(w) && w >= 1 && w == round(w) && w <= 65535)
                error('fixed:numerictype:invalidWordLength', ...
                      'La taille des mots doit etre un entier de 1 a 65535.');
            end
            T.WordLength = double(w);
        end
        function T = set.FractionLength(T, f)
            if ~(isnumeric(f) && isscalar(f) && f == round(f) && isfinite(f))
                error('fixed:numerictype:invalidFractionLength', ...
                      'Le nombre de bits apres la virgule doit etre un entier.');
            end
            T.FractionLength = double(f);
            if strcmp(T.Scaling, 'Unspecified') %#ok<MCSUP>
                T.Scaling = 'BinaryPoint'; %#ok<MCSUP>
            end
        end
        function T = set.Signed(T, s)
            T.Signed = logical(s);
        end

        function oui = isfixed(T)
            oui = strcmp(T.Mode, 'fixe');
        end
        function oui = isfloat(T)
            oui = any(strcmp(T.Mode, {'double', 'single'}));
        end
        function oui = isboolean(T)
            oui = strcmp(T.Mode, 'boolean');
        end
        function oui = isscalingbinarypoint(T)
            oui = strcmp(T.Mode, 'fixe') && strcmp(T.Scaling, 'BinaryPoint');
        end
        function oui = isscalingslopebias(T)
            oui = strcmp(T.Mode, 'fixe') && strcmp(T.Scaling, 'SlopeBias');
        end
        function oui = isscalingunspecified(T)
            oui = strcmp(T.Mode, 'fixe') && strcmp(T.Scaling, 'Unspecified');
        end
        function oui = isequal(A, B, varargin)
            oui = isa(B, 'embedded.numerictype') && strcmp(A.Mode, B.Mode) && ...
                  (~strcmp(A.Mode, 'fixe') || (A.Signed == B.Signed && ...
                   A.WordLength == B.WordLength && strcmp(A.Scaling, B.Scaling) && ...
                   A.FractionLength == B.FractionLength && ...
                   A.SlopeAdjustmentFactor == B.SlopeAdjustmentFactor && A.Bias == B.Bias));
            for i = 1:numel(varargin)
                oui = oui && isequal(A, varargin{i});
            end
        end
        function texte = tostring(T)
            texte = matlibre_fixe_type('texte', T);
        end
        function disp(T)
            matlibre_fixe_type('afficher', T);
        end
    end
end

function T = poser(T, nom, v)
    noms = {'Signed', 'Signedness', 'WordLength', 'FractionLength', 'Slope', 'Bias', ...
            'FixedExponent', 'SlopeAdjustmentFactor', 'DataTypeMode', 'Scaling'};
    k = find(strcmpi(nom, noms), 1);
    if isempty(k)
        error('fixed:numerictype:invalidProperty', ...
              'NUMERICTYPE n''a pas de propriete ''%s''.', nom);
    end
    switch noms{k}
        case 'Scaling'
            T.Scaling = matlibre_fixe_type('echelle', char(v));
        case 'SlopeAdjustmentFactor'
            if ~(isnumeric(v) && isscalar(v) && v >= 1 && v < 2)
                error('fixed:numerictype:invalidSlopeAdjustmentFactor', ...
                      'Le facteur d''ajustement de la pente va de 1 (compris) a 2 (exclu).');
            end
            T.SlopeAdjustmentFactor = double(v);
            if v ~= 1
                T.Scaling = 'SlopeBias';
            end
        otherwise
            T.(noms{k}) = v;
            if strcmp(noms{k}, 'FractionLength') && strcmp(T.Scaling, 'Unspecified')
                T.Scaling = 'BinaryPoint';
            end
    end
end
