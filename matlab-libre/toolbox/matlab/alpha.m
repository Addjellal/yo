function alpha(valeur)
%ALPHA Transparence (acceptée, sans effet).
%   ALPHA(A) règle, dans MATLAB, la transparence des objets de l'axe
%   courant : A va de 0 — transparent — à 1 — opaque.
%   ALPHA('clear'), ALPHA('opaque') et ALPHA('flat') sont les formes
%   nommées.
%
%   Le rendu de MatLibre ne gère pas la transparence : l'appel est
%   accepté pour qu'un programme tourne sans retouche et ne change rien à
%   l'image.
%
%   Exemple :
%      surf(peaks(30)); alpha(0.5);
%
%   Voir aussi SHADING, COLORMAP, LIGHTING, PATCH, FILL.
    if nargin >= 1 && isnumeric(valeur) && (valeur < 0 || valeur > 1)
        error('MATLAB:alpha:BadValue', 'The transparency must lie between 0 and 1.');
    end
end
