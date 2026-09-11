classdef matlibre_magasin_transforme < handle
%MATLIBRE_MAGASIN_TRANSFORME Magasin dont chaque morceau passe par une fonction.
%   C'est l'objet que rend TRANSFORM. La fonction n'est appliquée qu'à la
%   lecture : décrire un prétraitement ne coûte donc rien tant qu'on ne
%   lit pas.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB,
%   qui nomme cet objet TransformedDatastore.
%
%   Exemple :
%      t = matlibre_magasin_transforme(arrayDatastore([1;2]), @(x) x * 2);
%      read(t)                         % 2
%
%   Voir aussi TRANSFORM, COMBINE, DATASTORE.
    properties
        UnderlyingDatastores = {}
        Transforms = {}
    end

    methods
        function ds = matlibre_magasin_transforme(magasin, fonction)
            if nargin == 0
                return
            end
            ds.UnderlyingDatastores = {magasin};
            ds.Transforms = {fonction};
        end

        function t = hasdata(ds)
        %HASDATA Reste-t-il quelque chose à lire ?
            t = hasdata(ds.UnderlyingDatastores{1});
        end

        function donnees = read(ds)
        %READ Le morceau suivant, transformé.
            brut = read(ds.UnderlyingDatastores{1});
            donnees = ds.Transforms{1}(brut);
        end

        function donnees = readall(ds)
        %READALL Tout, transformé d'un coup.
            donnees = ds.Transforms{1}(readall(ds.UnderlyingDatastores{1}));
        end

        function donnees = preview(ds)
        %PREVIEW Les premiers éléments, transformés, sans avancer.
            donnees = ds.Transforms{1}(preview(ds.UnderlyingDatastores{1}));
        end

        function reset(ds)
        %RESET Revient au début.
            reset(ds.UnderlyingDatastores{1});
        end

        function n = numpartitions(ds, varargin)
        %NUMPARTITIONS Autant de morceaux que le magasin d'origine.
            n = numpartitions(ds.UnderlyingDatastores{1});
        end
    end
end
