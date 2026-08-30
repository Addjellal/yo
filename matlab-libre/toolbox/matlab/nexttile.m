function h = nexttile(indice)
%NEXTTILE Passe à la case suivante d'un TILEDLAYOUT.
%   NEXTTILE rend courante la case suivante du découpage préparé par
%   TILEDLAYOUT, et rend sa poignée.
%
%   NEXTTILE(K) va directement à la case K.
%
%   Sans TILEDLAYOUT préalable, la figure est découpée en une seule case.
%
%   Exemple :
%      tiledlayout(1, 2);
%      nexttile; plot(1:10); title('a gauche');
%      nexttile; plot(10:-1:1); title('a droite');
%
%   Voir aussi TILEDLAYOUT, SUBPLOT, AXES, GCA.
    [lignes, colonnes, courante] = matlibre_cases();
    if nargin > 0
        suivante = round(indice);
    else
        suivante = courante + 1;
    end
    if suivante > lignes * colonnes
        suivante = lignes * colonnes;
    end
    matlibre_cases(lignes, colonnes, suivante);
    h = subplot(lignes, colonnes, suivante);
end
