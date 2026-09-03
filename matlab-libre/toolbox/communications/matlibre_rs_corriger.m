function [mot, nombre] = matlibre_rs_corriger(mot, n, t, m, prim)
%MATLIBRE_RS_CORRIGER Corrige un mot de Reed-Solomon reçu.
%   Syndromes, Berlekamp-Massey, recherche de Chien pour les positions,
%   puis formule de Forney pour la valeur de chaque erreur.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    [journal, exponentielle] = matlibre_gf_journal(m, prim);
    ordre = 2 ^ m - 1;
    syndromes = zeros(1, 2 * t);
    for i = 1:(2 * t)
        somme = 0;
        for pos = 1:n
            if mot(pos) ~= 0
                exposant = mod(i * (n - pos), ordre);
                somme = bitxor(somme, ...
                    matlibre_gf_mul(mot(pos), exponentielle(exposant + 1), m, prim));
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
    % Polynôme d'évaluation : le produit du syndrome par le localisateur,
    % tronqué au degré 2t-1.
    evaluation = matlibre_gf_convolution(syndromes, localisateur, m, prim);
    evaluation = evaluation(1:min(numel(evaluation), 2 * t));
    derivee = matlibre_derivee_formelle(localisateur);
    for k = 1:numel(positions)
        i = positions(k);
        indice = n - i;
        if indice < 1 || indice > n
            nombre = -1;
            return
        end
        % Forney : la valeur de l'erreur en position i vaut
        % X^(1-b) Omega(X^-1) / Lambda'(X^-1), où X est alpha^i. Les
        % syndromes étant pris à partir d'alpha — b vaut un —, le facteur
        % X^(1-b) vaut un et le quotient suffit.
        inverse = mod(-i, ordre);
        haut = matlibre_gf_evaluer(evaluation, inverse, m, prim, journal, exponentielle);
        bas = matlibre_gf_evaluer(derivee, inverse, m, prim, journal, exponentielle);
        if bas == 0
            nombre = -1;
            return
        end
        valeur = matlibre_gf_div(haut, bas, m, prim);
        mot(indice) = bitxor(mot(indice), valeur);
    end
    nombre = numel(positions);
end
