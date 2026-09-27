function varargout = matlibre_fixe_calcul(action, varargin)
%MATLIBRE_FIXE_CALCUL Les calculs, l'indexation et l'affichage de FI.
%   R = MATLIBRE_FIXE_CALCUL(OP,A,B) calcule A OP B — 'plus', 'minus',
%   'times', 'mtimes', 'power' — ou OP(A) — 'uminus', 'abs', 'sum', 'max',
%   'min' — selon les règles FIMATH de l'opérande qui en porte, par défaut
%   sinon. R = MATLIBRE_FIXE_CALCUL('concatener',DIM,A,B,...) met bout à
%   bout dans le type du premier FI ; 'lire' et 'ecrire' font SUBSREF et
%   SUBSASGN ; 'afficher' fait DISP.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Voir aussi FI, FIMATH.
    objet = [];
    if ~strcmp(action, 'concatener') && ~isempty(varargin) && isa(varargin{1}, 'embedded.fi')
        objet = varargin{1};
    end
    for i = 1:numel(varargin)
        if isa(varargin{i}, 'embedded.fi')
            varargin{i} = internes(varargin{i});
        end
    end
    switch action
        case 'plus'
            varargout{1} = somme(varargin{1}, varargin{2}, 1);
        case 'minus'
            varargout{1} = somme(varargin{1}, varargin{2}, -1);
        case 'times'
            varargout{1} = produit(varargin{1}, varargin{2}, false);
        case 'mtimes'
            varargout{1} = produit(varargin{1}, varargin{2}, true);
        case 'uminus'
            varargout{1} = oppose(varargin{1});
        case 'power'
            varargout{1} = puissance(varargin{1}, varargin{2});
        case 'abs'
            a = varargin{1};
            varargout{1} = faire(matlibre_fixe_quantifier(abs(valeur(a)), a.Type, a.Maths), ...
                                 a.Type, a.Maths, a.MathsLocale);
        case 'sum'
            varargout{1} = sommeElements(varargin{:});
        case {'max', 'min'}
            [varargout{1:max(nargout, 1)}] = extremum(action, varargin{:});
        case 'concatener'
            varargout{1} = concatener(varargin{1}, varargin(2:end));
        case 'lire'
            [varargout{1:max(nargout, 1)}] = lire(varargin{1}, varargin{2}, objet);
        case 'ecrire'
            varargout{1} = emballer(ecrire(varargin{:}));
        case 'afficher'
            afficher(varargin{1});
    end
end

% --- les opérandes et les règles ---------------------------------------

% Un FI déballé : la structure que rend sa méthode INTERNES.
function oui = estFi(x)
    oui = isstruct(x) && isfield(x, 'EstFi');
end

function v = valeur(x)
    if estFi(x)
        v = x.Entiers * x.Type.Slope + x.Type.Bias;
    else
        v = double(x);
    end
end

function r = emballer(s)
    r = embedded.fi(s.Entiers, s.Type, s.Maths, s.MathsLocale);
end

% Un double qui se mêle au calcul prend le signe et la taille du FI, en
% meilleure précision ; un entier de MATLAB, son propre type.
function [a, b] = operandes(a, b)
    if ~estFi(a)
        a = depuisValeur(a, b);
    elseif ~estFi(b)
        b = depuisValeur(b, a);
    end
end

function x = depuisValeur(v, ref)
    classe = class(v);
    if isinteger(v)
        T = embedded.numerictype(classe(1) ~= 'u', str2double(regexprep(classe, '\D', '')), 0);
    else
        T = embedded.numerictype(ref.Type.Signed, ref.Type.WordLength);
        T.FractionLength = matlibre_fixe_precision(double(v), T.Signed, T.WordLength);
    end
    x = struct('Entiers', matlibre_fixe_quantifier(double(v), T, embedded.fimath()), ...
               'Type', T, 'Maths', ref.Maths, 'MathsLocale', false, 'EstFi', true);
end

% Les règles du résultat : celles d'un opérande qui en porte en propre,
% celles par défaut sinon.
function [F, locale] = regles(a, b)
    if a.MathsLocale
        F = a.Maths;
        locale = true;
    elseif nargin > 1 && b.MathsLocale
        F = b.Maths;
        locale = true;
    else
        F = embedded.fimath();
        locale = false;
    end
