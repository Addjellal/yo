classdef idpoly
%IDPOLY Modèle polynomial à temps discret.
%   M = IDPOLY(A,B,C,D,F,NOISEVARIANCE,TS) décrit le modèle
%
%      A(q) y(t) = [B(q)/F(q)] u(t) + [C(q)/D(q)] e(t)
%
%   où q est l'opérateur de décalage et e un bruit blanc. Les familles
%   usuelles en sont des cas particuliers : ARX quand C, D et F valent un,
%   ARMAX quand D et F valent un, sortie-erreur quand A, C et D valent un,
%   Box-Jenkins quand A vaut un.
%
%   M = IDPOLY(A) décrit un modèle autorégressif, sans entrée.
%
%   Le retard se lit dans les zéros de tête de B : un modèle dont l'entrée
%   agit au bout de deux périodes a B qui commence par deux zéros.
%
%   Propriétés : A, B, C, D, F, Ts, NoiseVariance, Report,
%   ParameterVector, CovarianceMatrix.
%
%   Ce qu'on lui demande : POLYDATA rend ses polynômes, TFDATA sa fonction
%   de transfert, SIM le simule, PREDICT le prédit, COMPARE le confronte
%   aux mesures, RESID examine ses résidus, FORECAST le prolonge.
%
%   Exemple :
%      m = idpoly([1 -0.8], [0 0.2], 1, 1, 1, 0.01, 0.1);
%      z = sim(m, iddata([], sign(sin((0:0.1:20)')), 0.1));
%
%   Voir aussi ARX, ARMAX, OE, BJ, POLYEST, IDSS, IDTF, IDDATA.
    properties
        A = 1
        B = []
        C = 1
        D = 1
        F = 1
        Ts = 1
        NoiseVariance = 0
        Report = []
        ParameterVector = []
        CovarianceMatrix = []
        Name = ''
        InputName = {}
        OutputName = {}
        Ordres = []
    end
    methods
        function obj = idpoly(A, B, C, D, F, variance, Ts)
            if nargin == 0
                return
            end
            if isa(A, 'idpoly')
                obj = A;
                return
            end
            obj.A = matlibre_id_polynome(A);
            if nargin > 1, obj.B = matlibre_id_polynome(B); end
            if nargin > 2 && ~isempty(C), obj.C = matlibre_id_polynome(C); end
            if nargin > 3 && ~isempty(D), obj.D = matlibre_id_polynome(D); end
            if nargin > 4 && ~isempty(F), obj.F = matlibre_id_polynome(F); end
            if nargin > 5 && ~isempty(variance), obj.NoiseVariance = variance; end
            if nargin > 6 && ~isempty(Ts), obj.Ts = Ts; end
        end

        function [a, b, c, d, f] = polydata(obj)
        %POLYDATA Les cinq polynômes du modèle.
            a = obj.A;
            b = obj.B;
            c = obj.C;
            d = obj.D;
            f = obj.F;
        end

        function [numerateur, denominateur, periode] = tfdata(obj, varargin)
        %TFDATA Fonction de transfert de l'entrée vers la sortie.
        %   [NUM,DEN] = TFDATA(M) rend B et le produit de A par F : c'est
        %   la part déterministe du modèle, celle qui relie l'entrée à la
        %   sortie sans le bruit.
            numerateur = obj.B;
            denominateur = conv(obj.A, obj.F);
            periode = obj.Ts;
            if ~isempty(varargin) && any(strcmpi(varargin, 'v'))
                return
            end
            numerateur = {numerateur};
            denominateur = {denominateur};
        end

        function p = getpvec(obj)
        %GETPVEC Les paramètres du modèle, à la file.
            p = matlibre_id_parametres(obj);
        end
        function obj = setpvec(obj, p)
        %SETPVEC Remplace les paramètres du modèle.
            obj = matlibre_id_poser_parametres(obj, p);
        end

        function sortie = sim(obj, entree, varargin)
        %SIM Simule la réponse du modèle.
            sortie = matlibre_id_simuler(obj, entree, varargin);
        end
        function sortie = predict(obj, donnees, horizon)
        %PREDICT Prédiction à un pas, ou à K pas.
            if nargin < 3
                horizon = 1;
            end
            sortie = matlibre_id_predire(obj, donnees, horizon);
        end
        function sortie = forecast(obj, donnees, horizon)
        %FORECAST Prolonge les données au-delà de leur fin.
            sortie = matlibre_id_prolonger(obj, donnees, horizon);
        end
        function varargout = compare(obj, donnees, varargin)
        %COMPARE Confronte le modèle aux mesures.
            [varargout{1:max(nargout, 1)}] = matlibre_id_comparer(obj, donnees, varargin);
        end
        function varargout = resid(obj, donnees, varargin)
        %RESID Examine les résidus du modèle.
            [varargout{1:max(nargout, 1)}] = matlibre_id_residus(obj, donnees, varargin);
        end

        function systeme = tf(obj)
        %TF Fonction de transfert, comme objet de l'automatique.
            [numerateur, denominateur] = tfdata(obj, 'v');
            systeme = tf(numerateur, denominateur, obj.Ts);
        end

        function disp(obj)
            fprintf('  Modèle polynomial à temps discret, Ts = %g\n', obj.Ts);
            fprintf('    A(q) = %s\n', matlibre_id_ecrire_polynome(obj.A));
            if ~isempty(obj.B)
                fprintf('    B(q) = %s\n', matlibre_id_ecrire_polynome(obj.B));
            end
            if numel(obj.C) > 1
                fprintf('    C(q) = %s\n', matlibre_id_ecrire_polynome(obj.C));
            end
            if numel(obj.D) > 1
                fprintf('    D(q) = %s\n', matlibre_id_ecrire_polynome(obj.D));
            end
            if numel(obj.F) > 1
                fprintf('    F(q) = %s\n', matlibre_id_ecrire_polynome(obj.F));
            end
            if obj.NoiseVariance > 0
                fprintf('    variance du bruit : %g\n', obj.NoiseVariance);
            end
        end
    end
end
