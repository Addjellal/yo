function [points, nombreOptimal, contrastes] = wvarchg(y, K, d)
%WVARCHG Détection de ruptures de variance.
%   [PTS,KOPT] = WVARCHG(Y,K,D) cherche jusqu'à K instants où la variance
%   du signal Y change. D est le nombre minimal d'échantillons entre deux
%   ruptures (dix par défaut) ; K vaut six par défaut.
%
%   [PTS,KOPT,CONTRASTES] = WVARCHG(...) rend en outre, pour chaque
%   nombre de ruptures de zéro à K, la valeur du contraste et les
%   instants trouvés : CONTRASTES(J+1) va avec la ligne J+1 de la
%   cellule PTS.
%
%   La recherche est exacte, non gloutonne : une programmation dynamique
%   parcourt toutes les découpes possibles et garde celle qui minimise
%
%      somme_segments n_i log(variance_i),
%
%   c'est-à-dire l'opposé de la vraisemblance gaussienne. Le nombre de
%   ruptures est choisi par pénalisation : on retient le plus grand K
%   dont l'ajout fait encore baisser le contraste d'au moins 4 log(n).
%   Une rupture ajoute deux paramètres — sa position et une variance —,
%   ce que le critère bayésien facturerait 2 log(n) ; sur du bruit pur ce
%   seuil laisse encore passer une découpe de temps en temps, et le
%   doubler l'écarte sans manquer les vraies ruptures, qui gagnent
%   d'ordinaire cent fois plus.
%
%   Appliquée aux détails d'ondelettes plutôt qu'au signal, elle détecte
%   les changements de régime d'une série dont la moyenne bouge aussi :
%   les détails effacent la tendance.
%
%   Exemple :
%      y = [randn(1, 200), 4 * randn(1, 200), randn(1, 200)];
%      [pts, k] = wvarchg(y, 3);
%      k                              % 2 : deux ruptures
%      sort(pts)                      % voisins de 200 et 400
%
%   Voir aussi WNOISEST, MODWTVAR, WDEN.
    if nargin < 2 || isempty(K), K = 6; end
    if nargin < 3 || isempty(d), d = 10; end
    y = double(y(:)).';
    n = numel(y);
    K = min(round(K), floor(n / max(d, 1)) - 1);
    if K < 0, K = 0; end
    d = max(round(d), 1);
    % Coût d'un segment : n_i log(variance_i). Les sommes cumulées
    % donnent la variance de n'importe quel segment en temps constant.
    cumulSomme = [0, cumsum(y)];
    cumulCarre = [0, cumsum(y .^ 2)];
    cout = inf(n, n);
    for i = 1:n
        j = (i + d - 1):n;
        if isempty(j), continue; end
        longueur = j - i + 1;
        somme = cumulSomme(j + 1) - cumulSomme(i);
        carre = cumulCarre(j + 1) - cumulCarre(i);
        variance = max(carre ./ longueur - (somme ./ longueur) .^ 2, realmin);
        cout(i, j) = longueur .* log(variance);
    end
    % Programmation dynamique : meilleur(k, j) est le contraste minimal
    % d'une découpe de 1..j en k+1 segments.
    meilleur = inf(K + 1, n);
    origine = zeros(K + 1, n);
    meilleur(1, :) = cout(1, :);
    for k = 1:K
        for j = (k + 1) * d:n
            coupes = max(k * d, 1):(j - d);
            if isempty(coupes), continue; end
            candidats = meilleur(k, coupes) + cout(coupes + 1, j).';
            [valeur, position] = min(candidats);
            if isfinite(valeur)
                meilleur(k + 1, j) = valeur;
                origine(k + 1, j) = coupes(position);
            end
        end
    end
    contrastes = meilleur(:, n).';
    decoupes = cell(K + 1, 1);
    for k = 0:K
        decoupes{k + 1} = remonter(origine, k, n);
    end
    % Choix du nombre de ruptures : chacune doit gagner au moins la
    % pénalité, faute de quoi on découperait le bruit.
    penalite = 4 * log(n);
    nombreOptimal = 0;
    for k = 1:K
        if isfinite(contrastes(k + 1)) && ...
                contrastes(k) - contrastes(k + 1) > penalite
            nombreOptimal = k;
        else
            break
        end
    end
    points = decoupes{nombreOptimal + 1};
    if nargout > 2
        contrastes = struct('contraste', contrastes, 'decoupes', {decoupes});
    end
end

function points = remonter(origine, k, n)
%REMONTER Les instants de rupture d'une découpe optimale.
    points = zeros(1, k);
    j = n;
    for indice = k:-1:1
        coupe = origine(indice + 1, j);
        if coupe == 0
            points = [];
            return
        end
        points(indice) = coupe;
        j = coupe;
    end
end
