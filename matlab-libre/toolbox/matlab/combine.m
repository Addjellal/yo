function ds = combine(varargin)
%COMBINE Réunit plusieurs magasins en un seul, lu en parallèle.
%   DS = COMBINE(DS1,DS2,...) rend un magasin dont chaque lecture prend
%   un morceau de chacun et les rend côte à côte, dans une cellule.
%
%   C'est ainsi qu'on apparie des données et leurs étiquettes quand elles
%   vivent dans deux magasins : les lire séparément ne garantirait pas
%   qu'on avance du même pas.
%
%   La lecture s'arrête dès que l'un des magasins est épuisé : apparier
%   au-delà n'aurait pas de sens, et continuer sur le plus long
%   produirait des paires boiteuses.
%
%   Exemple :
%      a = arrayDatastore([1; 2; 3]);
%      b = arrayDatastore([10; 20; 30]);
%      c = combine(a, b);
%      paire = read(c);
%      paire{1} == 1 && paire{2} == 10
%
%   Voir aussi DATASTORE, TRANSFORM, READ, HASDATA.
    if numel(varargin) < 2
        error('MATLAB:combine:Arguments', 'COMBINE attend au moins deux magasins.');
    end
    ds = matlibre_magasin_combine(varargin);
end
