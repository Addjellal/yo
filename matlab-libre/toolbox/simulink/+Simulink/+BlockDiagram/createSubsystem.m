function createSubsystem(blocs, varargin)
%SIMULINK.BLOCKDIAGRAM.CREATESUBSYSTEM Range des blocs dans un sous-système neuf.
%   SIMULINK.BLOCKDIAGRAM.CREATESUBSYSTEM(BLOCS) crée un sous-système et y
%   déplace les blocs BLOCS — leurs poignées, que rend SIMULINK.FINDBLOCKS
%   ou GET_PARAM(...,'Handle'), ou leurs chemins. Ils sont tous du même
%   système d'un modèle de la session, et le sous-système prend leur place
%   dans ce système. Il s'appelle 'Subsystem', ou 'Subsystem1'... si le
%   nom est pris.
%
%   Les liens se rebranchent comme dans Simulink. Un signal qui entre
%   dans le groupe devient une entrée du sous-système — une seule par
%   signal, quel que soit le nombre de blocs qu'il alimente dedans —, un
%   signal qui en sort, une sortie. Un port resté libre reçoit, dedans,
%   son Inport ou son Outport. Un bloc Inport ou Outport du groupe part
%   dans le sous-système, et un bloc de même nom et de même rang (Port)
%   le remplace dans le système, branché sur le port qui lui répond.
%   Entrées et sorties se numérotent dans l'ordre des blocs du groupe.
%
%   SIMULINK.BLOCKDIAGRAM.CREATESUBSYSTEM(BLOCS,'Name',NOM) nomme le
%   sous-système ; si NOM est pris, 'MakeNameUnique' 'on' — le défaut —
%   prend le rang libre suivant ('Controller1'), 'off' refuse.
%
%   Ne partent pas : les ports de contrôle — Enable, Trigger, Action Port,
%   Reset, For Each, les itérateurs —, et un bloc relié au dehors par une
%   connexion physique. Les poignées des blocs déplacés désignaient leur
%   ancien chemin : on les redemande. SIMULINK.BLOCKDIAGRAM.CREATESUBSYSTEM()
%   regroupe dans Simulink la sélection de l'éditeur ; il n'y en a pas ici.
%
%   Exemple :
%      bdclose('all');
%      new_system('essai');
%      add_block('built-in/Inport', 'essai/u');
%      add_block('built-in/Gain', 'essai/g', 'Gain', '3');
%      add_block('built-in/Outport', 'essai/y');
%      add_line('essai', {'u/1', 'g/1'}, {'g/1', 'y/1'});
%      Simulink.BlockDiagram.createSubsystem(Simulink.findBlocks('essai'), 'Name', 'tout');
%      find_system('essai', 'SearchDepth', 1)   % essai, tout, u, y
%      bdclose('all');
%
%   Voir aussi SIMULINK.BLOCKDIAGRAM.EXPANDSUBSYSTEM, SIMULINK.FINDBLOCKS,
%   SIMULINK.SUBSYSTEM.DELETECONTENTS.
    if nargin == 0
        error('Simulink:BlockDiagram:CreateSubsystemNoSelection', ...
              ['Simulink.BlockDiagram.createSubsystem() groups the editor selection ' ...
               'of Simulink, which does not exist here: pass the block handles, ' ...
               'Simulink.BlockDiagram.createSubsystem(Simulink.findBlocks(...)).']);
    end
    nom = '';
    unique = true;
    nomDonne = false;
    if mod(numel(varargin), 2) ~= 0
        error('Simulink:BlockDiagram:CreateSubsystemArguments', ...
              'createSubsystem options must be name-value pairs.');
    end
    for k = 1:2:numel(varargin)
        option = char(varargin{k});
        v = varargin{k + 1};
        switch lower(option)
            case 'name'
                if ~((ischar(v) && (isrow(v) || isempty(v))) || (isstring(v) && isscalar(v)))
                    error('Simulink:BlockDiagram:CreateSubsystemInvalidName', ...
                          'The subsystem name must be text.');
                end
                nom = char(v);
                nomDonne = true;
                if isempty(nom)
                    error('Simulink:BlockDiagram:CreateSubsystemInvalidName', ...
                          'The subsystem name must be nonempty text.');
                end
            case 'makenameunique'
                if ~((ischar(v) || (isstring(v) && isscalar(v))) && ...
                     any(strcmpi(char(v), {'on', 'off'})))
                    error('Simulink:BlockDiagram:CreateSubsystemArguments', ...
                          'MakeNameUnique must be ''on'' or ''off''.');
                end
                unique = strcmpi(char(v), 'on');
            otherwise
                error('Simulink:BlockDiagram:CreateSubsystemArguments', ...
                      ['createSubsystem has no option ''%s''. Valid options are Name and ' ...
                       'MakeNameUnique.'], option);
        end
    end
    if ~unique && ~nomDonne
        error('Simulink:BlockDiagram:CreateSubsystemArguments', ...
              'MakeNameUnique is only valid with Name.');
    end
    if isnumeric(blocs)
        blocs = num2cell(blocs(:).');
    elseif ischar(blocs)
        blocs = {blocs};
    elseif isstring(blocs)
        blocs = cellstr(blocs);
    end
    if ~iscell(blocs) || isempty(blocs)
        error('Simulink:BlockDiagram:CreateSubsystemNoBlocks', ...
              'createSubsystem requires at least one block, given by its handle or path.');
    end
    racine = '';
    parent = '';
    feuilles = cell(1, numel(blocs));
    for k = 1:numel(blocs)
        [r, chemin, genre] = matlibre_sl_nomme('systeme', blocs{k});
        if ~strcmp(genre, 'bloc') || isempty(chemin)
            error('Simulink:BlockDiagram:CreateSubsystemNoBlocks', ...
                  'createSubsystem groups blocks, not models, ports, or lines.');
        end
        barre = find(chemin == '/', 1, 'last');
        if isempty(barre)
            p = '';
            feuilles{k} = chemin;
        else
            p = chemin(1:barre - 1);
            feuilles{k} = chemin(barre + 1:end);
        end
        if k == 1
            racine = r;
            parent = p;
        elseif ~strcmp(r, racine)
            error('Simulink:BlockDiagram:CreateSubsystemDifferentModels', ...
                  ['The blocks to group must belong to the same model: ''%s'' is in ''%s'', ' ...
                   'the first one in ''%s''.'], getfullname(blocs{k}), r, racine);
        elseif ~strcmp(p, parent)
            error('Simulink:BlockDiagram:CreateSubsystemDifferentParents', ...
                  ['The blocks to group must belong to the same system: ''%s'' is not in ' ...
                   'the system of the first one.'], getfullname(blocs{k}));
        end
    end
    ctx = matlibre_sl_restructurer('ouvrir', racine, parent);
    ou = racine;
    if ~isempty(parent)
        ou = [racine '/' parent];
    end
    systeme = matlibre_sl_restructurer('regrouper', ctx.systeme, unique_(feuilles), nom, ...
                                       unique, ou);
    matlibre_sl_restructurer('fermer', ctx, systeme);
end

% chaque bloc une fois, dans l'ordre où on les donne
function noms = unique_(noms)
    garde = true(size(noms));
    for k = 2:numel(noms)
        garde(k) = ~any(strcmp(noms(1:k - 1), noms{k}));
    end
    noms = noms(garde);
end
