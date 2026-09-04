classdef garch
%GARCH Modèle de variance conditionnelle hétéroscédastique.
%   MDL = GARCH(P,Q) décrit une variance qui dépend de ses P valeurs
%   passées et des Q derniers carrés d'innovation :
%      e(t) = sigma(t) z(t),  z blanc réduit
%      sigma(t)^2 = k + g(1) sigma(t-1)^2 + ... + a(1) e(t-1)^2 + ...
%   Les coefficients valent NaN : ils restent à estimer.
%
%   Les cours de bourse ne bougent pas au hasard de façon uniforme : les
%   fortes variations se suivent, les périodes calmes aussi. Un GARCH
%   décrit cela sans supposer que la variance soit prévisible en signe,
%   seulement en amplitude.
%
%   MDL = GARCH('GARCHLags',L1,'ARCHLags',L2,...) choisit les retards un à
%   un. Les autres propriétés se donnent de même : 'Constant', 'GARCH',
%   'ARCH', 'Offset', 'Distribution', 'Description'.
%
%   La variance est stationnaire quand la somme des coefficients GARCH et
%   ARCH reste inférieure à un ; la variance de long terme vaut alors
%   k / (1 - cette somme).
%
%   Exemple :
%      vrai = garch('Constant', 0.1, 'GARCH', {0.8}, 'ARCH', {0.1});
%      [y, e, v] = simulate(vrai, 2000);
%      ajuste = estimate(garch(1, 1), y);
%
%   Voir aussi ARIMA, ESTIMATE, SIMULATE, FORECAST, INFER, ARCHTEST.
    properties
        Description = ''
        Distribution = 'Gaussian'
        P = 0
        Q = 0
        Constant = NaN
        GARCH = {}
        ARCH = {}
        Leverage = {}
        Offset = 0
        GARCHLags = []
        ARCHLags = []
        LeverageLags = []
        LogL = []
        NumEstimatedParameters = 0
        Estimated = false
        EstimatedResiduals = []
        EstimatedVariances = []
        EstimatedNames = {}
        EstimatedValues = []
        ParamCovariance = []
    end

    methods
        function obj = garch(varargin)
            if nargin == 0
                return
            end
            debut = 1;
            if nargin >= 2 && isnumeric(varargin{1}) && isnumeric(varargin{2})
                p = round(varargin{1});
                q = round(varargin{2});
                obj.GARCHLags = 1:p;
                obj.ARCHLags = 1:q;
                obj.GARCH = num2cell(nan(1, p));
                obj.ARCH = num2cell(nan(1, q));
                debut = 3;
            elseif nargin == 1 && isa(varargin{1}, 'garch')
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
                    case 'offset',       obj.Offset = valeur;
                    case 'garchlags',    obj.GARCHLags = round(valeur(:).');
                    case 'archlags',     obj.ARCHLags = round(valeur(:).');
                    case 'leveragelags', obj.LeverageLags = round(valeur(:).');
                    case 'garch',        obj.GARCH = matlibre_cellule(valeur);
                    case 'arch',         obj.ARCH = matlibre_cellule(valeur);
                    case 'leverage',     obj.Leverage = matlibre_cellule(valeur);
                    otherwise
                        error('econ:garch:Option', ...
                              'Propriété inconnue : %s.', char(varargin{k}));
                end
                k = k + 2;
            end
            obj = matlibre_garch_normaliser(obj);
        end

        function disp(obj)
            matlibre_garch_afficher(obj);
        end
    end
end
