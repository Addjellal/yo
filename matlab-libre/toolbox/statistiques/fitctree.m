function arbre = fitctree(X, y, varargin)
%FITCTREE Arbre de décision binaire (CART, critère de Gini).
%   T = FITCTREE(X,Y) construit un arbre ; PREDICTTREE l'utilise.
%   Option 'MinLeafSize' (1 par défaut) et 'MaxDepth' (8 par défaut).
    tailleMin = 1;
    profondeurMax = 8;
    for i = 1:2:numel(varargin)-1
        switch lower(char(varargin{i}))
            case 'minleafsize'
                tailleMin = varargin{i+1};
            case 'maxdepth'
                profondeurMax = varargin{i+1};
        end
    end
    arbre = construire(X, y(:), tailleMin, profondeurMax, 1);
end

function noeud = construire(X, y, tailleMin, profondeurMax, profondeur)
    classes = unique(y);
    if numel(classes) == 1 || size(X, 1) <= tailleMin || profondeur > profondeurMax
        noeud = struct('feuille', 1, 'classe', mode(y), 'variable', 0, ...
                       'seuil', 0, 'gauche', 0, 'droite', 0);
        return;
    end
    meilleureVariable = 0;
    meilleurSeuil = 0;
    meilleurGini = inf;
    for v = 1:size(X, 2)
        valeurs = unique(X(:, v));
        for i = 1:numel(valeurs)-1
            seuil = (valeurs(i) + valeurs(i+1)) / 2;
            gauche = y(X(:, v) <= seuil);
            droite = y(X(:, v) > seuil);
            if isempty(gauche) || isempty(droite)
                continue;
            end
            g = (numel(gauche) * gini(gauche) + numel(droite) * gini(droite)) / numel(y);
            if g < meilleurGini
                meilleurGini = g;
                meilleureVariable = v;
                meilleurSeuil = seuil;
            end
        end
    end
    if meilleureVariable == 0
        noeud = struct('feuille', 1, 'classe', mode(y), 'variable', 0, ...
                       'seuil', 0, 'gauche', 0, 'droite', 0);
        return;
    end
    masque = X(:, meilleureVariable) <= meilleurSeuil;
    noeud = struct('feuille', 0, 'classe', mode(y), ...
                   'variable', meilleureVariable, 'seuil', meilleurSeuil, ...
                   'gauche', construire(X(masque, :), y(masque), tailleMin, profondeurMax, profondeur+1), ...
                   'droite', construire(X(~masque, :), y(~masque), tailleMin, profondeurMax, profondeur+1));
end

function g = gini(y)
    classes = unique(y);
    g = 1;
    for k = 1:numel(classes)
        p = sum(y == classes(k)) / numel(y);
        g = g - p ^ 2;
    end
end
