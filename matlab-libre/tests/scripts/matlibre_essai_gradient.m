function [valeur, gradient] = matlibre_essai_gradient(fonction, x)
%MATLIBRE_ESSAI_GRADIENT Valeur et dérivée d'une fonction d'essai.
%   [V,G] = MATLIBRE_ESSAI_GRADIENT(FONCTION,X) sert aux vérifications de
%   la dérivation automatique : elle s'appelle depuis DLFEVAL.
    valeur = fonction(x);
    gradient = dlgradient(valeur, x);
end
