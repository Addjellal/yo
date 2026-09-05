classdef idproc
%IDPROC Modèle de procédé, décrit par ses constantes de temps.
%   M = IDPROC(TYPE) crée un modèle de la forme
%
%      G(s) = K (1 + Tz s) / [(1 + Tp1 s)(1 + Tp2 s)] exp(-Td s)
%
%   où le TYPE dit ce qui est présent : 'P1' pour un seul pôle, 'P2' pour
%   deux, 'P0' pour aucun, la lettre 'D' pour un retard, 'Z' pour un zéro,
%   'I' pour un intégrateur. Ainsi 'P1D' est un premier ordre retardé, et
%   'P2ZD' un second ordre à zéro et retard.
%
%   C'est la description qu'emploie l'automaticien : quatre nombres qui se
%   lisent sur une réponse indicielle — un gain, une ou deux constantes de
%   temps, un retard — plutôt que des coefficients de polynômes sans
%   signification physique.
%
%   Propriétés : Type, K, Tp1, Tp2, Tz, Td, Ts, NoiseVariance, Report.
%
%   Exemple :
%      m = procest(z, 'P1D');
%      m.K, m.Tp1, m.Td
%
%   Voir aussi PROCEST, IDTF, TFEST.
    properties
        Type = 'P1'
        K = 1
        Tp1 = 1
        Tp2 = 0
        Tp3 = 0
        Tz = 0
        Td = 0
        Ts = 0
        NoiseVariance = 0
        Report = []
        Name = ''
    end
    methods
        function obj = idproc(type, varargin)
            if nargin == 0
                return
            end
            if isa(type, 'idproc')
                obj = type;
                return
            end
            obj.Type = upper(char(type));
            for k = 1:2:numel(varargin) - 1
                obj.(char(varargin{k})) = varargin{k + 1};
            end
        end

        function [numerateur, denominateur] = tfdata(obj, varargin)
        %TFDATA Numérateur et dénominateur du modèle continu.
            [numerateur, denominateur] = matlibre_id_proc_polynomes(obj);
            if isempty(varargin) || ~any(strcmpi(varargin, 'v'))
                numerateur = {numerateur};
                denominateur = {denominateur};
            end
        end

        function sortie = sim(obj, entree, varargin)
        %SIM Simule la réponse du modèle.
            sortie = matlibre_id_simuler_proc(obj, entree);
        end
        function sortie = predict(obj, donnees, horizon)
        %PREDICT Prédiction du modèle, qui est sa simulation.
            sortie = matlibre_id_simuler_proc(obj, donnees);
        end
        function varargout = compare(obj, donnees, varargin)
        %COMPARE Confronte le modèle aux mesures.
            jeu = matlibre_id_experience(iddata(donnees), 1);
            prediction = matlibre_id_simuler_proc(obj, jeu);
            ajustement = compareFit(jeu.OutputData, prediction.OutputData);
            if nargout == 0
                matlibre_id_tracer_comparaison(jeu, prediction, ajustement);
                varargout = {};
                return
            end
            varargout = {prediction, ajustement};
            varargout = varargout(1:min(max(nargout, 1), 2));
        end
        function varargout = resid(obj, donnees, varargin)
        %RESID Examine les résidus du modèle.
            jeu = matlibre_id_experience(iddata(donnees), 1);
            e = jeu.OutputData - matlibre_id_simuler_proc(obj, jeu).OutputData;
            [varargout{1:max(nargout, 1)}] = ...
                matlibre_id_residus_bruts(e, jeu.InputData, varargin, nargout);
        end
        function disp(obj)
            fprintf('  Modèle de procédé « %s »\n', obj.Type);
            fprintf('    K   = %g\n', obj.K);
            if obj.Tp1 ~= 0, fprintf('    Tp1 = %g\n', obj.Tp1); end
            if obj.Tp2 ~= 0, fprintf('    Tp2 = %g\n', obj.Tp2); end
            if obj.Tz ~= 0,  fprintf('    Tz  = %g\n', obj.Tz); end
            if obj.Td ~= 0,  fprintf('    Td  = %g\n', obj.Td); end
        end
    end
end