end

function oui = binaire(T)
    oui = strcmp(T.Scaling, 'BinaryPoint') && T.Bias == 0 && T.SlopeAdjustmentFactor == 1;
end

function r = faire(Q, T, F, locale)
    r = embedded.fi(Q, T, F, locale);
end

% Une valeur réelle rangée dans un type : pour les échelles qui ne sont pas
% des puissances de deux, le calcul se fait sur les valeurs.
function r = rangerDans(v, T, F, locale)
    r = faire(matlibre_fixe_quantifier(v, T, F), T, F, locale);
end

% Le mode de FIMATH appliqué au résultat en pleine précision (Q, T).
function r = appliquerMode(Q, T, F, mode, w, fr, wMax, locale)
    switch mode
        case 'FullPrecision'
            if T.WordLength > wMax
                error('fixed:fi:maxWordLengthExceeded', ...
                      ['Le resultat demanderait %d bits, au-dela des %d que permet ' ...
                       'FIMATH.'], T.WordLength, wMax);
            end
            r = faire(Q, T, F, locale);
            return
        case 'KeepLSB'
            T2 = embedded.numerictype(T.Signed, w, T.FractionLength);
        case 'KeepMSB'
            T2 = embedded.numerictype(T.Signed, w, T.FractionLength - (T.WordLength - w));
        otherwise
            T2 = embedded.numerictype(T.Signed, w, fr);
    end
    r = rangerDans(Q * T.Slope, T2, F, locale);
end

% --- les opérations -------------------------------------------------------

function r = somme(a, b, signe)
    [a, b] = operandes(a, b);
    [F, locale] = regles(a, b);
    Ta = a.Type;
    Tb = b.Type;
    if ~(binaire(Ta) && binaire(Tb))
        r = rangerDans(valeur(a) + signe * valeur(b), Ta, F, locale);
        return
    end
    fr = max(Ta.FractionLength, Tb.FractionLength);
    ia = Ta.WordLength - Ta.FractionLength - Ta.Signed;
    ib = Tb.WordLength - Tb.FractionLength - Tb.Signed;
    s = Ta.Signed || Tb.Signed;
    T = embedded.numerictype(s, s + max(ia, ib) + 1 + fr, fr);
    Q = a.Entiers * 2 ^ (fr - Ta.FractionLength) + ...
        signe * (b.Entiers * 2 ^ (fr - Tb.FractionLength));
    if ~s && any(Q(:) < 0)
        Q = max(Q, 0);   % sans signe, une différence négative sature à zéro
    end
    r = appliquerMode(Q, T, F, F.SumMode, F.SumWordLength, F.SumFractionLength, ...
                      F.MaxSumWordLength, locale);
end

function r = produit(a, b, matriciel)
    [a, b] = operandes(a, b);
    [F, locale] = regles(a, b);
    Ta = a.Type;
    Tb = b.Type;
    scalaire = isscalar(a.Entiers) || isscalar(b.Entiers);
    if ~(binaire(Ta) && binaire(Tb))
        if matriciel && ~scalaire
            v = valeur(a) * valeur(b);
        else
            v = valeur(a) .* valeur(b);
        end
        r = rangerDans(v, Ta, F, locale);
        return
    end
    s = Ta.Signed || Tb.Signed;
    w = Ta.WordLength + Tb.WordLength;
    fr = Ta.FractionLength + Tb.FractionLength;
    if matriciel && ~scalaire
        if size(a.Entiers, 2) ~= size(b.Entiers, 1)
            error('MATLAB:innerdim', ...
                  'Les dimensions interieures du produit matriciel doivent s''accorder.');
        end
        Q = a.Entiers * b.Entiers;
        n = size(a.Entiers, 2);
        if n > 1
            w = w + ceil(log2(n));   % la somme des n produits
        end
        r = appliquerMode(Q, embedded.numerictype(s, w, fr), F, F.SumMode, ...
                          F.SumWordLength, F.SumFractionLength, F.MaxSumWordLength, locale);
        return
    end
    Q = a.Entiers .* b.Entiers;
    r = appliquerMode(Q, embedded.numerictype(s, w, fr), F, F.ProductMode, ...
                      F.ProductWordLength, F.ProductFractionLength, ...
                      F.MaxProductWordLength, locale);
