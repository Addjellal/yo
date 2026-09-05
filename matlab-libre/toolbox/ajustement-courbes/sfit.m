classdef sfit
%SFIT Surface ajustée, qu'on évalue comme une fonction de deux variables.
%   SO = FIT([X Y],Z,MODELE) rend un objet SFIT. On l'évalue en
%   l'appelant : SO(XNOUVEAU,YNOUVEAU).
%
%   Les modèles sont les polynômes à deux variables — 'poly11', 'poly22',
%   jusqu'à 'poly55' — et les interpolants 'linearinterp',
%   'nearestinterp', 'cubicinterp', 'lowess' et 'loess'.
%
%   Ce qu'on lui demande : COEFFVALUES, CONFINT, FORMULA, COEFFNAMES,
%   TYPE, ISLINEAR, NUMCOEFFS, PLOT.
%
%   Exemple :
%      [x, y] = meshgrid(0:0.25:1, 0:0.25:1);
%      z = 1 + 2*x - 3*y;
%      so = fit([x(:) y(:)], z(:), 'poly11');
%      so(0.5, 0.5)      % 0.5
%
%   Voir aussi FIT, CFIT, FITTYPE, PREPARESURFACEDATA.
    properties
        Modele = []
        Coefficients = []
        Imposees = {}
        Interpolant = []
        Residus = []
        Jacobienne = []
        Poids = []
        DDL = 0
    end
    methods
        function obj = sfit(modele, coefficients, imposees, interpolant, ...
                            residus, jacobienne, poids, ddl)
            if nargin == 0
                return
            end
            obj.Modele = modele;
            obj.Coefficients = double(coefficients(:)).';
            obj.Imposees = imposees;
            obj.Interpolant = interpolant;
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
                return
            end
            % Un coefficient se lit par son nom, comme dans MATLAB :
            % f.a rend le premier coefficient du modele. C'est la
            % notation qu'on emploie neuf fois sur dix apres un
            % ajustement, et elle prime sur les proprietes internes.
            if strcmp(s(1).type, '.') && ischar(s(1).subs)
                noms = coeffnames(obj);
                position = find(strcmp(noms, s(1).subs), 1);
                if ~isempty(position) && position <= numel(obj.Coefficients)
                    valeur = obj.Coefficients(position);
                    if numel(s) > 1
                        [varargout{1:nargout}] = subsref(valeur, s(2:end));
                    else
                        varargout{1} = valeur;
                    end
                    return
                end
            end
            [varargout{1:nargout}] = builtin('subsref', obj, s);
        end

        function z = feval(obj, x, y)
        %FEVAL Évalue la surface ajustée.
            if nargin < 3
                xy = double(x);
                if size(xy, 2) ~= 2
                    xy = reshape(xy, [], 2);
                end
                forme = [size(xy, 1), 1];
            else
                forme = size(x);
                xy = [double(x(:)), double(y(:))];
            end
            if ~isempty(obj.Interpolant)
                z = matlibre_evaluer_surface(obj.Interpolant, xy);
            else
                z = obj.Modele.Base(xy) * obj.Coefficients(:);
            end
            z = reshape(z, forme);
        end

        function c = coeffvalues(obj), c = obj.Coefficients; end
        function c = coeffnames(obj), c = coeffnames(obj.Modele); end
        function t = formula(obj), t = formula(obj.Modele); end
        function c = indepnames(obj), c = indepnames(obj.Modele); end
        function c = dependnames(obj), c = dependnames(obj.Modele); end
        function c = probnames(obj), c = probnames(obj.Modele); end
        function p = probvalues(obj), p = obj.Imposees; end
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
            if nargin < 2
                niveau = 0.95;
            end
            bornes = matlibre_intervalle_coefficients(obj, niveau);
        end

        function h = plot(obj, varargin)
        %PLOT Trace la surface ajustée.
            h = matlibre_tracer_surface(obj, varargin);
        end

        function disp(obj)
            fprintf('     Surface ajustée « %s » :\n', type(obj.Modele));
            fprintf('       %s\n', formula(obj.Modele));
            noms = coeffnames(obj.Modele);
            for k = 1:numel(noms)
                fprintf('       %-6s = %12.6g\n', noms{k}, obj.Coefficients(k));
            end
        end
    end
end
