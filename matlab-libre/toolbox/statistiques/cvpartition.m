classdef cvpartition
%CVPARTITION Découpage d'un jeu de données pour la validation croisée.
%   P = CVPARTITION(N,'KFold',K) découpe N observations en K blocs de
%   tailles aussi égales que possible.
%   P = CVPARTITION(N,'HoldOut',F) réserve une fraction F pour le test.
%   P = CVPARTITION(N,'Resubstitution') apprend et teste sur tout.
%   P = CVPARTITION(GROUPES,'KFold',K) stratifie : chaque bloc garde à peu
%   près les proportions de chaque groupe.
%
%   Propriétés :
%      NumObservations  le nombre d'observations
%      NumTestSets      le nombre de découpages
%      TrainSize        la taille d'apprentissage de chacun
%      TestSize         leur taille de test
%      Type             'kfold', 'holdout' ou 'resubstitution'
%
%   Méthodes :
%      TEST(P,K)      les observations de test du K-ième découpage
%      TRAINING(P,K)  celles d'apprentissage
%      REPARTITION(P) un nouveau tirage, même forme
%
%   Le découpage est aléatoire mais complet : chaque observation est
%   testée une fois et une seule sur l'ensemble des K blocs. C'est ce qui
%   distingue la validation croisée d'un simple tirage répété, où certaines
%   observations ne seraient jamais testées et d'autres plusieurs fois.
%
%   La stratification importe dès que les classes sont déséquilibrées :
%   sans elle, un bloc peut ne contenir aucun exemple d'une classe rare,
%   et l'erreur mesurée sur ce bloc ne veut plus rien dire.
%
%   Exemple :
%      p = cvpartition(50, 'KFold', 5);
%      for k = 1:p.NumTestSets
%          apprentissage = training(p, k);
%          essai = test(p, k);
%      end
%
%   Voir aussi CROSSVAL, FITCKNN, FITCDISCR.
    properties (SetAccess = private)
        Type = 'kfold'
        NumObservations = 0
        NumTestSets = 1
        blocs = []
        groupes = []
        parametre = 10
    end
    methods
        function obj = cvpartition(n, methode, parametre)
            if nargin < 2
                methode = 'KFold';
            end
            if nargin < 3
                parametre = 10;
            end
            if isscalar(n) && isnumeric(n)
                obj.NumObservations = double(n);
                obj.groupes = ones(obj.NumObservations, 1);
            else
                % Une liste de groupes : le découpage sera stratifié.
                obj.groupes = matlibre_stat_indicesGroupes(n);
                obj.NumObservations = numel(obj.groupes);
            end
            obj.parametre = parametre;
            switch lower(char(methode))
                case 'holdout'
                    obj.Type = 'holdout';
                    obj.NumTestSets = 1;
                case 'resubstitution'
                    obj.Type = 'resubstitution';
                    obj.NumTestSets = 1;
                otherwise
                    obj.Type = 'kfold';
                    obj.NumTestSets = parametre;
            end
            obj = repartition(obj);
        end

        function obj = repartition(obj)
        %REPARTITION Retire un découpage de la même forme.
            n = obj.NumObservations;
            switch obj.Type
                case 'resubstitution'
                    obj.blocs = ones(n, 1);
                case 'holdout'
                    obj.blocs = 2 * ones(n, 1);
                    nTest = max(1, round(obj.parametre * n));
                    ordre = randperm(n);
                    obj.blocs(ordre(1:nTest)) = 1;
                otherwise
                    % Stratification : chaque groupe est réparti à son tour
                    % sur les blocs, si bien que leurs proportions se
                    % retrouvent dans chacun.
                    k = obj.NumTestSets;
                    obj.blocs = zeros(n, 1);
                    depart = 0;
                    for g = unique(obj.groupes(:).')
                        indices = find(obj.groupes == g);
                        indices = indices(randperm(numel(indices)));
                        for i = 1:numel(indices)
                            obj.blocs(indices(i)) = mod(depart + i - 1, k) + 1;
                        end
                        depart = depart + numel(indices);
                    end
            end
        end

        function t = test(obj, k)
        %TEST Observations de test du K-ième découpage.
            if nargin < 2
                k = 1;
            end
            if strcmp(obj.Type, 'resubstitution')
                t = true(obj.NumObservations, 1);
            else
                t = obj.blocs == k;
            end
        end

        function t = training(obj, k)
        %TRAINING Observations d'apprentissage du K-ième découpage.
            if nargin < 2
                k = 1;
            end
            if strcmp(obj.Type, 'resubstitution')
                t = true(obj.NumObservations, 1);
            else
                t = ~test(obj, k);
            end
        end

        function n = get.TrainSize(obj)
            n = zeros(1, obj.NumTestSets);
            for k = 1:obj.NumTestSets
                n(k) = sum(training(obj, k));
            end
        end

        function n = get.TestSize(obj)
            n = zeros(1, obj.NumTestSets);
            for k = 1:obj.NumTestSets
                n(k) = sum(test(obj, k));
            end
        end
    end
    properties (Dependent)
        TrainSize
        TestSize
    end
end
