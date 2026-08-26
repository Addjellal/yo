function mra = modwtmra(w, nom)
%MODWTMRA Analyse multirésolution issue d'une MODWT.
%   MRA = MODWTMRA(W,NOM) rend, pour chaque ligne de W, la composante du
%   signal qu'elle porte : leur somme redonne le signal exactement.
%
%   Exemple :
%      w = modwt(1:8, 'haar', 2);
%      max(abs(sum(modwtmra(w, 'haar')) - (1:8)))   % nul
    if nargin < 2 || isempty(nom), nom = 'haar'; end
    lignes = size(w, 1);
    mra = zeros(size(w));
    for k = 1:lignes
        isole = zeros(size(w));
        isole(k, :) = w(k, :);
        mra(k, :) = imodwt(isole, nom);
    end
end
