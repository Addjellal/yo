function varargout = matlibre_sl_types(action, varargin)
%MATLIBRE_SL_TYPES Les types de données des signaux : propagation et contrôle.
%   T = MATLIBRE_SL_TYPES('propager',C) rend le type de chaque port de
%   sortie du modèle compilé C, comme Simulink le propage : un code par
%   port — 2 double, 3 single, 4 int8, 5 uint8, 6 int16, 7 uint16,
%   8 int32, 9 uint32, 10 boolean, et à partir de 101 les types à
%   virgule fixe (fixdt(1,16,8), 'sfix16_En8'), numérotés à mesure
%   qu'on les rencontre. Une constante a le type de sa valeur ou
%   celui de son OutDataTypeStr ; une entrée, celui de son OutDataTypeStr,
%   double sinon ; un opérateur relationnel ou logique rend un booléen ;
%   un bloc de calcul ou d'aiguillage hérite du type de ses entrées —
%   double si elles en ont plusieurs —, une MATLAB Function de la classe
%   de ce qu'elle rend. Un signal que rien ne type est double.
%
%   Les types sont ensuite contrôlés comme Simulink les contrôle : un
%   bloc continu, un Fcn, une S-fonction, une fonction trigonométrique ne
%   reçoivent que des doubles ; les entrées d'un Merge sont d'un même
%   type ; une entrée ou une sortie typée reçoit son type. Chaque refus
%   est une erreur Simulink:DataType:… qui nomme le bloc.
%
%   X = MATLIBRE_SL_TYPES('complexite',C) rend, pour chaque port de
%   sortie, vrai si son signal est complexe : une constante, un gain, une
%   donnée de l'espace de travail complexes le rendent complexe, un calcul
%   le transmet, Abs ou Complex to Real-Imag le rendent réel. Un bloc qui
%   ne calcule qu'en réel — une saturation, un intégrateur, une table... —
%   refuse une entrée complexe : Simulink:DataType:InputPortComplexityMismatch.
%
%   Un calcul à virgule fixe dont le type n'est pas dit (Inherit via
%   internal rule) prend le type qui ne perd rien : une somme garde la
%   plus fine des échelles et gagne les bits de ses retenues, un produit
%   additionne tailles et bits après la virgule, un gain y range d'abord
%   son paramètre en meilleure précision sur la taille de l'entrée ; le
%   tout borné à 32 bits, en rognant les bits après la virgule.
%
%   V = MATLIBRE_SL_TYPES('convertir',CODE,V) range V dans le type CODE :
%   un FI pour un type à virgule fixe. T = MATLIBRE_SL_TYPES('numerictype',
%   CODE) rend le NUMERICTYPE d'un type à virgule fixe, et L =
%   MATLIBRE_SL_TYPES('fixes') la table de ceux qu'on a rencontrés : une
%   ligne [signe, taille, bits après la virgule, ajustement, biais] par
%   code, à partir de 101.
%
%   C = MATLIBRE_SL_TYPES('code',NOM) rend le code d'un nom de type
%   ('int8', 'boolean'...), 0 pour un type hérité ; N =
%   MATLIBRE_SL_TYPES('nom',CODE) le nom ; K =
%   MATLIBRE_SL_TYPES('classe',CODE) la classe MATLAB ('logical' pour
%   boolean).
%
%   Un type énuméré s'écrit 'Enum: Couleur', où Couleur est une
%   énumération de valeurs entières — dérivée de Simulink.IntEnumType ou
%   d'un entier de MATLAB. Ses codes vont à partir de 201, dans l'ordre où
%   on les rencontre. Son signal porte la valeur entière de chaque membre ;
%   il ne se calcule pas — un gain, une somme le refusent —, mais il se
%   retarde, s'aiguille, se compare à un membre du même type et se
%   convertit en entier (Data Type Conversion). K =
%   MATLIBRE_SL_TYPES('enum',CODE) rend la classe d'un type énuméré, '' pour
%   un autre type ; V = MATLIBRE_SL_TYPES('defaut',CODE) la valeur de son
%   membre par défaut — celui que rend la méthode statique getDefaultValue
%   de la classe, le premier membre sinon — ; V =
%   MATLIBRE_SL_TYPES('valeurs',CODE) les valeurs de ses membres ; T =
%   MATLIBRE_SL_TYPES('texte',M) le texte MATLAB d'un membre ou d'un
%   tableau de membres, 'Couleur.Rouge' ou '[Couleur.Rouge Couleur.Vert]',
%   comme un modèle l'enregistre.
%
%   MATLIBRE_SL_TYPES('surcharge',MODE,PORTEE) pose le Data Type Override
%   de Simulink le temps d'une compilation : MODE 'Double', 'Single' ou
%   'ScaledDouble' remplace les types numériques — tous
%   ('AllNumericTypes'), les flottants ('Floating-point') ou les entiers et
%   virgules fixes ('Fixed-point') —, les booléens et les énumérations
%   jamais ; 'UseLocalSettings' et 'Off' n'en remplacent aucun.
%   MATLIBRE_SL_TYPES('surcharge') rend l'état, que la même action
%   restaure.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_sl_types('code', 'int16')          % 6
%
%   Voir aussi MATLIBRE_SL_COMPILER, ADD_BLOCK.
    switch action
        case 'propager'
            varargout{1} = propager(varargin{1});
        case 'complexite'
            varargout{1} = complexite(varargin{1});
        case 'code'
            varargout{1} = codeDe(varargin{1});
        case 'nom'
            varargout{1} = nomDe(varargin{1});
        case 'classe'
            varargout{1} = classeDe(varargin{1});
        case 'convertir'
            varargout{1} = convertir(varargin{1}, varargin{2});
        case 'numerictype'
            varargout{1} = typeNumerique(varargin{1});
        case 'fixes'
            varargout{1} = registre('tout');
        case 'codeValeur'
            varargout{1} = codeDeValeur(varargin{1});
        case 'parametreGain'
            varargout{1} = codeParametreGain(varargin{:});
        case 'typeFixe'
            varargout{1} = typeFixe(varargin{:});
        case 'quantifier'
            varargout{1} = quantifier(varargin{:});
        case 'enum'
            varargout{1} = '';
            if varargin{1} > 200
                varargout{1} = registreEnum('classe', varargin{1});
            end
        case 'defaut'
            varargout{1} = defautEnum(varargin{1});
        case 'valeurs'
            varargout{1} = double(enumeration(registreEnum('classe', varargin{1})));
        case 'texte'
            varargout{1} = texteMembres(varargin{1});
        case 'surcharge'
            varargout{1} = surcharge(varargin{:});
        otherwise
            error('Simulink:DataType:Action', 'Action inconnue : %s.', char(action));
    end
end

function n = nomDe(code)
    if code > 200
        n = ['Enum: ' registreEnum('classe', code)];
        return
    elseif code > 100
        n = nomFixe(registre('ligne', code));
        return
    end
    noms = {'', 'double', 'single', 'int8', 'uint8', 'int16', 'uint16', 'int32', ...
            'uint32', 'boolean'};
    n = noms{code};
end

% Le nom que Simulink donne à un type à virgule fixe : sfix16_En8, ufix8,
% sfix16_E2, sfix16_S0p5_B2.
function n = nomFixe(l)
    lettres = 'us';
    n = sprintf('%cfix%d', lettres(l(1) + 1), l(2));
    if l(4) ~= 1 || l(5) ~= 0
        ecrire = @(x) strrep(strrep(num2str(x, 10), '.', 'p'), '-', 'n');
        n = sprintf('%s_S%s_B%s', n, ecrire(l(4) * 2 ^ -l(3)), ecrire(l(5)));
    elseif l(3) > 0
        n = sprintf('%s_En%d', n, l(3));
    elseif l(3) < 0
        n = sprintf('%s_E%d', n, -l(3));
    end
