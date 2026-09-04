classdef varbacktest
%VARBACKTEST Contrôle a posteriori d'un modèle de valeur en risque.
%   V = VARBACKTEST(RENDEMENTS,VAR) confronte les pertes réellement
%   subies aux valeurs en risque annoncées la veille. VARBACKTEST(...,
%   'VaRLevel',A) donne le niveau du modèle (0,95 par défaut).
%
%   Un modèle de valeur en risque est une prévision, et une prévision se
%   vérifie. Deux questions se posent : le nombre de dépassements est-il
%   celui qu'annonce le niveau, et ces dépassements sont-ils dispersés ou
%   groupés ? Un modèle peut avoir le bon nombre de dépassements et
%   rester mauvais s'ils arrivent tous la même semaine.
%
%   Les méthodes : TL le feu tricolore de Bâle, BIN le test binomial,
%   POF la proportion de dépassements de Kupiec, TUFF le temps jusqu'au
%   premier, CCI l'indépendance de Christoffersen, CC la couverture
%   conditionnelle, TBFI et TBF les temps entre dépassements de Haas.
%   RUNTESTS les passe tous, SUMMARY compte.
%
%   Exemple :
%      v = varbacktest(rendements, valeursEnRisque, 'VaRLevel', 0.99);
%      runtests(v)
%
%   Voir aussi ESBACKTEST, VALUEATRISK, EXPECTEDSHORTFALL.
    properties
        PortfolioData = []
        VaRData = []
        VaRLevel = 0.95
        PortfolioID = 'Portefeuille'
        VaRID = 'VaR'
    end

    methods
        function obj = varbacktest(donnees, valeursEnRisque, varargin)
            if nargin == 0
                return
            end
            obj.PortfolioData = double(donnees(:));
            obj.VaRData = double(valeursEnRisque(:));
            if isscalar(obj.VaRData)
                obj.VaRData = repmat(obj.VaRData, size(obj.PortfolioData));
            end
            if numel(obj.PortfolioData) ~= numel(obj.VaRData)
                error('risque:varbacktest:Tailles', ...
                      'Il faut une valeur en risque par observation.');
            end
            k = 1;
            while k + 1 <= numel(varargin)
                switch lower(char(varargin{k}))
                    case 'varlevel',    obj.VaRLevel = varargin{k+1};
                    case 'portfolioid', obj.PortfolioID = char(varargin{k+1});
                    case 'varid',       obj.VaRID = char(varargin{k+1});
                    otherwise
                        error('risque:varbacktest:Option', ...
                              'Option inconnue : %s.', char(varargin{k}));
                end
                k = k + 2;
            end
        end

        function resultat = tl(obj, varargin)
        %TL Feu tricolore de Bâle.
            resultat = matlibre_var_test(obj, 'tl', varargin{:});
        end

        function resultat = bin(obj, varargin)
        %BIN Test binomial du nombre de dépassements.
            resultat = matlibre_var_test(obj, 'bin', varargin{:});
        end

        function resultat = pof(obj, varargin)
        %POF Test de proportion de dépassements de Kupiec.
            resultat = matlibre_var_test(obj, 'pof', varargin{:});
        end

        function resultat = tuff(obj, varargin)
        %TUFF Temps jusqu'au premier dépassement.
            resultat = matlibre_var_test(obj, 'tuff', varargin{:});
        end

        function resultat = cci(obj, varargin)
        %CCI Indépendance des dépassements, selon Christoffersen.
            resultat = matlibre_var_test(obj, 'cci', varargin{:});
        end

        function resultat = cc(obj, varargin)
        %CC Couverture conditionnelle : proportion et indépendance ensemble.
            resultat = matlibre_var_test(obj, 'cc', varargin{:});
        end

        function resultat = tbfi(obj, varargin)
        %TBFI Indépendance par les temps entre dépassements.
            resultat = matlibre_var_test(obj, 'tbfi', varargin{:});
        end

        function resultat = tbf(obj, varargin)
        %TBF Temps entre dépassements, proportion comprise.
            resultat = matlibre_var_test(obj, 'tbf', varargin{:});
        end

        function resultats = runtests(obj, varargin)
        %RUNTESTS Passe les huit tests d'un coup.
        %   R = RUNTESTS(V) rend une cellule par test, chacune portant son
        %   nom, sa statistique, sa valeur critique et son verdict.
            resultats = matlibre_lancer_tests(obj, varargin{:});
        end
    end
end
