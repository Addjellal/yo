function d = pdist(X, metrique, parametre)
%PDIST Distances entre toutes les paires d'observations.
%   D = PDIST(X) rend les distances euclidiennes entre les lignes de X,
%   sous forme d'un vecteur ligne de N(N-1)/2 termes — seulement le
%   triangle supérieur, puisque la matrice est symétrique et de diagonale
%   nulle. L'ordre est celui des colonnes du triangle :
%
%      (2,1) (3,1) … (N,1) (3,2) … (N,2) … (N,N-1)
%
%   SQUAREFORM(D) redonne la matrice carrée.
%
%   D = PDIST(X,METRIQUE) choisit la distance :
%      'euclidean'    la racine de la somme des carrés (défaut) ;
%      'seuclidean'   euclidienne normalisée par l'écart type de chaque
%                     variable, pour que les unités ne pèsent plus ;
%      'cityblock'    la somme des écarts absolus, dite de Manhattan ;
%      'chebychev'    le plus grand écart, coordonnée par coordonnée ;
%      'minkowski'    la norme p ; PDIST(X,'minkowski',P) fixe P (2 par
%                     défaut) ;
%      'cosine'       un moins le cosinus de l'angle entre les vecteurs ;
%      'correlation'  un moins la corrélation des deux lignes, chacune
%                     centrée sur sa propre moyenne ;
%      'hamming'      la proportion de coordonnées qui diffèrent ;
%      'jaccard'      la proportion de coordonnées qui diffèrent parmi
%                     celles où au moins l'une des deux est non nulle ;
%      'spearman'     un moins la corrélation des rangs.
%
%   La métrique peut aussi être une poignée de fonction @(u,v) …, appelée
%   sur une ligne u et une matrice v de lignes.
%
%   Exemples :
%      X = [0 0; 3 4; 0 4];
%      pdist(X)                        % [5 4 3]
%      squareform(pdist(X))            % la matrice 3 x 3
%      pdist(X, 'cityblock')           % [7 4 3]
%      pdist([1 0; 0 1], 'cosine')     % 1 : les vecteurs sont orthogonaux
%
%   Voir aussi SQUAREFORM, PDIST2, LINKAGE, MAHAL, KMEANS, KNNSEARCH.
    if nargin < 2 || isempty(metrique)
        metrique = 'euclidean';
    end
    if nargin < 3
        parametre = 2;
    end
    n = size(X, 1);
    d = zeros(1, n * (n - 1) / 2);
    if n < 2
        return;
    end
    if strcmp(char(class(metrique)), 'function_handle')
        position = 1;
        for i = 1:n - 1
            valeurs = metrique(X(i, :), X(i + 1:n, :));
            valeurs = valeurs(:)';
            d(position:position + numel(valeurs) - 1) = valeurs;
            position = position + numel(valeurs);
        end
        return;
    end
    nom = lower(char(metrique));
    echelle = [];
    if strcmp(nom, 'seuclidean')
        echelle = std(X, 0, 1);
        echelle(echelle == 0) = 1;
    end
    if strcmp(nom, 'spearman')
        X = tiedrank(X);
        nom = 'correlation';
    end
    position = 1;
    for i = 1:n - 1
        for j = i + 1:n
            d(position) = matlibre_distance(X(i, :), X(j, :), nom, parametre, echelle);
            position = position + 1;
        end
    end
end
