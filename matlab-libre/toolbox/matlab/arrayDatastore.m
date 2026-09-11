classdef arrayDatastore < handle
%ARRAYDATASTORE Magasin de données bâti sur un tableau déjà en mémoire.
%   DS = ARRAYDATASTORE(A) parcourt A par morceaux, ligne par ligne par
%   défaut. DS = ARRAYDATASTORE(A,'ReadSize',N) prend N lignes à la fois.
%   DS = ARRAYDATASTORE(A,'IterationDimension',D) parcourt suivant D.
%
%   Il n'économise aucune mémoire — le tableau y est déjà. Son emploi est
%   d'écrire une seule fois le code qui parcourt un magasin, et de le
%   faire marcher aussi bien sur un fichier que sur ce qu'on a sous la
%   main : c'est utile pour essayer, et pour les tests.
%
%   Exemple :
%      ds = arrayDatastore([1 2; 3 4; 5 6], 'ReadSize', 2);
%      size(read(ds))                  % 2 lignes prises
%      hasdata(ds)                     % 1 : il en reste une
%
%   Voir aussi DATASTORE, TABULARTEXTDATASTORE, READ, READALL.
    properties
        ReadSize = 1
        IterationDimension = 1
    end
    properties (Access = private)
        Donnees = []
        Position = 1
    end

    methods
        function ds = arrayDatastore(a, varargin)
            if nargin == 0
                return
            end
            options = matlibre_lire_options(varargin, ...
                struct('ReadSize', 1, 'IterationDimension', 1));
            ds.Donnees = a;
            ds.ReadSize = options.ReadSize;
            ds.IterationDimension = options.IterationDimension;
        end

        function n = matlibre_longueur(ds)
        %MATLIBRE_LONGUEUR Nombre d'éléments à parcourir.
            n = size(ds.Donnees, ds.IterationDimension);
        end

        function t = hasdata(ds)
        %HASDATA Reste-t-il quelque chose à lire ?
            t = ds.Position <= matlibre_longueur(ds);
        end

        function donnees = read(ds)
        %READ Le morceau suivant.
            if ~hasdata(ds)
                error('MATLAB:datastore:NoMoreData', ...
                      'Il n''y a plus rien a lire. Employez HASDATA ou RESET.');
            end
            dernier = min(ds.Position + ds.ReadSize - 1, matlibre_longueur(ds));
            if ds.IterationDimension == 1
                donnees = ds.Donnees(ds.Position:dernier, :);
            else
                donnees = ds.Donnees(:, ds.Position:dernier);
            end
            ds.Position = dernier + 1;
        end

        function donnees = readall(ds)
        %READALL Le tableau entier.
            donnees = ds.Donnees;
        end

        function donnees = preview(ds)
        %PREVIEW Les premiers éléments, sans avancer.
            dernier = min(8, matlibre_longueur(ds));
            if ds.IterationDimension == 1
                donnees = ds.Donnees(1:dernier, :);
            else
                donnees = ds.Donnees(:, 1:dernier);
            end
        end

        function reset(ds)
        %RESET Revient au début.
            ds.Position = 1;
        end

        function n = numpartitions(ds, varargin)
        %NUMPARTITIONS Nombre de morceaux que la lecture produira.
            n = max(1, ceil(matlibre_longueur(ds) / ds.ReadSize));
        end
    end
end
