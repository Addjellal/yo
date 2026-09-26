function varargout = matlibre_sl_bus(action, varargin)
%MATLIBRE_SL_BUS Les types de bus : lecture, forme, conformité.
%   NOM = MATLIBRE_SL_BUS('type',TEXTE) rend le nom du type d'un paramètre
%   OutDataTypeStr qui vaut 'Bus: NOM', ou '' pour tout autre type.
%
%   B = MATLIBRE_SL_BUS('objet',NOM,QUI) lit dans l'espace de travail de
%   base l'objet SIMULINK.BUS nommé NOM ; QUI, le bloc qui le demande,
%   est nommé dans l'erreur s'il manque ou n'est pas un type de bus.
%
%   F = MATLIBRE_SL_BUS('forme',B,QUI) rend la forme du bus de type B :
%   un élément par élément du type, avec son nom, ses dimensions, sa
%   largeur, sa place dans le vecteur qui les porte bout à bout, et, pour
%   un bus emboîté, sa propre forme.
%
%   MATLIBRE_SL_BUS('accorder',F,B,QUI,NOMTYPE) vérifie qu'un bus de forme
%   F est du type B : les mêmes éléments, sous les mêmes noms, dans le
%   même ordre, aux mêmes dimensions.
%
%   S = MATLIBRE_SL_BUS('structure',B) rend la structure qui a la forme du
%   bus, faite de zéros.
%
%   INFO = MATLIBRE_SL_BUS('creer',MODELE,BLOCS) crée les types des bus
%   que forment des Bus Creator : c'est SIMULINK.BUS.CREATEOBJECT.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_sl_bus('type', 'Bus: Capteurs')        % 'Capteurs'
%
%   Voir aussi SIMULINK.BUS, SIMULINK.BUSELEMENT, MATLIBRE_SL_COMPILER.
    switch action
        case 'type'
            varargout{1} = nomDuType(varargin{1});
        case 'objet'
            varargout{1} = lireObjet(varargin{:});
        case 'forme'
            varargout{1} = forme(varargin{1}, varargin{2}, 0);
        case 'accorder'
            accorder(varargin{:});
        case 'structure'
            varargout{1} = structure(varargin{1}, 0);
        case 'creer'
            varargout{1} = creer(varargin{:});
        otherwise
            error('Simulink:Bus:Action', 'Action inconnue : %s.', char(action));
    end
end

function nom = nomDuType(texte)
    nom = '';
    if ~(ischar(texte) || isstring(texte))
        return
    end
    jetons = regexp(char(texte), '^\s*Bus\s*:\s*([A-Za-z]\w*)\s*$', 'tokens', 'once');
    if ~isempty(jetons)
        nom = jetons{1};
    end
end

function objet = lireObjet(nom, qui)
    if nargin < 2
        qui = '';
    end
    existe = evalin('base', sprintf('exist(''%s'', ''var'')', nom));
    if existe ~= 1
        error('Simulink:Bus:BusObjectNotFound', ...
              ['%sle type de bus ''%s'' est introuvable : aucun objet Simulink.Bus ne ' ...
               'porte ce nom dans l''espace de travail de base.'], prefixe(qui), nom);
    end
    objet = evalin('base', nom);
    if ~isa(objet, 'Simulink.Bus')
        error('Simulink:Bus:NotABusObject', ...
              ['%s''%s'' est un %s, non un Simulink.Bus : le type d''un bus se definit ' ...
               'par Simulink.Bus et Simulink.BusElement.'], prefixe(qui), nom, class(objet));
    end
end

function t = prefixe(qui)
    t = '';
    if ~isempty(qui)
        t = sprintf('Le bloc ''%s'' : ', qui);
    end
end

% Les dimensions d'un élément, en [lignes colonnes] : 3 est un vecteur.
function d = dimensions(e, qui)
    d = double(e.Dimensions);
    if isscalar(d)
        d = [d 1];
    end
    if numel(d) ~= 2 || any(d < 1) || any(d ~= round(d))
        error('Simulink:Bus:InvalidElementDimensions', ...
              '%sl''element ''%s'' a des dimensions invalides : %s.', prefixe(qui), ...
              char(e.Name), mat2str(double(e.Dimensions)));
    end
end

function f = forme(objet, qui, profondeur)
    if profondeur > 32
        error('Simulink:Bus:BusRecursive', ...
              '%sun type de bus se contient lui-meme, directement ou non.', prefixe(qui));
    end
    f = struct('nom', {}, 'dims', {}, 'largeur', {}, 'debut', {}, 'sous', {});
    debut = 1;
    elements = objet.Elements;
    for j = 1:numel(elements)
        e = elements(j);
        sous = [];
        emboite = nomDuType(e.DataType);
        if ~isempty(emboite)
            sous = forme(lireObjet(emboite, qui), qui, profondeur + 1);
            d = [sum([sous.largeur]) 1];
        else
            d = dimensions(e, qui);
        end
        w = prod(d);
        f(end + 1) = struct('nom', char(e.Name), 'dims', d, 'largeur', w, 'debut', debut, ...
                            'sous', {sous}); %#ok<AGROW>
        debut = debut + w;
    end
