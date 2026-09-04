function echelles = matlibre_echelles_brisk(octaves)
%MATLIBRE_ECHELLES_BRISK Échelles de la pyramide de BRISK.
%   E = MATLIBRE_ECHELLES_BRISK(OCTAVES) rend les échelles des couches :
%   une octave double l'échelle, et une couche intermédiaire s'intercale à
%   une fois et demie. Deux couches consécutives sont donc dans un rapport
%   d'environ 1,4, assez proche pour qu'un coin soit vu par au moins deux
%   d'entre elles.
%
%   Exemple :
%      matlibre_echelles_brisk(3)     % 1 1.5 2 3 4 6
%
%   Voir aussi DETECTBRISKFEATURES.
    puissances = 2 .^ (0:(octaves - 1));
    echelles = reshape([puissances; 1.5 * puissances], 1, []);
end
