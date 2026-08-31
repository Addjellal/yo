function [Y, contrainte] = mdscale(D, dimension, varargin)
%MDSCALE Positionnement multidimensionnel non métrique.
%   Y = MDSCALE(D,P) cherche P coordonnées par objet telles que les
%   distances entre les points de Y reproduisent au mieux les
%   dissemblances D. D est le vecteur que rend PDIST, ou la matrice
%   carrée correspondante.
%
%   Le positionnement métrique — CMDSCALE — cherche à reproduire les
%   distances elles-mêmes. Le positionnement non métrique, lui, ne
%   demande que de respecter leur ordre : deux objets plus dissemblables
%   que deux autres doivent être plus éloignés, sans que le rapport des
%   distances importe. C'est ce qui le rend applicable à des jugements
%   de similarité, où seul le classement a un sens.
%
%   [Y,STRESS] = MDSCALE(D,P) rend la contrainte finale, entre 0 et 1 :
%   c'est l'écart résiduel entre les distances obtenues et les
%   dissemblances ajustées, rapporté à leur taille. Sous 0.05 la
%   représentation est excellente, au-delà de 0.20 elle est douteuse.
%
%   MDSCALE(...,'criterion',C) choisit la contrainte à minimiser :
%   'stress' (défaut), la forme de Kruskal ; 'sstress', qui porte sur les
%   carrés des distances et pèse donc davantage les grandes ; 'metricstress'
%   et 'metricsstress', qui ajustent les distances sans passer par les
%   rangs.
%   MDSCALE(...,'start',Y0) part d'une configuration donnée ; 'random'
%   part d'un tirage. Sans elle, on part du positionnement métrique, qui
%   est un bon point de départ et rend le résultat reproductible.
%   MDSCALE(...,'replicates',R) recommence R fois depuis des départs au
%   hasard et garde la meilleure : le critère a des minima locaux.
%
%   Exemples :
%      % Quatre villes, leurs distances : on retrouve le plan
%      X = [0 0; 3 0; 0 4; 3 4];
%      Y = mdscale(pdist(X), 2);
%      max(abs(pdist(Y) - pdist(X)))     % petit : la carte est bonne
%
%      [Y, contrainte] = mdscale(pdist(randn(20, 5)), 2);
%      contrainte                        % plus grande : cinq dimensions
%                                        % ne tiennent pas dans deux
%
%   Voir aussi CMDSCALE, PDIST, SQUAREFORM, PCA, PROCRUSTES.
    critere = 'stress';
    depart = [];
    repetitions = 1;
    k = 1;
    while k + 1 <= numel(varargin)
        nom = lower(char(varargin{k}));
        switch nom
            case 'criterion'
                critere = lower(char(varargin{k + 1}));
            case 'start'
                depart = varargin{k + 1};
            case 'replicates'
                repetitions = varargin{k + 1};
            case {'weights', 'options'}
                % acceptés et sans effet
            otherwise
                error('stats:mdscale:BadOption', 'Unknown option ''%s''.', nom);
        end
        k = k + 2;
    end
    if isvector(D)
        dissemblances = D(:)';
        M = squareform(dissemblances);
    else
        M = D;
        dissemblances = squareform(M);
    end
    n = size(M, 1);
    if dimension >= n
        error('stats:mdscale:TooManyDimensions', ...
              'The number of dimensions must be smaller than the number of points.');
    end

    meilleure = [];
    meilleureContrainte = Inf;
    for essai = 1:max(1, repetitions)
        if essai == 1 && (isempty(depart) || ~ischar(depart))
            if isempty(depart)
                Y0 = departMetrique(M, dimension);
            else
                Y0 = depart;
            end
        else
            Y0 = randn(n, dimension);
        end
        [Y1, contrainte1] = ajuster(Y0, dissemblances, critere);
        if contrainte1 < meilleureContrainte
            meilleureContrainte = contrainte1;
            meilleure = Y1;
        end
    end
    Y = meilleure;
    contrainte = meilleureContrainte;
end

function Y = departMetrique(M, dimension)
%DEPARTMETRIQUE Le positionnement métrique, comme point de départ.
    Y = cmdscale(M);
    if size(Y, 2) < dimension
        Y = [Y, zeros(size(Y, 1), dimension - size(Y, 2))];
    end
    Y = Y(:, 1:dimension);
end

function [Y, contrainte] = ajuster(Y0, dissemblances, critere)
%AJUSTER Descente sur les coordonnées, par le simplexe de Nelder-Mead.
    n = size(Y0, 1);
    dimension = size(Y0, 2);
    objectif = @(v) contrainteDe(reshape(v, n, dimension), dissemblances, critere);
    v = matlibre_nelder_mead(objectif, Y0(:)', 300, 1e-8);
    Y = reshape(v, n, dimension);
    contrainte = objectif(v);
    % On centre et on oriente sur les axes principaux : la solution n'est
    % définie qu'à une isométrie près, et deux appels doivent donner la
    % même carte.
    Y = Y - repmat(mean(Y, 1), n, 1);
    if n > dimension
        [~, scores] = pca(Y);
        Y = scores(:, 1:dimension);
    end
end

function s = contrainteDe(Y, dissemblances, critere)
%CONTRAINTEDE La contrainte de Kruskal pour une configuration.
    d = pdist(Y);
    if any(strcmp(critere, {'metricstress', 'metricsstress'}))
        cible = dissemblances;
    else
        % Régression monotone : les dissemblances ajustées sont la
        % meilleure suite croissante qui approche les distances dans
        % l'ordre des dissemblances. C'est l'algorithme du « pool
        % adjacent violators ».
        [~, ordre] = sort(dissemblances);
        ajustees = matlibre_regression_isotone(d(ordre));
        cible = zeros(size(d));
        cible(ordre) = ajustees;
    end
    if strcmp(critere, 'sstress') || strcmp(critere, 'metricsstress')
        numerateur = sum((d .^ 2 - cible .^ 2) .^ 2);
        denominateur = sum(d .^ 4);
    else
        numerateur = sum((d - cible) .^ 2);
        denominateur = sum(d .^ 2);
    end
    if denominateur == 0
        s = 0;
    else
        s = sqrt(numerateur / denominateur);
    end
end
