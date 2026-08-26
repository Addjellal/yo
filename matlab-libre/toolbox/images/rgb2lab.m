function lab = rgb2lab(rgb, varargin)
%RGB2LAB Passage de sRGB à L*a*b*.
%   L* va de 0 à 100, a* et b* sont centrés sur zéro. C'est l'espace où
%   les distances euclidiennes correspondent le mieux aux différences
%   perçues.
%
%   Exemple :
%      rgb2lab([1 1 1])   % [100 0 0]
    lab = xyz2lab(rgb2xyz(rgb), varargin{:});
end
