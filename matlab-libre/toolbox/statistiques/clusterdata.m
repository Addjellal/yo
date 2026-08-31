function T = clusterdata(X, varargin)
%CLUSTERDATA Regroupe des observations, de la distance à la coupure.
%   T = CLUSTERDATA(X,CUTOFF) fait d'un seul geste ce que font PDIST,
%   LINKAGE et CLUSTER : il calcule les distances entre les lignes de X,
%   bâtit l'arbre, puis le coupe.
%
%   Si CUTOFF est un entier supérieur ou égal à 2, c'est le nombre de
%   groupes voulu. Sinon, c'est une hauteur de coupure. C'est la règle de
%   MATLAB, un peu surprenante : CLUSTERDATA(X,2) demande deux groupes,
%   CLUSTERDATA(X,2.0001) coupe à la hauteur 2.0001.
%
%   T = CLUSTERDATA(X,'maxclust',K) lève l'ambiguïté et demande K groupes.
%   T = CLUSTERDATA(X,'cutoff',C) coupe à la hauteur C.
%
%   Les options 'linkage' et 'distance' choisissent la méthode de LINKAGE
%   et la métrique de PDIST :
%
%      T = clusterdata(X, 'maxclust', 3, 'linkage', 'ward');
%
%   Exemples :
%      X = [1 1; 1.2 1; 5 5; 5.1 5.2];
%      clusterdata(X, 2)                       % [1;1;2;2]
%      clusterdata(X, 'maxclust', 2, 'linkage', 'average')
%
%   Voir aussi PDIST, LINKAGE, CLUSTER, DENDROGRAM, KMEANS.
    methode = 'single';
    metrique = 'euclidean';
    critere = '';
    valeur = [];
    k = 1;
    if numel(varargin) >= 1 && isnumeric(varargin{1})
        valeur = varargin{1};
        if valeur == fix(valeur) && valeur >= 2
            critere = 'maxclust';
        else
            critere = 'cutoff';
        end
        k = 2;
    end
    while k + 1 <= numel(varargin)
        nom = lower(char(varargin{k}));
        switch nom
            case 'maxclust'
                critere = 'maxclust';
                valeur = varargin{k + 1};
            case 'cutoff'
                critere = 'cutoff';
                valeur = varargin{k + 1};
            case 'linkage'
                methode = varargin{k + 1};
            case 'distance'
                metrique = varargin{k + 1};
            case 'criterion'
                % 'distance' est le seul critère que MatLibre applique
            otherwise
                error('stats:clusterdata:BadOption', 'Unknown option ''%s''.', nom);
        end
        k = k + 2;
    end
    if isempty(critere)
        error('stats:clusterdata:NoCutoff', ...
              'CLUSTERDATA needs a number of clusters or a cutoff.');
    end
    Z = linkage(X, methode, metrique);
    T = cluster(Z, critere, valeur);
end
