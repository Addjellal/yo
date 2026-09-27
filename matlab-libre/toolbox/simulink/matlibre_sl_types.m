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
        otherwise
            error('Simulink:DataType:Action', 'Action inconnue : %s.', char(action));
    end
end

function n = nomDe(code)
    if code > 100
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
    if code > 100
        k = 'double';
        return
    end
    k = nomDe(code);
    if strcmp(k, 'boolean')
        k = 'logical';
    end
end

function v = convertir(code, v)
    if code > 100
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

% Le code d'un type décrit par un NUMERICTYPE : un entier de MATLAB quand
% il en est un (fixdt(1,16,0) est int16), sinon un type à virgule fixe.
function code = codeDuType(T)
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

% Le code du type d'une valeur : un FI a celui de son NUMERICTYPE.
function code = codeDeValeur(v)
    if isa(v, 'embedded.fi')
        code = codeDuType(numerictype(v));
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
    if isempty(code)
        code = codeFixeDe(nom);
    end
end

% Un type à virgule fixe écrit : 'fixdt(1,16,8)', 'sfix16_En8', ou le nom
% d'une variable de l'espace de travail qui porte un Simulink.NumericType ;
% -1 pour ce qui n'en est pas un, -2 pour une échelle qui n'est pas dite.
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
        end
    end
    if ~isempty(T)
        code = codeDuType(T);
    end
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
    end
    if t < 0
        error('Simulink:DataType:UnknownDataType', ...
              ['Le type ''%s'' du bloc ''%s'' est inconnu : les types sont double, single, ' ...
               'int8, uint8, int16, uint16, int32, uint32, boolean, les types a virgule ' ...
               'fixe (fixdt(1,16,8), sfix16_En8), ou ''Inherit: ...''.'], ...
              char(p.OutDataTypeStr), chemin);
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
            s = regle(c, k, typesEntrees(c, k, t));
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

function s = regle(c, k, tE)
    p = c.p{k};
    ch = c.chemins{k};
    n = c.nOut(k);
    arithmetique = {'gain', 'sum', 'product', 'bias', 'unaryminus', 'abs', 'dotproduct', ...
                    'rounding', 'quantizer', 'saturation', 'deadzone', 'sign'};
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
                if any(tE > 100) && all(tE > 0)
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
              'ratelimiter', 'tappeddelay', 'difference', 'busselector', 'busassignment', ...
              'algebraicconstraint'}
            r = commun(tE(1:min(1, end)));
        case {'minmax', 'mux', 'concatenate', 'merge', 'dotproduct'}
            r = commun(tE);
        case 'switch'
            r = commun(tE([1 min(3, end)]));
        case 'multiportswitch'
            r = commun(tE(2:end));
        case 'matlabfunction'
            if any(tE == 0)
                s = [];
                return
            end
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
        u{j} = convertir(tE(j), zeros(d));
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

function s = classesGraphe(c, k)
    code = c.fonctions{k};
    s = 2 * ones(1, c.nOut(k));
    for q = 1:min(c.nOut(k), numel(code.sorties))
        nom = code.sorties{q};
        if isfield(code.contexte, nom)
            r = codeDe(class(code.contexte.(nom)));
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
    doublesSeuls = {'integrator', 'secondorderintegrator', 'derivative', 'transferfcn', ...
                    'statespace', 'zeropole', 'transportdelay', 'pidcontroller', ...
                    'variabletransportdelay', ...
                    'trigonometry', 'fcn', 'interpretedmatlabfunction', 'sfunction', ...
                    'msfunction'};
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
        case 'constant'
            attendu = typeFixe(p, ch);
            if attendu > 100
                T = typeNumerique(attendu);
                [bas, haut] = matlibre_fixe_bornes(T);
                v = (double(p.Value(:)) - T.Bias) / T.Slope;
                if any(v < bas - 0.5 | v >= haut + 0.5)
                    error('Simulink:Parameters:ParamOverflow', ...
                          ['La valeur %s de ''%s'' deborde le type %s, qui va de %g a %g.'], ...
                          mat2str(p.Value, 6), ch, nomDe(attendu), bas * T.Slope + T.Bias, ...
                          haut * T.Slope + T.Bias);
                end
            end
            if attendu >= 4 && attendu <= 9
                bornes = [-128 127; 0 255; -32768 32767; 0 65535; -2147483648 2147483647; ...
                          0 4294967295];
                b = bornes(attendu - 3, :);
                v = double(p.Value(:));
                if any(v < b(1) | v > b(2))
                    error('Simulink:Parameters:ParamOverflow', ...
                          ['La valeur %s de ''%s'' deborde le type %s, qui va de %d a %d.'], ...
                          mat2str(p.Value, 6), ch, nomDe(attendu), b(1), b(2));
                end
            end
    end
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
                    u{j} = convertir(c.typePort(c.entrees{k}(j)), u{j});
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
