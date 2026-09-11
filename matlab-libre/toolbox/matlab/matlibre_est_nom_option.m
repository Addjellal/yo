function t = matlibre_est_nom_option(valeur)
%MATLIBRE_EST_NOM_OPTION Une valeur peut-elle être le nom d'une option ?
%   T = MATLIBRE_EST_NOM_OPTION(V) rend vrai si V est un vecteur de
%   caractères d'une seule ligne, ou une chaîne unique.
%
%   Cela distingue « 'VariableNames' » d'une colonne de texte. Sans la
%   distinction, une colonne de deux lignes de caractères serait
%   examinée comme un nom d'option — ce qui n'a pas de sens, et ce qui a
%   déjà coûté une comparaison hors des bornes.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
%
%   Exemple :
%      matlibre_est_nom_option('VariableNames')    % 1
%      matlibre_est_nom_option(["a"; "b"])         % 0 : deux textes
%      matlibre_est_nom_option(['a'; 'b'])         % 0 : deux lignes
%
%   Voir aussi TABLE, TIMETABLE, DATETIME.
    if ischar(valeur)
        t = size(valeur, 1) == 1 && ~isempty(valeur);
    elseif isstring(valeur)
        t = isscalar(valeur);
    else
        t = false;
    end
end
