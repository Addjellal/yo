function [x, y, largeur, hauteur] = matlibre_sl_disposition(modele, rangs)
%MATLIBRE_SL_DISPOSITION Place les blocs d'un schéma sur la feuille.
%   [X,Y,L,H] = MATLIBRE_SL_DISPOSITION(MODELE,RANGS) rend le centre de
%   chaque bloc, ainsi que la largeur et la hauteur communes.
%
%   Les blocs d'une même couche sont ordonnés par la hauteur moyenne de
%   ceux qui les alimentent — le barycentre. Deux passes suffisent à
%   défaire l'essentiel des croisements ; les ranger dans l'ordre de
%   création en produirait à chaque embranchement.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      m = new_system('c');
%      m = add_block(m, 'constant', 'u', 'Value', 1);
%      m = add_block(m, 'gain', 'k', 'Gain', 2);
%      m = add_line(m, 'u', 'k');
%      [x, y] = matlibre_sl_disposition(m, matlibre_sl_rangs(m));
%      x(2) > x(1)                     % 1 : le gain est a droite
%
%   Voir aussi OPEN_SYSTEM, MATLIBRE_SL_RANGS.
    largeur = 1.7;
    hauteur = 1.0;
    ecartX = 3.2;
    ecartY = 1.9;
    n = numel(modele.blocs);
    x = zeros(1, n);
    y = zeros(1, n);
    if n == 0
        return
    end

    couches = cell(1, max(rangs) + 1);
    for k = 1:n
        couches{rangs(k) + 1}(end + 1) = k;
    end

    % Première pose : chaque couche centrée sur zéro.
    for c = 1:numel(couches)
        placerCouche(c);
    end
    % Deux passes de barycentre, de la gauche vers la droite.
    for passe = 1:2
        for c = 2:numel(couches)
            membres = couches{c};
            centres = zeros(1, numel(membres));
            for i = 1:numel(membres)
                centres(i) = barycentre(membres(i), y, modele.liens);
                if isnan(centres(i))
                    centres(i) = y(membres(i));
                end
            end
            [~, ordre] = sort(centres);
            couches{c} = membres(ordre);
            placerCouche(c);
        end
    end

    function placerCouche(c)
        membres = couches{c};
        hauteurTotale = (numel(membres) - 1) * ecartY;
        for i = 1:numel(membres)
            x(membres(i)) = (c - 1) * ecartX;
            y(membres(i)) = hauteurTotale / 2 - (i - 1) * ecartY;
        end
    end
end

function m = barycentre(bloc, y, liens)
% Hauteur moyenne des blocs qui alimentent celui-ci.
    if isempty(liens)
        m = NaN;
        return
    end
    sources = liens(liens(:, 2) == bloc, 1);
    if isempty(sources)
        m = NaN;
    else
        m = mean(y(sources));
    end
end
