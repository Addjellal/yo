classdef fittype
%FITTYPE Modèle d'ajustement, nommé ou écrit à la main.
%   FT = FITTYPE('poly2') désigne un modèle de la bibliothèque. Les noms
%   sont ceux de MATLAB : 'poly1' à 'poly9', 'exp1', 'exp2', 'power1',
%   'power2', 'gauss1' à 'gauss8', 'sin1' à 'sin8', 'fourier1' à
%   'fourier8', 'rat' suivi de deux chiffres, 'weibull', et les
%   interpolants 'linearinterp', 'nearestinterp', 'pchipinterp',
%   'cubicinterp', 'splineinterp', 'smoothingspline'.
%
%   FT = FITTYPE('a*exp(b*x) + c') lit une expression : tout identifiant
%   qui n'est ni la variable indépendante, ni un paramètre imposé, ni le
%   nom d'une fonction connue, est un coefficient à ajuster. Les
%   coefficients sont rangés par ordre alphabétique, comme dans MATLAB.
%
%   FITTYPE(...,'independent',V) nomme la variable indépendante ('x' par
%   défaut), 'dependent' la variable expliquée, 'coefficients' impose la
%   liste des coefficients et leur ordre, 'problem' déclare des paramètres
%   qui seront donnés au moment de l'ajustement plutôt qu'ajustés.
%
%   Ce qu'on demande à un modèle : FORMULA, COEFFNAMES, NUMCOEFFS,
%   INDEPNAMES, DEPENDNAMES, PROBNAMES, ARGNAMES, NUMARGS, ISLINEAR, TYPE.
%   FEVAL l'évalue.
%
%   Exemple :
%      ft = fittype('a*x^2 + b');
%      coeffnames(ft)      % a, b
%      feval(ft, [2 1], 3)   % 19
%
%   Voir aussi FIT, FITOPTIONS, CFIT, SETOPTIONS.
    properties
        Type = 'custom'
        Formula = ''
        Coefficients = {}
        Independent = {'x'}
        Dependent = {'y'}
        Problem = {}
        Linear = false
        Categorie = 'custom'
        Evaluer = []
        Base = []
        Depart = []
        Lower = []
        Upper = []
        Options = []
    end
    methods
        function obj = fittype(expression, varargin)
            if nargin == 0
                return
            end
            if isa(expression, 'fittype')
                obj = expression;
                return
            end
            independante = 'x';
            dependante = 'y';
            coefficients = {};
            probleme = {};
            for k = 1:2:numel(varargin) - 1
                switch lower(char(varargin{k}))
                    case 'independent',  independante = char(varargin{k + 1});
                    case 'dependent',    dependante = char(varargin{k + 1});
                    case 'coefficients', coefficients = matlibre_noms_modele(varargin{k + 1});
                    case 'problem',      probleme = matlibre_noms_modele(varargin{k + 1});
                    case 'options',      obj.Options = varargin{k + 1};
                    otherwise
                        error('curvefit:fittype:Option', ...
                              'Option inconnue : %s.', char(varargin{k}));
                end
            end
            obj.Independent = {independante};
            obj.Dependent = {dependante};
            obj.Problem = probleme;
            % Un « polyIJ » a deux chiffres : c'est un modele de surface,
            % et non le polynome de degre IJ que lirait la bibliotheque
            % des courbes.
            bibliotheque = matlibre_modele_surface(expression);
            if ~isempty(bibliotheque) && ~strcmp(bibliotheque.Categorie, 'interpolant')
                obj.Independent = {'x', 'y'};
                obj.Dependent = {'z'};
            else
                bibliotheque = matlibre_modele_bibliotheque(expression);
            end
            if ~isempty(bibliotheque) && isempty(coefficients)
                obj.Type = bibliotheque.Type;
                obj.Formula = bibliotheque.Formula;
                obj.Coefficients = bibliotheque.Coefficients;
                obj.Linear = bibliotheque.Linear;
                obj.Categorie = bibliotheque.Categorie;
                obj.Evaluer = bibliotheque.Evaluer;
                obj.Base = bibliotheque.Base;
                obj.Depart = bibliotheque.Depart;
                obj.Lower = bibliotheque.Lower;
                obj.Upper = bibliotheque.Upper;
                return
            end
            obj.Formula = strtrim(char(expression));
            obj.Type = 'custom';
            obj.Categorie = 'custom';
            if isempty(coefficients)
                coefficients = matlibre_coefficients_expression(obj.Formula, ...
                                                                independante, probleme);
            end
            obj.Coefficients = coefficients;
            obj.Evaluer = matlibre_fonction_expression(obj.Formula, coefficients, ...
                                                       probleme, independante);
            obj.Linear = matlibre_expression_lineaire(obj.Formula, coefficients, ...
                                                      independante);
            if obj.Linear
                obj.Base = matlibre_base_expression(obj.Formula, coefficients, ...
                                                    probleme, independante);
            end
        end

        function t = formula(obj), t = obj.Formula; end
        function c = coeffnames(obj), c = obj.Coefficients(:); end
        function n = numcoeffs(obj), n = numel(obj.Coefficients); end
        function c = indepnames(obj), c = obj.Independent(:); end
        function c = dependnames(obj), c = obj.Dependent(:); end
        function c = probnames(obj), c = obj.Problem(:); end
        function c = argnames(obj)
            c = [obj.Coefficients(:); obj.Problem(:); obj.Independent(:)];
        end
        function n = numargs(obj), n = numel(argnames(obj)); end
        function v = islinear(obj), v = obj.Linear; end
        function t = type(obj), t = obj.Type; end
        function obj = setoptions(obj, options)
        %SETOPTIONS Attache des réglages d'ajustement au modèle.
            obj.Options = options;
        end
        function y = feval(obj, varargin)
        %FEVAL Évalue le modèle.
        %   Y = FEVAL(FT,COEFFS,X) évalue le modèle pour ces coefficients.
        %   Les paramètres imposés se placent entre les coefficients et
        %   la variable indépendante.
            y = matlibre_evaluer_modele(obj, varargin);
        end
        function disp(obj)
            fprintf('     Modèle d''ajustement « %s » :\n', obj.Type);
            fprintf('       %s(%s) = %s\n', obj.Dependent{1}, obj.Independent{1}, obj.Formula);
            if ~isempty(obj.Coefficients)
                fprintf('     Coefficients : %s\n', strjoin(obj.Coefficients, ', '));
            end
            if ~isempty(obj.Problem)
                fprintf('     Paramètres imposés : %s\n', strjoin(obj.Problem, ', '));
            end
        end
    end
end