end

% La classe MATLAB d'un signal : un type à virgule fixe se calcule en
% double, ses valeurs ramenées à la grille de son type après chaque bloc.
function k = classeDe(code)
    if code > 200
        k = registreEnum('classe', code);
        return
    elseif code > 100
        k = 'double';
        return
    end
    k = nomDe(code);
    if strcmp(k, 'boolean')
        k = 'logical';
    end
end

function v = convertir(code, v)
    if code > 200
        % les valeurs entières deviennent les membres qui les portent
        v = feval(registreEnum('classe', code), double(v));
    elseif code > 100
        v = fi(v, typeNumerique(code));
    elseif code > 2
        v = cast(v, classeDe(code));
    end
end

function T = typeNumerique(code)
    l = registre('ligne', code);
    if l(4) == 1 && l(5) == 0
        T = numerictype(l(1), l(2), l(3));
    else
        T = numerictype(l(1), l(2), l(4) * 2 ^ -l(3), l(5));
    end
end

% Les types à virgule fixe rencontrés, une ligne [signe, taille, bits après
% la virgule, ajustement de la pente, biais] chacun, numérotés à partir de
% 101 dans l'ordre où on les rencontre.
function varargout = registre(action, x)
    persistent tableFixes
    if isempty(tableFixes)
        tableFixes = zeros(0, 5);
    end
    switch action
        case 'code'
            k = find(all(tableFixes == repmat(x, size(tableFixes, 1), 1), 2), 1);
            if isempty(k)
                tableFixes(end + 1, :) = x;
                k = size(tableFixes, 1);
            end
            varargout{1} = 100 + k;
        case 'ligne'
            varargout{1} = tableFixes(x - 100, :);
        otherwise
            varargout{1} = tableFixes;
    end
end

% Les types énumérés rencontrés, par le nom de leur classe, numérotés à
% partir de 201 dans l'ordre où on les rencontre.
function varargout = registreEnum(action, x)
    persistent classesEnum
    if isempty(classesEnum)
        classesEnum = {};
    end
    switch action
        case 'code'
            k = find(strcmp(classesEnum, x), 1);
            if isempty(k)
                classesEnum{end + 1} = x;
                k = numel(classesEnum);
            end
            varargout{1} = 200 + k;
        otherwise
            varargout{1} = classesEnum{x - 200};
    end
end

% Le code du type énuméré d'une classe : -3 si la classe n'est pas une
% énumération, -4 si ses membres ne portent pas des valeurs entières —
% Simulink n'admet que les énumérations entières.
function code = codeEnumDe(classe)
    code = -3;
    if isempty(regexp(classe, '^[A-Za-z]\w*(\.[A-Za-z]\w*)*$', 'once'))
        return
    end
    try
        membres = enumeration(classe);
    catch
        return
    end
    if isempty(membres)
        return
    end
    try
        v = double(membres);
    catch
        code = -4;
        return
    end
    if any(v ~= round(v)) || any(abs(v) > 2 ^ 31)
        code = -4;
        return
    end
    code = registreEnum('code', classe);
end

% Le texte MATLAB d'un membre, ou d'un tableau de membres ligne par ligne.
function t = texteMembres(m)
    classe = class(m);
    if isscalar(m)
        t = [classe '.' char(m)];
        return
    end
    lignes = cell(1, size(m, 1));
    for i = 1:size(m, 1)
        noms = cellfun(@(n) [classe '.' n], cellstr(m(i, :)), 'UniformOutput', false);
        lignes{i} = strjoin(noms, ' ');
    end
    t = ['[' strjoin(lignes, '; ') ']'];
end

% La valeur du membre par défaut d'un type énuméré : celui que rend la
% méthode statique getDefaultValue de la classe, le premier sinon.
function v = defautEnum(code)
    classe = registreEnum('classe', code);
    membres = enumeration(classe);
    defaut = membres(1);
    if ismethod(defaut, 'getDefaultValue')
        defaut = feval([classe '.getDefaultValue']);
        if ~isa(defaut, classe) || ~isscalar(defaut)
            error('Simulink:DataType:EnumDefaultValue', ...
                  ['La methode getDefaultValue de l''enumeration ''%s'' doit rendre l''un ' ...
                   'de ses membres.'], classe);
        end
    end
    v = double(defaut);
end

% Le code d'un type décrit par un NUMERICTYPE : un entier de MATLAB quand
% il en est un (fixdt(1,16,0) est int16), sinon un type à virgule fixe.
function code = codeDuType(T)
    code = surcharger(codeDuTypeLocal(T));
end

function code = codeDuTypeLocal(T)
    switch T.Mode
        case 'double'
            code = 2;
        case 'single'
            code = 3;
        case 'boolean'
            code = 10;
        otherwise
            if strcmp(T.Scaling, 'Unspecified')
                code = -2;
                return
            end
            l = [T.Signed, T.WordLength, T.FractionLength, T.SlopeAdjustmentFactor, T.Bias];
            entiers = [8 4 5; 16 6 7; 32 8 9];
            k = find(entiers(:, 1) == l(2), 1);
            if l(3) == 0 && l(4) == 1 && l(5) == 0 && ~isempty(k)
                code = entiers(k, 3 - l(1));
            else
                code = registre('code', double(l));
            end
    end
end

% Data Type Override : l'état — le code qui remplace, 0 pour aucun, et la
% portée, 1 tous les types numériques, 2 les flottants, 3 les entiers et
% les virgules fixes —, persistant le temps d'une compilation.
function etat = surcharge(varargin)
    persistent courant
    if isempty(courant)
        courant = [0 1];
    end
    etat = courant;
    if nargin == 0
        return
    end
    if isnumeric(varargin{1})
        courant = varargin{1};
        return
    end
    code = 0;
    switch char(varargin{1})
        case {'Double', 'ScaledDouble'}
            code = 2;
        case 'Single'
            code = 3;
    end
    portee = 1;
    if nargin > 1
        portee = find(strcmp(char(varargin{2}), ...
                             {'AllNumericTypes', 'Floating-point', 'Fixed-point'}), 1);
    end
    courant = [code, portee];
end

% Un type sous le Data Type Override : un double ou un single, un entier
% ou une virgule fixe devient le type qui les remplace, selon la portée ;
% un booléen, une énumération, un type hérité restent ce qu'ils sont.
function code = surcharger(code)
    etat = surcharge();
    if etat(1) == 0 || code <= 0 || code == 10 || code > 200
        return
    end
    flottant = code == 2 || code == 3;
    if (flottant && etat(2) ~= 3) || (~flottant && etat(2) ~= 2)
        code = etat(1);
    end
end

% Le code du type d'une valeur : un FI a celui de son NUMERICTYPE.
function code = codeDeValeur(v)
    if isa(v, 'embedded.fi')
        code = codeDuType(numerictype(v));
    elseif isobject(v) && isenum(v)
        code = codeEnumDe(class(v));
    else
        code = codeDe(class(v));
    end
end

% Un nom de type — 'int8', ou une classe MATLAB — ; 0 pour un type hérité
% ('Inherit: ...'), -1 pour ce que MatLibre ne connaît pas.
function code = codeDe(nom)
    nom = strtrim(char(nom));
    if isempty(nom) || strncmpi(nom, 'Inherit', 7)
        code = 0;
        return
    end
    noms = {'double', 'single', 'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', ...
            'boolean'};
    code = find(strcmp(nom, noms), 1) + 1;
    if strcmp(nom, 'logical')
        code = 10;
    end
    if isempty(code) && strncmp(nom, 'Enum:', 5)
        code = codeEnumDe(strtrim(nom(6:end)));
    elseif isempty(code)
        code = codeFixeDe(nom);
    end
    code = surcharger(code);
