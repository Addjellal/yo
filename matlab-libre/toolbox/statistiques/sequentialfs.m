function [choix, historique] = sequentialfs(critere, X, y, varargin)
%SEQUENTIALFS Choix séquentiel de variables.
%   IN = SEQUENTIALFS(FUN,X,Y) ajoute les variables une à une, en
%   prenant chaque fois celle qui fait le plus baisser le critère, et
%   s'arrête quand plus aucune ne l'améliore. IN est un vecteur de
%   booléens désignant les variables retenues.
%
%   FUN est appelée FUN(XAPPRENTISSAGE,YAPPRENTISSAGE,XTEST,YTEST) et
%   rend le nombre d'erreurs — ou toute autre perte à minimiser.
%
%   SEQUENTIALFS(...,'direction','backward') part de toutes les
%   variables et en retire.
%   SEQUENTIALFS(...,'cv',K) évalue par validation croisée à K blocs
%   (10 par défaut ; 0 pour évaluer sur les données d'apprentissage).
%   SEQUENTIALFS(...,'nfeatures',N) s'arrête à N variables.
%
%   [IN,HISTOIRE] = SEQUENTIALFS(...) rend en outre le critère atteint à
%   chaque étape.
%
%   Exemple :
%      rng(1);
%      X = randn(100, 6);
%      y = double(X(:, 1) - X(:, 3) > 0);
%      f = @(Xa, ya, Xt, yt) sum(predict(fitcnb(Xa, ya), Xt) ~= yt);
%      in = sequentialfs(f, X, y);
%
%   Voir aussi RELIEFF, CVPARTITION, FITCTREE, LASSO.
    X = double(X);
    n = size(X, 1);
    p = size(X, 2);
    direction = 'forward';
    blocs = 10;
    nFeatures = 0;
    j = 1;
    while j + 1 <= numel(varargin)
        switch lower(char(varargin{j}))
            case 'direction', direction = lower(char(varargin{j+1}));
            case 'cv'
                valeur = varargin{j+1};
                if ischar(valeur) || isstring(valeur)
                    blocs = 0;
                else
                    blocs = round(valeur);
                end
            case 'nfeatures', nFeatures = round(varargin{j+1});
            case {'options', 'keepin', 'keepout', 'nullmodel'}
                % Acceptées et sans effet.
            otherwise
                error('stats:sequentialfs:Option', ...
                      'Option inconnue : %s.', char(varargin{j}));
        end
        j = j + 2;
    end
    enAvant = strncmp(direction, 'f', 1);
    choix = false(1, p);
    if ~enAvant
        choix = true(1, p);
    end
    historique = [];
    meilleurCourant = evaluer(critere, X, y, choix, blocs, n);
    while true
        candidat = 0;
        meilleurEssai = meilleurCourant;
        for v = 1:p
            if enAvant == choix(v)
                continue;
            end
            essai = choix;
            essai(v) = enAvant;
            if ~any(essai)
                continue;
            end
            valeur = evaluer(critere, X, y, essai, blocs, n);
            if valeur < meilleurEssai - 1e-12
                meilleurEssai = valeur;
                candidat = v;
            end
        end
        if candidat == 0
            break;
        end
        choix(candidat) = enAvant;
        meilleurCourant = meilleurEssai;
        historique(end + 1) = meilleurCourant;   %#ok<AGROW>
        if nFeatures > 0 && sum(choix) >= nFeatures
            break;
        end
    end
end

function valeur = evaluer(critere, X, y, choix, blocs, n)
% Le critère, moyenné sur les blocs de la validation croisée.
    if ~any(choix)
        valeur = inf;
        return;
    end
    Xc = X(:, choix);
    if blocs <= 1
        valeur = critere(Xc, y, Xc, y) / n;
        return;
    end
    blocs = min(blocs, n);
    appartenance = mod(0:(n - 1), blocs) + 1;
    total = 0;
    for b = 1:blocs
        test = (appartenance == b).';
        if all(test) || ~any(test)
            continue;
        end
        total = total + critere(Xc(~test, :), y(~test), Xc(test, :), y(test));
    end
    valeur = total / n;
end