end

% Un bus de forme F est-il du type B ? Les mêmes noms, dans le même ordre,
% aux mêmes largeurs ; un bus emboîté, du même type emboîté.
function accorder(f, objet, qui, nomType)
    attendue = forme(objet, qui, 0);
    if isempty(f)
        error('Simulink:Bus:SignalNotBus', ...
              ['Le bloc ''%s'' attend un bus de type ''%s'', mais son signal n''est pas un ' ...
               'bus.'], qui, nomType);
    end
    accorderFormes(f, attendue, qui, nomType, '');
end

function accorderFormes(f, attendue, qui, nomType, chemin)
    nomsVus = {f.nom};
    nomsAttendus = {attendue.nom};
    if ~isequal(nomsVus, nomsAttendus)
        error('Simulink:Bus:ElementNamesMismatch', ...
              ['Le bloc ''%s'' attend un bus de type ''%s''%s, d''elements %s ; le bus ' ...
               'qu''il recoit porte %s.'], qui, nomType, chemin, ...
              strjoin(nomsAttendus, ', '), strjoin(nomsVus, ', '));
    end
    for j = 1:numel(f)
        if f(j).largeur ~= attendue(j).largeur
            error('Simulink:Bus:ElementDimensionsMismatch', ...
                  ['Le bloc ''%s'' attend un bus de type ''%s'' : l''element ''%s%s'' y est ' ...
                   'de largeur %d, et il en recoit %d.'], qui, nomType, chemin, f(j).nom, ...
                  attendue(j).largeur, f(j).largeur);
        end
        if ~isempty(attendue(j).sous)
            if isempty(f(j).sous)
                error('Simulink:Bus:ElementNotBus', ...
                      ['Le bloc ''%s'' attend un bus de type ''%s'' : l''element ''%s%s'' ' ...
                       'y est un bus, et il recoit un signal.'], qui, nomType, chemin, f(j).nom);
            end
            accorderFormes(f(j).sous, attendue(j).sous, qui, nomType, ...
                           [chemin f(j).nom '.']);
        end
    end
end

function s = structure(objet, profondeur)
    if profondeur > 32
        error('Simulink:Bus:BusRecursive', 'Un type de bus se contient lui-meme.');
    end
    s = struct();
    elements = objet.Elements;
    for j = 1:numel(elements)
        e = elements(j);
        emboite = nomDuType(e.DataType);
        if ~isempty(emboite)
            s.(char(e.Name)) = structure(lireObjet(emboite, ''), profondeur + 1);
        else
            s.(char(e.Name)) = zeros(dimensions(e, ''));
        end
    end
end

% SIMULINK.BUS.CREATEOBJECT : un type par Bus Creator, et un par bus
% emboîté, nommés slBus1, slBus2... dans l'espace de travail de base.
function info = creer(modele, blocs)
    modele = matlibre_sl_modele(modele);
    if ischar(blocs) || isstring(blocs)
        blocs = {char(blocs)};
    end
    c = matlibre_sl_compiler(modele, struct('silencieux', true));
    info = struct('block', {}, 'busName', {});
    rang = 0;
    for q = 1:numel(blocs)
        nom = char(blocs{q});
        prefixeModele = [char(modele.nom) '/'];
        if strncmp(nom, prefixeModele, numel(prefixeModele))
            nom = nom(numel(prefixeModele) + 1:end);
        end
        k = find(strcmp(c.noms, nom), 1);
        if isempty(k) || ~strcmp(c.types{k}, 'buscreator')
            error('Simulink:Bus:CreateObjectNotBusCreator', ...
                  'Simulink.Bus.createObject attend un Bus Creator du modele ; ''%s'' n''en est pas un.', ...
                  char(blocs{q}));
        end
        [nomType, rang] = creerType(c, k, rang);
        info(end + 1) = struct('block', [prefixeModele nom], 'busName', nomType); %#ok<AGROW>
    end
end

function [nomType, rang] = creerType(c, k, rang)
    rang = rang + 1;
    nomType = sprintf('slBus%d', rang);
    noms = strtrim(strsplit(char(num2str(c.p{k}.Inputs)), ','));
    if numel(noms) ~= c.nIn(k) || ~isnan(str2double(noms{1}))
        noms = arrayfun(@(j) sprintf('signal%d', j), 1:c.nIn(k), 'UniformOutput', false);
    end
    elements = Simulink.BusElement.empty(0, 1);
    for j = 1:c.nIn(k)
        e = Simulink.BusElement;
        e.Name = noms{j};
        source = c.entrees{k}(j);
        if source > 0 && strcmp(c.types{c.proprio(source)}, 'buscreator')
            [emboite, rang] = creerType(c, c.proprio(source), rang);
            e.DataType = ['Bus: ' emboite];
        elseif source > 0
            d = c.dims{source};
            if d(2) == 1
                d = d(1);
            end
            e.Dimensions = d;
        end
        elements(j) = e;
    end
    objet = Simulink.Bus;
    objet.Elements = elements;
    assignin('base', nomType, objet);
end
