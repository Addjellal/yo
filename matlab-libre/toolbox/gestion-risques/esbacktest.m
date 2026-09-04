classdef esbacktest
%ESBACKTEST Contrôle a posteriori d'une perte moyenne au-delà de la VaR.
%   E = ESBACKTEST(RENDEMENTS,VAR,ES) confronte les pertes subies aux
%   valeurs en risque et aux pertes moyennes au-delà annoncées.
%
%   La valeur en risque ne dit rien de l'ampleur des dépassements ; la
%   perte moyenne au-delà, si. La contrôler demande un test différent :
%   il ne suffit plus de compter les dépassements, il faut mesurer
%   combien ils ont coûté.
%
%   Le test est celui d'Acerbi et Székely : la somme des pertes
%   dépassantes, rapportée à ce que le modèle annonçait, vaut zéro en
%   moyenne quand le modèle dit vrai. Sa loi n'a pas de forme fermée ;
%   elle est simulée sous l'hypothèse nulle, à graine fixée, de sorte que
%   deux appels identiques rendent le même verdict.
%
%   Les méthodes : UNCONDITIONALNORMAL suppose des rendements gaussiens,
%   UNCONDITIONALT une loi de Student, RUNTESTS les passe tous deux,
%   SUMMARY compte les dépassements.
%
%   Exemple :
%      e = esbacktest(rendements, valeursEnRisque, pertesMoyennes);
%      runtests(e)
%
%   Voir aussi VARBACKTEST, EXPECTEDSHORTFALL, VALUEATRISK.
    properties
        PortfolioData = []
        VaRData = []
        ESData = []
        VaRLevel = 0.95
        PortfolioID = 'Portefeuille'
        VaRID = 'VaR'
    end

    methods
        function obj = esbacktest(donnees, valeursEnRisque, pertesMoyennes, varargin)
            if nargin == 0
                return
            end
            obj.PortfolioData = double(donnees(:));
            obj.VaRData = double(valeursEnRisque(:));
            obj.ESData = double(pertesMoyennes(:));
            n = numel(obj.PortfolioData);
            if isscalar(obj.VaRData), obj.VaRData = repmat(obj.VaRData, n, 1); end
            if isscalar(obj.ESData),  obj.ESData = repmat(obj.ESData, n, 1);  end
            if numel(obj.VaRData) ~= n || numel(obj.ESData) ~= n
                error('risque:esbacktest:Tailles', ...
                      'Il faut une valeur en risque et une perte moyenne par observation.');
            end
            k = 1;
            while k + 1 <= numel(varargin)
                switch lower(char(varargin{k}))
                    case 'varlevel',    obj.VaRLevel = varargin{k+1};
                    case 'portfolioid', obj.PortfolioID = char(varargin{k+1});
                    case 'varid',       obj.VaRID = char(varargin{k+1});
                    otherwise
                        error('risque:esbacktest:Option', ...
                              'Option inconnue : %s.', char(varargin{k}));
                end
                k = k + 2;
            end
        end

        function resultat = unconditionalNormal(obj, varargin)
        %UNCONDITIONALNORMAL Test d'Acerbi et Székely, hypothèse gaussienne.
            resultat = matlibre_es_test(obj, 'normal', 0, varargin{:});
        end

        function resultat = unconditionalT(obj, varargin)
        %UNCONDITIONALT Test d'Acerbi et Székely, hypothèse de Student.
            degres = 5;
            k = 1;
            while k + 1 <= numel(varargin)
                if strcmpi(char(varargin{k}), 'degreesoffreedom')
                    degres = varargin{k+1};
                end
                k = k + 2;
            end
            resultat = matlibre_es_test(obj, 't', degres, varargin{:});
        end

        function resultats = runtests(obj, varargin)
        %RUNTESTS Passe les deux tests d'un coup.
            resultats = matlibre_lancer_tests(obj, varargin{:});
        end
    end
end
