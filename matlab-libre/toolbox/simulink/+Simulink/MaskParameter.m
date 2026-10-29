classdef MaskParameter < handle
%MASKPARAMETER Un paramètre du masque d'un bloc.
%   Les paramètres d'un SIMULINK.MASK — sa propriété Parameters,
%   ADDPARAMETER, GETPARAMETER — se lisent et se règlent ici, sur le bloc
%   lui-même : Name, Prompt, Type ('edit', 'checkbox', 'popup',
%   'radiobutton', 'combobox'), TypeOptions (les choix d'un menu), Value,
%   Evaluate ('on' : la valeur s'évalue ; une case vaut alors 1 ou 0, un
%   menu le rang de son choix), Tunable, Visible, Enabled, Callback.
%   Name ne se change pas.
%
%   Exemple :
%      new_system('parametre');
%      add_block('simulink/Ports & Subsystems/Subsystem', 'parametre/s');
%      m = Simulink.Mask.create('parametre/s');
%      p = m.addParameter('Name', 'mode', 'Type', 'popup', ...
%                         'TypeOptions', {'lent', 'rapide'});
%      p.Value = 'rapide';
%      get_param('parametre/s', 'mode')         % 'rapide'
%      bdclose('parametre');
%
%   Voir aussi SIMULINK.MASK.
    properties (SetAccess = private)
        Name = ''
        BlockHandle = -1
    end
    properties (Dependent)
        Prompt
        Type
        TypeOptions
        Value
        Evaluate
        Tunable
        Visible
        Enabled
        Callback
    end
    methods
        function p = MaskParameter(h, nom)
            if nargin > 0
                p.BlockHandle = h;
                p.Name = nom;
            end
        end
        function v = get.Prompt(p)
            v = lire(p, 'Prompt');
        end
        function set.Prompt(p, v)
            poser(p, 'Prompt', v);
        end
        function v = get.Type(p)
            v = lire(p, 'Type');
        end
        function set.Type(p, v)
            poser(p, 'Type', v);
        end
        function v = get.TypeOptions(p)
            v = lire(p, 'TypeOptions');
        end
        function set.TypeOptions(p, v)
            poser(p, 'TypeOptions', v);
        end
        function v = get.Value(p)
            v = lire(p, 'Value');
        end
        function set.Value(p, v)
            if isnumeric(v) || islogical(v)
                v = mat2str(double(v), 17);
            end
            % la valeur se pose comme SET_PARAM la poserait : vérifiée
            set_param(getfullname(p.BlockHandle), p.Name, char(v));
        end
        function v = get.Evaluate(p)
            v = lire(p, 'Evaluate');
        end
        function set.Evaluate(p, v)
            poser(p, 'Evaluate', v);
        end
        function v = get.Tunable(p)
            v = lire(p, 'Tunable');
        end
        function set.Tunable(p, v)
            poser(p, 'Tunable', v);
        end
        function v = get.Visible(p)
            v = lire(p, 'Visible');
        end
        function set.Visible(p, v)
            poser(p, 'Visible', v);
        end
        function v = get.Enabled(p)
            v = lire(p, 'Enabled');
        end
        function set.Enabled(p, v)
            poser(p, 'Enabled', v);
        end
        function v = get.Callback(p)
            v = lire(p, 'Callback');
        end
        function set.Callback(p, v)
            poser(p, 'Callback', v);
        end
        function disp(p)
            fprintf('  Simulink.MaskParameter ''%s'' (%s) = ''%s''\n\n', p.Name, p.Type, p.Value);
        end
    end
end

function [S, k] = parametresDe(p)
    chemin = getfullname(p.BlockHandle);
    S = matlibre_sl_masque('parametres', matlibre_sl_memoire('bloc', chemin));
    k = find(strcmp({S.Name}, p.Name), 1);
    if isempty(k)
        error('Simulink:Masking:ParameterNotFound', ...
              'Le masque de ''%s'' n''a plus de parametre nomme ''%s''.', chemin, p.Name);
    end
end

function v = lire(p, champ)
    [S, k] = parametresDe(p);
    v = S(k).(champ);
end

function poser(p, champ, v)
    [S, k] = parametresDe(p);
    if isstring(v)
        if isscalar(v) && ~strcmp(champ, 'TypeOptions')
            v = char(v);
        else
            v = cellstr(v);
        end
    end
    if strcmp(champ, 'TypeOptions')
        if ~iscell(v) || isempty(v)
            error('Simulink:Masking:InvalidPropertyValue', ...
                  'Les TypeOptions d''un parametre de masque sont une cellule de textes.');
        end
        v = cellfun(@char, v(:).', 'UniformOutput', false);
    elseif ~ischar(v)
        error('Simulink:Masking:InvalidPropertyValue', ...
              'La propriete %s d''un parametre de masque est un texte.', champ);
    end
    switch champ
        case 'Type'
            v = lower(v);
            if ~any(strcmp(v, {'edit', 'checkbox', 'popup', 'radiobutton', 'combobox'}))
                error('Simulink:Masking:InvalidParameterType', ...
                      ['Le genre d''un parametre de masque est ''edit'', ''checkbox'', ' ...
                       '''popup'', ''radiobutton'' ou ''combobox'' ; pas ''%s''.'], v);
            end
        case {'Evaluate', 'Tunable', 'Visible', 'Enabled'}
            if ~any(strcmpi(v, {'on', 'off'}))
                error('Simulink:Masking:InvalidPropertyValue', ...
                      'La propriete %s d''un parametre de masque vaut ''on'' ou ''off''.', champ);
            end
            v = lower(v);
    end
    S(k).(champ) = v;
    matlibre_sl_masque('modifier', getfullname(p.BlockHandle), ...
                       @(b) matlibre_sl_masque('ecrire', b, S));
end
