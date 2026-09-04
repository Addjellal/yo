classdef creditDefaultCopula
%CREDITDEFAULTCOPULA Modèle de portefeuille de crédit à copule de défaut.
%   C = CREDITDEFAULTCOPULA(PD,LGD,EAD,POIDS) décrit un portefeuille par
%   la probabilité de défaut, la perte en cas de défaut et l'exposition de
%   chaque contrepartie, ainsi que sa sensibilité à des facteurs communs.
%
%   POIDS a une colonne par facteur, plus une dernière pour la part
%   propre à la contrepartie ; la somme des carrés de chaque ligne doit
%   valoir un, faute de quoi la variable latente n'est plus réduite.
%
%   Le modèle est celui qui fonde toutes les mesures de risque de crédit
%   modernes : une variable latente normale par contrepartie, corrélée
%   aux autres par des facteurs communs, et un défaut lorsqu'elle passe
%   sous le quantile correspondant à sa probabilité de défaut. La
%   corrélation entre défauts ne vient donc pas d'une hypothèse
%   supplémentaire : elle est celle des variables latentes.
%
%   SIMULATE engendre des scénarios, PORTFOLIORISK résume les pertes,
%   RISKCONTRIBUTION dit d'où elles viennent, CONFIDENCEBANDS montre à
%   quelle vitesse l'estimation se stabilise et GETSCENARIOS rend les
%   pertes simulées.
%
%   CREDITDEFAULTCOPULA(...,'VaRLevel',A) règle le quantile (0,95),
%   'FactorCorrelation',R la corrélation entre facteurs.
%
%   Exemple :
%      c = creditDefaultCopula([0.02; 0.05], [0.4; 0.6], [100; 200], ...
%                              [0.5 sqrt(0.75); 0.5 sqrt(0.75)]);
%      c = simulate(c, 20000);
%      portfolioRisk(c)
%
%   Voir aussi CREDITMIGRATIONCOPULA, ASRF, CONCENTRATIONINDICES.
    properties
        PD = []
        LGD = []
        EAD = []
        FactorCorrelation = []
        Weights = []
        VaRLevel = 0.95
        PortfolioLosses = []
        Losses = []
        NumScenarios = 0
        Copula = 'gaussian'
        DegreesOfFreedom = 5
    end

    methods
        function obj = creditDefaultCopula(pd, lgd, ead, poids, varargin)
            if nargin == 0
                return
            end
            obj.PD = double(pd(:));
            obj.LGD = double(lgd(:));
            obj.EAD = double(ead(:));
            n = numel(obj.PD);
            if numel(obj.LGD) == 1, obj.LGD = repmat(obj.LGD, n, 1); end
            if numel(obj.EAD) == 1, obj.EAD = repmat(obj.EAD, n, 1); end
            if nargin < 4 || isempty(poids)
                poids = [zeros(n, 1), ones(n, 1)];
            end
            obj.Weights = double(poids);
            if size(obj.Weights, 1) ~= n
                error('risque:copule:Poids', ...
                      'Il faut une ligne de poids par contrepartie.');
            end
            sommes = sum(obj.Weights .^ 2, 2);
            if any(abs(sommes - 1) > 1e-6)
                error('risque:copule:Norme', ...
                      ['La somme des carrés des poids doit valoir un ' ...
                       'sur chaque ligne.']);
            end
            k = 1;
            while k + 1 <= numel(varargin)
                switch lower(char(varargin{k}))
                    case 'varlevel',          obj.VaRLevel = varargin{k+1};
                    case 'factorcorrelation', obj.FactorCorrelation = double(varargin{k+1});
                    otherwise
                        error('risque:copule:Option', ...
                              'Option inconnue : %s.', char(varargin{k}));
                end
                k = k + 2;
            end
            if isempty(obj.FactorCorrelation)
                obj.FactorCorrelation = eye(max(size(obj.Weights, 2) - 1, 1));
            end
        end
    end
end