end

% Un type à virgule fixe écrit : 'fixdt(1,16,8)', 'sfix16_En8', ou le nom
% d'une variable de l'espace de travail qui porte un Simulink.NumericType
% ou un Simulink.AliasType ; -1 pour ce qui n'en est pas un, -2 pour une
% échelle qui n'est pas dite.
function code = codeFixeDe(nom)
    code = -1;
    T = [];
    if strncmp(nom, 'fixdt(', 6) || ~isempty(regexp(nom, '^[su]fix\d', 'once'))
        try
            T = matlibre_fixe_versType(nom);
        catch
            return
        end
    elseif isvarname(nom) && evalin('base', sprintf('exist(''%s'', ''var'')', nom)) == 1
        v = evalin('base', nom);
        if isa(v, 'embedded.numerictype')
            T = v;
        elseif isa(v, 'Simulink.AliasType')
            code = codeAlias(v);
            return
        end
    end
    if ~isempty(T)
        code = codeDuType(T);
    end
end

% Un Simulink.AliasType vaut son type de base, qui peut être lui-même un
% alias ; une chaîne d'alias qui revient sur elle-même n'est pas un type.
function code = codeAlias(v)
    persistent profondeur
    if isempty(profondeur)
        profondeur = 0;
    end
    if profondeur > 32
        code = -1;
        return
    end
    profondeur = profondeur + 1;
    try
        code = codeDe(char(v.BaseType));
    catch err
        profondeur = profondeur - 1;
        rethrow(err);
    end
    profondeur = profondeur - 1;
end

