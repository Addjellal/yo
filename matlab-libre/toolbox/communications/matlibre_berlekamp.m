function localisateur = matlibre_berlekamp(syndromes, t, m, prim, journal, exponentielle)
%MATLIBRE_BERLEKAMP Polynôme localisateur d'erreurs, par Berlekamp-Massey.
%   Le polynôme rendu est à coefficients dans GF(2^m), par puissances
%   croissantes, de terme constant un. Ses racines inverses désignent les
%   positions en erreur.
%
%   L'algorithme construit le plus court registre à décalage qui engendre
%   la suite des syndromes : c'est cette longueur minimale qui garantit
%   qu'on ne corrige pas plus d'erreurs qu'il n'y en a.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    if nargin < 5
        [journal, exponentielle] = matlibre_gf_journal(m, prim);
    end
    localisateur = 1;          % sigma(x) = 1
    precedent = 1;             % le meilleur avant la dernière correction
    decalage = 1;
    ecartPrecedent = 1;
    for k = 1:(2 * t)
        % L'écart : ce que le registre courant prédit de travers.
        ecart = syndromes(k);
        for j = 2:numel(localisateur)
            if k - j + 1 >= 1
                ecart = bitxor(ecart, ...
                    matlibre_gf_mul(localisateur(j), syndromes(k - j + 1), m, prim));
            end
        end
        if ecart == 0
            decalage = decalage + 1;
            continue
        end
        facteur = matlibre_gf_div(ecart, ecartPrecedent, m, prim);
        correction = [zeros(1, decalage), ...
                      matlibre_gf_mul(precedent, repmat(facteur, size(precedent)), m, prim)];
        nouveau = localisateur;
        if numel(correction) > numel(nouveau)
            nouveau = [nouveau, zeros(1, numel(correction) - numel(nouveau))];
        else
            correction = [correction, zeros(1, numel(nouveau) - numel(correction))];
        end
        nouveau = bitxor(nouveau, correction);
        if 2 * (numel(localisateur) - 1) <= k - 1
            precedent = localisateur;
            ecartPrecedent = ecart;
            decalage = 1;
        else
            decalage = decalage + 1;
        end
        localisateur = nouveau;
    end
    % Les zéros de tête ne portent rien.
    dernier = find(localisateur ~= 0, 1, 'last');
    localisateur = localisateur(1:dernier);
end
