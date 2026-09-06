function uiresume(~)
%UIRESUME Reprend après UIWAIT.
%   UIRESUME(F) débloque un programme arrêté par UIWAIT.
%
%   Elle est sans effet ici : l'interface de MatLibre n'a pas de boucle
%   d'événements bloquante, si bien qu'UIWAIT rend la main aussitôt et
%   qu'il n'y a rien à reprendre. La fonction existe pour qu'un programme
%   écrit pour MATLAB s'exécute sans modification — elle ne fait pas
%   semblant d'attendre, elle ne bloque simplement jamais.
%
%   Exemple :
%      f = uifigure();
%      uiwait(f);                      % rend la main aussitot
%      uiresume(f);                    % sans effet
%
%   Voir aussi UIWAIT, UIFIGURE, CLOSEAPP.
end
