function [genre, analogique] = matlibre_genre_filtre(arguments)
%MATLIBRE_GENRE_FILTRE Démêle le type de bande et le mot-clé « s ».
%   [GENRE,ANALOGIQUE] = MATLIBRE_GENRE_FILTRE(ARGS) lit, dans les
%   arguments de queue de BUTTER, CHEBY1, CHEBY2 et ELLIP, le type de
%   bande — 'low', 'high', 'bandpass', 'stop' — et le mot-clé 's' qui
%   demande un filtre analogique. L'ordre des deux est indifférent, comme
%   dans MATLAB.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    genre = 'low';
    analogique = false;
    for k = 1:numel(arguments)
        mot = lower(char(arguments{k}));
        if strcmp(mot, 's')
            analogique = true;
        elseif ~isempty(mot)
            genre = mot;
        end
    end
end
