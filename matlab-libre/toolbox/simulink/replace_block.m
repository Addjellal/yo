function varargout = replace_block(modele, ancien, nouveau, varargin)
%REPLACE_BLOCK Remplace les blocs d'un type par un autre type.
%   MODELE = REPLACE_BLOCK(MODELE,ANCIEN,NOUVEAU) change le type de tous
%   les blocs de type ANCIEN en NOUVEAU. Les noms et les liens sont
%   conservés, ainsi que les paramètres que le nouveau type porte aussi ;
%   les autres sont retirés, puisque plus personne ne les lirait. Les
%   types se désignent comme dans ADD_BLOCK : nom MatLibre, type Simulink
%   ou chemin de bibliothèque.
%   REPLACE_BLOCK(MODELE,ANCIEN,NOUVEAU,'Param',VALEUR,...) fixe en outre
%   des paramètres sur chaque bloc remplacé.
%
%   REMPLACES = REPLACE_BLOCK(SYSTEME,ANCIEN,NOUVEAU) est la forme de
%   Simulink, sur un modèle chargé : ANCIEN est un type de bloc ('Gain',
%   ou un chemin de la bibliothèque), ou des couples 'Param',VALEUR que
%   FIND_SYSTEM cherche ; NOUVEAU est 'built-in/Abs' ou un chemin de la
%   bibliothèque. Tout le modèle sous SYSTEME est parcouru ; REMPLACES
%   est la colonne des chemins des blocs remplacés. 'noprompt' à la fin
%   est accepté.
%
%   Le câblage ne bouge pas : c'est tout l'intérêt, remplacer un
%   intégrateur continu par son équivalent discret sans redessiner le
%   schéma.
%
%   Exemple :
%      m = new_system('essai');
%      m = add_block(m, 'integrator', 'i1');
%      m = add_block(m, 'integrator', 'i2');
%      m = replace_block(m, 'integrator', 'discreteintegrator', ...
%                        'SampleTime', 0.1);
%      get_param(m, 'i1', 'BlockType')          % 'discreteintegrator'
%      get_param(m, 'i2', 'SampleTime')         % 0.1
%
%   Voir aussi ADD_BLOCK, DELETE_BLOCK, SET_PARAM, FIND_SYSTEM.
    if ~isstruct(modele)
        args = varargin;
        if nargin >= 3
            args = [{nouveau}, args];
        end
        if nargin >= 2
            args = [{ancien}, args];
        end
        varargout{1} = remplacerParNom(modele, args);
        return
    end
    varargout{1} = remplacerTous(modele, ancien, nouveau, varargin{:});
end

function remplaces = remplacerParNom(systeme, args)
    if ~isempty(args) && (ischar(args{end}) || isstring(args{end})) && ...
       any(strcmpi(char(args{end}), {'noprompt', 'prompt'}))
        args(end) = [];
    end
    if numel(args) < 2
        error('Simulink:Commands:ReplaceBlockArguments', ...
              'REPLACE_BLOCK(SYSTEME, ANCIEN, NOUVEAU) : il faut l''ancien et le nouveau.');
    end
    nouveau = matlibre_sl_catalogue('type', sansBuiltIn(args{end}));
    criteres = args(1:end - 1);
    if numel(criteres) == 1
        ancien = matlibre_sl_catalogue('type', sansBuiltIn(criteres{1}));
        criteres = {'BlockType', ancien.simulink};
    elseif mod(numel(criteres), 2) ~= 0
        error('Simulink:Commands:ReplaceBlockArguments', ...
              'Les criteres de REPLACE_BLOCK vont par paires : un parametre, une valeur.');
    end
    cibles = find_system(systeme, 'LookUnderMasks', 'all', criteres{:});
    remplaces = {};
    for k = 1:numel(cibles)
        if ~strcmp(matlibre_sl_memoire('genre', cibles{k}), 'bloc')
            continue
        end
        [parent, feuille] = matlibre_sl_memoire('decouper', cibles{k});
        matlibre_sl_memoire('appliquer', parent, ...
                            @(s) remplacerUn(s, matlibre_sl_indice(s, feuille), nouveau, {}));
        remplaces{end + 1, 1} = cibles{k}; %#ok<AGROW>
    end
end

function t = sansBuiltIn(t)
    t = char(t);
    if strncmpi(t, 'built-in/', 9)
        t = t(10:end);
    end
end

function modele = remplacerTous(modele, ancien, nouveau, varargin)
    ancien = matlibre_sl_catalogue('type', ancien);
    nouveau = matlibre_sl_catalogue('type', nouveau);
    for i = 1:numel(modele.blocs)
        try
            actuel = matlibre_sl_catalogue('type', modele.blocs{i}.type);
        catch
            continue
        end
        if ~strcmp(actuel.type, ancien.type)
            continue
        end
        modele = remplacerUn(modele, i, nouveau, varargin);
    end
end

% Le bloc I prend le type NOUVEAU : il garde les paramètres que ce type
% porte aussi, et reçoit les REGLAGES.
function modele = remplacerUn(modele, i, nouveau, reglages)
    gardes = struct();
    anciens = fieldnames(modele.blocs{i}.parametres);
    for k = 1:numel(anciens)
        canon = matlibre_sl_catalogue('parametre', nouveau, anciens{k});
        if ~isempty(canon)
            gardes.(canon) = modele.blocs{i}.parametres.(anciens{k});
        end
    end
    for k = 1:2:numel(reglages) - 1
        canon = matlibre_sl_catalogue('parametre', nouveau, reglages{k});
        if isempty(canon)
            error('Simulink:Commands:ParamUnknown', ...
                  'Un bloc %s n''a pas de parametre nomme ''%s''.', nouveau.affiche, ...
                  char(reglages{k}));
        end
        gardes.(canon) = reglages{k + 1};
    end
    modele.blocs{i}.type = nouveau.type;
    modele.blocs{i}.parametres = gardes;
end
