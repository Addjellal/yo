function [perte, gradients] = matlibre_essai_perte_reseau(reseau, X, cible)
%MATLIBRE_ESSAI_PERTE_RESEAU Perte d'un réseau et ses dérivées.
    perte = crossentropy(forward(reseau, X), cible);
    gradients = dlgradient(perte, reseau);
end
