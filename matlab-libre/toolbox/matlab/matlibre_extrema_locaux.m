function [marque, proeminence] = matlibre_extrema_locaux(a, options, versLeHaut)
%MATLIBRE_EXTREMA_LOCAUX Rouage commun d'ISLOCALMAX et d'ISLOCALMIN.
%   Un minimum de A est un maximum de -A : la fonction ne traite que le
%   cas du maximum, et le retournement suffit pour l'autre.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_extrema_locaux([1 3 2], {}, true)     % [0 1 0]
%
%   Voir aussi ISLOCALMAX, ISLOCALMIN.
    ligne = isrow(a);
    x = double(a(:));
    if ~versLeHaut
        x = -x;
    end
    n = numel(x);
    marque = false(n, 1);
    proeminence = zeros(n, 1);
    if n >= 3
        % Un plateau ne vaut qu'un maximum, pose sur son premier point.
        k = 2;
        while k <= n - 1
            if x(k) > x(k - 1)
                fin = k;
                while fin < n && x(fin + 1) == x(k)
                    fin = fin + 1;
                end
                if fin < n && x(fin + 1) < x(k)
                    marque(k) = true;
                end
                k = fin + 1;
            else
                k = k + 1;
            end
        end
    end
    for k = find(marque(:))'
        proeminence(k) = proeminenceEn(x, k);
    end

    minProeminence = 0;
    minSeparation = 0;
    maxNombre = inf;
    for k = 1:2:numel(options) - 1
        switch lower(char(options{k}))
            case 'minprominence', minProeminence = double(options{k + 1});
            case 'minseparation', minSeparation = double(options{k + 1});
            case 'maxnumextrema', maxNombre = double(options{k + 1});
            otherwise
                error('MATLAB:islocalmax:UnknownOption', ...
                      'Option inconnue : %s.', char(options{k}));
        end
    end
    marque(proeminence < minProeminence) = false;

    if minSeparation > 0 || isfinite(maxNombre)
        indices = find(marque);
        [~, ordre] = sort(proeminence(indices), 'descend');
        indices = indices(ordre);
        gardes = [];
        for k = 1:numel(indices)
            if isfinite(maxNombre) && numel(gardes) >= maxNombre
                break
            end
            if isempty(gardes) || min(abs(gardes - indices(k))) >= minSeparation
                gardes(end + 1) = indices(k);   %#ok<AGROW>
            end
        end
        marque = false(n, 1);
        marque(gardes) = true;
    end
    proeminence(~marque) = 0;

    if ligne
        marque = marque.';
        proeminence = proeminence.';
    end
end

function p = proeminenceEn(x, k)
% La proeminence : hauteur du sommet au-dessus du col le plus haut qui le
% separe d'un sommet plus eleve. On cherche de part et d'autre le premier
% point plus haut, et l'on retient le creux le plus haut des deux cotes.
    n = numel(x);
    gauche = k;
    while gauche > 1 && x(gauche - 1) <= x(k)
        gauche = gauche - 1;
    end
    droite = k;
    while droite < n && x(droite + 1) <= x(k)
        droite = droite + 1;
    end
    creuxGauche = min(x(gauche:k));
    creuxDroite = min(x(k:droite));
    p = x(k) - max(creuxGauche, creuxDroite);
end
