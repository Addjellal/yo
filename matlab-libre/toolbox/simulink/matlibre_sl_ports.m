function [nEntrees, nSorties] = matlibre_sl_ports(bloc, type)
%MATLIBRE_SL_PORTS Le nombre de ports d'entrée et de sortie d'un bloc.
%   [NE,NS] = MATLIBRE_SL_PORTS(BLOC) rend le nombre de ports d'entrée et
%   de sortie du bloc, tel que ses paramètres le fixent : une sommation a
%   autant d'entrées que de signes, un Mux autant que son paramètre
%   Inputs, un Demux autant de sorties que son paramètre Outputs, un
%   sous-système autant d'entrées et de sorties que le modèle qu'il abrège
%   porte de blocs INPORT et OUTPORT.
%
%   [NE,NS] = MATLIBRE_SL_PORTS(BLOC,TYPE) prend le type canonique déjà
%   résolu, ce qui épargne une recherche dans le catalogue.
%
%   Un paramètre donné par une expression — « 'Inputs', 'n' » — ne se
%   connaît qu'au moment de simuler : le nombre rendu est alors NaN, et
%   c'est la compilation du modèle qui tranchera.
%
%   ADD_LINE s'en sert pour refuser un port qui n'existe pas, la
%   compilation pour valider le câblage, l'éditeur pour dessiner les ports.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      b = struct('type', 'sum', 'nom', 's', 'parametres', struct('Signs', '+-+'));
%      [ne, ns] = matlibre_sl_ports(b)          % 3 et 1
%
%   Voir aussi ADD_LINE, MATLIBRE_SL_CATALOGUE.
    if nargin < 2 || isempty(type)
        entree = matlibre_sl_catalogue('type', bloc.type);
        type = entree.type;
    end
    p = bloc.parametres;
    nEntrees = 1;
    nSorties = 1;
    switch type
        case {'constant', 'step', 'ramp', 'sine', 'clock', 'digitalclock', ...
              'pulsegenerator', 'ground', 'repeatingsequence', 'randomnumber', ...
              'uniformrandomnumber', 'inport', 'fromworkspace', 'from'}
            nEntrees = 0;
        case 'math'
            if any(strcmpi(lire(p, 'Operator', 'square'), {'pow', 'hypot', 'rem', 'mod'}))
                nEntrees = 2;
            end
        case 'trigonometry'
            operateur = lower(char(lire(p, 'Operator', 'sin')));
            if strcmp(operateur, 'atan2')
                nEntrees = 2;
            elseif strcmp(operateur, 'sincos')
                nSorties = 2;
            end
        case 'sum'
            nEntrees = compterSignes(lireAlias(p, {'Signs', 'Inputs', 'ListOfSigns'}, '++'), '+-');
        case 'product'
            nEntrees = compterSignes(lire(p, 'Inputs', '**'), '*/');
        case 'minmax'
            nEntrees = entier(lire(p, 'Inputs', 2));
        case 'logic'
            if strcmpi(lire(p, 'Operator', 'AND'), 'NOT')
                nEntrees = 1;
            else
                nEntrees = entier(lire(p, 'Inputs', 2));
            end
        case {'relational', 'dotproduct', 'lookup2d'}
            nEntrees = 2;
        case 'switch'
            nEntrees = 3;
        case 'multiportswitch'
            nEntrees = 1 + entier(lire(p, 'Inputs', 3));
        case 'buscreator'
            nEntrees = compterNoms(lire(p, 'Inputs', '2'));
        case 'busselector'
            if strcmpi(char(lire(p, 'OutputAsBus', 'off')), 'on')
                nSorties = 1;
            else
                nSorties = compterNoms(lire(p, 'OutputSignals', 'signal1,signal2'));
            end
        case 'mux'
            nEntrees = compterParties(lire(p, 'Inputs', 2));
        case 'demux'
            nSorties = compterParties(lire(p, 'Outputs', 2));
        case 'concatenate'
            nEntrees = entier(lire(p, 'NumInputs', 2));
        case 'goto'
            nSorties = 0;
        case {'outport', 'display', 'toworkspace', 'terminator', 'stopsimulation', ...
              'assertion'}
            nSorties = 0;
        case 'scope'
            nEntrees = entier(lire(p, 'NumInputPorts', 1));
            nSorties = 0;
        case 'signalconversion'
            nEntrees = entier(lire(p, 'NombreDePorts', 1));
            nSorties = nEntrees;
        case 'subsystem'
            [nEntrees, nSorties] = bornesSousSysteme(p);
        case {'enableport', 'triggerport', 'actionport'}
            nEntrees = 0;
            nSorties = 0;
        case 'if'
            nEntrees = entier(lire(p, 'NumInputs', 1));
            nSorties = 1 + numel(expressionsSinonSi(lire(p, 'ElseIfExpressions', ''))) + ...
                       strcmpi(char(lire(p, 'ShowElse', 'on')), 'on');
        case 'switchcase'
            cas = lire(p, 'CaseConditions', '{1}');
            if ischar(cas) || isstring(cas)
                try
                    cas = eval(char(cas));
                catch
                    cas = NaN;
                end
            end
            if iscell(cas)
                nSorties = numel(cas) + strcmpi(char(lire(p, 'ShowDefaultCase', 'on')), 'on');
            else
                nSorties = NaN;
            end
        case 'merge'
            nEntrees = entier(lire(p, 'Inputs', 2));
        case 'garde'
            nEntrees = (lire(p, 'Enable', 0) ~= 0) + ~strcmpi(char(lire(p, 'Trigger', 'none')), ...
                                                             'none') + (lire(p, 'Action', 0) ~= 0);
        case 'chart'
            nEntrees = entier(lire(p, 'Inputs', 1));
            sorties = lire(p, 'Outputs', {'etat'});
            if ischar(sorties) || isstring(sorties)
                sorties = cellstr(sorties);
            end
            nSorties = numel(sorties);
        case 'matlabfunction'
            % Les arguments de la fonction sont les entrées, ses sorties les
            % sorties.
            try
                [nEntrees, nSorties] = matlibre_sl_fonction('signature', ...
                    lire(p, 'Script', sprintf('function y = fcn(u)\ny = u;')));
            catch
                nEntrees = NaN;
                nSorties = NaN;
            end
        case 'sfunction'
            % Une S-fonction dit ses tailles au drapeau 0 : un port d'entrée
            % si elle a des entrées, un de sortie si elle a des sorties.
            try
                parametres = lire(p, 'Parameters', '');
                if ischar(parametres) || isstring(parametres)
                    parametres = evalin('base', ['{' char(parametres) '}']);
                end
                tailles = matlibre_sl_fonction('sfonction', lire(p, 'FunctionName', ...
                                               'system'), parametres, bloc.nom);
                nEntrees = double(tailles(4) ~= 0);
                nSorties = double(tailles(3) ~= 0);
            catch
                nEntrees = 1;
                nSorties = 1;
            end
    end
