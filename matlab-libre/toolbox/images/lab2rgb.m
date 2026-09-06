function rgb = lab2rgb(lab, varargin)
%LAB2RGB Passage de L*a*b* à sRGB.
%   RGB = LAB2RGB(LAB) convertit depuis l'espace perceptuel CIE L*a*b*,
%   où L est la clarté de 0 à 100, a et b les deux axes chromatiques.
%
%   L'intérêt de L*a*b* est que la distance euclidienne y correspond à peu
%   près à l'écart perçu : deux couleurs à même distance y paraissent
%   également différentes, ce qui n'est pas du tout le cas en RVB. C'est
%   pourquoi on y calcule les différences de couleur et les segmentations.
%
%   Il est aussi bien plus vaste que le sRGB : une conversion peut sortir
%   de l'intervalle [0,1], et il faut alors écrêter.
%
%   Exemple :
%      lab2rgb([100 0 0])              % blanc
%      lab2rgb([0 0 0])                % noir
%
%   Voir aussi RGB2LAB, YCBCR2RGB, NTSC2RGB.
    rgb = xyz2rgb(lab2xyz(lab, varargin{:}));
end
