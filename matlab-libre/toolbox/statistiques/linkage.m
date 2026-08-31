function Z = linkage(X, methode, metrique)
%LINKAGE Arbre de regroupement hiérarchique.
%   Z = LINKAGE(Y) construit l'arbre de regroupement à partir du vecteur
%   de distances Y que rend PDIST. Z compte N-1 lignes, une par fusion,
%   et trois colonnes : les deux groupes réunis, puis la distance à
%   laquelle ils l'ont été. Les observations d'origine portent les
%   numéros 1 à N ; le groupe formé à la k-ième fusion porte le numéro
%   N+k, de sorte qu'il peut être réuni à son tour.
%
%   Z = LINKAGE(X) où X est une matrice d'observations — une par ligne —
%   calcule d'abord PDIST(X), puis l'arbre.
%
%   Z = LINKAGE(...,METHODE) choisit comment mesurer la distance entre
%   deux groupes :
%      'single'    la plus courte distance entre leurs membres (défaut),
%                  dite du plus proche voisin ; elle suit les filaments ;
%      'complete'  la plus longue, dite du diamètre ; elle fait des
%                  groupes compacts ;
%      'average'   la moyenne de toutes les paires (UPGMA) ;
%      'weighted'  la moyenne des deux sous-groupes, à poids égal
%                  (WPGMA) ;
%      'centroid'  la distance entre les centres de gravité (UPGMC) ;
%      'median'    la distance entre les centres, chacun placé au milieu
%                  de ses deux sous-groupes (WPGMC) ;
%      'ward'      l'accroissement de l'inertie intragroupe qu'entraîne
%                  la fusion ; c'est la méthode qui fait les groupes les
%                  plus équilibrés.
%
%   Z = LINKAGE(X,METHODE,METRIQUE) passe METRIQUE à PDIST. Les méthodes
%   'centroid', 'median' et 'ward' n'ont de sens que pour la distance
%   euclidienne.
%
%   Les distances de 'centroid' et 'median' peuvent décroître d'une
%   fusion à la suivante — c'est l'inversion, propre à ces deux méthodes,
%   et non une erreur de calcul.
%
%   Exemples :
%      X = [1 1; 1.2 1; 5 5; 5.1 5.2];
%      Z = linkage(X)
%      % deux paires serrees, puis leur reunion, loin
%      T = cluster(Z, 'maxclust', 2)   % [1;1;2;2]
%      dendrogram(Z);
%
%      Z = linkage(X, 'ward');
%      cophenet(Z, pdist(X))           % proche de 1 : l'arbre est fidele
%
%   Voir aussi PDIST, CLUSTER, CLUSTERDATA, COPHENET, DENDROGRAM, KMEANS.
    if nargin < 2 || isempty(methode)
        methode = 'single';
    end
    if nargin < 3 || isempty(metrique)
        metrique = 'euclidean';
    end
    methode = lower(char(methode));
    if isvector(X) && size(X, 1) == 1
        y = X;
    elseif isvector(X) && size(X, 2) == 1 && numel(X) ~= 1
        y = X';
    else
        y = pdist(X, metrique);
    end
    D = squareform(y);
    n = size(D, 1);
    if n < 2
        Z = zeros(0, 3);
        return;
    end

    % Les trois dernières méthodes travaillent sur les carrés des
    % distances : les formules de mise à jour de Lance-Williams n'y sont
    % valables que sous cette forme.
    carre = any(strcmp(methode, {'centroid', 'median', 'ward'}));
    if carre
        D = D .^ 2;
    end

    effectif = ones(1, n);        % taille de chaque groupe vivant
    numero = 1:n;                 % son numéro dans Z
    vivant = true(1, n);
    Z = zeros(n - 1, 3);
    infini = Inf;
    for k = 1:n - 1
        % La paire vivante la plus proche.
        meilleur = infini;
        pi_ = 0;
        pj = 0;
        for i = 1:n
            if ~vivant(i)
                continue;
            end
            for j = i + 1:n
                if vivant(j) && D(i, j) < meilleur
                    meilleur = D(i, j);
                    pi_ = i;
                    pj = j;
                end
            end
        end
        a = numero(pi_);
        b = numero(pj);
        Z(k, 1) = min(a, b);
        Z(k, 2) = max(a, b);
        if carre
            Z(k, 3) = sqrt(max(meilleur, 0));
        else
            Z(k, 3) = meilleur;
        end

        % Mise à jour de Lance-Williams : le groupe fusionné prend la
        % place de PI_, PJ disparaît.
        ni = effectif(pi_);
        nj = effectif(pj);
        for m = 1:n
            if ~vivant(m) || m == pi_ || m == pj
                continue;
            end
            nm = effectif(m);
            dim = D(pi_, m);
            djm = D(pj, m);
            dij = meilleur;
            switch methode
                case 'single'
                    d = min(dim, djm);
                case 'complete'
                    d = max(dim, djm);
                case 'average'
                    d = (ni * dim + nj * djm) / (ni + nj);
                case 'weighted'
                    d = (dim + djm) / 2;
                case 'centroid'
                    d = (ni * dim + nj * djm) / (ni + nj) - ...
                        ni * nj * dij / (ni + nj) ^ 2;
                case 'median'
                    d = dim / 2 + djm / 2 - dij / 4;
                case 'ward'
                    d = ((ni + nm) * dim + (nj + nm) * djm - nm * dij) / ...
                        (ni + nj + nm);
                otherwise
                    error('stats:linkage:UnknownMethod', ...
                          'Unknown linkage method ''%s''.', methode);
            end
            D(pi_, m) = d;
            D(m, pi_) = d;
        end
        effectif(pi_) = ni + nj;
        numero(pi_) = n + k;
        vivant(pj) = false;
    end
end
