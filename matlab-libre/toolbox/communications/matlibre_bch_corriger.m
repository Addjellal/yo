function [mot, nombre] = matlibre_bch_corriger(mot, n, t, m, prim)
%MATLIBRE_BCH_CORRIGER Corrige un mot BCH reçu.
%   Syndromes, puis Berlekamp-Massey, puis recherche de Chien.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    [journal, exponentielle] = matlibre_gf_journal(m, prim);
    ordre = 2 ^ m - 1;
    % Syndrome numéro i : la valeur du mot reçu en alpha^i, pour i allant
    % de un à 2t. Un mot de code les annule tous.
    syndromes = zeros(1, 2 * t);
    for i = 1:(2 * t)
        somme = 0;
        for position = 1:n
            if mot(position) ~= 0
                % Le bit de rang « position » porte x^(n-position).
                exposant = mod(i * (n - position), ordre);
                somme = bitxor(somme, exponentielle(exposant + 1));
            end
        end
        syndromes(i) = somme;
    end
    if all(syndromes == 0)
        nombre = 0;
        return
    end
    localisateur = matlibre_berlekamp(syndromes, t, m, prim, journal, exponentielle);
    positions = matlibre_chien(localisateur, n, m, prim, journal, exponentielle);
    degre = numel(localisateur) - 1;
    if isempty(positions) || numel(positions) ~= degre || degre > t
        nombre = -1;
        return
    end
    for k = 1:numel(positions)
        indice = n - positions(k);
        if indice < 1 || indice > n
            nombre = -1;
            return
        end
        mot(indice) = 1 - mot(indice);
    end
    nombre = numel(positions);
end
