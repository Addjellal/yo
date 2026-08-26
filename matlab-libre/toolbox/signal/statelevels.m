function [niveaux, histogramme, bornes] = statelevels(x, nbins, methode, limites)
%STATELEVELS Niveaux bas et haut d'un signal à deux états.
%   NIVEAUX = STATELEVELS(X) rend [BAS HAUT] par la méthode de
%   l'histogramme : l'étendue est découpée en NBINS classes (100 par
%   défaut), séparées en deux moitiés, et chaque niveau est le mode de sa
%   moitié. METHODE vaut 'mode' (par défaut) ou 'mean'.
%
%   [NIVEAUX,HISTOGRAMME,BORNES] = STATELEVELS(...) rend aussi le compte
%   par classe et les bornes utilisées.
%
%   Exemple :
%      statelevels([zeros(1,50) ones(1,50)])   % [0 1]
    if nargin < 2 || isempty(nbins), nbins = 100; end
    if nargin < 3 || isempty(methode), methode = 'mode'; end
    x = double(x(:));
    if nargin < 4 || isempty(limites)
        bornes = [min(x) max(x)];
    else
        bornes = [min(limites) max(limites)];
    end
    if bornes(2) <= bornes(1)
        niveaux = [bornes(1) bornes(1)];
        histogramme = numel(x);
        return
    end
    largeur = (bornes(2) - bornes(1)) / nbins;
    indices = min(nbins, max(1, floor((x - bornes(1)) / largeur) + 1));
    histogramme = zeros(nbins, 1);
    for k = 1:numel(indices)
        histogramme(indices(k)) = histogramme(indices(k)) + 1;
    end
    centres = bornes(1) + ((1:nbins)' - 0.5) * largeur;
    milieu = floor(nbins / 2);
    basPlage = 1:milieu;
    hautPlage = milieu+1:nbins;
    niveaux = [niveauMoitie(histogramme(basPlage), centres(basPlage), methode), ...
               niveauMoitie(histogramme(hautPlage), centres(hautPlage), methode)];
end

function v = niveauMoitie(compte, centres, methode)
    if sum(compte) == 0
        v = mean(centres);
        return
    end
    if strcmpi(char(methode), 'mean')
        v = sum(compte .* centres) / sum(compte);
    else
        [~, k] = max(compte);
        v = centres(k);
    end
end