function t = typeFixe(p, chemin)
    t = 0;
    if ~isfield(p, 'OutDataTypeStr')
        return
    end
    if ~isempty(matlibre_sl_bus('type', p.OutDataTypeStr))
        return   % un type de bus : ses éléments sont des doubles
    end
    t = codeDe(p.OutDataTypeStr);
    if t == -2 && isfield(p, 'Value')
        % une constante de type fixdt(1,16) : la meilleure précision pour
        % sa valeur
        T = matlibre_fixe_versType(char(p.OutDataTypeStr));
        T.FractionLength = matlibre_fixe_precision(p.Value, T.Signed, T.WordLength);
        t = codeDuType(T);
    elseif t == -2
        error('Simulink:DataType:UnspecifiedScaling', ...
              ['Le type ''%s'' du bloc ''%s'' ne dit pas son echelle : donnez-lui ses bits ' ...
               'apres la virgule, fixdt(S,W,F).'], char(p.OutDataTypeStr), chemin);
    elseif t == -3
        error('Simulink:DataType:EnumTypeUndefined', ...
              ['Le type ''%s'' du bloc ''%s'' nomme une classe qui n''est pas une ' ...
               'enumeration connue : definissez-la par classdef, avec un bloc ' ...
               'enumeration, dans un fichier du chemin.'], char(p.OutDataTypeStr), chemin);
    elseif t == -4
        error('Simulink:DataType:EnumTypeNotInteger', ...
              ['Le type ''%s'' du bloc ''%s'' est une enumeration dont les membres ne ' ...
               'portent pas de valeurs entieres : derivez-la de Simulink.IntEnumType ' ...
               '(classdef Couleur < Simulink.IntEnumType) et donnez a chaque membre sa ' ...
               'valeur, Rouge(1).'], char(p.OutDataTypeStr), chemin);
    end
    if t < 0
        error('Simulink:DataType:UnknownDataType', ...
              ['Le type ''%s'' du bloc ''%s'' est inconnu : les types sont double, single, ' ...
               'int8, uint8, int16, uint16, int32, uint32, boolean, les types a virgule ' ...
               'fixe (fixdt(1,16,8), sfix16_En8), les types enumeres (''Enum: Couleur''), ' ...
               'le nom d''un Simulink.NumericType ou d''un Simulink.AliasType, ou ' ...
               '''Inherit: ...''.'], char(p.OutDataTypeStr), chemin);
    end
end

function t = propager(c)
    t = zeros(1, c.nPorts);
    for tour = 1:(2 * c.n + 5)
        progres = false;
        for k = 1:c.n
            if c.nOut(k) == 0
                continue
            end
            ports = c.portDebut(k) + (0:c.nOut(k) - 1);
            if all(t(ports) > 0)
                continue
            end
            s = regle(c, k, typesEntrees(c, k, t), t);
            if isempty(s) || any(s == 0)
                continue
            end
            t(ports) = s;
            progres = true;
        end
        if all(t > 0)
            break
        end
        if ~progres
            t(t == 0) = 2;   % une boucle que rien ne type : double
            break
        end
    end
    % Le Data Type Override : chaque type numérique propagé — un double par
    % défaut, un entier hérité — se remplace
    for q = 1:numel(t)
        t(q) = surcharger(t(q));
    end
    for k = 1:c.n
        verifier(c, k, typesEntrees(c, k, t), t);
    end
end

% Le type de chaque entrée : 0 s'il n'est pas encore connu ; une entrée
% en l'air vaut zéro, un double.
function tE = typesEntrees(c, k, t)
    e = c.entrees{k};
    tE = 2 * ones(1, numel(e));
    for j = 1:numel(e)
        if e(j) > 0
            tE(j) = t(e(j));
        end
    end
end

% Le type commun de plusieurs entrées : le leur s'il est le même, double
% sinon ; 0 tant qu'aucun n'est connu.
function r = commun(tE)
    connus = tE(tE > 0);
    if isempty(connus)
        r = 0;
    elseif all(connus == connus(1))
        r = connus(1);
    else
        r = 2;
    end
end

function s = regle(c, k, tE, t)
    p = c.p{k};
    ch = c.chemins{k};
    n = c.nOut(k);
    arithmetique = {'gain', 'sum', 'product', 'bias', 'unaryminus', 'abs', 'dotproduct', ...
                    'rounding', 'quantizer', 'saturation', 'deadzone', 'sign', 'difference', ...
                    'ratelimiter', 'backlash'};
    switch c.types{k}
        case 'constant'
            r = typeFixe(p, ch);
            if r == 0
                r = 2;
                if isfield(p, 'Classes') && isfield(p.Classes, 'Value')
                    r = max(2, codeDe(p.Classes.Value));
                end
            end
        case 'inport'
            r = typeFixe(p, ch);
            if r == 0
                r = 2;
            end
        case {'datatypeconversion', 'signalconversion'}
            r = typeFixe(p, ch);
            if r == 0
                r = commun(tE(1:min(1, end)));
            end
            if isfield(p, 'TypeVerifie')
                % Signal Specification : le type annoncé doit être celui de
                % l'entrée, qu'il ne convertit pas
                attendu = typeFixe(struct('OutDataTypeStr', p.TypeVerifie), ch);
                if attendu > 0 && ~isempty(tE) && tE(1) > 0 && tE(1) ~= attendu
                    error('Simulink:DataType:SignalSpecificationMismatch', ...
                          ['Le bloc Signal Specification ''%s'' annonce le type %s, et son ' ...
                           'entree est de type %s.'], ch, ...
                          matlibre_sl_types('classe', attendu), ...
                          matlibre_sl_types('classe', tE(1)));
                end
            end
        case {'logic', 'relational', 'comparetoconstant', 'comparetozero', 'detectchange', ...
              'detectincrease', 'detectdecrease', 'intervaltest'}
            % un booléen, ou le type que dit OutDataTypeStr
            r = typeFixe(p, ch);
            if r == 0
                r = 10;
            end
        case {'sum', 'product', 'gain'}
            r = typeFixe(p, ch);
            if r == 0 && any(strcmpi(strtrim(char(p.OutDataTypeStr)), ...
                                     {'Inherit: Same as first input', 'Inherit: Same as input'}))
                r = tE(1);
            elseif r == 0
                if any(tE > 100 & tE <= 200) && all(tE > 0)
                    r = regleInterne(c.types{k}, p, tE, ch);
                elseif strcmp(c.types{k}, 'gain')
                    r = commun(tE(1:min(1, end)));
                else
                    r = commun(tE);
                end
            end
        case {'abs', 'unaryminus', 'sign', 'rounding', 'saturation', 'deadzone', ...
              'quantizer', 'bias', 'zoh', 'memory', 'delay', 'ratetransition', 'from', ...
              'selector', 'reshape', 'demux', 'ic', 'manualswitch', 'wraptozero', 'backlash', ...
              'ratelimiter', 'tappeddelay', 'difference', 'busassignment', ...
              'algebraicconstraint'}
            r = commun(tE(1:min(1, end)));
            if r == 0 && any(strcmp(c.types{k}, {'memory', 'delay'})) && ...
               ~isempty(classeParametre(p, 'InitialCondition'))
                % dans une boucle, un retard énuméré prend le type de sa
                % condition initiale, un membre
                r = codeDe(p.Classes.InitialCondition);
            end
        case {'minmax', 'mux', 'concatenate', 'merge', 'dotproduct'}
            r = commun(tE);
        case 'busselector'
            s = typesChoisis(c, k, t);
            return
        case 'switch'
            r = commun(tE([1 min(3, end)]));
        case 'multiportswitch'
            r = commun(tE(2:end));
        case {'trigonometry', 'math', 'sqrt', 'polynomial'}
            % en virgule flottante : single si toutes les entrées le sont
            r = 2;
            if any(tE == 0)
                r = 0;
            elseif all(tE == 3)
                r = 3;
            end
        case 'matlabfunction'
            if any(tE == 0)
                s = [];
                return
            end
            verifierFlottants(c, k, tE);   % avant l'appel d'essai, qui échouerait
            s = classesFonction(c, k, tE);
            return
        case 'chart'
            s = classesGraphe(c, k);
            return
        otherwise
            r = 2;
    end
    if r == 10 && any(strcmp(c.types{k}, arithmetique))
        r = 2;   % un calcul sur des booléens rend un double
    end
    s = r * ones(1, n);
end

% Le type de chaque sortie d'un Bus Selector : celui de l'élément qu'elle
% choisit ; un bus, ou des éléments de types mêlés, passent en double,
% comme le vecteur qui les porte.
function s = typesChoisis(c, k, t)
    n = c.nOut(k);
    s = 2 * ones(1, n);
    if ~isfield(c, 'choixBus') || isempty(c.choixBus{k}) || isempty(c.formeBus{k})
        return
    end
    codes = typesElements(c.formeBus{k}, t);
    if any(codes == 0)
        s = [];   % un élément n'est pas encore typé
        return
    end
    choix = c.choixBus{k};
    if isfield(c.p{k}, 'OutputAsBus') && strcmp(c.p{k}.OutputAsBus, 'on')
        return
    end
    for q = 1:min(n, numel(choix))
        morceau = codes(choix(q).debut:choix(q).debut + choix(q).largeur - 1);
        if all(morceau == morceau(1))
            s(q) = morceau(1);
        end
    end
end

% Les types des valeurs d'un bus, un code par valeur : celui du signal qui
% forme chaque élément, ou celui que son type de bus déclare ; 0 tant que
% l'un n'est pas connu.
function codes = typesElements(forme, t)
    codes = zeros(1, 0);
    for j = 1:numel(forme)
        e = forme(j);
        if ~isempty(e.sous)
            codes = [codes, typesElements(e.sous, t)]; %#ok<AGROW>
        elseif isfield(e, 'donnee') && ~isempty(e.donnee)
            code = codeDe(e.donnee);
            if code <= 0
                code = 2;   % un élément hérité, ou d'un type que MatLibre ne range pas
            end
            codes = [codes, code * ones(1, e.largeur)]; %#ok<AGROW>
        elseif isfield(e, 'source') && e.source > 0
            codes = [codes, t(e.source) * ones(1, e.largeur)]; %#ok<AGROW>
        else
            codes = [codes, 2 * ones(1, e.largeur)]; %#ok<AGROW>
        end
    end
end

% Un bus de type déclaré : chaque élément reçoit un signal de son type.
function verifierElements(forme, objet, t, qui, nomType, chemin)
    for j = 1:min(numel(forme), numel(objet.Elements))
        e = objet.Elements(j);
        emboite = matlibre_sl_bus('type', e.DataType);
        if ~isempty(emboite)
            if ~isempty(forme(j).sous)
                verifierElements(forme(j).sous, matlibre_sl_bus('objet', emboite, qui), t, ...
                                 qui, nomType, [chemin forme(j).nom '.']);
            end
            continue
        end
        attendu = codeDe(char(e.DataType));
        if attendu <= 0
            continue   % un élément hérité : pas de contrainte
        end
        vu = typesElements(forme(j), t);
        faux = find(vu ~= attendu & vu > 0, 1);
        if ~isempty(faux)
            error('Simulink:Bus:ElementDataTypeMismatch', ...
                  ['L''element ''%s%s'' du bus de type ''%s'' est de type %s, et ''%s'' lui ' ...
                   'donne un signal de type %s : convertissez-le (Data Type Conversion).'], ...
                  chemin, forme(j).nom, nomType, nomDe(attendu), qui, nomDe(vu(faux)));
        end
    end
end

% Les classes de ce que rend une MATLAB Function, appelée sur des zéros
% des types et dimensions de ses entrées ; ses variables persistantes sont
% ensuite remises à zéro.
function s = classesFonction(c, k, tE)
    h = c.fonctions{k}.h;
    u = cell(1, c.nIn(k));
    for j = 1:c.nIn(k)
        d = [1 1];
        if c.entrees{k}(j) > 0
            d = c.dims{c.entrees{k}(j)};
        end
        u{j} = valeurEssai(tE(j), 0, d);
    end
    sorties = cell(1, c.nOut(k));
    try
        [sorties{:}] = h(u{:});
    catch err
        if strncmp(err.identifier, 'Simulink:', 9) && ~isempty(strfind(err.message, c.chemins{k}))
            rethrow(err);
        end
        error('Simulink:blocks:MATLABFunctionError', ...
              'La fonction du bloc ''%s'' echoue sur des entrees nulles typees : %s', ...
              c.chemins{k}, err.message);
    end
    clear(func2str(h));
    s = 2 * ones(1, c.nOut(k));
    for q = 1:c.nOut(k)
        r = codeDeValeur(sorties{q});
        if r > 0
            s(q) = r;
        end
    end
end

% Une valeur d'essai du type CODE, de dimensions D : V, ou le membre par
% défaut d'un type énuméré — une valeur quelconque n'en est pas un membre.
function u = valeurEssai(code, v, d)
    if code > 200
        u = convertir(code, defautEnum(code) * ones(d));
    else
        u = convertir(code, v .* ones(d));
    end
end

function s = classesGraphe(c, k)
    code = c.fonctions{k};
    s = 2 * ones(1, c.nOut(k));
    for q = 1:min(c.nOut(k), numel(code.sorties))
        nom = code.sorties{q};
        if isfield(code.contexte, nom)
            r = codeDeValeur(code.contexte.(nom));   % un entier, un membre, un fi
            if r > 0
                s(q) = r;
            end
        end
    end
end

% Ce que Simulink refuse.
function verifier(c, k, tE, t)
    p = c.p{k};
    ch = c.chemins{k};
    verifierEnum(c, k, tE, t);
    doublesSeuls = {'integrator', 'secondorderintegrator', 'derivative', 'transferfcn', ...
                    'statespace', 'zeropole', 'transportdelay', 'pidcontroller', ...
                    'variabletransportdelay', ...
                    'fcn', 'interpretedmatlabfunction', 'sfunction', ...
                    'msfunction'};
    verifierFlottants(c, k, tE);
    if any(strcmp(c.types{k}, doublesSeuls))
        for j = 1:numel(tE)
            if tE(j) ~= 2
                error('Simulink:DataType:InputPortDataTypeMismatch', ...
                      ['L''entree %d de ''%s'' recoit un signal de type %s, mais ce bloc ne ' ...
                       'calcule qu''en double : convertissez le signal (Data Type ' ...
                       'Conversion).'], j, ch, nomDe(tE(j)));
            end
        end
    end
    if strcmp(c.types{k}, 'matlabfunction') && isfield(p, 'EntiersSeuls') && p.EntiersSeuls
        % les opérations bit à bit de la bibliothèque : des entiers seulement
        % (une entrée libre est une masse, qui prend le type qu'on attend)
        for j = 1:numel(tE)
            libre = j > numel(c.entrees{k}) || c.entrees{k}(j) == 0;
            if ~libre && tE(j) > 0 && ~(tE(j) >= 4 && tE(j) <= 9)
                error('Simulink:DataType:BitOperationInputType', ...
                      ['L''entree %d de ''%s'' recoit un signal de type %s : ce bloc opere ' ...
                       'sur les bits d''un entier (int8 a uint32). Convertissez le signal ' ...
                       '(Data Type Conversion).'], j, ch, nomDe(tE(j)));
            end
        end
    end
    switch c.types{k}
        case 'buscreator'
            nomType = '';
            if isfield(p, 'OutDataTypeStr')
                nomType = matlibre_sl_bus('type', p.OutDataTypeStr);
            end
            if ~isempty(nomType) && isfield(c, 'formeBus') && ~isempty(c.formeBus{k})
                verifierElements(c.formeBus{k}, matlibre_sl_bus('objet', nomType, ch), t, ch, ...
                                 nomType, '');
            end
        case 'busassignment'
            if isfield(c, 'choixBus') && ~isempty(c.choixBus{k}) && ~isempty(c.formeBus{k})
                codes = typesElements(c.formeBus{k}, t);
                places = c.choixBus{k};
                for q = 1:min(numel(places), numel(tE) - 1)
                    morceau = codes(places(q).debut:places(q).debut + places(q).largeur - 1);
                    if tE(q + 1) > 0 && all(morceau > 0) && any(morceau ~= tE(q + 1))
                        noms = strtrim(strsplit(char(p.AssignedSignals), ','));
                        error('Simulink:Bus:AssignmentDataTypeMismatch', ...
                              ['Le Bus Assignment ''%s'' remplace ''%s'', de type %s, par un ' ...
                               'signal de type %s : un element garde son type.'], ch, ...
                              noms{q}, nomDe(morceau(1)), nomDe(tE(q + 1)));
                    end
                end
            end
        case 'merge'
            if any(tE ~= tE(1))
                [~, j] = max(tE ~= tE(1));
                error('Simulink:DataType:MergeDataTypeMismatch', ...
                      ['Les entrees du Merge ''%s'' doivent etre du meme type : l''entree 1 ' ...
                       'est de type %s, l''entree %d de type %s.'], ch, nomDe(tE(1)), j, ...
                      nomDe(tE(j)));
            end
        case {'outport', 'signalconversion', 'inport'}
            attendu = typeFixe(p, ch);
            if attendu > 0 && ~isempty(tE) && tE(1) ~= attendu && c.entrees{k}(1) > 0
                error('Simulink:DataType:InputPortDataTypeMismatch', ...
                      ['''%s'' est de type %s (OutDataTypeStr), et recoit un signal de type ' ...
                       '%s : convertissez le signal (Data Type Conversion).'], ch, ...
                      nomDe(attendu), nomDe(tE(1)));
            end
    end
