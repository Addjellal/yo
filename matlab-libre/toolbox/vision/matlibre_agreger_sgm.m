function total = matlibre_agreger_sgm(cout, P1, P2)
%MATLIBRE_AGREGER_SGM Propage le coût le long de quatre directions.
%   S = MATLIBRE_AGREGER_SGM(COUT) ajoute, en chaque pixel et pour chaque
%   disparité, le coût cumulé le long des quatre balayages — gauche à
%   droite, droite à gauche, haut en bas, bas en haut. La récurrence est
%
%      L(p,d) = C(p,d) + min( L(q,d),
%                             L(q,d±1) + P1,
%                             min_k L(q,k) + P2 ) - min_k L(q,k)
%
%   où q est le pixel précédent du balayage. Changer de disparité d'un cran
%   coûte P1, en changer davantage coûte P2 : la première pénalité laisse
%   passer les surfaces inclinées, la seconde retient les sauts sauf là où
%   la ressemblance les impose. La soustraction du minimum précédent
%   empêche le cumul de croître sans borne.
%
%   S = MATLIBRE_AGREGER_SGM(COUT,P1,P2) impose les deux pénalités.
%
%   Exemple :
%      c = rand(4, 5, 3);
%      size(matlibre_agreger_sgm(c))    % 4 5 3
%
%   Voir aussi DISPARITYSGM.
    if nargin < 2
        P1 = 5;
    end
    if nargin < 3
        P2 = 60;
    end
    total = zeros(size(cout));
    total = total + balayerColonnes(cout, 1, P1, P2);
    total = total + balayerColonnes(cout, -1, P1, P2);
    transposee = permute(cout, [2 1 3]);
    total = total + permute(balayerColonnes(transposee, 1, P1, P2), [2 1 3]);
    total = total + permute(balayerColonnes(transposee, -1, P1, P2), [2 1 3]);
end

function L = balayerColonnes(cout, sens, P1, P2)
% Un balayage horizontal : les colonnes sont parcourues dans l'ordre du
% sens donné, toutes les lignes et toutes les disparités à la fois.
    [~, l, ~] = size(cout);
    L = zeros(size(cout));
    if sens > 0
        ordre = 1:l;
    else
        ordre = l:-1:1;
    end
    precedent = cout(:, ordre(1), :);
    L(:, ordre(1), :) = precedent;
    for k = 2:numel(ordre)
        precedent = reshape(precedent, size(cout, 1), size(cout, 3));
        minimum = min(precedent, [], 2);
        % Les trois candidats : même disparité, disparité voisine, saut.
        voisinBas = [repmat(Inf, size(precedent, 1), 1), precedent(:, 1:end-1)] + P1;
        voisinHaut = [precedent(:, 2:end), repmat(Inf, size(precedent, 1), 1)] + P1;
        saut = repmat(minimum + P2, 1, size(precedent, 2));
        meilleur = min(min(precedent, voisinBas), min(voisinHaut, saut));
        courant = reshape(cout(:, ordre(k), :), size(precedent)) + ...
                  meilleur - repmat(minimum, 1, size(precedent, 2));
        L(:, ordre(k), :) = reshape(courant, size(precedent, 1), 1, size(precedent, 2));
        precedent = courant;
    end
end
