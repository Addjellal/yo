function varargout = matlibre_sl_types(action, varargin)
%MATLIBRE_SL_TYPES Les types de données des signaux : propagation et contrôle.
%   T = MATLIBRE_SL_TYPES('propager',C) rend le type de chaque port de
%   sortie du modèle compilé C, comme Simulink le propage : un code par
%   port — 2 double, 3 single, 4 int8, 5 uint8, 6 int16, 7 uint16,
%   8 int32, 9 uint32, 10 boolean. Une constante a le type de sa valeur ou
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
        case 'code'
            varargout{1} = codeDe(varargin{1});
        case 'nom'
            varargout{1} = nomDe(varargin{1});
        case 'classe'
            varargout{1} = classeDe(varargin{1});
        otherwise
            error('Simulink:DataType:Action', 'Action inconnue : %s.', char(action));
    end
end

function n = nomDe(code)
    noms = {'', 'double', 'single', 'int8', 'uint8', 'int16', 'uint16', 'int32', ...
            'uint32', 'boolean'};
    n = noms{code};
end

function k = classeDe(code)
    k = nomDe(code);
    if strcmp(k, 'boolean')
        k = 'logical';
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
        code = -1;
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
    if t < 0
        error('Simulink:DataType:UnknownDataType', ...
              ['Le type ''%s'' du bloc ''%s'' est inconnu : les types sont double, single, ' ...
               'int8, uint8, int16, uint16, int32, uint32 et boolean, ou ''Inherit: ...''.'], ...
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
        case {'logic', 'relational', 'comparetoconstant', 'comparetozero', 'detectchange', ...
              'detectincrease', 'detectdecrease', 'intervaltest'}
            % un booléen, ou le type que dit OutDataTypeStr
            r = typeFixe(p, ch);
            if r == 0
                r = 10;
            end
        case {'gain', 'abs', 'unaryminus', 'sign', 'rounding', 'saturation', 'deadzone', ...
              'quantizer', 'bias', 'zoh', 'memory', 'delay', 'ratetransition', 'from', ...
              'selector', 'reshape', 'demux', 'ic', 'manualswitch', 'wraptozero', 'backlash', ...
              'ratelimiter', 'tappeddelay', 'difference', 'busselector'}
            r = commun(tE(1:min(1, end)));
        case {'sum', 'product', 'minmax', 'mux', 'concatenate', 'merge', 'dotproduct'}
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
        u{j} = cast(zeros(d), classeDe(tE(j)));
    end
    sorties = cell(1, c.nOut(k));
    try
        [sorties{:}] = h(u{:});
    catch err
        error('Simulink:blocks:MATLABFunctionError', ...
              'La fonction du bloc ''%s'' echoue sur des entrees nulles typees : %s', ...
              c.chemins{k}, err.message);
    end
    clear(func2str(h));
    s = 2 * ones(1, c.nOut(k));
    for q = 1:c.nOut(k)
        r = codeDe(class(sorties{q}));
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
