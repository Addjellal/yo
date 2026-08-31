function image_ = getframe(varargin)
%GETFRAME Capture le contenu d'une figure.
%   F = GETFRAME capture la figure courante et rend une structure de deux
%   champs : F.cdata, l'image, et F.colormap, la carte de couleurs. C'est
%   ainsi que MATLAB construit les vues d'une animation, qu'on rejoue
%   ensuite avec MOVIE.
%
%   F = GETFRAME(H) capture la figure ou l'axe désigné.
%
%   MatLibre rend ses figures en SVG, non en tableau de pixels : F.cdata
%   est vide, et F.svg porte le dessin sous forme de texte. C'est ce
%   qu'il faut pour l'enregistrer ou le comparer ; ce qui manque est le
%   tableau de pixels que MOVIE rejouerait.
%
%   Exemples :
%      plot(1:10);
%      f = getframe;
%      numel(f.svg) > 0
%
%   Voir aussi MOVIE, SAVEAS, PRINT, SAVEFIG, EXPORTGRAPHICS.
    image_ = struct('cdata', [], 'colormap', [], 'svg', matlibre_svg());
end
