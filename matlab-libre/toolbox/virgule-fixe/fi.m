function a = fi(varargin)
%FI Un nombre, ou un tableau, à virgule fixe.
%   A = FI(V) range les valeurs V en virgule fixe : signées, sur des mots
%   de 16 bits, avec autant de bits après la virgule que la plus grande
%   valeur en laisse — la meilleure précision. FI(pi) garde 13 bits après
%   la virgule ; un entier de MATLAB garde son type (int8 : 8 bits, sans
%   virgule).
%   A = FI(V,S), FI(V,S,W) : signé ou non (S vrai ou faux), sur W bits, en
%   meilleure précision.
%   A = FI(V,S,W,F) : F bits après la virgule — une valeur vaut son entier
%   stocké fois 2^-F.
%   A = FI(V,S,W,PENTE,BIAIS) et FI(V,S,W,AJUSTEMENT,EXPOSANT,BIAIS) : une
%   valeur vaut PENTE fois son entier stocké, plus BIAIS.
%   A = FI(V,T) et FI(V,T,F) : le type T (NUMERICTYPE, ou ce que rend
%   FIXDT) et les règles de calcul F (FIMATH), qui peuvent aussi suivre les
%   nombres : FI(V,1,16,8,F).
%   Les propriétés se donnent aussi par paires : FI(V,1,16,8,
%   'RoundingMethod','Floor','OverflowAction','Wrap').
%
%   Une valeur est arrondie au plus proche et saturée aux bornes du type,
%   sauf règles contraires ; NaN devient 0. Les calculs suivent FIMATH :
%   en pleine précision, A + B garde la plus fine des deux échelles et
%   gagne un bit ; A .* B additionne tailles et bits après la virgule ;
%   SUM gagne ceil(log2(N)) bits. Un double qui se mêle au calcul prend le
%   signe et la taille de l'autre opérande, en meilleure précision. Une
%   division demande le type du quotient : DIVIDE(T,A,B).
%
%   Propriétés : data (la valeur, en double), int (l'entier stocké), bin,
%   hex, dec, oct, numerictype, fimath, Signed, Signedness, WordLength,
%   FractionLength, Slope, Bias, DataTypeMode, RoundingMethod,
%   OverflowAction, ProductMode, SumMode. Écrire l'une des propriétés du
%   type range à nouveau la valeur dans le type changé.
%
%   Les entiers stockés sont des doubles : au-delà de 53 bits, les derniers
%   se perdent.
%
%   Exemple :
%      a = fi(pi)                     % 3.1416 : 16 bits, 13 après la virgule
%      a.bin                          % '0110010010001000'
%      b = fi(0.1, 1, 8, 6);
%      c = a + b                      % 17 bits, 13 après la virgule
%      d = a * b                      % 24 bits, 19 après la virgule
%      fi(300, 0, 8, 0)               % 255 : saturé
%      fi(300, 0, 8, 0, 'OverflowAction', 'Wrap')      % 44
%
%   Voir aussi NUMERICTYPE, FIMATH, FIXDT, DIVIDE, ISFI, UPPERBOUND.
    v = [];
    if nargin >= 1
        v = varargin{1};
    end
    args = varargin(2:end);
    n = 0;
    while n < numel(args) && (isnumeric(args{n + 1}) || islogical(args{n + 1}))
        n = n + 1;
    end
    nombres = args(1:n);
    args(1:n) = [];
    T = [];
    F = embedded.fimath();
    locale = false;
    if isa(v, 'embedded.fi')
        interne = internes(v);
        T = interne.Type;
        F = interne.Maths;
        locale = interne.MathsLocale;
        v = double(v);
    end
    if ~isempty(args) && n == 0 && ~(ischar(args{1}) || isstring(args{1})) && ...
       ~isa(args{1}, 'embedded.fimath')
        T = matlibre_fixe_versType(args{1});
        args(1) = [];
    end
    if ~isempty(args) && isa(args{1}, 'embedded.fimath')
        F = args{1};
        locale = true;
        args(1) = [];
    end
    if n > 0
        T = matlibre_fixe_type('positionnel', embedded.numerictype(), nombres);
        if n == 1
            T.Scaling = 'Unspecified';
        end
    elseif isempty(T)
        T = embedded.numerictype(true, 16);
        if isinteger(v)
            classe = class(v);
            T = embedded.numerictype(classe(1) ~= 'u', str2double(regexprep(classe, '\D', '')), 0);
        end
    end
    if mod(numel(args), 2) ~= 0
        error('fixed:fi:invalidPVPairs', 'Les proprietes de FI se donnent par paires nom, valeur.');
    end
    proprietesMaths = properties(F);
    for i = 1:2:numel(args)
        nom = char(args{i});
        valeur = args{i + 1};
        if strcmpi(nom, 'numerictype')
            T = matlibre_fixe_versType(valeur);
        elseif strcmpi(nom, 'fimath')
            F = valeur;
            locale = true;
        elseif any(strcmpi(nom, proprietesMaths))
            F.(proprietesMaths{strcmpi(nom, proprietesMaths)}) = valeur;
            locale = true;
        else
            T = numerictypeAvec(T, nom, valeur);
        end
    end
    if ~strcmp(T.Mode, 'fixe')
        error('fixed:fi:floatingPointType', ...
              'MatLibre ne range en FI que des types a virgule fixe, pas des %s.', T.Mode);
    end
    if strcmp(T.Scaling, 'Unspecified')
        T.FractionLength = matlibre_fixe_precision(v, T.Signed, T.WordLength, F);
        T.Scaling = 'BinaryPoint';
    end
    if ~(isnumeric(v) || islogical(v))
        error('fixed:fi:invalidValue', 'FI range des nombres, pas des %s.', class(v));
    end
    a = embedded.fi(matlibre_fixe_quantifier(double(v), T, F), T, F, locale);
end

function T = numerictypeAvec(T, nom, valeur)
    noms = {'Signed', 'Signedness', 'WordLength', 'FractionLength', 'Slope', 'Bias', ...
            'FixedExponent', 'SlopeAdjustmentFactor', 'DataTypeMode', 'Scaling'};
    k = find(strcmpi(nom, noms), 1);
    if isempty(k)
        error('fixed:fi:invalidProperty', 'FI n''a pas de propriete ''%s''.', nom);
    end
    T.(noms{k}) = valeur;
    if any(strcmp(noms{k}, {'FractionLength', 'FixedExponent'})) && strcmp(T.Scaling, 'Unspecified')
        T.Scaling = 'BinaryPoint';
    end
end
