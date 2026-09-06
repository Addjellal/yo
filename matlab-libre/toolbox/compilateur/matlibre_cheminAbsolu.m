function tf = matlibre_cheminAbsolu(chemin)
%MATLIBRE_CHEMINABSOLU Vrai si le chemin ne dépend pas du dossier courant.
%   Une barre oblique en tête sous Unix, une lettre de lecteur suivie de
%   deux-points sous Windows, ou un chemin réseau à deux barres.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    chemin = char(chemin);
    if isempty(chemin)
        tf = false;
        return
    end
    tf = chemin(1) == '/' || chemin(1) == '\' || ...
         (numel(chemin) >= 2 && isletter(chemin(1)) && chemin(2) == ':');
end
