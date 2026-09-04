classdef creditMigrationCopula
%CREDITMIGRATIONCOPULA Modèle de portefeuille de crédit à migrations.
%   C = CREDITMIGRATIONCOPULA(VALEURS,NOTATIONS,TRANSITION,LGD,POIDS)
%   décrit un portefeuille dont chaque position vaut quelque chose de
%   différent selon la notation de son émetteur. VALEURS a une colonne par
%   notation, la dernière étant le défaut.
%
%   Là où CREDITDEFAULTCOPULA ne connaît que deux états — vivant ou en
%   défaut —, celui-ci suit toute l'échelle : une dégradation de notation
%   fait déjà perdre de la valeur, bien avant le défaut. C'est la
%   différence entre un modèle de perte et un modèle de valeur de marché.
%
%   La corrélation vient des mêmes variables latentes ; ce sont les seuils
%   tirés de la matrice de transition qui découpent leur domaine en
%   notations d'arrivée.
%
%   Exemple :
%      valeurs = [100 98 95 60; 100 98 95 60];
%      c = creditMigrationCopula(valeurs, [1; 2], transition, [0.4; 0.4], poids);
%      c = simulate(c, 20000);
%      portfolioRisk(c)
%
%   Voir aussi CREDITDEFAULTCOPULA, TRANSPROBTOTHRESHOLDS, TRANSPROB.
    properties
        MigrationValues = []
        Ratings = []
        TransitionMatrix = []
        LGD = []
        Weights = []
        FactorCorrelation = []
        VaRLevel = 0.95
        PortfolioLosses = []
        Losses = []
        NumScenarios = 0
        Copula = 'gaussian'
        DegreesOfFreedom = 5
        Thresholds = []
    end

    methods
        function obj = creditMigrationCopula(valeurs, notations, transition, lgd, poids, varargin)
            if nargin == 0
                return
            end
            obj.MigrationValues = double(valeurs);
            obj.Ratings = round(double(notations(:)));
            obj.TransitionMatrix = double(transition);
            obj.LGD = double(lgd(:));
            n = numel(obj.Ratings);
            if numel(obj.LGD) == 1, obj.LGD = repmat(obj.LGD, n, 1); end
            if nargin < 5 || isempty(poids)
                poids = [zeros(n, 1), ones(n, 1)];
            end
            obj.Weights = double(poids);
            sommes = sum(obj.Weights .^ 2, 2);
            if any(abs(sommes - 1) > 1e-6)
                error('risque:migration:Norme', ...
                      ['La somme des carrés des poids doit valoir un ' ...
                       'sur chaque ligne.']);
            end
            k = 1;
            while k + 1 <= numel(varargin)
                switch lower(char(varargin{k}))
                    case 'varlevel',          obj.VaRLevel = varargin{k+1};
                    case 'factorcorrelation', obj.FactorCorrelation = double(varargin{k+1});
                    otherwise
                        error('risque:migration:Option', ...
                              'Option inconnue : %s.', char(varargin{k}));
                end
                k = k + 2;
            end
            if isempty(obj.FactorCorrelation)
                obj.FactorCorrelation = eye(max(size(obj.Weights, 2) - 1, 1));
            end
            obj.Thresholds = transprobtothresholds(obj.TransitionMatrix);
        end
    end
end
