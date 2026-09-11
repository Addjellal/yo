function h = sgtitle(varargin)
%SGTITLE Titre commun à tous les sous-graphes d'une figure.
%   SGTITLE(TXT) pose TXT au-dessus de l'ensemble des sous-graphes.
%   H = SGTITLE(...) rend la poignée du texte.
%
%   La différence avec TITLE tient à la portée : TITLE nomme un axe,
%   SGTITLE nomme la figure entière. C'est ce qu'il faut quand plusieurs
%   sous-graphes racontent une même chose sous des angles différents.
%
%   Le rendu étant plan et sans zone réservée au-dessus des axes, le titre
%   est posé sur le premier sous-graphe : il est lisible et se retrouve à
%   l'impression, mais il n'est pas centré sur la figure comme dans
%   MATLAB. C'est la seule différence, et elle est dite ici plutôt que
%   laissée à découvrir.
%
%   Exemple :
%      figure;
%      subplot(1, 2, 1); plot(1:10);
%      subplot(1, 2, 2); plot(10:-1:1);
%      sgtitle('Deux vues du meme signal');
%      close all;
%
%   Voir aussi TITLE, SUBPLOT, SUBTITLE, XLABEL.
    axePrecedent = gca;
    enfants = get(gcf, 'Children');
    if ~isempty(enfants)
        axes(enfants(end));
    end
    poignee = title(varargin{:});
    axes(axePrecedent);
    if nargout > 0
        h = poignee;
    end
end
