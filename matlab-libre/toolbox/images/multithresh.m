function seuils = multithresh(image, n)
%MULTITHRESH Seuils d'Otsu multiples.
%   S = MULTITHRESH(I,N) rend N seuils qui découpent l'histogramme en N+1
%   classes en maximisant la variance interclasse — la généralisation
%   directe de la méthode d'Otsu.
%
%   Exemple :
%      multithresh([zeros(1,50) ones(1,50)], 1)   % proche de 0,5
    if nargin < 2, n = 1; end
    x = im2double(image);
    x = x(:);
    bacs = 256;
    compte = accumarray(min(max(round(x * (bacs - 1)), 0), bacs - 1) + 1, 1, [bacs 1]);
    p = compte / sum(compte);
    niveaux = (0:bacs-1)' / (bacs - 1);
    meilleur = -inf;
    meilleurs = zeros(1, n);
    tolerance = 1e-12;
    % Recherche exhaustive sur une grille grossière puis affinage : au-delà
    % de deux seuils, l'exhaustif complet coûterait trop.
    grille = round(linspace(2, bacs - 1, min(bacs - 2, 64)));
    combinaisons = combinaisonsCroissantes(grille, n);
    for k = 1:size(combinaisons, 1)
        v = variationInterclasse(p, niveaux, combinaisons(k, :), bacs);
        if v > meilleur
            meilleur = v;
            meilleurs = combinaisons(k, :);
        end
    end
    % Affinage local autour de la meilleure combinaison.
    for tour = 1:3
        for j = 1:n
            for candidat = max(2, meilleurs(j) - 8):min(bacs - 1, meilleurs(j) + 8)
                essai = meilleurs;
                essai(j) = candidat;
                if any(diff(sort(essai)) <= 0), continue, end
                v = variationInterclasse(p, niveaux, sort(essai), bacs);
                if v > meilleur + tolerance
                    meilleur = v;
                    meilleurs = sort(essai);
                end
            end
        end
    end
    % Le maximum peut être atteint sur tout un palier — c'est le cas d'un
    % histogramme à deux masses séparées. On prend alors le milieu du
    % palier, seul choix qui ne dépende pas de l'ordre du parcours.
    for j = 1:n
        egaux = [];
        for candidat = 2:bacs - 1
            essai = meilleurs;
            essai(j) = candidat;
            if any(diff(sort(essai)) <= 0), continue, end
            if abs(variationInterclasse(p, niveaux, sort(essai), bacs) - meilleur) <= tolerance
                egaux(end + 1) = candidat; %#ok<AGROW>
            end
        end
        if ~isempty(egaux)
            meilleurs(j) = egaux(ceil(numel(egaux) / 2));
        end
    end
    seuils = niveaux(sort(meilleurs))';
end

function v = variationInterclasse(p, niveaux, coupes, bacs)
    bornes = [1, coupes, bacs + 1];
    moyenneGlobale = sum(p .* niveaux);
    v = 0;
    for k = 1:numel(bornes) - 1
        plage = bornes(k):bornes(k + 1) - 1;
        poids = sum(p(plage));
        if poids <= 0, continue, end
        moyenne = sum(p(plage) .* niveaux(plage)) / poids;
        v = v + poids * (moyenne - moyenneGlobale)^2;
    end
end

function c = combinaisonsCroissantes(valeurs, n)
%COMBINAISONSCROISSANTES Toutes les combinaisons strictement croissantes.
    if n == 1
        c = valeurs(:);
        return
    end
    c = [];
    for k = 1:numel(valeurs) - n + 1
        reste = combinaisonsCroissantes(valeurs(k+1:end), n - 1);
        c = [c; repmat(valeurs(k), size(reste, 1), 1), reste]; %#ok<AGROW>
    end
end
