function [t, periode] = matlibre_sl_instant(nouveau, nouvellePeriode)
%MATLIBRE_SL_INSTANT L'instant de la simulation, pour le code d'un bloc.
%   [T,TS] = MATLIBRE_SL_INSTANT() rend l'instant où calcule le bloc
%   MATLAB Function qui l'appelle, et la période d'échantillonnage de ce
%   bloc : sa période s'il en a une, héritée ou donnée ; 0 s'il est
%   continu. Hors d'une simulation, T et TS valent ce qu'ils valaient au
%   dernier appel, 0 au départ.
%
%   MATLIBRE_SL_INSTANT(T,TS) les règle : SIM le fait avant d'appeler la
%   fonction d'un bloc qui s'en sert. Les blocs de la bibliothèque que
%   MatLibre écrit en MATLAB Function — le PID discret, l'intégrateur
%   discret borné, les retards variables — y lisent leur pas.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_sl_instant(0.5, 0.1);
%      [t, Ts] = matlibre_sl_instant()          % 0.5 et 0.1
%
%   Voir aussi SIM, ADD_BLOCK.
    persistent instant pas
    if isempty(instant)
        instant = 0;
        pas = 0;
    end
    if nargin >= 1
        instant = nouveau;
        pas = 0;
        if nargin >= 2
            pas = nouvellePeriode;
        end
    end
    t = instant;
    periode = pas;
end
