function message = matlibre_bch_extraire(mots, n, k, forme)
%MATLIBRE_BCH_EXTRAIRE Le message contenu dans des mots systématiques.
%
%   Fonction interne à la boîte à outils : elle n'existe pas dans MATLAB.
    switch forme
        case 'end'
            message = mots(:, (n - k + 1):n);
        case 'beg'
            message = mots(:, 1:k);
        case 'none'
            % Le mot est le produit du message par le générateur : on
            % divise pour retrouver le message.
            generateur = fliplr(bchgenpoly(n, k, [], 'double'));
            message = zeros(size(mots, 1), k);
            for ligne = 1:size(mots, 1)
                quotient = gfdeconv(fliplr(mots(ligne, :)), generateur, 2);
                message(ligne, :) = fliplr(completerLongueur(quotient, k));
            end
        otherwise
            error('comm:bchdec:Forme', ...
                  'La forme doit être ''end'', ''beg'' ou ''none''.');
    end
end
