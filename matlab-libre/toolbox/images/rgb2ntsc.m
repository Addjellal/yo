function yiq = rgb2ntsc(rgb)
%RGB2NTSC Passage de RVB à l'espace YIQ de la télévision NTSC.
%   Y porte la luminance, I et Q la chrominance. La première ligne de la
%   matrice est celle de RGB2GRAY.
%
%   Exemple :
%      rgb2ntsc([1 1 1])   % [1 0 0]
    M = [0.299  0.587  0.114
         0.596 -0.274 -0.322
         0.211 -0.523  0.312];
    yiq = appliquerMatriceCouleur(im2double(rgb), M);
end
