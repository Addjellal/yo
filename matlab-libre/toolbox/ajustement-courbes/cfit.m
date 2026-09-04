classdef cfit
%CFIT Courbe ajustée, qu'on évalue comme une fonction.
%   FO = FIT(X,Y,MODELE) rend un objet CFIT. On l'évalue en l'appelant :
%   FO(XNOUVEAU). Il porte les coefficients trouvés, les résidus et de
%   quoi calculer les intervalles de confiance.
%
%   Ce qu'on lui demande :
%      COEFFVALUES   - la valeur des coefficients
%      CONFINT       - leur intervalle de confiance
%      PREDINT       - l'intervalle de confiance de la courbe, ou d'une
%                      observation à venir
%      DIFFERENTIATE - les dérivées première et seconde
%      INTEGRATE     - la primitive
%      PLOT          - le tracé, avec les points s'ils sont donnés
%      FORMULA, COEFFNAMES, PROBVALUES, TYPE, ISLINEAR, NUMCOEFFS
%
%   Exemple :
%      fo = fit((1:10)', (1:10)'.^2, 'poly2');
%      fo(3)              % 9
%      coeffvalues(fo)    % 1, 0, 0 a l'arrondi pres
%      confint(fo)
%
%   Voir aussi FIT, FITTYPE, SFIT, CONFINT, PREDINT.
    properties
        Modele = []
        Coefficients = []
        Imposees = {}
        Interpolant = []
        Normalisation = [0 1]
        Residus = []
        Jacobienne = []
        Poids = []
        DDL = 0
    end
    methods
        function obj = cfit(modele, coefficients, imposees, interpolant, ...
                            normalisation, residus, jacobienne, poids, ddl)
            if nargin == 0
                return
            end
            obj.Modele = modele;
            obj.Coefficients = double(coefficients(:)).';
            obj.Imposees = imposees;
            obj.Interpolant = interpolant;
            obj.Normalisation = normalisation;
            obj.Residus = residus;
            obj.Jacobienne = jacobienne;
            obj.Poids = poids;
            obj.DDL = ddl;
        end

        function varargout = subsref(obj, s)
            if strcmp(s(1).type, '()')
                valeur = feval(obj, s(1).subs{:});
                if numel(s) > 1
                    [varargout{1:nargout}] = subsref(valeur, s(2:end));
                else
                    varargout{1} = valeur;
                end
            else
                [varargout{1:nargout}] = builtin('subsref', obj, s);
            end
        end

        function y = feval(obj, x)
        %FEVAL Évalue la courbe ajustée.
            x = double(x);
            forme = size(x);
            xa = (x(:) - obj.Normalisation(1)) / obj.Normalisation(2);
            if ~isempty(obj.Interpolant)
                y = matlibre_evaluer_interpolant(obj.Interpolant, xa);
            else
                y = matlibre_evaluer_modele(obj.Modele, ...
                                            [{obj.Coefficients}, obj.Imposees, {xa}]);
            end
            y = reshape(y, forme);
        end

        function c = coeffvalues(obj)
        %COEFFVALUES Valeur des coefficients ajustés.
            c = obj.Coefficients;
        end
        function p = probvalues(obj)
        %PROBVALUES Valeur des paramètres imposés.
            p = obj.Imposees;
            if iscell(p) && ~isempty(p)
                p = cell2mat(p);
            end
        end
        function t = formula(obj), t = formula(obj.Modele); end
        function c = coeffnames(obj), c = coeffnames(obj.Modele); end
        function c = probnames(obj), c = probnames(obj.Modele); end
        function c = indepnames(obj), c = indepnames(obj.Modele); end
        function c = dependnames(obj), c = dependnames(obj.Modele); end
        function c = argnames(obj), c = argnames(obj.Modele); end
        function n = numargs(obj), n = numargs(obj.Modele); end
        function n = numcoeffs(obj), n = numel(obj.Coefficients); end
        function v = islinear(obj), v = islinear(obj.Modele); end
        function t = type(obj), t = type(obj.Modele); end
        function obj = setoptions(obj, options)
        %SETOPTIONS Attache des réglages au modèle sous-jacent.
            obj.Modele = setoptions(obj.Modele, options);
        end

        function bornes = confint(obj, niveau)
        %CONFINT Intervalle de confiance des coefficients.
        %   B = CONFINT(FO) rend, sur deux lignes, les bornes basse et
        %   haute à 95 %. CONFINT(FO,NIVEAU) change le niveau.
            if nargin < 2
                niveau = 0.95;
            end
            bornes = matlibre_intervalle_coefficients(obj, niveau);
        end

        function bornes = predint(obj, x, niveau, genre, simultane)
        %PREDINT Intervalle de confiance de la courbe ou d'une observation.
        %   B = PREDINT(FO,X) rend les bornes de la courbe ajustée.
        %   PREDINT(FO,X,NIVEAU,GENRE,SIMULTANE) où GENRE vaut
        %   'functional' — l'incertitude sur la courbe — ou 'observation'
        %   — celle d'un point à venir, qui ajoute le bruit de mesure —,
        %   et SIMULTANE vaut 'off' ou 'on'.
            if nargin < 3 || isempty(niveau), niveau = 0.95; end
            if nargin < 4 || isempty(genre), genre = 'functional'; end
            if nargin < 5 || isempty(simultane), simultane = 'off'; end
            bornes = matlibre_intervalle_prediction(obj, x, niveau, genre, simultane);
        end

        function [premiere, seconde] = differentiate(obj, x)
        %DIFFERENTIATE Dérivées première et seconde de la courbe ajustée.
            [premiere, seconde] = matlibre_deriver_ajustement(obj, x);
        end

        function valeur = integrate(obj, x, depart)
        %INTEGRATE Primitive de la courbe ajustée.
        %   V = INTEGRATE(FO,X,X0) rend l'intégrale de X0 à chaque X.
            if nargin < 3
                depart = 0;
            end
            valeur = matlibre_integrer_ajustement(obj, x, depart);
        end

        function h = plot(obj, varargin)
        %PLOT Trace la courbe ajustée, et les points s'ils sont donnés.
            h = matlibre_tracer_ajustement(obj, varargin);
        end

        function disp(obj)
            fprintf('     Modèle ajusté « %s » :\n', type(obj.Modele));
            fprintf('       %s\n', formula(obj.Modele));
            noms = coeffnames(obj.Modele);
            if ~isempty(noms) && ~isempty(obj.Coefficients)
                fprintf('     Coefficients :\n');
                for k = 1:numel(noms)
                    fprintf('       %-6s = %12.6g\n', noms{k}, obj.Coefficients(k));
                end
            end
        end
    end
end
