function N = matlibre_base_bspline(noeuds, ordre, x)
%MATLIBRE_BASE_BSPLINE Matrice des B-splines évaluées.
%   N = MATLIBRE_BASE_BSPLINE(NOEUDS,ORDRE,X) rend la matrice dont la
%   colonne j est la j-ième B-spline d'ordre ORDRE évaluée en X.
%
%   Les B-splines sont construites par la récurrence de Cox et de Boor :
%   celles d'ordre un sont les indicatrices des intervalles, et chaque
%   ordre suivant combine deux voisines d'ordre inférieur. Elles sont
%   positives, à support borné, et somment à un : une combinaison de
%   B-splines reste donc dans l'enveloppe de ses coefficients, ce qui rend
%   l'ajustement stable là où une base de monômes ne le serait pas.
%
%   Exemple :
%      N = matlibre_base_bspline([0 0 0 1 2 2 2], 3, [0.5; 1.5]);
%      sum(N, 2)      % des uns
%
%   Voir aussi SPAP2, FNVAL.
    noeuds = double(noeuds(:)).';
    x = double(x(:));
    nombre = numel(noeuds) - ordre;
    N = zeros(numel(x), nombre);
    for k = 1:numel(x)
        N(k, :) = matlibre_bspline_ligne(noeuds, ordre, nombre, x(k));
    end
end

function ligne = matlibre_bspline_ligne(noeuds, ordre, nombre, valeur)
    total = numel(noeuds) - 1;
    courant = zeros(1, total);
    dernier = noeuds(end);
    for i = 1:total
        if noeuds(i) <= valeur && valeur < noeuds(i + 1)
            courant(i) = 1;
        end
    end
    if valeur >= dernier
        % Le dernier point appartient au dernier intervalle non vide :
        % sans cette convention, la spline n'y serait pas définie.
        derniere = find(noeuds < dernier, 1, 'last');
        if ~isempty(derniere)
            courant(derniere) = 1;
        end
    end
    for degre = 2:ordre
        suivant = zeros(1, total);
        for i = 1:(total - degre + 1)
            gauche = 0;
            largeurGauche = noeuds(i + degre - 1) - noeuds(i);
            if largeurGauche > 0
                gauche = (valeur - noeuds(i)) / largeurGauche * courant(i);
            end
            droite = 0;
            largeurDroite = noeuds(i + degre) - noeuds(i + 1);
            if largeurDroite > 0
                droite = (noeuds(i + degre) - valeur) / largeurDroite * courant(i + 1);
            end
            suivant(i) = gauche + droite;
        end
        courant = suivant;
    end
    ligne = courant(1:nombre);
end
