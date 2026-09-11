function h = wordcloud(varargin)
%WORDCLOUD Nuage de mots, dont la taille suit la fréquence.
%   WORDCLOUD(MOTS,TAILLES) place chaque mot, écrit d'autant plus grand
%   que sa taille est élevée.
%   WORDCLOUD(TEXTE) compte les mots d'un texte et les place.
%   H = WORDCLOUD(...) rend les poignées des textes posés.
%
%   Le placement est en spirale : le mot le plus fréquent au centre, les
%   suivants tournant autour, chacun au premier endroit libre. C'est la
%   disposition usuelle, et elle a l'avantage de mettre au centre ce qu'on
%   veut voir d'abord.
%
%   Un nuage de mots ne mesure rien : deux aires ne se comparent pas à
%   l'œil, et l'ordre des mots y est celui du hasard du placement. Il
%   montre ce qui domine, non de combien — pour cela, un diagramme en
%   barres dit la vérité et se lit.
%
%   Exemple :
%      figure;
%      wordcloud(["chat" "chien" "oiseau"], [10 6 3]);
%      close all;
%
%   Voir aussi BAR, TEXT, HISTOGRAM, CATEGORICAL.
    [mots, tailles] = matlibre_nuage_entree(varargin);
    if isempty(mots)
        h = [];
        if nargout == 0, clear h; end
        return
    end
    [tailles, ordre] = sort(double(tailles(:))', 'descend');
    mots = mots(ordre);

    minimale = 8;
    maximale = 40;
    if max(tailles) > min(tailles)
        polices = minimale + (maximale - minimale) * ...
                  (tailles - min(tailles)) / (max(tailles) - min(tailles));
    else
        polices = repmat((minimale + maximale) / 2, 1, numel(tailles));
    end

    tenu = ishold;
    poignees = [];
    places = zeros(0, 4);          % x, y, demi-largeur, demi-hauteur
    for k = 1:numel(mots)
        % La largeur d'un mot tient a son nombre de lettres et a sa
        % police : c'est une estimation, mais elle suffit a eviter les
        % chevauchements, qui sont le seul defaut visible d'un nuage.
        demiLargeur = 0.3 * polices(k) * numel(char(mots(k))) / 40;
        demiHauteur = 0.6 * polices(k) / 40;
        [x, y] = matlibre_nuage_place(places, demiLargeur, demiHauteur);
        places(end + 1, :) = [x, y, demiLargeur, demiHauteur];   %#ok<AGROW>
        poignees = [poignees, text(x, y, char(mots(k)), ...
                                   'FontSize', polices(k), ...
                                   'HorizontalAlignment', 'center')];   %#ok<AGROW>
        hold on
    end
    axis([-1.2 1.2 -1.2 1.2]);
    axis off
    if ~tenu
        hold off
    end
    if nargout > 0
        h = poignees;
    end
end
