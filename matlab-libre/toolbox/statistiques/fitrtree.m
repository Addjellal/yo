function arbre = fitrtree(X, y, varargin)
%FITRTREE Arbre de régression.
%   T = FITRTREE(X,Y) construit un arbre binaire qui prédit une valeur
%   numérique. À chaque nœud, la coupure choisie est celle qui réduit le
%   plus la somme des carrés des écarts — le critère qui remplace, en
%   régression, l'impureté de Gini de FITCTREE.
%
%   Options : 'MinLeafSize' (5 par défaut) et 'MaxDepth' (8 par défaut).
%
%   PREDICT applique l'arbre.
%
%   Exemple :
%      rng(1);
%      X = rand(200, 1) * 10;
%      y = sin(X) + 0.1 * randn(200, 1);
%      t = fitrtree(X, y, 'MinLeafSize', 5);
%      mean((predict(t, X) - y) .^ 2) < 0.05
%
%   Voir aussi FITCTREE, PREDICT, FITRSVM, FITRGP, FITLM.
    tailleMin = 5;
    profondeurMax = 8;
    for i = 1:2:numel(varargin) - 1
        switch lower(char(varargin{i}))
            case 'minleafsize', tailleMin = round(varargin{i+1});
            case 'maxdepth',    profondeurMax = round(varargin{i+1});
            case {'predictornames', 'crossval', 'prune'}
                % Acceptées et sans effet.
            otherwise
                error('stats:fitrtree:Option', 'Option inconnue : %s.', char(varargin{i}));
        end
    end
    racine = construireRegression(double(X), double(y(:)), tailleMin, profondeurMax, 1);
    arbre = racine;
    arbre.type = 'arbre-regression';
end

function noeud = construireRegression(X, y, tailleMin, profondeurMax, profondeur)
    noeud = struct('type', 'arbre-regression', 'feuille', 1, 'valeur', mean(y), ...
                   'variable', 0, 'seuil', 0, 'gauche', 0, 'droite', 0);
    if numel(y) <= tailleMin || profondeur > profondeurMax || all(y == y(1))
        return;
    end
    meilleureVariable = 0;
    meilleurSeuil = 0;
    meilleureErreur = sommeCarres(y);
    for v = 1:size(X, 2)
        valeurs = unique(X(:, v));
        for i = 1:numel(valeurs) - 1
            seuil = (valeurs(i) + valeurs(i + 1)) / 2;
            aGauche = X(:, v) <= seuil;
            if sum(aGauche) < 1 || sum(~aGauche) < 1
                continue;
            end
            erreur = sommeCarres(y(aGauche)) + sommeCarres(y(~aGauche));
            if erreur < meilleureErreur - 1e-12
                meilleureErreur = erreur;
                meilleureVariable = v;
                meilleurSeuil = seuil;
            end
        end
    end
    if meilleureVariable == 0
        return;
    end
    aGauche = X(:, meilleureVariable) <= meilleurSeuil;
    noeud.feuille = 0;
    noeud.variable = meilleureVariable;
    noeud.seuil = meilleurSeuil;
    noeud.gauche = construireRegression(X(aGauche, :), y(aGauche), tailleMin, ...
                                        profondeurMax, profondeur + 1);
    noeud.droite = construireRegression(X(~aGauche, :), y(~aGauche), tailleMin, ...
                                        profondeurMax, profondeur + 1);
end

function s = sommeCarres(y)
    if isempty(y)
        s = 0;
    else
        s = sum((y - mean(y)) .^ 2);
    end
end
