% Les temps de montée (10 à 90 %) et d'établissement (à 2 %) d'une réponse
% indicielle de valeur finale YF, interpolés entre les échantillons.
function [montee, etablissement] = tempsDeReponse110(t, y, yf)
    passe = @(seuil) interp1(y(find(y >= seuil, 1) - 1:find(y >= seuil, 1)), ...
                             t(find(y >= seuil, 1) - 1:find(y >= seuil, 1)), seuil);
    montee = passe(0.9 * yf) - passe(0.1 * yf);
    hors = find(abs(y - yf) > 0.02 * yf, 1, 'last');
    etablissement = interp1(y(hors:hors + 1), t(hors:hors + 1), 0.98 * yf);
end