end

% Un paramètre rangé dans un type entier ou à virgule fixe, comme Simulink
% le range en compilant : arrondi au plus proche sur la grille du type, et
% les quatre diagnostics des paramètres de la configuration —
% ParameterDowncastMsg (un paramètre qui porte déjà un type, int32(5),
% rangé dans un type plus étroit), ParameterOverflowMsg (une valeur hors
% des bornes du type, saturée si l'on ne s'arrête pas),
% ParameterUnderflowMsg (une valeur non nulle qui devient nulle) et
% ParameterPrecisionLossMsg (une valeur qui ne s'écrit pas exactement).
% Un double, un single, un booléen, une énumération ne se quantifient pas.
% CLASSE est la classe que le paramètre portait avant d'être lu en double
% (« int32(5) »).
function q = quantifier(valeur, code, nom, chemin, config, classe)
    q = valeur;
    if ~isnumeric(valeur) || ~isreal(valeur) || isempty(valeur) || ...
       ~((code >= 4 && code <= 9) || (code > 100 && code <= 200))
        return
    end
    nomType = nomDe(code);
    v = double(valeur);
    if code <= 9
        bornes = [-128 127; 0 255; -32768 32767; 0 65535; -2147483648 2147483647; ...
                  0 4294967295];
        bas = bornes(code - 3, 1);
        haut = bornes(code - 3, 2);
        pente = 1;
        biais = 0;
    else
        T = typeNumerique(code);
        [bas, haut] = matlibre_fixe_bornes(T);
        pente = T.Slope;
        biais = T.Bias;
    end
    if nargin < 6
        classe = class(valeur);
    end
    entiers = {'int8', 'uint8', 'int16', 'uint16', 'int32', 'uint32', 'int64', 'uint64'};
    if strcmp(classe, 'single') || ...
       (any(strcmp(classe, entiers)) && ...
        (double(intmin(classe)) < bas * pente + biais || double(intmax(classe)) > haut * pente + biais))
        signalerParametre(config, 'ParameterDowncastMsg', 2, 'Simulink:Parameters:ParamDowncast', ...
            sprintf(['Le parametre %s de ''%s'' est de type %s, et le bloc le range en %s, plus ' ...
                     'etroit : la conversion le retrecit (downcast). ParameterDowncastMsg regle ' ...
                     'ce diagnostic.'], nom, chemin, classe, nomType));
    end
    n = round((v - biais) / pente);
    hors = n < bas | n > haut;
    if any(hors(:))
        signalerParametre(config, 'ParameterOverflowMsg', 2, 'Simulink:Parameters:ParamOverflow', ...
            sprintf(['La valeur %s du parametre %s de ''%s'' deborde le type %s, qui va de %g a ' ...
                     '%g : elle est saturee. ParameterOverflowMsg regle ce diagnostic.'], ...
                    texteParametre(v(hors)), nom, chemin, nomType, bas * pente + biais, ...
                    haut * pente + biais));
        n = min(max(n, bas), haut);
    end
    r = n * pente + biais;
    nul = ~hors & v ~= 0 & r == 0;
    if any(nul(:))
        signalerParametre(config, 'ParameterUnderflowMsg', 0, 'Simulink:Parameters:ParamUnderflow', ...
            sprintf(['La valeur %s du parametre %s de ''%s'' est trop petite pour le type %s : ' ...
                     'elle devient 0. ParameterUnderflowMsg regle ce diagnostic.'], ...
                    texteParametre(v(nul)), nom, chemin, nomType));
    end
    perdu = ~hors & ~nul & abs(r - v) > 8 * eps(max(abs(r), abs(v)));
    if any(perdu(:))
        signalerParametre(config, 'ParameterPrecisionLossMsg', 1, ...
            'Simulink:Parameters:ParamPrecisionLoss', ...
            sprintf(['La valeur %s du parametre %s de ''%s'' ne s''ecrit pas exactement en %s : ' ...
                     'elle devient %s. ParameterPrecisionLossMsg regle ce diagnostic.'], ...
                    texteParametre(v(perdu)), nom, chemin, nomType, texteParametre(r(perdu))));
    end
    q = reshape(r, size(valeur));
end

% Le niveau d'un diagnostic des paramètres : none, warning ou error.
function signalerParametre(config, champ, defaut, identifiant, texte)
    niveau = defaut;
    if isstruct(config) && isfield(config, champ)
        niveau = find(strcmp({'none', 'warning', 'error'}, config.(champ))) - 1;
    end
    if niveau == 2
        error(identifiant, '%s', texte);
    elseif niveau == 1
        warning(identifiant, '%s', texte);
    end
end

function t = texteParametre(v)
    v = v(:)';
    if numel(v) == 1
        t = num2str(v, 10);
    elseif numel(v) <= 8
        t = mat2str(v, 10);
    else
        t = [mat2str(v(1:8), 10) '...'];
        t = strrep(t, ']...', ' ...]');
    end
end

% Les blocs qui ne calculent qu'en virgule flottante — double ou single — :
% Trigonometric Function, Polynomial, Magnitude-Angle to Complex ; et Real-
% Imag to Complex, qui ne forme pas de complexe à virgule fixe.
function verifierFlottants(c, k, tE)
    p = c.p{k};
    ch = c.chemins{k};
    bibliotheque = '';
    if strcmp(c.types{k}, 'matlabfunction') && isfield(p, 'Bibliotheque')
        bibliotheque = p.Bibliotheque;
    end
    if any(strcmp(c.types{k}, {'trigonometry', 'polynomial'})) || ...
       strcmp(bibliotheque, 'magnitudeangletocomplex')
        j = find(tE ~= 2 & tE ~= 3 & tE <= 200, 1);
        if ~isempty(j)
            error('Simulink:DataType:InputPortDataTypeMismatch', ...
                  ['L''entree %d de ''%s'' recoit un signal de type %s, mais ce bloc ne ' ...
                   'calcule qu''en virgule flottante (double, single) : convertissez le ' ...
                   'signal (Data Type Conversion).'], j, ch, nomDe(max(tE(j), 2)));
        end
    elseif strcmp(bibliotheque, 'realimagtocomplex')
        j = find(tE > 100 & tE <= 200, 1);
        if ~isempty(j)
            error('Simulink:DataType:InputPortDataTypeMismatch', ...
                  ['L''entree %d de ''%s'' recoit un signal de type %s : MatLibre ne forme ' ...
                   'pas de complexe a virgule fixe ; convertissez les parties en double ' ...
                   'ou en single (Data Type Conversion).'], j, ch, nomDe(tE(j)));
        end
    end
end

% --- les types énumérés --------------------------------------------------

% Les blocs qui admettent un signal énuméré, entrée par entrée : ceux qui
% le retardent, l'aiguillent, le rangent, le comparent ou le convertissent
% sans calculer dessus — la liste de la documentation de Simulink.
function admis = entreesEnumAdmises(c, k, nE)
    p = c.p{k};
    admis = false(1, nE);
    switch c.types{k}
        case {'mux', 'demux', 'concatenate', 'selector', 'reshape', 'merge', 'inport', ...
              'signalconversion', 'datatypeconversion', 'ic', 'zoh', 'memory', ...
              'ratetransition', 'outport', 'terminator', 'scope', 'display', 'toworkspace', ...
              'manualswitch', 'relational', 'comparetoconstant', 'switchcase', 'width', ...
              'goto', 'from', 'multiportswitch', 'buscreator', 'busselector', 'busassignment', ...
              'chart'}
            admis(:) = true;
        case 'delay'
            admis(1) = true;   % le signal retardé ; longueur, activation, remise sont numériques
        case 'switch'
            admis([1 min(3, end)]) = true;   % les données, pas la commande
        case 'matlabfunction'
            admis(:) = ~isfield(p, 'Bibliotheque');   % une fonction écrite par l'utilisateur
    end
end

% La classe énumérée d'un paramètre, '' s'il est numérique.
function classe = classeParametre(p, nom)
    classe = '';
    if isfield(p, 'Classes') && isfield(p.Classes, nom) && strncmp(p.Classes.(nom), 'Enum:', 5)
        classe = strtrim(p.Classes.(nom)(6:end));
    end
end

function verifierEnum(c, k, tE, t)
    p = c.p{k};
    ch = c.chemins{k};
    type = c.types{k};
    % un membre ne se donne qu'aux paramètres qui valent un signal : la
    % valeur d'une constante, une condition ou une sortie initiale, la
    % constante d'une comparaison
    if isfield(p, 'Classes')
        admis = struct('constant', {{'Value'}}, 'ic', {{'Value'}}, ...
                       'delay', {{'InitialCondition'}}, 'memory', {{'InitialCondition'}}, ...
                       'merge', {{'InitialOutput'}}, 'outport', {{'InitialOutput'}}, ...
                       'comparetoconstant', {{'const'}});
        noms = fieldnames(p.Classes);
        for i = 1:numel(noms)
            if strncmp(p.Classes.(noms{i}), 'Enum:', 5) && ...
               ~(isfield(admis, type) && any(strcmp(noms{i}, admis.(type))))
                error('Simulink:DataType:EnumParameterMismatch', ...
                      ['Le parametre ''%s'' de ''%s'' est un membre de %s : ce parametre ' ...
                       'attend un nombre.'], noms{i}, ch, strtrim(p.Classes.(noms{i})(6:end)));
            end
        end
    end
    if strcmp(type, 'datatypeconversion') && ~isempty(tE) && c.nOut(k) > 0
        % une énumération se convertit en entier et un entier en
        % énumération, non une énumération en une autre, ni en virgule fixe
        entree = tE(1);
        sortie = t(c.portDebut(k));
        fixe = @(x) x > 100 && x <= 200;
        if entree ~= sortie && ((entree > 200 && sortie > 200) || ...
                                (entree > 200 && fixe(sortie)) || (sortie > 200 && fixe(entree)))
            error('Simulink:DataType:EnumTypeMismatch', ...
                  ['''%s'' convertirait un signal de type %s en %s : un type enumere se ' ...
                   'convertit en entier, et un entier en type enumere. Passez par un ' ...
                   'entier (int32).'], ch, nomDe(entree), nomDe(sortie));
        end
    end
    enumE = tE > 200;
    if any(enumE)
        j = find(enumE & ~entreesEnumAdmises(c, k, numel(tE)), 1);
        if ~isempty(j)
            error('Simulink:DataType:EnumTypeNotSupported', ...
                  ['L''entree %d de ''%s'' recoit un signal de type %s : ce bloc ne calcule ' ...
                   'pas sur un type enumere. Convertissez le signal en entier (Data Type ' ...
                   'Conversion), ou comparez-le a un membre (Relational Operator).'], j, ch, ...
                  nomDe(tE(j)));
        end
    end
    % les entrées qui doivent partager un même type
    switch type
        case {'relational', 'mux', 'concatenate', 'merge', 'manualswitch'}
            groupe = 1:numel(tE);
        case 'switch'
            groupe = [1 min(3, numel(tE))];
        case 'multiportswitch'
            groupe = 2:numel(tE);
        otherwise
            groupe = [];
    end
    groupe = groupe(groupe <= numel(tE));
    if any(tE(groupe) > 200) && any(tE(groupe) ~= tE(groupe(1)))
        j = groupe(find(tE(groupe) ~= tE(groupe(find(tE(groupe) > 200, 1))), 1));
        a = groupe(find(tE(groupe) > 200, 1));
        error('Simulink:DataType:EnumTypeMismatch', ...
              ['Les entrees %d et %d de ''%s'' sont de types %s et %s : un type enumere ne ' ...
               'se melange qu''a lui-meme. Convertissez l''autre signal (Data Type ' ...
               'Conversion).'], a, j, ch, nomDe(tE(a)), nomDe(tE(j)));
    end
    % un paramètre qui est un membre : du type du signal, et réciproquement
    parametres = {};
    switch type
        case 'comparetoconstant'
            parametres = {'const', tE(1)};
        case {'delay', 'memory'}
            parametres = {'InitialCondition', tE(1)};
        case 'ic'
            parametres = {'Value', tE(1)};
        case 'merge'
            parametres = {'InitialOutput', tE(1)};
        case 'constant'
            typeSortie = typeFixe(p, ch);
            if typeSortie > 200 || ~isempty(classeParametre(p, 'Value'))
                parametres = {'Value', typeSortie};
            end
    end
    if isempty(parametres) || isempty(tE) && ~strcmp(type, 'constant')
        return
    end
    nom = parametres{1};
    attendu = parametres{2};
    classe = classeParametre(p, nom);
    if attendu == 0 && ~isempty(classe)
        return   % une constante qui hérite du type de sa valeur
    end
    if attendu > 200 && isempty(classe) && any(strcmp(type, {'merge', 'outport'})) && ...
       all(double(p.(nom)(:)) == 0)
        return   % la sortie initiale par défaut : le membre par défaut
    end
    if attendu > 200 && ~strcmp(classe, registreEnum('classe', attendu))
        if isempty(classe)
            vu = 'une valeur numerique';
        else
            vu = ['un membre de ' classe];
        end
        error('Simulink:DataType:EnumParameterMismatch', ...
              ['Le parametre ''%s'' de ''%s'' est %s, et le signal est de type %s : ' ...
               'donnez-lui un membre de cette enumeration, comme %s.%s.'], nom, ch, vu, ...
              nomDe(attendu), registreEnum('classe', attendu), premierMembre(attendu));
    elseif attendu <= 200 && ~isempty(classe)
        error('Simulink:DataType:EnumParameterMismatch', ...
              ['Le parametre ''%s'' de ''%s'' est un membre de %s, et le signal est de ' ...
               'type %s : un membre ne vaut que pour un signal de son type.'], nom, ch, ...
              classe, nomDe(max(attendu, 2)));
    end
end

function n = premierMembre(code)
    [~, noms] = enumeration(registreEnum('classe', code));
    n = noms{1};
end

% --- la complexité des signaux ------------------------------------------

% Un signal ne fait que devenir complexe : une boucle peut apporter un
% complexe à un bloc qui ne voyait que du réel, jamais l'inverse. On
% répète donc les règles jusqu'à ce que plus rien ne change.
function x = complexite(c)
    x = false(1, c.nPorts);
    sondes = cell(1, c.n);
    for tour = 1:(2 * c.n + 5)
        change = false;
        for k = 1:c.n
            if c.nOut(k) == 0
                continue
            end
            ports = c.portDebut(k) + (0:c.nOut(k) - 1);
            [s, sondes{k}] = regleComplexe(c, k, complexitesEntrees(c, k, x), sondes{k});
            nouveau = x(ports) | s;
            if any(nouveau ~= x(ports))
                x(ports) = nouveau;
                change = true;
            end
        end
        if ~change
            break
        end
    end
    for k = 1:c.n
        verifierComplexe(c, k, complexitesEntrees(c, k, x));
    end
end

function xE = complexitesEntrees(c, k, x)
    e = c.entrees{k};
    xE = false(1, numel(e));
    for j = 1:numel(e)
        if e(j) > 0
            xE(j) = x(e(j));
        end
    end
end

function oui = complexeValeur(p, nom)
    oui = isfield(p, nom) && isnumeric(p.(nom)) && ~isreal(p.(nom));
end

% Les blocs qui calculent aussi bien en complexe, entrée par entrée : ce
% que dit la documentation de chaque bloc de Simulink.
function admis = entreesComplexesAdmises(c, k, nE)
    p = c.p{k};
    admis = false(1, nE);
    switch c.types{k}
        case {'gain', 'sum', 'product', 'bias', 'unaryminus', 'abs', 'mux', 'demux', ...
              'concatenate', 'selector', 'reshape', 'merge', 'signalconversion', ...
              'datatypeconversion', 'ic', 'zoh', 'memory', 'ratetransition', 'tappeddelay', ...
              'difference', 'outport', 'terminator', 'scope', 'display', 'toworkspace', ...
              'manualswitch', 'dotproduct', 'width'}
            admis(:) = true;
        case 'delay'
            admis(1) = true;   % le signal retardé ; longueur, activation, remise sont réelles
        case 'discretefilter'
            % un Discrete FIR Filter, ramené à un filtre de dénominateur 1
            admis(:) = isfield(p, 'Bibliotheque') && strcmp(p.Bibliotheque, 'discretefirfilter');
        case 'switch'
            admis([1 min(3, end)]) = true;   % les données, pas la commande
        case 'multiportswitch'
            admis(2:end) = true;
        case 'relational'
            admis(:) = any(strcmp(p.Operator, {'==', '~='}));
        case 'math'
            admis(:) = ~any(strcmp(p.Operator, {'hypot', 'rem', 'mod'}));
        case 'sqrt'
            admis(:) = ~strcmp(p.Operator, 'signedSqrt');
        case 'trigonometry'
            admis(:) = ~any(strcmp(p.Operator, {'atan2', 'sincos', 'cos + jsin'}));
        case 'matlabfunction'
            if ~isfield(p, 'Bibliotheque')
                admis(:) = true;   % une MATLAB Function écrite par l'utilisateur
            else
                admis(:) = any(strcmp(p.Bibliotheque, {'complextorealimag', ...
                    'complextomagnitudeangle', 'assignment', 'permutedimensions', ...
                    'squeeze', 'discretefirfilter'}));
            end
    end
end

function [s, sonde] = regleComplexe(c, k, xE, sonde)
    p = c.p{k};
    s = false(1, c.nOut(k));
    tous = any(xE & entreesComplexesAdmises(c, k, numel(xE)));
    switch c.types{k}
        case 'constant'
            s(:) = complexeValeur(p, 'Value');
        case 'gain'
            s(:) = tous || complexeValeur(p, 'Gain');
        case 'bias'
            s(:) = tous || complexeValeur(p, 'Bias');
        case {'ic', 'delay', 'memory', 'difference', 'tappeddelay'}
            s(:) = tous || complexeValeur(p, 'Value') || complexeValeur(p, 'InitialCondition') ...
                   || complexeValeur(p, 'ICPrevInput') || complexeValeur(p, 'vinit');
        case {'sum', 'product', 'unaryminus', 'mux', 'demux', 'concatenate', 'selector', ...
              'reshape', 'merge', 'signalconversion', 'datatypeconversion', 'zoh', ...
              'ratetransition', 'manualswitch', 'dotproduct', 'switch', 'multiportswitch', ...
              'discretefilter'}
            s(:) = tous;
        case 'math'
            s(:) = tous && ~strcmp(p.Operator, 'magnitude^2');
        case {'sqrt', 'trigonometry'}
            s(:) = tous || strcmp(p.Operator, 'cos + jsin');
        case 'fromworkspace'
            s(:) = isfield(c, 'sourceComplexe') && c.sourceComplexe(k);
        case 'matlabfunction'
            [s, sonde] = complexiteFonction(c, k, xE, sonde);
    end
end

% Ce que rend une MATLAB Function se sonde. Sur des zéros, un calcul
% complexe peut s'annuler en réel — 0 * 1i vaut 0 — : on la sonde donc
% aussi sur des valeurs quelconques, 0,7 pour une entrée réelle, 0,7 +
% 0,3i pour une complexe ; qu'elle échoue alors ne dit rien. Une sortie
% complexe à l'une des deux sondes est complexe.
function [s, sonde] = complexiteFonction(c, k, xE, sonde)
    if ~isempty(sonde) && isequal(sonde.xE, xE)
        s = sonde.s;
        return
    end
    s = false(1, c.nOut(k));
    if isfield(c, 'fonctions') && isstruct(c.fonctions{k}) && isfield(c.fonctions{k}, 'h')
        h = c.fonctions{k}.h;
        for essai = 1:2
            u = cell(1, c.nIn(k));
            for j = 1:c.nIn(k)
                d = [1 1];
                if c.entrees{k}(j) > 0
                    d = c.dims{c.entrees{k}(j)};
                end
                valeur = (essai - 1) * complex(0.7, 0.3 * xE(j));
                if ~xE(j)
                    valeur = real(valeur);
                end
                u{j} = valeur * ones(d);
                if isfield(c, 'typePort') && c.entrees{k}(j) > 0
                    u{j} = valeurEssai(c.typePort(c.entrees{k}(j)), u{j}, d);
                end
                if xE(j)
                    u{j} = complex(u{j});
                end
            end
            sorties = cell(1, c.nOut(k));
            try
                [sorties{:}] = h(u{:});
                for q = 1:c.nOut(k)
                    s(q) = s(q) || (isnumeric(sorties{q}) && ~isreal(sorties{q}));
                end
            catch err
                if essai == 1
                    clear(func2str(h));
                    if strncmp(err.identifier, 'Simulink:', 9) && ...
                       ~isempty(strfind(err.message, c.chemins{k}))
                        rethrow(err);
                    end
                    error('Simulink:blocks:MATLABFunctionError', ...
                          'La fonction du bloc ''%s'' echoue sur des entrees nulles : %s', ...
                          c.chemins{k}, err.message);
                end
            end
            clear(func2str(h));
        end
    end
    sonde = struct('xE', xE, 's', s);
end

function verifierComplexe(c, k, xE)
    p = c.p{k};
    ch = c.chemins{k};
    if isfield(p, 'ComplexiteVerifiee') && ~isempty(xE)
        % Signal Specification : la complexité annoncée doit être celle de
        % l'entrée
        if (strcmp(p.ComplexiteVerifiee, 'real') && xE(1)) || ...
           (strcmp(p.ComplexiteVerifiee, 'complex') && ~xE(1))
            noms = {'reel', 'complexe'};
            error('Simulink:DataType:SignalSpecificationMismatch', ...
                  ['Le bloc Signal Specification ''%s'' annonce un signal %s, et son entree ' ...
                   'est un signal %s.'], ch, noms{1 + ~xE(1)}, noms{1 + xE(1)});
        end
    end
    if strcmp(c.types{k}, 'outport') && isfield(p, 'SignalType') && ~isempty(xE) && ...
       c.entrees{k}(1) > 0 && ((strcmp(p.SignalType, 'real') && xE(1)) || ...
                               (strcmp(p.SignalType, 'complex') && ~xE(1)))
        noms = {'reel', 'complexe'};
        error('Simulink:DataType:InputPortComplexityMismatch', ...
              '''%s'' attend un signal %s (SignalType), et recoit un signal %s.', ch, ...
              noms{1 + ~xE(1)}, noms{1 + xE(1)});
    end
    if ~any(xE)
        return
    end
    admis = entreesComplexesAdmises(c, k, numel(xE));
    j = find(xE & ~admis, 1);
    if ~isempty(j)
        error('Simulink:DataType:InputPortComplexityMismatch', ...
              ['L''entree %d de ''%s'' recoit un signal complexe, mais ce bloc ne traite ' ...
               'que des signaux reels : separez parties reelle et imaginaire (Complex to ' ...
               'Real-Imag), ou prenez le module (Abs).'], j, ch);
    end
end

% --- la règle interne des calculs à virgule fixe -------------------------

% [signe, taille, bits après la virgule] d'un type ; vide pour une échelle
% qui n'est pas une puissance de deux.
function d = decrire(code)
    entiers = [4 1 8; 5 0 8; 6 1 16; 7 0 16; 8 1 32; 9 0 32; 10 0 1];
    k = find(entiers(:, 1) == code, 1);
    if ~isempty(k)
        d = [entiers(k, 2:3), 0];
    elseif code > 100
        l = registre('ligne', code);
        d = l(1:3);
        if l(4) ~= 1 || l(5) ~= 0
            d = [];
        end
    else
        d = [];
    end
end

function r = regleInterne(type, p, tE, chemin)
    if any(tE == 2 | tE == 3)
        r = 2 + all(tE(tE == 2 | tE == 3) == 3);   % un flottant : le calcul se fait en flottant
        return
    end
    d = zeros(numel(tE), 3);
    for j = 1:numel(tE)
        dj = decrire(tE(j));
        if isempty(dj)
            r = tE(1);   % une pente quelconque : le type de la première entrée
            return
        end
        d(j, :) = dj;
    end
    switch type
        case 'sum'
            signes = char(p.Signs);
            n = max(numel(tE), 2);
            moins = any(signes == '-');
            S = any(d(:, 1)) || moins;
            F = max(d(:, 3));
            I = max(d(:, 2) - d(:, 3) - d(:, 1)) + ceil(log2(n));
            W = S + I + F;
        case 'product'
            if any(char(p.Inputs) == '/')
                r = tE(1);
                return
            end
            S = any(d(:, 1));
            W = sum(d(:, 2));
            F = sum(d(:, 3));
        otherwise   % gain : entrée fois paramètre, dans le type de ce dernier
            dK = decrire(codeParametreGain(p, tE(1), chemin));
            if isempty(dK)
                r = tE(1);
                return
            end
            S = d(1, 1) || dK(1);
            W = d(1, 2) + dK(2);
            F = d(1, 3) + dK(3);
    end
    if W > 32
        F = F - (W - 32);   % au plus 32 bits : les bits après la virgule cèdent
        W = 32;
    end
    r = codeDuType(numerictype(S, W, F));
    if r < 0
        error('Simulink:DataType:InternalRule', ...
              'Le type de sortie de ''%s'' ne se deduit pas de ses entrees.', chemin);
    end
end

% Le type du paramètre d'un gain dont l'entrée est à virgule fixe : celui
% que dit ParamDataTypeStr, ou la meilleure précision pour sa valeur, sur
% la taille et le signe de l'entrée — signé si le gain est négatif.
function r = codeParametreGain(p, typeEntree, chemin)
    r = 0;
    if isfield(p, 'ParamDataTypeStr')
        r = typeFixe(struct('OutDataTypeStr', p.ParamDataTypeStr, 'Value', p.Gain), chemin);
    end
    if r ~= 0
        return
    end
    d = decrire(typeEntree);
    if isempty(d)
        r = typeEntree;
        return
    end
    K = double(p.Gain);
    sK = any(K(:) < 0) || d(1);
    r = codeDuType(numerictype(sK, d(2), matlibre_fixe_precision(K, sK, d(2))));
end
