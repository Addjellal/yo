classdef arima
%ARIMA Modèle autorégressif intégré à moyenne mobile.
%   MDL = ARIMA(P,D,Q) décrit un modèle dont la partie autorégressive a
%   P retards, la partie moyenne mobile Q retards, et dont la série est
%   différenciée D fois. Les coefficients valent NaN : ils restent à
%   estimer.
%
%   MDL = ARIMA('ARLags',L1,'MALags',L2,...) choisit les retards un à un,
%   ce qui permet un modèle creux — un retard 1 et un retard 12 sans les
%   dix intermédiaires. Les autres propriétés se donnent de même :
%   'Constant', 'AR', 'MA', 'D', 'Variance', 'Seasonality', 'SARLags',
%   'SAR', 'SMALags', 'SMA', 'Distribution', 'Description'.
%
%   Le modèle s'écrit, sur la série différenciée,
%      y(t) = c + phi(1) y(t-1) + ... + e(t) + theta(1) e(t-1) + ...
%   où e est un bruit blanc de variance Variance.
%
%   Un coefficient laissé à NaN est estimé ; un coefficient donné est
%   tenu pour connu et n'est pas touché. C'est ainsi qu'on impose une
%   contrainte : 'Constant',0 estime le reste sans constante.
%
%   ESTIMATE ajuste le modèle à des données, SIMULATE en tire des
%   trajectoires, FORECAST prolonge une série observée, INFER retrouve
%   les innovations et SUMMARIZE résume l'ajustement.
%
%   Exemple :
%      modele = arima(1, 0, 1);
%      vrai = arima('Constant', 0.5, 'AR', {0.7}, 'MA', {0.3}, 'Variance', 1);
%      y = simulate(vrai, 500);
%      ajuste = estimate(modele, y);
%
%   Voir aussi GARCH, ESTIMATE, SIMULATE, FORECAST, INFER, SUMMARIZE,
%   AICBIC, LBQTEST.
    properties
        Description = ''
        Distribution = 'Gaussian'
        P = 0
        D = 0
        Q = 0
        Constant = NaN
        AR = {}
        SAR = {}
        MA = {}
        SMA = {}
        Seasonality = 0
        Variance = NaN
        ARLags = []
        MALags = []
        SARLags = []
        SMALags = []
        LogL = []
        NumEstimatedParameters = 0
        Estimated = false
        EstimatedResiduals = []
        EstimatedNames = {}
        EstimatedValues = []
        ParamCovariance = []
    end

    methods
        function obj = arima(varargin)
            if nargin == 0
                return
            end
            debut = 1;
            if nargin >= 3 && isnumeric(varargin{1}) && isnumeric(varargin{2}) ...
                    && isnumeric(varargin{3})
                p = round(varargin{1});
                obj.D = round(varargin{2});
                q = round(varargin{3});
                obj.ARLags = 1:p;
                obj.MALags = 1:q;
                obj.AR = num2cell(nan(1, p));
                obj.MA = num2cell(nan(1, q));
                debut = 4;
            elseif nargin == 1 && isa(varargin{1}, 'arima')
                obj = varargin{1};
                return
            end
            k = debut;
            while k + 1 <= nargin
                nom = lower(char(varargin{k}));
                valeur = varargin{k+1};
                switch nom
                    case 'description',  obj.Description = char(valeur);
                    case 'distribution', obj.Distribution = valeur;
                    case 'constant',     obj.Constant = valeur;
                    case 'variance',     obj.Variance = valeur;
                    case 'd',            obj.D = round(valeur);
                    case 'seasonality',  obj.Seasonality = round(valeur);
                    case 'arlags',       obj.ARLags = round(valeur(:).');
                    case 'malags',       obj.MALags = round(valeur(:).');
                    case 'sarlags',      obj.SARLags = round(valeur(:).');
                    case 'smalags',      obj.SMALags = round(valeur(:).');
                    case 'ar',           obj.AR = matlibre_cellule(valeur);
                    case 'ma',           obj.MA = matlibre_cellule(valeur);
                    case 'sar',          obj.SAR = matlibre_cellule(valeur);
                    case 'sma',          obj.SMA = matlibre_cellule(valeur);
                    otherwise
                        error('econ:arima:Option', ...
                              'Propriété inconnue : %s.', char(varargin{k}));
                end
                k = k + 2;
            end
            obj = matlibre_arima_normaliser(obj);
        end

        function disp(obj)
            matlibre_arima_afficher(obj);
        end

        function y = filter(obj, Z, varargin)
        %FILTER Passe des innovations dans le modèle.
        %   Y = FILTER(MDL,Z) applique le modèle aux innovations Z, prises
        %   telles quelles : c'est SIMULATE quand on veut choisir le bruit.
            y = matlibre_arima_filtrer(obj, Z, varargin{:});
        end
    end
end
