classdef ModelWorkspace < handle
%MODELWORKSPACE L'espace de travail propre à un modèle.
%   HWS = GET_PARAM(MODELE,'ModelWorkspace') rend l'espace de travail du
%   modèle : les variables qu'on y pose valent pour ses blocs avant
%   celles de l'espace de travail de base. Un gain réglé sur 'K' lit le K
%   du modèle s'il en a un, sinon celui de base ; un masque le voit de
%   même.
%
%      ASSIGNIN(HWS,NOM,VALEUR)    pose une variable
%      V = GETVARIABLE(HWS,NOM)    la relit
%      HASVARIABLE(HWS,NOM)        dit si elle y est
%      EVALIN(HWS,CODE)            exécute du code dont les variables sont
%                                  celles de l'espace ; ce qu'il pose y reste
%      CLEAR(HWS), CLEAR(HWS,NOM,...)   retire tout, ou ces variables
%      S = WHOS(HWS)               les variables : name, size, class
%      RELOAD(HWS)                 si DataSource vaut 'MATLAB Code',
%                                  réexécute MATLABCode dans un espace vidé
%
%   L'espace suit le modèle par son nom le temps de la session :
%   NEW_SYSTEM et BDCLOSE le vident. SAVE_SYSTEM l'écrit dans le .m qui
%   rebâtit le modèle.
%
%   Exemple :
%      m = new_system('espace');
%      m = add_block(m, 'constant', 'c', 'Value', 'K');
%      m = add_line(add_block(m, 'outport', 'y'), 'c', 'y');
%      hws = get_param(m, 'ModelWorkspace');
%      assignin(hws, 'K', 42);
%      r = sim(m, 1);
%      r.yout(end)                        % 42
%
%   Voir aussi GET_PARAM, SIM, SIMULINK.SIMULATIONINPUT.
    properties
        DataSource = 'Model File'
        FileName = ''
        MATLABCode = ''
    end
    properties (SetAccess = private)
        ModelName = ''
    end
    properties (Hidden)
        Donnees = struct()
    end
    methods
        function obj = ModelWorkspace(nomModele)
            if nargin > 0
                obj.ModelName = char(nomModele);
            end
        end
        function set.DataSource(obj, v)
            obj.DataSource = matlibre_sl_parametre('choix', v, 'DataSource', ...
                {'Model File', 'MAT-File', 'MATLAB File', 'MATLAB Code'});
        end
        function set.MATLABCode(obj, v)
            obj.MATLABCode = matlibre_sl_parametre('texte', v, 'MATLABCode');
        end
        function assignin(obj, nom, valeur)
            nom = char(nom);
            if ~isvarname(nom)
                error('Simulink:Data:InvalidVariableName', ...
                      '''%s'' n''est pas un nom de variable.', nom);
            end
            obj.Donnees.(nom) = valeur;
        end
        function valeur = getVariable(obj, nom)
            nom = char(nom);
            if ~isfield(obj.Donnees, nom)
                error('Simulink:Data:VariableNotFound', ...
                      'L''espace de travail du modele ''%s'' n''a pas de variable ''%s''.', ...
                      obj.ModelName, nom);
            end
            valeur = obj.Donnees.(nom);
        end
        function oui = hasVariable(obj, nom)
            oui = isfield(obj.Donnees, char(nom));
        end
        function clear(obj, varargin)
            if isempty(varargin)
                obj.Donnees = struct();
                return
            end
            for k = 1:numel(varargin)
                nom = char(varargin{k});
                if isfield(obj.Donnees, nom)
                    obj.Donnees = rmfield(obj.Donnees, nom);
                end
            end
        end
        function s = whos(obj)
            noms = fieldnames(obj.Donnees);
            s = struct('name', {}, 'size', {}, 'class', {});
            for k = 1:numel(noms)
                v = obj.Donnees.(noms{k});
                s(end + 1) = struct('name', noms{k}, 'size', size(v), 'class', class(v)); %#ok<AGROW>
            end
        end
        function evalin(obj, code)
            obj.Donnees = matlibre_sl_espace('executer', obj.Donnees, char(code), ...
                                             obj.ModelName);
        end
        function reload(obj)
            if strcmp(obj.DataSource, 'MATLAB Code')
                obj.Donnees = matlibre_sl_espace('executer', struct(), obj.MATLABCode, ...
                                                 obj.ModelName);
            end
        end
        function disp(obj)
            fprintf('  Simulink.ModelWorkspace du modele ''%s'' : %d variable(s)\n', ...
                    obj.ModelName, numel(fieldnames(obj.Donnees)));
            noms = fieldnames(obj.Donnees);
            for k = 1:numel(noms)
                fprintf('    %s\n', noms{k});
            end
        end
    end
end
