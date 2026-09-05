classdef idss
%IDSS Modèle d'état estimé.
%   M = IDSS(A,B,C,D) décrit x(t+1) = A x(t) + B u(t), y(t) = C x(t) + D u(t).
%   M = IDSS(A,B,C,D,K,X0,TS) ajoute le gain de Kalman, l'état initial et
%   la période d'échantillonnage.
%
%   La forme d'état dit la même chose qu'un modèle polynomial, mais elle
%   la dit avec un seul entier : l'ordre. C'est ce qui la rend commode
%   quand on ne sait pas d'avance combien de retards il faut, et c'est la
%   forme que rendent les méthodes par sous-espaces.
%
%   Propriétés : A, B, C, D, K, x0, Ts, NoiseVariance, Report.
%
%   Ce qu'on lui demande : SSDATA rend ses matrices, SIM le simule,
%   PREDICT le prédit, COMPARE le confronte aux mesures, RESID examine ses
%   résidus.
%
%   Exemple :
%      m = n4sid(z, 2);
%      [A, B, C, D] = ssdata(m);
%
%   Voir aussi N4SID, SSEST, IDPOLY, IDTF, IDDATA.
    properties
        A = []
        B = []
        C = []
        D = []
        K = []
        x0 = []
        Ts = 1
        NoiseVariance = 0
        Report = []
        Name = ''
    end
    methods
        function obj = idss(A, B, C, D, K, x0, Ts)
            if nargin == 0
                return
            end
            if isa(A, 'idss')
                obj = A;
                return
            end
            obj.A = double(A);
            if nargin > 1, obj.B = double(B); end
            if nargin > 2, obj.C = double(C); end
            if nargin > 3, obj.D = double(D); end
            if nargin > 4 && ~isempty(K), obj.K = double(K); end
            if nargin > 5 && ~isempty(x0), obj.x0 = double(x0(:)); end
            if nargin > 6 && ~isempty(Ts), obj.Ts = Ts; end
            if isempty(obj.K)
                obj.K = zeros(size(obj.A, 1), size(obj.C, 1));
            end
            if isempty(obj.x0)
                obj.x0 = zeros(size(obj.A, 1), 1);
            end
        end

        function [A, B, C, D, K, x0, Ts] = ssdata(obj)
        %SSDATA Les matrices du modèle d'état.
            A = obj.A; B = obj.B; C = obj.C; D = obj.D;
            K = obj.K; x0 = obj.x0; Ts = obj.Ts;
        end

        function n = order(obj)
        %ORDER Ordre du modèle, c'est-à-dire sa dimension d'état.
            n = size(obj.A, 1);
        end

        function sortie = sim(obj, entree, varargin)
        %SIM Simule la réponse du modèle.
            sortie = matlibre_id_simuler_etat(obj, entree, varargin);
        end
        function sortie = predict(obj, donnees, horizon)
        %PREDICT Prédiction du modèle d'état.
            if nargin < 3
                horizon = 1;
            end
            sortie = matlibre_id_predire_etat(obj, donnees, horizon);
        end
        function varargout = compare(obj, donnees, varargin)
        %COMPARE Confronte le modèle aux mesures.
            [varargout{1:max(nargout, 1)}] = ...
                matlibre_id_comparer_etat(obj, donnees, varargin);
        end
        function varargout = resid(obj, donnees, varargin)
        %RESID Examine les résidus du modèle.
            jeu = matlibre_id_experience(iddata(donnees), 1);
            prediction = matlibre_id_predire_etat(obj, jeu, 1);
            e = jeu.OutputData - prediction.OutputData;
            [varargout{1:max(nargout, 1)}] = ...
                matlibre_id_residus_bruts(e, jeu.InputData, varargin, nargout);
        end
        function systeme = ss(obj)
        %SS Modèle d'état, comme objet de l'automatique.
            systeme = ss(obj.A, obj.B, obj.C, obj.D, obj.Ts);
        end
        function disp(obj)
            fprintf('  Modèle d''état à temps discret, ordre %d, Ts = %g\n', ...
                    order(obj), obj.Ts);
            if obj.NoiseVariance > 0
                fprintf('    variance du bruit : %g\n', obj.NoiseVariance);
            end
        end
    end
end
