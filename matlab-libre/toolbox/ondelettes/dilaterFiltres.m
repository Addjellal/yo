function [bas, haut] = dilaterFiltres(Lo, Hi, niveau)
%DILATERFILTRES Insère 2^niveau - 1 zéros entre les coefficients.
%   C'est l'algorithme « à trous » : au lieu de décimer le signal, on
%   étire le filtre, ce qui garde toutes les positions.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    facteur = 2 ^ niveau;
    if facteur == 1
        bas = Lo;
        haut = Hi;
        return
    end
    bas = zeros(1, (numel(Lo) - 1) * facteur + 1);
    haut = zeros(1, (numel(Hi) - 1) * facteur + 1);
    bas(1:facteur:end) = Lo;
    haut(1:facteur:end) = Hi;
end