end

% Les conditions « sinon si » d'un bloc If : une liste séparée par des
% virgules, hors des parenthèses — « u1 > 0, max(u1,u2) < 3 » en porte
% deux.
function liste = expressionsSinonSi(texte)
    liste = {};
    texte = char(texte);
    if isempty(strtrim(texte))
        return
    end
    profondeur = 0;
    debut = 1;
    for i = 1:numel(texte)
        switch texte(i)
            case {'(', '[', '{'}
                profondeur = profondeur + 1;
            case {')', ']', '}'}
                profondeur = profondeur - 1;
            case ','
                if profondeur == 0
                    liste{end + 1} = strtrim(texte(debut:i - 1)); %#ok<AGROW>
                    debut = i + 1;
                end
        end
    end
    liste{end + 1} = strtrim(texte(debut:end));
end

function v = lire(p, nom, defaut)
    v = defaut;
    champs = fieldnames(p);
    for k = 1:numel(champs)
        if strcmpi(champs{k}, nom)
            v = p.(champs{k});
            return
        end
    end
end

function v = lireAlias(p, noms, defaut)
    v = defaut;
    for k = 1:numel(noms)
        trouve = lire(p, noms{k}, []);
        if ~isempty(trouve)
            v = trouve;
            return
        end
    end
end

% Un nombre de ports donné par une expression ne se connaît pas avant la
% simulation : NaN le dit.
function n = entier(v)
    if ischar(v) || isstring(v)
        valeur = str2double(char(v));
        if isnan(valeur)
            n = NaN;
            return
        end
        v = valeur;
    end
    n = double(v);
    if ~isscalar(n)
        n = NaN;
    end
end

% Les signes d'une sommation ou d'un produit : « +-+ », « |+- » ou
% « **/ ». Les barres et les espaces ne sont que de la mise en page. Un
% nombre dit autant de signes par défaut.
function n = compterSignes(v, admis)
    if isnumeric(v)
        n = double(v);
        if ~isscalar(n), n = NaN; end
        return
    end
    texte = char(v);
    valeur = str2double(texte);
    if ~isnan(valeur) && all(ismember(texte, '0123456789 '))
        n = valeur;
        return
    end
    n = sum(ismember(texte, admis));
end

% Un nombre, ou une liste de noms séparés par des virgules.
function n = compterNoms(v)
    if isnumeric(v)
        n = entier(v);
        return
    end
    texte = strtrim(char(v));
    valeur = str2double(texte);
    if ~isnan(valeur)
        n = valeur;
        return
    end
    n = numel(strsplit(texte, ','));
end

% Mux et Demux : un nombre de voies, ou un vecteur de largeurs dont chaque
% élément est une voie.
function n = compterParties(v)
    if ischar(v) || isstring(v)
        valeur = str2num(char(v)); %#ok<ST2NM>
        if isempty(valeur)
            n = NaN;
            return
        end
        v = valeur;
    end
    v = double(v);
    if isscalar(v)
        n = v;
    else
        n = numel(v);
    end
end

function [nEntrees, nSorties] = bornesSousSysteme(p)
    nEntrees = 0;
    nSorties = 0;
    modele = [];
    if isfield(p, 'Model'), modele = p.Model;
    elseif isfield(p, 'Modele'), modele = p.Modele;
    end
    if isempty(modele)
        return
    end
    try
        modele = matlibre_sl_modele(modele);
    catch
        nEntrees = NaN;
        nSorties = NaN;
        return
    end
    for k = 1:numel(modele.blocs)
        switch typeCanonique(modele.blocs{k}.type)
            case {'inport', 'enableport', 'triggerport', 'actionport'}
                % Les ports de contrôle viennent après les entrées : Enable,
                % puis Trigger ; ou Action Port.
                nEntrees = nEntrees + 1;
            case 'outport'
                nSorties = nSorties + 1;
        end
    end
end

% Un bloc intérieur peut avoir été posé sous son nom Simulink (« In1 ») :
% le catalogue le ramène au nom de MatLibre. Un type inconnu ne compte ni
% comme entrée ni comme sortie ; la compilation le refusera en le nommant.
function t = typeCanonique(type)
    try
        entree = matlibre_sl_catalogue('type', type);
        t = entree.type;
    catch
        t = lower(char(type));
    end
end
