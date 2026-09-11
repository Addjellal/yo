classdef matlibre_magasin_combine < handle
%MATLIBRE_MAGASIN_COMBINE Magasin qui lit plusieurs magasins de front.
%   C'est l'objet que rend COMBINE. Chaque lecture prend un morceau de
%   chacun des magasins réunis et les rend dans une cellule ; la lecture
%   s'arrête dès que l'un d'eux est épuisé.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB,
%   qui nomme cet objet CombinedDatastore.
%
%   Exemple :
%      c = matlibre_magasin_combine({arrayDatastore([1;2]), arrayDatastore([3;4])});
%      numel(read(c))                  % 2 : un morceau par magasin
%
%   Voir aussi COMBINE, TRANSFORM, DATASTORE.
    properties
        UnderlyingDatastores = {}
    end

    methods
        function ds = matlibre_magasin_combine(magasins)
            if nargin == 0
                return
            end
            ds.UnderlyingDatastores = magasins;
        end

        function t = hasdata(ds)
        %HASDATA Vrai tant que tous les magasins ont encore de quoi lire.
            t = true;
            for k = 1:numel(ds.UnderlyingDatastores)
                t = t && hasdata(ds.UnderlyingDatastores{k});
            end
        end

        function donnees = read(ds)
        %READ Un morceau de chacun, côte à côte.
            if ~hasdata(ds)
                error('MATLAB:datastore:NoMoreData', ...
                      'L''un des magasins est epuise.');
            end
            donnees = cell(1, numel(ds.UnderlyingDatastores));
            for k = 1:numel(ds.UnderlyingDatastores)
                donnees{k} = read(ds.UnderlyingDatastores{k});
            end
        end

        function donnees = readall(ds)
        %READALL Tout, magasin par magasin.
            donnees = cell(1, numel(ds.UnderlyingDatastores));
            for k = 1:numel(ds.UnderlyingDatastores)
                donnees{k} = readall(ds.UnderlyingDatastores{k});
            end
        end

        function donnees = preview(ds)
        %PREVIEW Les premiers morceaux, sans avancer.
            donnees = cell(1, numel(ds.UnderlyingDatastores));
            for k = 1:numel(ds.UnderlyingDatastores)
                donnees{k} = preview(ds.UnderlyingDatastores{k});
            end
        end

        function reset(ds)
        %RESET Ramène chaque magasin au début.
            for k = 1:numel(ds.UnderlyingDatastores)
                reset(ds.UnderlyingDatastores{k});
            end
        end

        function n = numpartitions(ds, varargin)
        %NUMPARTITIONS Le plus petit des nombres de morceaux.
            n = inf;
            for k = 1:numel(ds.UnderlyingDatastores)
                n = min(n, numpartitions(ds.UnderlyingDatastores{k}));
            end
            if isinf(n), n = 0; end
        end
    end
end
