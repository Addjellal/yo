function tiledlayout(lignes, colonnes, varargin)
%TILEDLAYOUT Découpe la figure en cases, comme SUBPLOT.
%   TILEDLAYOUT(M,N) prépare un découpage en M lignes et N colonnes. Les
%   cases se remplissent ensuite une à une par NEXTTILE, dans l'ordre de
%   lecture — c'est ce qui distingue cette disposition de SUBPLOT, où l'on
%   nomme la case à chaque fois.
%
%   TILEDLAYOUT('flow') laisse le nombre de cases se décider à mesure :
%   MatLibre prend alors trois colonnes.
%
%   Les options de MATLAB — 'TileSpacing', 'Padding' — sont acceptées et
%   sans effet : l'espacement des cases n'est pas réglable ici.
%
%   Exemple :
%      tiledlayout(2, 2);
%      nexttile; plot(1:10);
%      nexttile; plot(sin(1:10));
%      nexttile; bar([3 1 2]);
%
%   Voir aussi NEXTTILE, SUBPLOT, FIGURE, AXES.
    if nargin < 1
        lignes = 1;
        colonnes = 1;
    end
    if ischar(lignes) || isstring(lignes)
        % « flow » : on ne sait pas encore combien de cases, on en prévoit
        % de quoi voir venir.
        lignes = 2;
        colonnes = 3;
    elseif nargin < 2 || ischar(colonnes) || isstring(colonnes)
        colonnes = 1;
    end
    matlibre_cases(round(lignes), round(colonnes), 0);
end