end

function r = oppose(a)
    [F, locale] = regles(a);
    T = a.Type;
    if T.Signed || ~binaire(T)
        r = rangerDans(-valeur(a), T, F, locale);
    else
        T2 = embedded.numerictype(true, T.WordLength + 1, T.FractionLength);
        r = faire(-a.Entiers, T2, F, locale);
    end
end

function r = puissance(a, n)
    n = valeur(n);
    if ~(isnumeric(n) && isscalar(n) && n >= 1 && n == round(n))
        error('fixed:fi:powerExponent', ...
              'A.^N ne se calcule en virgule fixe que pour un entier N positif.');
    end
    r = emballer(a);
    for i = 2:n
        r = produit(internes(r), a, false);
    end
end

function r = sommeElements(a, dim)
    if nargin < 2
        dim = find(size(a.Entiers) ~= 1, 1);
        if isempty(dim)
            dim = 1;
        end
    end
    [F, locale] = regles(a);
    T = a.Type;
    n = size(a.Entiers, dim);
    Q = sum(a.Entiers, dim);
    if ~binaire(T)
        r = rangerDans(Q * T.Slope + n * T.Bias, T, F, locale);
        return
    end
    w = T.WordLength;
    if n > 1
        w = w + ceil(log2(n));
    end
    r = appliquerMode(Q, embedded.numerictype(T.Signed, w, T.FractionLength), F, F.SumMode, ...
                      F.SumWordLength, F.SumFractionLength, F.MaxSumWordLength, locale);
end

function [r, rang] = extremum(quoi, a, b, dim)
    f = str2func(quoi);
    if nargin >= 3 && ~isempty(b)
        [a, b] = operandes(a, b);
        [F, locale] = regles(a, b);
        r = rangerDans(f(valeur(a), valeur(b)), a.Type, F, locale);
        rang = [];
        return
    end
    % la pente est positive : l'ordre des entiers stockés est celui des valeurs
    if nargin < 4
        [Q, rang] = f(a.Entiers);
    else
        [Q, rang] = f(a.Entiers, [], dim);
    end
    r = faire(Q, a.Type, a.Maths, a.MathsLocale);
end

function r = concatener(dim, parts)
    for i = 1:numel(parts)
        if isa(parts{i}, 'embedded.fi')
            parts{i} = internes(parts{i});
        end
    end
    k = find(cellfun(@estFi, parts), 1);
    ref = parts{k};
    Q = cell(1, numel(parts));
    for i = 1:numel(parts)
        x = parts{i};
        if estFi(x) && isequal(x.Type, ref.Type)
            Q{i} = x.Entiers;
        else
            Q{i} = matlibre_fixe_quantifier(valeur(x), ref.Type, ref.Maths);
        end
    end
    r = faire(cat(dim, Q{:}), ref.Type, ref.Maths, ref.MathsLocale);
end

% --- indexation --------------------------------------------------------------

