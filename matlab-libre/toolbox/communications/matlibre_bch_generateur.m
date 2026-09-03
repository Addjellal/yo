function [generateur, t, kEffectif] = matlibre_bch_generateur(n, k, m, prim)
%MATLIBRE_BCH_GENERATEUR Générateur d'un code BCH, par puissances
%   décroissantes.
%   On accumule les polynômes minimaux de alpha, alpha^2, ... jusqu'à ce
%   que le degré du produit atteigne n-k. La capacité de correction est
%   le nombre de racines consécutives ainsi annulées, divisé par deux.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    redondance = n - k;
    if redondance < 1 || k < 1
        error('comm:bch:Dimension', ...
              'La dimension doit rester entre un et %d.', n - 1);
    end
    [journal, exponentielle] = matlibre_gf_journal(m, prim);
    dejaPrise = false(1, n);
    % Le produit est tenu par puissances croissantes, puis retourné.
    produit = 1;
    t = 0;
    racine = 1;
    while numel(produit) - 1 < redondance
        if racine > n
            error('comm:bch:Impossible', ...
                  'Aucun code BCH de longueur %d et de dimension %d.', n, k);
        end
        if ~dejaPrise(racine)
            classe = racine;
            courant = mod(racine * 2, n);
            while courant ~= racine
                classe(end + 1) = courant;   %#ok<AGROW>
                courant = mod(courant * 2, n);
            end
            for j = 1:numel(classe)
                dejaPrise(classe(j)) = true;
            end
            minimal = matlibre_gf_minimal(classe, m, prim, journal, exponentielle);
            produit = matlibre_gf2_conv(produit, minimal);
        end
        if mod(racine, 2) == 1
            t = (racine + 1) / 2;
        end
        racine = racine + 1;
    end
    if numel(produit) - 1 ~= redondance
        error('comm:bch:Dimension', ...
              ['Il n''y a pas de code BCH de longueur %d et de dimension ' ...
               '%d ; la plus proche est %d.'], n, k, n - (numel(produit) - 1));
    end
    kEffectif = n - (numel(produit) - 1);
    generateur = fliplr(produit);
end
