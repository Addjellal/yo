classdef idtf
%IDTF Fonction de transfert estimée.
%   M = IDTF(NUM,DEN) décrit la fonction de transfert de numérateur NUM et
%   de dénominateur DEN. M = IDTF(NUM,DEN,TS) la rend à temps discret ;
%   avec TS nul, elle est à temps continu.
%
%   C'est la forme la plus lisible d'un modèle linéaire : ses pôles et ses
%   zéros se lisent directement, et son gain statique aussi.
%
%   Propriétés : Numerator, Denominator, IODelay, Ts, NoiseVariance,
%   Report.
%
%   Exemple :
%      m = tfest(z, 2, 1);
%      [num, den] = tfdata(m, 'v');
%
%   Voir aussi TFEST, IDPOLY, IDSS, IDPROC.
    properties
        Numerator = 1
        Denominator = 1
        IODelay = 0
        Ts = 1
        NoiseVariance = 0
        Report = []
        Name = ''
    end
    methods
        function obj = idtf(numerateur, denominateur, periode)
            if nargin == 0
                return
            end
            if isa(numerateur, 'idtf')
                obj = numerateur;
                return
            end
            obj.Numerator = double(numerateur(:)).';
            if nargin > 1
                obj.Denominator = double(denominateur(:)).';
            end
            if nargin > 2
                obj.Ts = periode;
            end
        end

        function [numerateur, denominateur, periode] = tfdata(obj, varargin)
        %TFDATA Numérateur et dénominateur du modèle.
            numerateur = obj.Numerator;
            denominateur = obj.Denominator;
            periode = obj.Ts;
            if ~isempty(varargin) && any(strcmpi(varargin, 'v'))
                return
            end
            numerateur = {numerateur};
            denominateur = {denominateur};
        end

        function sortie = sim(obj, entree, varargin)
        %SIM Simule la réponse du modèle.
            sortie = matlibre_id_simuler_tf(obj, entree);
        end
        function sortie = predict(obj, donnees, horizon)
        %PREDICT Prédiction du modèle.
            if nargin < 3
                horizon = Inf;
            end
            sortie = matlibre_id_simuler_tf(obj, donnees);
        end
        function varargout = compare(obj, donnees, varargin)
        %COMPARE Confronte le modèle aux mesures.
            jeu = matlibre_id_experience(iddata(donnees), 1);
            prediction = matlibre_id_simuler_tf(obj, jeu);
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
            e = jeu.OutputData - matlibre_id_simuler_tf(obj, jeu).OutputData;
            [varargout{1:max(nargout, 1)}] = ...
                matlibre_id_residus_bruts(e, jeu.InputData, varargin, nargout);
        end
        function systeme = tf(obj)
        %TF Fonction de transfert, comme objet de l'automatique.
            systeme = tf(obj.Numerator, obj.Denominator, obj.Ts);
        end
        function disp(obj)
            if obj.Ts == 0
                fprintf('  Fonction de transfert continue estimée\n');
            else
                fprintf('  Fonction de transfert discrète estimée, Ts = %g\n', obj.Ts);
            end
            fprintf('    numerateur   : %s\n', mat2str(obj.Numerator, 5));
            fprintf('    denominateur : %s\n', mat2str(obj.Denominator, 5));
            if obj.IODelay ~= 0
                fprintf('    retard : %g\n', obj.IODelay);
            end
        end
    end
end