function varargout = lire(a, s, objet)
    switch s(1).type
        case '()'
            r = faire(a.Entiers(s(1).subs{:}), a.Type, a.Maths, a.MathsLocale);
        case '.'
            nom = s(1).subs;
            proprietesType = {'Signed', 'Signedness', 'WordLength', 'FractionLength', ...
                              'Slope', 'Bias', 'FixedExponent', 'SlopeAdjustmentFactor', ...
                              'DataTypeMode', 'Scaling'};
            proprietesMaths = {'RoundingMethod', 'OverflowAction', 'ProductMode', ...
                               'ProductWordLength', 'ProductFractionLength', 'SumMode', ...
                               'SumWordLength', 'SumFractionLength', 'CastBeforeSum', ...
                               'MaxProductWordLength', 'MaxSumWordLength'};
            switch nom
                case 'data'
                    r = valeur(a);
                case 'int'
                    r = matlibre_fixe_stocke(a.Entiers, a.Type);
                case {'bin', 'oct', 'hex', 'dec'}
                    bases = struct('bin', 2, 'oct', 8, 'hex', 16, 'dec', 10);
                    r = matlibre_fixe_chiffres(a.Entiers, a.Type, bases.(nom));
                case 'numerictype'
                    r = a.Type;
                case 'fimath'
                    r = a.Maths;
                case {'Entiers', 'Type', 'Maths', 'MathsLocale'}
                    r = a.(nom);
                otherwise
                    if any(strcmp(nom, proprietesType))
                        r = a.Type.(nom);
                    elseif any(strcmp(nom, proprietesMaths))
                        r = a.Maths.(nom);
                    elseif numel(s) > 1 && strcmp(s(2).type, '()')
                        arguments_ = s(2).subs;
                        [varargout{1:max(nargout, 1)}] = feval(nom, objet, arguments_{:});
                        return
                    else
                        [varargout{1:max(nargout, 1)}] = feval(nom, objet);
                        return
                    end
            end
        otherwise
            error('fixed:fi:braceIndexing', ...
                  'Un nombre a virgule fixe ne s''indexe pas par accolades.');
    end
    if numel(s) > 1
        r = suite(r, s(2:end));
    end
    varargout{1} = r;
end

function r = suite(r, s)
    if isa(r, 'embedded.fi')
        r = lire(internes(r), s, r);
        return
    end
    for i = 1:numel(s)
        switch s(i).type
            case '()'
                r = r(s(i).subs{:});
            case '.'
                r = r.(s(i).subs);
            otherwise
                r = r{s(i).subs{:}};
        end
    end
end

function a = ecrire(a, s, v)
    switch s(1).type
        case '()'
            a.Entiers(s(1).subs{:}) = matlibre_fixe_quantifier(valeur(v), a.Type, a.Maths);
        case '.'
            nom = s(1).subs;
            if numel(s) > 1
                v = subsasgn(lire(a, s(1), emballer(a)), s(2:end), v);
            end
            if isa(v, 'embedded.fi') && ~strcmp(nom, 'fimath')
                v = valeur(internes(v));
            end
            proprietesType = {'Signed', 'Signedness', 'WordLength', 'FractionLength', ...
                              'Slope', 'Bias', 'FixedExponent', 'SlopeAdjustmentFactor', ...
                              'DataTypeMode', 'Scaling'};
            switch nom
                case 'data'
                    a.Entiers = matlibre_fixe_quantifier(v, a.Type, a.Maths);
                case 'int'
                    [bas, haut] = matlibre_fixe_bornes(a.Type);
                    a.Entiers = min(max(round(double(v)), bas), haut);
                case 'numerictype'
                    a = retyper(a, matlibre_fixe_versType(v));
                case 'fimath'
                    if isempty(v)
                        a.Maths = embedded.fimath();
                        a.MathsLocale = false;
                    else
                        a.Maths = v;
                        a.MathsLocale = true;
                    end
                case {'Entiers', 'Type', 'Maths', 'MathsLocale'}
                    a.(nom) = v;
                otherwise
                    if any(strcmp(nom, proprietesType))
                        T = a.Type;
                        T.(nom) = v;
                        a = retyper(a, T);
                    elseif any(strcmp(nom, properties(a.Maths)))
                        F = a.Maths;
                        F.(nom) = v;
                        a.Maths = F;
                        a.MathsLocale = true;
                    else
                        error('fixed:fi:invalidProperty', ...
                              'FI n''a pas de propriete ''%s''.', nom);
                    end
            end
        otherwise
            error('fixed:fi:braceIndexing', ...
                  'Un nombre a virgule fixe ne s''indexe pas par accolades.');
    end
end

function a = retyper(a, T)
    a.Entiers = matlibre_fixe_quantifier(valeur(a), T, a.Maths);
    a.Type = T;
end

function afficher(a)
    v = valeur(a);
    if isempty(v)
        disp('     []');
    else
        disp(v);
    end
    fprintf('\n');
    matlibre_fixe_type('afficher', a.Type);
    if a.MathsLocale
        fprintf('\n');
        disp(a.Maths);
    end
end
